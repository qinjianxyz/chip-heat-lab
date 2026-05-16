import Foundation

enum RustRunnerError: Error, LocalizedError {
    case missingExecutable
    case processFailed(Int32, String)
    case noOutput

    var errorDescription: String? {
        switch self {
        case .missingExecutable:
            return "Missing bundled chip_heat_cli executable. Build Rust and copy it into Resources/bin."
        case .processFailed(let code, let stderr):
            return "chip_heat_cli exited with \(code): \(stderr)"
        case .noOutput:
            return "chip_heat_cli returned no JSON output."
        }
    }
}

final class RustRunner {
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()

    func run(_ input: ScenarioInput) async throws -> SimulationResult {
        try await Task.detached(priority: .userInitiated) {
            let executableURL = try Self.resolveExecutableURL()
            let process = Process()
            process.executableURL = executableURL

            let stdin = Pipe()
            let stdout = Pipe()
            let stderr = Pipe()
            process.standardInput = stdin
            process.standardOutput = stdout
            process.standardError = stderr

            let payload = try self.encoder.encode(input)
            try process.run()
            stdin.fileHandleForWriting.write(payload)
            try stdin.fileHandleForWriting.close()
            process.waitUntilExit()

            let output = stdout.fileHandleForReading.readDataToEndOfFile()
            let errorOutput = stderr.fileHandleForReading.readDataToEndOfFile()
            if process.terminationStatus != 0 {
                let stderrText = String(data: errorOutput, encoding: .utf8) ?? ""
                throw RustRunnerError.processFailed(process.terminationStatus, stderrText)
            }
            guard !output.isEmpty else {
                throw RustRunnerError.noOutput
            }
            return try self.decoder.decode(SimulationResult.self, from: output)
        }.value
    }

    private static func resolveExecutableURL() throws -> URL {
        if let override = ProcessInfo.processInfo.environment["CHIP_HEAT_CLI_PATH"], !override.isEmpty {
            return URL(fileURLWithPath: override)
        }
        if let bundled = ResourceLocator.url(named: "chip_heat_cli", subdirectory: "bin") {
            return bundled
        }
        throw RustRunnerError.missingExecutable
    }
}
