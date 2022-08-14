import Foundation

/// The result of running an external command.
public struct CommandResult: Equatable, Sendable {
    /// Combined stdout and stderr, trimmed.
    public var output: String
    public var status: Int32

    public init(output: String, status: Int32) {
        self.output = output
        self.status = status
    }

    public var succeeded: Bool { status == 0 }
}

public enum Shell {
    /// Runs an executable and waits for it to exit. This blocks, so call it off the main thread.
    @discardableResult
    public static func run(_ path: String, _ args: [String]) -> CommandResult {
        let p = Process()
        p.executableURL = URL(fileURLWithPath: path)
        p.arguments = args
        let pipe = Pipe()
        p.standardOutput = pipe
        p.standardError = pipe
        do { try p.run() } catch { return CommandResult(output: error.localizedDescription, status: -1) }
        // Drain the pipe before waiting, or a chatty process can fill the buffer and deadlock.
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        p.waitUntilExit()
        let output = String(decoding: data, as: UTF8.self).trimmingCharacters(in: .whitespacesAndNewlines)
        return CommandResult(output: output, status: p.terminationStatus)
    }
}
