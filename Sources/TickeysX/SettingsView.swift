import SwiftUI

/// Settings window UI built with SwiftUI
/// Replaces the original NIB-based settings from Tickeys
struct SettingsView: View {
    @ObservedObject var engine: TickeysEngine

    @State private var showingAppPicker = false

    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerSection

            if engine.needsAccessibilityPermission {
                HStack(spacing: 10) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("未获得辅助功能权限")
                            .font(.subheadline.bold())
                        Text("请在系统设置中允许 TickeysX 监听键盘")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Button("前往开启") {
                        KeyboardMonitor.openAccessibilitySettings()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                }
                .padding(10)
                .background(Color.orange.opacity(0.12))
                .cornerRadius(8)
                .padding(.horizontal, 16)
                .padding(.top, 10)
            }

            Divider()
                .padding(.top, 8)

            ScrollView {
                VStack(spacing: 20) {
                    // Sound scheme picker
                    schemeSection

                    Divider()

                    // Volume & Pitch controls
                    controlsSection

                    Divider()

                    // App filter
                    filterSection

                    Divider()

                    // Footer
                    footerSection
                }
                .padding(20)
            }
        }
        .frame(width: 400, height: 520)
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack {
            Image(systemName: "keyboard")
                .font(.system(size: 28))
                .foregroundColor(.accentColor)

            VStack(alignment: .leading, spacing: 2) {
                Text("TickeysX")
                    .font(.title2.bold())
                Text("原版经典键盘音效复刻")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Text("v1.0.0")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(16)
    }

    // MARK: - Scheme Selection

    private var schemeSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("音效方案", systemImage: "music.note.list")
                .font(.headline)

            Picker("", selection: Binding(
                get: { engine.currentSchemeName },
                set: { engine.switchScheme(name: $0) }
            )) {
                ForEach(engine.schemeManager.schemes, id: \.name) { scheme in
                    Text(scheme.displayName).tag(scheme.name)
                }
            }
            .pickerStyle(.menu)
            .labelsHidden()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Volume & Pitch Controls

    private var controlsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("控制", systemImage: "slider.horizontal.3")
                .font(.headline)

            // Volume
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("音量")
                    Spacer()
                    Text(String(format: "%.0f%%", engine.volume * 100))
                        .foregroundColor(.secondary)
                        .monospacedDigit()
                }
                HStack {
                    Image(systemName: "speaker")
                        .foregroundColor(.secondary)
                    Slider(value: $engine.volume, in: 0...1, step: 0.01)
                    Image(systemName: "speaker.wave.3")
                        .foregroundColor(.secondary)
                }
            }

            // Pitch
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("音调")
                    Spacer()
                    Text(String(format: "%.2fx", engine.pitch))
                        .foregroundColor(.secondary)
                        .monospacedDigit()
                }
                HStack {
                    Text("低")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Slider(value: $engine.pitch, in: 0.5...2.0, step: 0.01)
                    Text("高")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - App Filter

    private var filterSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("应用过滤", systemImage: "line.3.horizontal.decrease.circle")
                .font(.headline)

            Picker("模式", selection: Binding(
                get: { engine.filterList.mode },
                set: { engine.filterList.mode = $0 }
            )) {
                Text("黑名单（静音列表中的应用）").tag(FilterList.Mode.blackList)
                Text("白名单（仅列表中的应用有声音）").tag(FilterList.Mode.whiteList)
            }
            .pickerStyle(.radioGroup)

            // Filter list
            VStack(spacing: 4) {
                ForEach(Array(engine.filterList.bundleIds.enumerated()), id: \.offset) { index, bundleId in
                    HStack {
                        Text(FilterList.appName(for: bundleId))
                            .lineLimit(1)
                            .truncationMode(.middle)
                        Spacer()
                        Text(bundleId)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                        Button(action: { engine.filterList.removeApp(at: index) }) {
                            Image(systemName: "minus.circle.fill")
                                .foregroundColor(.red)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.vertical, 2)
                }
            }
            .frame(maxHeight: 120)

            // Add app button
            HStack {
                Button(action: { showingAppPicker = true }) {
                    Label("添加应用", systemImage: "plus.circle")
                }
                .popover(isPresented: $showingAppPicker) {
                    appPickerPopover
                }

                Spacer()
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - App Picker Popover

    private var appPickerPopover: some View {
        VStack(spacing: 0) {
            Text("选择应用")
                .font(.headline)
                .padding(12)

            Divider()

            ScrollView {
                VStack(spacing: 2) {
                    ForEach(FilterList.runningApps(), id: \.bundleId) { app in
                        Button(action: {
                            engine.filterList.addApp(bundleId: app.bundleId)
                            showingAppPicker = false
                        }) {
                            HStack {
                                Text(app.name)
                                Spacer()
                                if engine.filterList.bundleIds.contains(app.bundleId) {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.accentColor)
                                }
                            }
                            .contentShape(Rectangle())
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 4)
            }
            .frame(width: 280, height: 200)
        }
    }

    // MARK: - Footer

    private var footerSection: some View {
        HStack {
            Text("💡 输入 QAZ123 可快速打开设置")
                .font(.caption)
                .foregroundColor(.secondary)

            Spacer()

            Button("退出 TickeysX") {
                NSApp.terminate(nil)
            }
            .controlSize(.small)
        }
    }
}
