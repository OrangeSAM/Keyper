import Foundation

/// Manages user preferences using UserDefaults
class Preferences {
    static let shared = Preferences()

    private let defaults = UserDefaults.standard

    private enum Keys {
        static let schemeName = "tickeys_scheme"
        static let volume = "tickeys_volume"
        static let pitch = "tickeys_pitch"
        static let filterMode = "tickeys_filter_mode"
        static let filterList = "tickeys_filter_list"
        static let prefExists = "tickeys_pref_exists"
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

    private init() {}
}
