import Foundation

/// A repository the user has added to the app.
struct Repo: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var path: String

    /// Folder name, used as the display name in the list.
    var name: String { (path as NSString).lastPathComponent }
}

/// Outcome of pulling a single repo.
enum PullState: Equatable {
    case idle
    case running
    case success(String)   // summary line, e.g. "Already up to date."
    case failure(String)

    var isRunning: Bool { self == .running }
}

/// Everything the UI needs to know about one repo at a moment in time.
struct RepoStatus: Identifiable {
    let id: UUID
    var branch: String = ""
    var state: PullState = .idle
    /// Full stdout+stderr of the last pull, shown in the detail pane.
    var log: String = ""
}

/// Persists the repo list to ~/Library/Application Support/GitPuller/repos.json
enum Store {
    private static var fileURL: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("GitPuller", isDirectory: true)
        try? FileManager.default.createDirectory(at: base, withIntermediateDirectories: true)
        return base.appendingPathComponent("repos.json")
    }

    static func load() -> [Repo] {
        guard let data = try? Data(contentsOf: fileURL),
              let repos = try? JSONDecoder().decode([Repo].self, from: data) else { return [] }
        return repos
    }

    static func save(_ repos: [Repo]) {
        guard let data = try? JSONEncoder().encode(repos) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }
}
