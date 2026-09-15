import SwiftUI
import AppKit

/// Modern, beautifully styled settings window for Keyper
struct SettingsView: View {
    @ObservedObject var engine: KeyperEngine
    @State private var selectedTab: SettingsTab = .schemes
    @State private var testText: String = ""
    @State private var showingAppPicker: Bool = false
    @State private var appSearchQuery: String = ""
    @State private var launchAtLogin: Bool = Preferences.shared.launchAtLogin

    enum SettingsTab: String, CaseIterable, Identifiable {
        case schemes = "音效方案"
        case audio = "声音调节"
        case filter = "应用过滤"
        case about = "关于与暗号"

        var id: String { rawValue }

        var icon: String {
            switch self {
            case .schemes: return "waveform.circle.fill"
            case .audio: return "slider.horizontal.3"
            case .filter: return "shield.lefthalf.filled"
            case .about: return "command.circle.fill"
            }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Top Header & Tab Navigation
            headerSection
                .padding(.horizontal, 22)
                .padding(.top, 20)
                .padding(.bottom, 12)

            // Accessibility Warning Banner (if permission missing)
            if engine.needsAccessibilityPermission {
                accessibilityAlertBanner
                    .padding(.horizontal, 20)
                    .padding(.bottom, 10)
            }

            Divider()
                .opacity(0.6)

            // Main Tab Content
            ScrollView(.vertical, showsIndicators: true) {
                VStack(spacing: 16) {
                    switch selectedTab {
                    case .schemes:
                        schemesTabContent
                    case .audio:
                        audioTabContent
                    case .filter:
                        filterTabContent
                    case .about:
                        aboutTabContent
                    }
                }
                .padding(22)
            }
        }
        .frame(width: 530, height: 600)
        .background(VisualEffectView(material: .underWindowBackground, blendingMode: .behindWindow))
    }

    // MARK: - Header & Tab Bar

    private var headerSection: some View {
        VStack(spacing: 14) {
            HStack(alignment: .center, spacing: 14) {
                // App Logo
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [Color.blue.opacity(0.8), Color.purple.opacity(0.9)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 44, height: 44)
                        .shadow(color: Color.blue.opacity(0.3), radius: 6, x: 0, y: 3)

                    Image(systemName: "keyboard.fill")
                        .font(.system(size: 22))
                        .foregroundColor(.white)
                }

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 8) {
                        Text("Keyper")
                            .font(.system(size: 20, weight: .bold, design: .rounded))

                        Text("v1.0.0")
                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.secondary.opacity(0.12))
                            .cornerRadius(4)
                    }

                    Text("敲击即反馈 · 现代 macOS 原生键盘音效伴侣")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Live Status Pill
                HStack(spacing: 6) {
                    Circle()
                        .fill(engine.needsAccessibilityPermission ? Color.orange : Color.green)
                        .frame(width: 8, height: 8)
                    Text(engine.needsAccessibilityPermission ? "待授权" : "运行中")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(engine.needsAccessibilityPermission ? .orange : .green)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(
                    (engine.needsAccessibilityPermission ? Color.orange : Color.green)
                        .opacity(0.12)
                )
                .cornerRadius(12)
            }

            // Segmented Tabs
            HStack(spacing: 4) {
                ForEach(SettingsTab.allCases) { tab in
                    Button(action: { selectedTab = tab }) {
                        HStack(spacing: 6) {
                            Image(systemName: tab.icon)
                                .font(.system(size: 13, weight: .medium))
                            Text(tab.rawValue)
                                .font(.system(size: 13, weight: selectedTab == tab ? .semibold : .regular))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 7)
                        .background(
                            selectedTab == tab
                                ? Color.accentColor.opacity(0.18)
                                : Color.clear
                        )
                        .foregroundColor(selectedTab == tab ? .accentColor : .primary)
                        .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(3)
            .background(Color.secondary.opacity(0.08))
            .cornerRadius(10)
        }
    }

    // MARK: - Accessibility Alert Banner

    private var accessibilityAlertBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.orange)
                .font(.system(size: 18))

            VStack(alignment: .leading, spacing: 2) {
                Text("尚未获得辅助功能权限")
                    .font(.system(size: 13, weight: .semibold))
                Text("需要此权限以全局捕获按键并发出声音")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }

            Spacer()

