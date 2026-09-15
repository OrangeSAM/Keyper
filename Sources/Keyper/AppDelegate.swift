import Cocoa
import SwiftUI

/// Main application delegate
/// Manages status bar, system events, and the Keyper engine
class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    var statusItem: NSStatusItem!
    var engine: KeyperEngine!
    var settingsWindow: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        print("[Keyper] Application starting...")

        // Initialize engine
        engine = KeyperEngine()
        engine.onOpenSettings = { [weak self] in
            self?.openSettings()
        }

        // Setup status bar
        setupStatusBar()

        // Setup system notifications
        setupSystemNotifications()

        // Start the engine
        engine.start()

        // If accessibility permission is not yet granted, guide user immediately
        if !KeyboardMonitor.hasAccessibilityPermission() {
            DispatchQueue.main.async { [weak self] in
                self?.showAccessibilityGuide()
            }
        }

        print("[Keyper] Application started. Type QAZ123 to open settings.")
    }

    func applicationWillTerminate(_ notification: Notification) {
        engine.stop()
        print("[Keyper] Application terminated")
    }

    // MARK: - Status Bar

    private func setupStatusBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "keyboard", accessibilityDescription: "Keyper")
            button.image?.size = NSSize(width: 18, height: 18)
        }

        let menu = NSMenu()
        menu.delegate = self
        statusItem.menu = menu
    }

    // Dynamic menu update when user clicks menu bar icon
    func menuNeedsUpdate(_ menu: NSMenu) {
        menu.removeAllItems()

        let titleItem = NSMenuItem(title: "⌨️ Keyper", action: nil, keyEquivalent: "")
        titleItem.isEnabled = false
        menu.addItem(titleItem)

        if !KeyboardMonitor.hasAccessibilityPermission() {
            let warnItem = NSMenuItem(
                title: "⚠️ 未授权辅助功能 (点击去开启)",
                action: #selector(openAccessibilitySettings),
                keyEquivalent: ""
            )
            warnItem.target = self
            menu.addItem(warnItem)
        } else {
            let currentScheme = engine.schemeManager.currentScheme?.displayName ?? engine.currentSchemeName
            let statusItem = NSMenuItem(title: "音效: \(currentScheme)", action: nil, keyEquivalent: "")
            statusItem.isEnabled = false
            menu.addItem(statusItem)
        }

        menu.addItem(NSMenuItem.separator())

        let settingsItem = NSMenuItem(title: "设置... (QAZ123)", action: #selector(openSettings), keyEquivalent: ",")
        settingsItem.target = self
        menu.addItem(settingsItem)

        menu.addItem(NSMenuItem.separator())

        let quitItem = NSMenuItem(title: "退出 Keyper", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
    }

    // MARK: - System Notifications

    private func setupSystemNotifications() {
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(systemDidWake),
            name: NSWorkspace.didWakeNotification,
            object: nil
        )
    }

    @objc private func systemDidWake(_ notification: Notification) {
        print("[AppDelegate] System woke from sleep")
        engine.handleSystemWake()
    }

    // MARK: - Settings Window

    @objc func openSettings() {
        if let window = settingsWindow {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let settingsView = SettingsView(engine: engine)
        let hostingController = NSHostingController(rootView: settingsView)

        let window = NSWindow(contentViewController: hostingController)
        window.title = "Keyper"
        window.styleMask = [.titled, .closable, .miniaturizable, .fullSizeContentView]
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.setContentSize(NSSize(width: 530, height: 600))
        window.center()
        window.isReleasedWhenClosed = false
        window.delegate = self
        window.level = .floating
        window.isMovableByWindowBackground = true

        self.settingsWindow = window
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    // MARK: - Accessibility Guide

    @objc func openAccessibilitySettings() {
        KeyboardMonitor.openAccessibilitySettings()
    }

    private func showAccessibilityGuide() {
        KeyboardMonitor.openAccessibilitySettings()

        let alert = NSAlert()
        alert.messageText = "Keyper 需要「辅助功能」权限"
        alert.informativeText = """
        Keyper 需要辅助功能权限才能监听键盘输入并即时播放音效。

        【已自动打开系统设置】：
        1. 请在「隐私与安全性 → 辅助功能」列表中找到「Keyper」
        2. 打开其右侧的开关允许权限（若不在列表中，可点击下方「+」号添加 Keyper.app）
        3. 开启后无需重启应用，Keyper 会立即自动开始发声！
        """
        alert.alertStyle = .warning
        alert.addButton(withTitle: "重新打开设置")
        alert.addButton(withTitle: "我知道了")

        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            KeyboardMonitor.openAccessibilitySettings()
        }
    }

    // MARK: - Actions

    @objc private func quitApp() {
        engine.stop()
        NSApp.terminate(nil)
    }
}

// MARK: - NSWindowDelegate

extension AppDelegate: NSWindowDelegate {
    func windowWillClose(_ notification: Notification) {
        settingsWindow = nil
    }
}
