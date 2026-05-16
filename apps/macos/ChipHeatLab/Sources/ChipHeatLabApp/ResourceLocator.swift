import Foundation

enum ResourceLocator {
    static func url(named name: String, extension ext: String? = nil, subdirectory: String? = nil) -> URL? {
        let fileName = ext.map { "\(name).\($0)" } ?? name
        for base in candidateBases() {
            let directory = subdirectory.map { base.appendingPathComponent($0) } ?? base
            let url = directory.appendingPathComponent(fileName)
            if FileManager.default.fileExists(atPath: url.path) {
                return url
            }
        }
        return nil
    }

    private static func candidateBases() -> [URL] {
        var bases: [URL] = []
        if let resourceURL = Bundle.main.resourceURL {
            bases.append(resourceURL)
        }
        bases.append(Bundle.main.bundleURL)
        bases.append(URL(fileURLWithPath: FileManager.default.currentDirectoryPath).appendingPathComponent("Resources"))
        if let executable = Bundle.main.executableURL {
            bases.append(executable.deletingLastPathComponent().appendingPathComponent("Resources"))
            bases.append(executable.deletingLastPathComponent())
        }
        return bases
    }
}
