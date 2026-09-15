import Foundation

/// Core engine that connects keyboard monitoring to audio playback
/// Equivalent to the original Tickeys struct in tickeys.rs
class TickeysEngine: ObservableObject {
    let keyboardMonitor = KeyboardMonitor()
    let audioEngine = AudioEngine()
    let schemeManager = SchemeManager()

    @Published var currentSchemeName: String = "" {
        didSet { Preferences.shared.schemeName = currentSchemeName }
    }
    @Published var volume: Float = 0.5 {
        didSet {
            audioEngine.volume = volume
            Preferences.shared.volume = volume
        }
    }
    @Published var pitch: Float = 1.0 {
        didSet {
            audioEngine.pitch = pitch
            Preferences.shared.pitch = pitch
        }
    }
    @Published var isMuted: Bool = false
    @Published var isRunning: Bool = false
    @Published var needsAccessibilityPermission: Bool = false

    let filterList = FilterList()

    // Secret key sequence detection (QAZ123)
    // keyCode: Q=12, A=0, Z=6, 1=18, 2=19, 3=20
    private let secretSequence: [Int64] = [12, 0, 6, 18, 19, 20]
    // Also support numpad: Q=12, A=0, Z=6, numpad1=83, numpad2=84, numpad3=85
    private let secretSequenceNumpad: [Int64] = [12, 0, 6, 83, 84, 85]
    private var recentKeys: [Int64] = []
    private let maxRecentKeys = 6

    /// Callback when secret sequence is detected
    var onOpenSettings: (() -> Void)?

    init() {
        loadPreferences()
        setupCallbacks()
    }

    private func loadPreferences() {
        let prefs = Preferences.shared
        volume = prefs.volume
        pitch = prefs.pitch

        if let name = prefs.schemeName, schemeManager.setScheme(name: name) {
            currentSchemeName = name
        } else if let first = schemeManager.schemes.first {
            currentSchemeName = first.name
            _ = schemeManager.setScheme(name: first.name)
        }
    }

    private func setupCallbacks() {
        keyboardMonitor.onKeyDown = { [weak self] keyCode in
            self?.handleKeyDown(keyCode: keyCode)
        }

        keyboardMonitor.onPermissionDenied = { [weak self] in
            DispatchQueue.main.async {
                self?.needsAccessibilityPermission = true
            }
        }

        keyboardMonitor.onPermissionGranted = { [weak self] in
            DispatchQueue.main.async {
                self?.needsAccessibilityPermission = false
            }
        }
    }

    /// Start the engine
    func start() {
        guard !isRunning else { return }

        // Load current scheme audio
        if let scheme = schemeManager.currentScheme {
            audioEngine.loadSchemeAudio(scheme: scheme, schemeManager: schemeManager)
        }

        keyboardMonitor.start()
        isRunning = true
        print("[TickeysEngine] Started")
    }

    /// Stop the engine
    func stop() {
        keyboardMonitor.stop()
        audioEngine.stopAll()
        isRunning = false
        print("[TickeysEngine] Stopped")
    }

    /// Switch to a different audio scheme
    func switchScheme(name: String) {
        guard schemeManager.setScheme(name: name) else { return }
        currentSchemeName = name
        if let scheme = schemeManager.currentScheme {
            audioEngine.loadSchemeAudio(scheme: scheme, schemeManager: schemeManager)
        }
    }

    /// Handle a key down event
    private func handleKeyDown(keyCode: Int64) {
        // Check secret sequence
        detectSecretSequence(keyCode: keyCode)

        // Don't play sound if muted or filtered
        guard !isMuted else { return }

        // Check app filter
        if filterList.shouldMute() {
            return
        }

        // Play sound
        guard let scheme = schemeManager.currentScheme else { return }
        let audioIndex = scheme.audioIndex(forKeyCode: Int(keyCode))
        audioEngine.play(bufferIndex: audioIndex)
    }

    /// Detect the secret key sequence QAZ123 to open settings
    private func detectSecretSequence(keyCode: Int64) {
        recentKeys.append(keyCode)
        if recentKeys.count > maxRecentKeys {
            recentKeys.removeFirst()
        }

        if recentKeys.count == maxRecentKeys {
            if recentKeys == secretSequence || recentKeys == secretSequenceNumpad {
                print("[TickeysEngine] Secret sequence detected! Opening settings...")
                recentKeys.removeAll()
                DispatchQueue.main.async { [weak self] in
                    self?.onOpenSettings?()
                }
            }
        }
    }

    /// Restart after system wake
    func handleSystemWake() {
        print("[TickeysEngine] System wake - restarting audio engine")
        audioEngine.restart()
    }
}
