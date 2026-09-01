import SwiftUI
import AppKit

struct ContentView: View {
    @EnvironmentObject var model: AppModel

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            repoList
            Divider()
            footer
        }
        .frame(minWidth: 620, minHeight: 460)
        .background(Color(nsColor: .windowBackgroundColor))
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 12) {
            Image(systemName: "arrow.triangle.branch")
                .font(.system(size: 22, weight: .medium))
                .foregroundStyle(.tint)

            VStack(alignment: .leading, spacing: 1) {
                Text("Git Puller").font(.headline)
                Text(model.summaryText)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button(action: model.pullAll) {
                HStack(spacing: 6) {
                    if model.isPulling {
                        ProgressView()
                            .controlSize(.small)
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "arrow.down.circle.fill")
                    }
                    Text(model.isPulling ? "Pulling…" : "Pull All")
                }
                .frame(minWidth: 86)
            }
            .controlSize(.large)
            .buttonStyle(.borderedProminent)
            .keyboardShortcut("r", modifiers: .command)
            .disabled(model.isPulling || model.repos.isEmpty)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    // MARK: - List

    private var repoList: some View {
        Group {
            if model.repos.isEmpty {
                emptyState
            } else {
                List(selection: $model.selection) {
                    ForEach(model.repos) { repo in
                        RepoRow(repo: repo, status: model.statuses[repo.id] ?? RepoStatus(id: repo.id))
                            .tag(repo.id)
                            .contextMenu {
                                Button("Reveal in Finder") { reveal(repo) }
                                Button("Copy Path") {
                                    NSPasteboard.general.clearContents()
                                    NSPasteboard.general.setString(repo.path, forType: .string)
                                }
                                Divider()
                                Button("Remove", role: .destructive) { model.remove(repo) }
                            }
                    }
                }
                .listStyle(.inset)
                .alternatingRows()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "folder.badge.plus")
                .font(.system(size: 38))
                .foregroundStyle(.tertiary)
            Text("No repositories")
                .font(.title3.weight(.medium))
            Text("Add a folder to start pulling.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Button("Add Repository…", action: chooseFolders)
                .padding(.top, 4)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Footer

    private var footer: some View {
        HStack(spacing: 8) {
            Button(action: chooseFolders) {
                Image(systemName: "plus")
            }
            .help("Add repository")

            Button(action: model.removeSelected) {
                Image(systemName: "minus")
            }
            .help("Remove selected repository")
            .disabled(model.selection == nil)

            Spacer()

            Text("\(model.repos.count) \(model.repos.count == 1 ? "repository" : "repositories")")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .buttonStyle(.borderless)
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
    }

    // MARK: - Actions

    private func chooseFolders() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = true
        panel.prompt = "Add"
        panel.message = "Choose one or more git repositories"
        if panel.runModal() == .OK {
            model.add(paths: panel.urls.map(\.path))
        }
    }

    private func reveal(_ repo: Repo) {
        NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: repo.path)
    }
}

// MARK: - Row

struct RepoRow: View {
    let repo: Repo
    let status: RepoStatus

    var body: some View {
        HStack(spacing: 11) {
            statusIcon
                .frame(width: 18)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(repo.name)
                        .font(.system(size: 13, weight: .medium))
                        .lineLimit(1)

                    if !status.branch.isEmpty {
                        Text(status.branch)
                            .font(.system(size: 10, weight: .medium, design: .monospaced))
                            .padding(.horizontal, 5)
                            .padding(.vertical, 1)
                            .background(Color.secondary.opacity(0.15), in: Capsule())
                            .foregroundStyle(.secondary)
                    }
                }

                Text(detailText)
                    .font(.system(size: 11))
                    .foregroundStyle(detailColor)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }

            Spacer()
        }
        .padding(.vertical, 4)
        .help(status.log.isEmpty ? repo.path : status.log)
    }

    @ViewBuilder
    private var statusIcon: some View {
        switch status.state {
        case .idle:
            Image(systemName: "circle.dashed")
                .foregroundStyle(.tertiary)
        case .running:
            ProgressView().controlSize(.small).scaleEffect(0.6)
        case .success:
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
        case .failure:
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
        }
    }

    private var detailText: String {
        switch status.state {
        case .idle:                 return repo.path
        case .running:              return "Pulling…"
        case .success(let message): return message
        case .failure(let message): return message
        }
    }

    private var detailColor: Color {
        if case .failure = status.state { return .orange }
        return .secondary
    }
}

// `alternatingRowBackgrounds` landed in macOS 14; fall back cleanly on 13.
private extension View {
    @ViewBuilder
    func alternatingRows() -> some View {
        if #available(macOS 14.0, *) {
            self.alternatingRowBackgrounds(.enabled)
        } else {
            self
        }
    }
}
