import Foundation

/// Runs git commands. A GUI app launched from Finder does not inherit the
/// user's shell PATH, so we resolve git explicitly and hand the child a
/// PATH that covers the usual install locations.
enum Git {

    struct Result {
        let output: String      // stdout + stderr combined
        let exitCode: Int32
        var ok: Bool { exitCode == 0 }
    }

    /// Located once, lazily: Homebrew (Apple silicon and Intel), Xcode's shim,
    /// then whatever `xcrun` reports.
    static let executable: String = {
        let candidates = [
            "/opt/homebrew/bin/git",
            "/usr/local/bin/git",
            "/usr/bin/git",
        ]
        for path in candidates where FileManager.default.isExecutableFile(atPath: path) {
            return path
        }
        return "/usr/bin/git"
    }()

    private static var childEnvironment: [String: String] {
        var env = ProcessInfo.processInfo.environment
        let extra = "/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
        env["PATH"] = (env["PATH"].map { "\($0):\(extra)" }) ?? extra
        // Never let git stop and wait for a password prompt we cannot answer;
        // a hung child process would freeze the pull with no way out.
        env["GIT_TERMINAL_PROMPT"] = "0"
        env["GIT_ASKPASS"] = env["GIT_ASKPASS"] ?? "/usr/bin/true"
        return env
    }

    /// Runs `git <args>` inside `directory` and waits for it to finish.
    static func run(_ args: [String], in directory: String) -> Result {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: executable)
        process.arguments = args
        process.currentDirectoryURL = URL(fileURLWithPath: directory)
        process.environment = childEnvironment

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe

        do {
            try process.run()
        } catch {
            return Result(output: "Failed to launch git: \(error.localizedDescription)", exitCode: -1)
        }

        // Read before waitUntilExit: a chatty pull can fill the pipe buffer and
        // deadlock if we wait first.
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()

        let text = String(data: data, encoding: .utf8) ?? ""
        return Result(output: text.trimmingCharacters(in: .whitespacesAndNewlines),
                      exitCode: process.terminationStatus)
    }

    static func isRepo(_ path: String) -> Bool {
        var isDir: ObjCBool = false
        guard FileManager.default.fileExists(atPath: path, isDirectory: &isDir), isDir.boolValue else {
            return false
        }
        return run(["rev-parse", "--is-inside-work-tree"], in: path).output == "true"
    }

    static func currentBranch(_ path: String) -> String {
        let result = run(["rev-parse", "--abbrev-ref", "HEAD"], in: path)
        return result.ok ? result.output : "—"
    }

    /// Pulls with rebase off and fast-forward preferred, so a clean repo stays clean.
    static func pull(_ path: String) -> Result {
        run(["pull", "--ff-only"], in: path)
    }
}
