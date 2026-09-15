import Cocoa
import Foundation

/// Manages the app black/white list filtering
/// When an app in the filter list is in the foreground:
/// - BlackList mode: mute sounds
/// - WhiteList mode: only play sounds for listed apps
class FilterList: ObservableObject {
    enum Mode: Int {
        case blackList = 0
        case whiteList = 1
    }

    @Published var mode: Mode {
        didSet { Preferences.shared.filterMode = mode.rawValue }
    }

    @Published var bundleIds: [String] {
        didSet { Preferences.shared.filterBundleIds = bundleIds }
    }

    init() {
        self.mode = Mode(rawValue: Preferences.shared.filterMode) ?? .blackList
        self.bundleIds = Preferences.shared.filterBundleIds
    }

    /// Check if sounds should be muted for the current foreground app
    func shouldMute() -> Bool {
        guard !bundleIds.isEmpty else {
            // Empty list: blacklist means mute nothing, whitelist means mute everything
            return mode == .whiteList
        }

        guard let frontApp = NSWorkspace.shared.frontmostApplication,
              let bundleId = frontApp.bundleIdentifier else {
            return false
        }

        let isInList = bundleIds.contains(bundleId)

        switch mode {
        case .blackList:
            return isInList  // Mute if app is in blacklist
        case .whiteList:
            return !isInList  // Mute if app is NOT in whitelist
        }
    }

    /// Add an app's bundle identifier to the filter list
    func addApp(bundleId: String) {
        guard !bundleIds.contains(bundleId) else { return }
        bundleIds.append(bundleId)
    }

    /// Remove an app's bundle identifier from the filter list
    func removeApp(at index: Int) {
        guard index >= 0, index < bundleIds.count else { return }
        bundleIds.remove(at: index)
    }

    /// Get display name for a bundle identifier
    static func appName(for bundleId: String) -> String {
        if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleId) {
            return FileManager.default.displayName(atPath: url.path)
        }
        return bundleId
    }

    /// Get list of running applications (for adding to filter)
    static func runningApps() -> [(name: String, bundleId: String)] {
        return NSWorkspace.shared.runningApplications
            .filter { $0.activationPolicy == .regular }
            .compactMap { app -> (String, String)? in
                guard let bundleId = app.bundleIdentifier,
                      let name = app.localizedName else { return nil }
                return (name, bundleId)
            }
            .sorted { $0.0 < $1.0 }
    }
}
