import Foundation
import ServiceManagement

/// Manages user preferences using UserDefaults and ServiceManagement
class Preferences {
    static let shared = Preferences()

    private let defaults = UserDefaults.standard

    private enum Keys {
        static let schemeName = "keyper_scheme"
        static let volume = "keyper_volume"
        static let pitch = "keyper_pitch"
        static let filterMode = "keyper_filter_mode"
        static let filterList = "keyper_filter_list"
        static let prefExists = "keyper_pref_exists"
        static let launchAtLogin = "keyper_launch_at_login"
    }

    var schemeName: String? {
        get { defaults.string(forKey: Keys.schemeName) }
        set { defaults.set(newValue, forKey: Keys.schemeName) }
    }

    var volume: Float {
        get {
            if defaults.bool(forKey: Keys.prefExists) {
                return defaults.float(forKey: Keys.volume)
            }
            return 0.5  // default
        }
        set {
            defaults.set(newValue, forKey: Keys.volume)
            defaults.set(true, forKey: Keys.prefExists)
        }
    }

    var pitch: Float {
        get {
            if defaults.bool(forKey: Keys.prefExists) {
                return defaults.float(forKey: Keys.pitch)
            }
            return 1.0  // default
        }
        set {
            defaults.set(newValue, forKey: Keys.pitch)
            defaults.set(true, forKey: Keys.prefExists)
        }
    }

    /// 0 = blacklist, 1 = whitelist
    var filterMode: Int {
        get { defaults.integer(forKey: Keys.filterMode) }
        set { defaults.set(newValue, forKey: Keys.filterMode) }
    }

    var filterBundleIds: [String] {
        get { defaults.stringArray(forKey: Keys.filterList) ?? [] }
        set { defaults.set(newValue, forKey: Keys.filterList) }
    }

    var launchAtLogin: Bool {
        get {
            if #available(macOS 13.0, *) {
                return SMAppService.mainApp.status == .enabled
            }
            return defaults.bool(forKey: Keys.launchAtLogin)
        }
        set {
            if #available(macOS 13.0, *) {
                do {
                    if newValue {
                        try SMAppService.mainApp.register()
                    } else {
                        try SMAppService.mainApp.unregister()
                    }
                } catch {
                    print("[Preferences] Failed to update launchAtLogin: \(error)")
                }
            }
            defaults.set(newValue, forKey: Keys.launchAtLogin)
        }
    }

    private init() {}
}
