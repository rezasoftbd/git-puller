import Foundation
import SwiftUI

@MainActor
final class AppModel: ObservableObject {
    @Published var repos: [Repo] = []
    @Published var statuses: [UUID: RepoStatus] = [:]
    @Published var isPulling = false
    @Published var selection: UUID?

    init() {
        repos = Store.load()
        for repo in repos {
            statuses[repo.id] = RepoStatus(id: repo.id)
        }
        refreshBranches()
    }

    // MARK: - Repo management

    func add(paths: [String]) {
        for path in paths {
            let clean = (path as NSString).standardizingPath
            guard !repos.contains(where: { $0.path == clean }) else { continue }
            let repo = Repo(path: clean)
            repos.append(repo)
            var status = RepoStatus(id: repo.id)
            if !Git.isRepo(clean) {
                status.state = .failure("Not a git repository")
            }
            statuses[repo.id] = status
        }
        persist()
        refreshBranches()
    }

    func remove(_ repo: Repo) {
        repos.removeAll { $0.id == repo.id }
        statuses[repo.id] = nil
        if selection == repo.id { selection = nil }
        persist()
    }

    func removeSelected() {
        guard let id = selection, let repo = repos.first(where: { $0.id == id }) else { return }
        remove(repo)
    }

    private func persist() { Store.save(repos) }

    // MARK: - Git work

    func refreshBranches() {
        let snapshot = repos
        Task.detached {
            let branches: [(UUID, String)] = snapshot
                .filter { Git.isRepo($0.path) }
                .map { ($0.id, Git.currentBranch($0.path)) }

            await MainActor.run { [branches] in
                for (id, branch) in branches {
                    self.statuses[id]?.branch = branch
                }
            }
        }
    }

    /// Pulls every repo. Each runs on its own task so one slow remote does not
    /// hold up the rest.
    func pullAll() {
        guard !isPulling, !repos.isEmpty else { return }
        isPulling = true

        for repo in repos {
            statuses[repo.id]?.state = .running
            statuses[repo.id]?.log = ""
        }

        let snapshot = repos
        Task {
            await withTaskGroup(of: (UUID, PullState, String, String).self) { group in
                for repo in snapshot {
                    group.addTask {
                        guard Git.isRepo(repo.path) else {
                            return (repo.id, .failure("Not a git repository"), "", "")
                        }
                        let result = Git.pull(repo.path)
                        let branch = Git.currentBranch(repo.path)
                        let state: PullState = result.ok
                            ? .success(Self.summarize(result.output))
                            : .failure(Self.summarize(result.output))
                        return (repo.id, state, result.output, branch)
                    }
                }

                for await (id, state, log, branch) in group {
                    self.statuses[id]?.state = state
                    self.statuses[id]?.log = log
                    if !branch.isEmpty { self.statuses[id]?.branch = branch }
                }
            }
            self.isPulling = false
        }
    }

    /// Condenses git's multi-line output down to one line for the list row.
    private nonisolated static func summarize(_ output: String) -> String {
        let lines = output.split(separator: "\n").map(String.init)
        guard !lines.isEmpty else { return "Done" }

        if let updating = lines.first(where: { $0.contains("files changed") || $0.contains("file changed") }) {
            return updating.trimmingCharacters(in: .whitespaces)
        }
        if let upToDate = lines.first(where: { $0.localizedCaseInsensitiveContains("up to date") }) {
            return upToDate
        }
        if let error = lines.first(where: { $0.hasPrefix("fatal:") || $0.hasPrefix("error:") }) {
            return error
        }
        return lines.last ?? "Done"
    }

    // MARK: - Aggregate status for the footer

    var summaryText: String {
        if isPulling { return "Pulling…" }
        let states = repos.compactMap { statuses[$0.id]?.state }
        guard !states.isEmpty else { return "No repositories yet" }

        let failed = states.filter { if case .failure = $0 { return true }; return false }.count
        let done = states.filter { if case .success = $0 { return true }; return false }.count

        if done == 0 && failed == 0 { return "\(repos.count) repositories" }
        if failed == 0 { return "Pulled \(done) of \(repos.count)" }
        return "Pulled \(done), \(failed) failed"
    }
}
