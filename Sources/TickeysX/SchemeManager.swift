import Foundation

/// Manages loading and switching audio schemes
class SchemeManager {
    private(set) var schemes: [AudioScheme] = []
    private(set) var currentScheme: AudioScheme?

    init() {
        loadSchemes()
    }

    /// Load all schemes from the bundled schemes.json
    func loadSchemes() {
        // 1. Check Bundle.main/data/schemes.json (inside .app bundle)
        if let mainResURL = Bundle.main.resourceURL {
            let directURL = mainResURL.appendingPathComponent("data/schemes.json")
            if FileManager.default.fileExists(atPath: directURL.path) {
                loadSchemes(from: directURL)
                return
            }
        }

        // 2. Check developmentDataPath/schemes.json
        if let devURL = developmentDataPath()?.appendingPathComponent("schemes.json"),
           FileManager.default.fileExists(atPath: devURL.path) {
            loadSchemes(from: devURL)
            return
        }

        // 3. Check Bundle.module
        if let url = Bundle.module.url(forResource: "schemes", withExtension: "json", subdirectory: "data") {
            loadSchemes(from: url)
            return
        }

        print("[SchemeManager] Failed to find schemes.json in any location")
    }

    private func loadSchemes(from url: URL) {
        do {
            let data = try Data(contentsOf: url)
            schemes = try JSONDecoder().decode([AudioScheme].self, from: data)
            print("[SchemeManager] Loaded \(schemes.count) schemes: \(schemes.map { $0.name })")
            if currentScheme == nil, let first = schemes.first {
                currentScheme = first
            }
        } catch {
            print("[SchemeManager] Failed to load schemes from \(url.path): \(error)")
        }
    }

    /// Set the active scheme by name
    func setScheme(name: String) -> Bool {
        guard let scheme = schemes.first(where: { $0.name == name }) else {
            print("[SchemeManager] Scheme not found: \(name)")
            return false
        }
        currentScheme = scheme
        print("[SchemeManager] Active scheme: \(scheme.displayName)")
        return true
    }

    /// Get URL for a specific audio file in a scheme
    func audioFileURL(scheme: AudioScheme, fileName: String) -> URL? {
        // 1. Check Bundle.main Resources/data/<scheme>/<file>
        if let mainResURL = Bundle.main.resourceURL {
            let directURL = mainResURL.appendingPathComponent("data").appendingPathComponent(scheme.name).appendingPathComponent(fileName)
            if FileManager.default.fileExists(atPath: directURL.path) {
                return directURL
            }
        }

        // 2. Check development / relative path
        if let devPath = developmentDataPath()?.appendingPathComponent(scheme.name).appendingPathComponent(fileName) {
            if FileManager.default.fileExists(atPath: devPath.path) {
                return devPath
            }
        }

        // 3. Check Bundle.module
        let nameWithoutExt = (fileName as NSString).deletingPathExtension
        let ext = (fileName as NSString).pathExtension
        if let url = Bundle.module.url(forResource: nameWithoutExt,
                                        withExtension: ext,
                                        subdirectory: "data/\(scheme.name)") {
            return url
        }

        return nil
    }

    /// Development fallback: look for data directory relative to executable
    private func developmentDataPath() -> URL? {
        let execURL = URL(fileURLWithPath: CommandLine.arguments[0])
        // Check ../Resources/data (for .app bundle)
        let resourcePath = execURL
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("Resources")
            .appendingPathComponent("data")
        if FileManager.default.fileExists(atPath: resourcePath.path) {
            return resourcePath
        }
        // Check relative to working directory
        let cwdPath = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent("Sources/TickeysX/Resources/data")
        if FileManager.default.fileExists(atPath: cwdPath.path) {
            return cwdPath
        }
        return nil
    }
}
