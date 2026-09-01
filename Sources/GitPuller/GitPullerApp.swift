import SwiftUI

@main
struct GitPullerApp: App {
    @StateObject private var model = AppModel()

    var body: some Scene {
        Window("Git Puller", id: "main") {
            ContentView()
                .environmentObject(model)
        }
        .windowResizability(.contentMinSize)
        .commands {
            CommandGroup(replacing: .newItem) { }
            CommandMenu("Repositories") {
                Button("Pull All") { model.pullAll() }
                    .keyboardShortcut("r", modifiers: .command)
                    .disabled(model.isPulling || model.repos.isEmpty)

                Button("Refresh Branches") { model.refreshBranches() }
                    .keyboardShortcut("r", modifiers: [.command, .shift])
            }
        }
    }
}
