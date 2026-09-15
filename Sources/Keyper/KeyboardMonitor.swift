import Foundation
import CoreGraphics
import ApplicationServices
import Cocoa

/// Monitors global keyboard events using CGEventTap
/// Requires Accessibility permissions in System Settings
class KeyboardMonitor {
    /// Called on every key down event with the keyCode
    var onKeyDown: ((Int64) -> Void)?

    /// Called when accessibility permission is missing
    var onPermissionDenied: (() -> Void)?

    /// Called when accessibility permission is granted and monitoring begins
    var onPermissionGranted: (() -> Void)?

    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var monitorThread: Thread?
    private(set) var isRunning = false
    private var permissionPollTimer: Timer?

    deinit {
        stop()
    }

    /// Check if process has accessibility permissions (non-prompting)
    static func hasAccessibilityPermission() -> Bool {
        let key = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String
        let options: NSDictionary = [key: false]
        return AXIsProcessTrustedWithOptions(options as CFDictionary)
    }

    /// Request accessibility permissions from system (will show system prompt if needed)
    @discardableResult
    static func requestAccessibilityPermission() -> Bool {
        let key = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String
        let options: NSDictionary = [key: true]
        return AXIsProcessTrustedWithOptions(options as CFDictionary)
    }

    /// Open System Settings directly to Privacy & Security -> Accessibility
    static func openAccessibilitySettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }

    /// Start monitoring keyboard events.
    /// If accessibility permission is not yet granted, requests it and polls in background until granted.
    func start() {
        guard !isRunning else { return }

        if !KeyboardMonitor.hasAccessibilityPermission() {
            print("[KeyboardMonitor] Accessibility permission not yet granted. Requesting...")
            KeyboardMonitor.requestAccessibilityPermission()
            onPermissionDenied?()
            startPollingForPermission()
            return
        }

        startEventTapThread()
    }

    /// Stop monitoring and polling
    func stop() {
        stopPollingForPermission()
        isRunning = false

        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
        }
        if let source = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetCurrent(), source, .commonModes)
        }
        eventTap = nil
        runLoopSource = nil
        monitorThread = nil
    }

    private func startPollingForPermission() {
        stopPollingForPermission()
        DispatchQueue.main.async { [weak self] in
            self?.permissionPollTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
                guard let self = self else {
                    timer.invalidate()
                    return
                }
                if KeyboardMonitor.hasAccessibilityPermission() {
                    print("[KeyboardMonitor] Accessibility permission granted by user!")
                    timer.invalidate()
                    self.permissionPollTimer = nil
                    self.onPermissionGranted?()
                    self.startEventTapThread()
                }
            }
        }
    }

    private func stopPollingForPermission() {
        permissionPollTimer?.invalidate()
        permissionPollTimer = nil
    }

    private func startEventTapThread() {
        guard !isRunning else { return }
        isRunning = true
        monitorThread = Thread { [weak self] in
            self?.setupEventTap()
        }
        monitorThread?.name = "com.tickeys.keyboard-monitor"
        monitorThread?.qualityOfService = .userInteractive
        monitorThread?.start()
    }

    private func setupEventTap() {
        let eventMask: CGEventMask = (1 << CGEventType.keyDown.rawValue)

        let callback: CGEventTapCallBack = { proxy, type, event, refcon -> Unmanaged<CGEvent>? in
            guard let refcon = refcon else {
                return Unmanaged.passUnretained(event)
            }

            let monitor = Unmanaged<KeyboardMonitor>.fromOpaque(refcon).takeUnretainedValue()

            // Re-enable tap if disabled by timeout
            if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
                if let tap = monitor.eventTap {
                    CGEvent.tapEnable(tap: tap, enable: true)
                }
                return Unmanaged.passUnretained(event)
            }

            if type == .keyDown {
                let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
                monitor.onKeyDown?(keyCode)
            }

            return Unmanaged.passUnretained(event)
        }

        let refcon = Unmanaged.passUnretained(self).toOpaque()

        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .listenOnly,
            eventsOfInterest: eventMask,
            callback: callback,
            userInfo: refcon
        ) else {
            print("[KeyboardMonitor] Failed to create CGEventTap, will retry in 1s...")
            isRunning = false
            DispatchQueue.main.async { [weak self] in
                self?.onPermissionDenied?()
                self?.startPollingForPermission()
            }
            return
        }

        self.eventTap = tap

        let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        self.runLoopSource = source
        CFRunLoopAddSource(CFRunLoopGetCurrent(), source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)

        print("[KeyboardMonitor] CGEventTap running successfully")
        DispatchQueue.main.async { [weak self] in
            self?.onPermissionGranted?()
        }

        // Run the loop - blocks thread
        CFRunLoopRun()
    }
}