            Button("立即授权") {
                KeyboardMonitor.openAccessibilitySettings()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color.orange.opacity(0.12))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.orange.opacity(0.3), lineWidth: 1)
        )
        .cornerRadius(10)
    }

    // MARK: - Tab 1: Schemes (音效方案)

    private var schemesTabContent: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("选择打字音效方案")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.secondary)

            // 2-Column Grid of 8 Schemes
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                ForEach(engine.schemeManager.schemes, id: \.name) { scheme in
                    SchemeCardView(
                        scheme: scheme,
                        isSelected: engine.currentSchemeName == scheme.name,
                        onSelect: {
                            engine.switchScheme(name: scheme.name)
                            // Play a preview sound
                            let sampleIdx = scheme.keyAudioMap["36"] ?? 0
                            engine.audioEngine.play(bufferIndex: sampleIdx)
                        }
                    )
                }
            }

            // Interactive Live Typing Sandbox
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "sparkles")
                        .foregroundColor(.accentColor)
                    Text("实时试打区域")
                        .font(.system(size: 13, weight: .semibold))
                    Spacer()
                    Text("敲击按键即可试听当前音效")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }

                TextField("在这里敲击键盘试听按键音效（回车、退格、空格）...", text: $testText)
                    .textFieldStyle(.plain)
                    .padding(12)
                    .background(Color.secondary.opacity(0.06))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.secondary.opacity(0.15), lineWidth: 1)
                    )
                    .cornerRadius(8)
            }
            .padding(14)
            .background(Color.secondary.opacity(0.04))
            .cornerRadius(12)
        }
    }

    // MARK: - Tab 2: Audio Controls (声音调节)

    private var audioTabContent: some View {
        VStack(spacing: 16) {
            // Volume Card
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: engine.volume == 0 ? "speaker.slash.fill" : "speaker.wave.3.fill")
                        .foregroundColor(.accentColor)
                        .font(.system(size: 16))
                    Text("音量调节")
                        .font(.system(size: 14, weight: .semibold))
                    Spacer()
                    Text("\(Int(engine.volume * 100))%")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundColor(.accentColor)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.accentColor.opacity(0.12))
                        .cornerRadius(6)
                }

                HStack(spacing: 14) {
                    Image(systemName: "speaker.fill")
                        .foregroundColor(.secondary)
                        .font(.system(size: 12))

                    Slider(value: $engine.volume, in: 0...1, step: 0.01)
                        .tint(.accentColor)

                    Image(systemName: "speaker.wave.3.fill")
                        .foregroundColor(.secondary)
                        .font(.system(size: 14))
                }
            }
            .padding(16)
            .background(Color.secondary.opacity(0.05))
            .cornerRadius(12)

            // Pitch Card
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "tuningfork")
                        .foregroundColor(.purple)
                        .font(.system(size: 16))
                    Text("音调微调 (Pitch)")
                        .font(.system(size: 14, weight: .semibold))
                    Spacer()
                    Text(pitchLabel(engine.pitch))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.purple)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.purple.opacity(0.12))
                        .cornerRadius(6)
                }

                HStack(spacing: 14) {
                    Text("低沉")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)

                    Slider(value: $engine.pitch, in: 0.5...2.0, step: 0.01)
                        .tint(.purple)

                    Text("清脆")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }

                HStack {
                    Spacer()
                    Button("恢复标准音调 (1.0x)") {
                        engine.pitch = 1.0
                    }
                    .buttonStyle(.link)
                    .font(.system(size: 12))
                }
            }
            .padding(16)
            .background(Color.secondary.opacity(0.05))
            .cornerRadius(12)

            // System Options Card
            VStack(spacing: 12) {
                Toggle(isOn: Binding(
                    get: { launchAtLogin },
                    set: {
                        launchAtLogin = $0
                        Preferences.shared.launchAtLogin = $0
                    }
                )) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("开机自动启动")
                            .font(.system(size: 13, weight: .medium))
                        Text("开机登录 macOS 时自动在后台静默运行")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                }
                .toggleStyle(.switch)

                Divider()

                Toggle(isOn: $engine.isMuted) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("全局静音")
                            .font(.system(size: 13, weight: .medium))
                        Text("暂时静音所有按键发声")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                }
                .toggleStyle(.switch)
            }
            .padding(16)
            .background(Color.secondary.opacity(0.05))
            .cornerRadius(12)
        }
    }

    private func pitchLabel(_ pitch: Float) -> String {
        if abs(pitch - 1.0) < 0.03 {
            return "1.00x 标准原声"
        } else if pitch < 1.0 {
            return String(format: "%.2fx 浑厚低沉", pitch)
        } else {
            return String(format: "%.2fx 高亢清脆", pitch)
        }
    }

    // MARK: - Tab 3: Filter (应用过滤)

    private var filterTabContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Mode Segmented Picker
            VStack(alignment: .leading, spacing: 8) {
                Text("过滤规则模式")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.secondary)

                Picker("", selection: Binding(
                    get: { engine.filterList.mode },
                    set: { engine.filterList.mode = $0 }
                )) {
                    Text("黑名单模式 (列表中的应用静音)").tag(FilterList.Mode.blackList)
                    Text("白名单模式 (仅在列表中发声)").tag(FilterList.Mode.whiteList)
                }
                .pickerStyle(.segmented)
            }

            // App List Card
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("已添加的应用 (\(engine.filterList.bundleIds.count))")
                        .font(.system(size: 13, weight: .semibold))
                    Spacer()

                    Button(action: { showingAppPicker = true }) {
                        Label("添加应用", systemImage: "plus.circle.fill")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                    .popover(isPresented: $showingAppPicker) {
                        appPickerPopover
                    }
                }

                if engine.filterList.bundleIds.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "app.badge.checkmark")
                            .font(.system(size: 32))
                            .foregroundColor(.secondary.opacity(0.6))
                        Text("暂无过滤应用")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.secondary)
                        Text(engine.filterList.mode == .blackList ? "当前所有应用均会播放敲击音效" : "白名单为空时将静音所有应用")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary.opacity(0.8))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 30)
                } else {
                    VStack(spacing: 6) {
                        ForEach(engine.filterList.bundleIds, id: \.self) { bundleId in
                            HStack(spacing: 10) {
                                Image(nsImage: FilterList.appIcon(for: bundleId))
                                    .resizable()
                                    .frame(width: 24, height: 24)

                                VStack(alignment: .leading, spacing: 1) {
                                    Text(FilterList.appName(for: bundleId))
                                        .font(.system(size: 13, weight: .medium))
                                    Text(bundleId)
                                        .font(.system(size: 10))
                                        .foregroundColor(.secondary)
                                }

                                Spacer()

                                Button(action: { engine.filterList.removeApp(bundleId: bundleId) }) {
                                    Image(systemName: "trash")
                                        .font(.system(size: 12))
                                        .foregroundColor(.red.opacity(0.8))
                                }
                                .buttonStyle(.plain)
                                .padding(6)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color.secondary.opacity(0.05))
                            .cornerRadius(8)
                        }
                    }
                }
            }
            .padding(16)
            .background(Color.secondary.opacity(0.04))
            .cornerRadius(12)
        }
    }

    private var appPickerPopover: some View {
        VStack(spacing: 0) {
            Text("选择正在运行的应用")
                .font(.system(size: 13, weight: .semibold))
                .padding(.vertical, 12)

            Divider()

            ScrollView {
                VStack(spacing: 2) {
                    ForEach(FilterList.runningApps()) { app in
                        Button(action: {
                            engine.filterList.addApp(bundleId: app.bundleId)
                            showingAppPicker = false
                        }) {
                            HStack(spacing: 10) {
                                Image(nsImage: app.icon)
                                    .resizable()
                                    .frame(width: 22, height: 22)
                                Text(app.name)
                                    .font(.system(size: 12))
                                Spacer()
                                if engine.filterList.bundleIds.contains(app.bundleId) {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundColor(.accentColor)
                                }
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 6)
            }
            .frame(width: 260, height: 240)
        }
    }

    // MARK: - Tab 4: About & Shortcuts (关于与暗号)

    private var aboutTabContent: some View {
        VStack(spacing: 20) {
            // Secret Shortcut Card
            VStack(spacing: 12) {
                Text("经典设置呼出暗号")
                    .font(.system(size: 14, weight: .bold))

                Text("在键盘任意位置盲打输入以下 6 个键，即可随时呼出此设置面板：")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)

                HStack(spacing: 8) {
                    KeyCapView(letter: "Q")
                    KeyCapView(letter: "A")
                    KeyCapView(letter: "Z")
                    Text("+")
                        .foregroundColor(.secondary)
                    KeyCapView(letter: "1")
                    KeyCapView(letter: "2")
                    KeyCapView(letter: "3")
                }
                .padding(.vertical, 4)

                Text("（也支持小键盘数字键 1 2 3）")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary.opacity(0.8))
            }
            .frame(maxWidth: .infinity)
            .padding(18)
            .background(
                LinearGradient(
                    colors: [Color.accentColor.opacity(0.08), Color.purple.opacity(0.06)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.accentColor.opacity(0.2), lineWidth: 1)
            )
            .cornerRadius(12)

            // About Info Card
            VStack(spacing: 10) {
                HStack {
                    Text("技术架构")
                    Spacer()
                    Text("Swift 5.9 + SwiftUI + CoreAudio")
                        .foregroundColor(.secondary)
                }
                .font(.system(size: 12))

                Divider()

                HStack {
                    Text("开源主页")
                    Spacer()
                    Button("GitHub: OrangeSAM/Keyper") {
                        if let url = URL(string: "https://github.com/OrangeSAM/Keyper") {
                            NSWorkspace.shared.open(url)
                        }
                    }
                    .buttonStyle(.link)
                    .font(.system(size: 12))
                }
                .font(.system(size: 12))

                Divider()

                HStack {
                    Text("辅助功能权限")
                    Spacer()
                    Button("打开系统设置") {
                        KeyboardMonitor.openAccessibilitySettings()
                    }
                    .buttonStyle(.link)
                    .font(.system(size: 12))
                }
                .font(.system(size: 12))
            }
            .padding(14)
            .background(Color.secondary.opacity(0.05))
            .cornerRadius(10)

            Spacer()

            // Quit App Button
            Button(role: .destructive, action: { NSApp.terminate(nil) }) {
                HStack {
                    Image(systemName: "power")
                    Text("退出 Keyper")
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }
            .buttonStyle(.bordered)
            .controlSize(.regular)
        }
    }
}

// MARK: - Supporting Views

/// Scheme Card with custom icons and gradients
struct SchemeCardView: View {
    let scheme: AudioScheme
    let isSelected: Bool
    let onSelect: () -> Void

    private var info: (title: String, desc: String, icon: String, gradient: [Color]) {
        switch scheme.name {
        case "bubble":
            return ("Bubble", "空灵清脆的水滴气泡", "drop.fill", [.cyan, .blue])
        case "typewriter":
            return ("Typewriter", "复古金属字模与换行铃", "printer.fill", [.orange, .brown])
        case "mechanical":
            return ("Mechanical", "经典机械轴体敲击", "keyboard.fill", [.purple, .indigo])
        case "sword":
            return ("Sword", "凌厉出鞘剑气与刀光", "bolt.shield.fill", [.blue, .teal])
        case "Cherry_G80_3000":
            return ("G80-3000", "Cherry 原厂青轴段落", "cpu.fill", [.red, .pink])
        case "Cherry_G80_3494":
            return ("G80-3494", "Cherry 原厂红轴绵密", "flame.fill", [Color(red: 0.8, green: 0.2, blue: 0.2), .red])
        case "drum":
            return ("Drum", "节奏感十足的架子鼓", "music.note.list", [.yellow, .orange])
        case "starwars":
            return ("Star Wars", "光剑挥舞与激光爆能", "sparkles", [.green, .mint])
        default:
            return (scheme.displayName, "按键音效方案", "music.note", [.blue, .indigo])
        }
    }

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                // Gradient Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: info.gradient,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 38, height: 38)
                        .shadow(color: info.gradient.first?.opacity(0.3) ?? .clear, radius: 4, x: 0, y: 2)

                    Image(systemName: info.icon)
                        .font(.system(size: 18))
                        .foregroundColor(.white)
                }

                // Title & Subtitle
                VStack(alignment: .leading, spacing: 2) {
                    Text(info.title)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.primary)

                    Text(info.desc)
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }

                Spacer()

                // Checkmark Pill
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.accentColor)
                        .font(.system(size: 18))
                }
            }
            .padding(10)
            .background(
                isSelected
                    ? Color.accentColor.opacity(0.12)
                    : Color.secondary.opacity(0.06)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? Color.accentColor : Color.secondary.opacity(0.12), lineWidth: isSelected ? 1.5 : 1)
            )
            .cornerRadius(10)
        }
        .buttonStyle(.plain)
    }
}

/// 3D Keycap badge for keyboard shortcuts
struct KeyCapView: View {
    let letter: String

    var body: some View {
        Text(letter)
            .font(.system(size: 14, weight: .bold, design: .monospaced))
            .foregroundColor(.primary)
            .frame(width: 32, height: 32)
            .background(
                LinearGradient(
                    colors: [Color.white.opacity(0.2), Color.black.opacity(0.1)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
            )
            .cornerRadius(6)
            .shadow(color: Color.black.opacity(0.15), radius: 1, x: 0, y: 1.5)
    }
}

/// Native NSVisualEffectView wrapper for SwiftUI
struct VisualEffectView: NSViewRepresentable {
    let material: NSVisualEffectView.Material
    let blendingMode: NSVisualEffectView.BlendingMode

    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
    }
}
