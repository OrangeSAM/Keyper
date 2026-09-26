# ⌨️ Keyper

<div align="center">

**Delightful, low-latency tactile audio feedback for every keystroke on macOS.**  
*敲击即反馈 · 专为 macOS 现代系统设计的原生高保真键盘音效伴侣*

[![macOS](https://img.shields.io/badge/macOS-13.0%2B-black?style=flat-square&logo=apple)](https://www.apple.com/macos/)
[![Swift](https://img.shields.io/badge/Swift-5.9%2B-F05138?style=flat-square&logo=swift)](https://swift.org)
[![License](https://img.shields.io/badge/License-MIT-blue?style=flat-square)](LICENSE)
[![Platform](https://img.shields.io/badge/Platform-Apple%20Silicon%20%7C%20Intel-success?style=flat-square)](#)
[![Downloads](https://img.shields.io/github/downloads/OrangeSAM/Keyper/total?style=flat-square&color=2563eb&logo=github)](https://github.com/OrangeSAM/Keyper/releases)


[English](#features) | [简体中文](#功能特性) | [🌐 在线交互试玩 / Live Demo](https://keyper.yibi.host/) | [安装指南](#安装指南--installation) | [快速上手](#快捷暗号--shortcut)

</div>

---

## 📖 项目起源 / Background

经典的 **Tickeys** 曾经陪伴无数开发者和打字爱好者度过了美妙的敲击时光。但由于原版基于早期的 Rust 和已被 Apple 彻底废弃的 **OpenAL/ALUT** 以及过时的 Cocoa FFI 接口构建，在最新的 macOS 系统上极易崩溃且即将完全停止兼容。

**Keyper** 由 [@OrangeSAM](https://github.com/OrangeSAM) 采用 **100% 现代 Swift + SwiftUI + CoreAudio (AVAudioEngine)** 彻底重写重生：
- **0 废弃 API**：基于 Apple 推荐的现代化音频管线，永久兼容未来 macOS 版本。
- **0 延迟多声部混音**：6 轨并发循环分配池，极速打字连击依然层次分明。
- **现代化磨砂毛玻璃 UI**：遵循现代 macOS HIG 设计规范。

---

## ✨ 功能特性 / Features

- 🫧 **8 套原版经典音效方案**：
  - **Bubble**（清脆水滴气泡）
  - **Typewriter**（打字机，带独立回车换行叮当声、退格齿轮声、空格长杆声）
  - **Mechanical**（经典清脆机械轴体）
  - **Sword**（凌厉拔刀与剑气出鞘）
  - **Cherry G80-3000**（德国原厂青轴段落手感）
  - **Cherry G80-3494**（经典原厂红轴绵密手感）
  - **Drum**（律动感十足的架子鼓打击乐）
  - **Star Wars**（星球大战光剑挥舞与激光音）
- 🎛️ **实时音调微调 (Dynamic Pitch)**：
  - 支持 0.5x ~ 2.0x 无级音调滑动，提供浑厚低沉到清脆高亢的定制手感。
- 🛡️ **应用黑/白名单过滤**：
  - 支持针对全屏游戏、特定编辑器设置静音规则，一键提取并显示正在运行的应用图标。
- 🎹 **实时打字试音区**：
  - 设置面板内嵌实时试打框，选择方案时无需切换窗口即可立刻试听手感。
- ⚡️ **开机自动启动 (Launch at Login)**：
  - 集成 Apple 官方 `SMAppService`，开机自启静默常驻，不占用 Dock 栏。
- 💡 **经典呼出暗号**：
  - 在任何界面盲打敲击 `Q` `A` `Z` `1` `2` `3`（或小键盘 123）随时呼出设置面板。
- 💤 **睡眠唤醒抗假死**：
  - 自动捕获系统休眠与唤醒通知，重新初始化音频引擎，杜绝合盖后无声问题。

---

## 🚀 安装指南 / Installation

前往 [Releases 页面](https://github.com/OrangeSAM/Keyper/releases) 下载最新安装包：

### 方式 1：双击 PKG 安装包（推荐）
下载 `Keyper-1.0.0.pkg`，双击根据系统安装器向导一步安装至 `/Applications`。

### 方式 2：DMG 拖拽安装
下载 `Keyper-1.0.0.dmg`，打开后将 `Keyper` 拖拽进 `Applications` 快捷方式。

> **⚠️ 首次使用权限提示**：
> 1. 打开应用后会自动弹出系统设置中的「辅助功能」授权页。
> 2. 在 **隐私与安全性 → 辅助功能** 列表中找到 **Keyper** 并勾选开启。
> 3. 勾选后**无需重启**，Keyper 在后台会自动侦测并即刻开始发声！

---

## ⌨️ 快捷暗号 / Shortcut

随时盲打敲击按键：
```
Q  A  Z  1  2  3
```
或者点击屏幕右上角菜单栏的 ⌨️ 小图标，即可打开设置面板。

---

## 🛠️ 从源码构建 / Build from Source

环境要求：macOS 13.0+，Xcode 15+ 或 Swift 5.9+ 工具链。

```bash
# 1. 克隆代码仓库
git clone git@github.com:OrangeSAM/Keyper.git
cd Keyper

# 2. 编译并创建 App Bundle
./scripts/build_app.sh

# 3. 运行体验
open Keyper.app

# 4. 如需生成 PKG 与 DMG 安装包
./scripts/build_package.sh
```

生成的安装包将存放在 `dist/` 目录下。

---

## 👨‍💻 关于作者与交流 / Author & Community

- **作者**：刘一笔 ([@OrangeSAM](https://github.com/OrangeSAM))
- **个人博客**：[blog.yibi.host](https://blog.yibi.host/)
- **微信公众号**：**「刘一笔」**（微信搜索关注，深度分享独立开发手记、技术实践与生活思考）
- **微信交流**：可前往官网 [keyper.yibi.host/#author](https://keyper.yibi.host/#author) 扫码添加个人微信（备注 `Keyper`），欢迎交流体验、反馈 Bug 或推荐新声学方案！

---

## 🤝 致敬与鸣谢 / Acknowledgements

- 感谢原版 [yingDev/Tickeys](https://github.com/yingDev/Tickeys) 带来的灵感与经典敲击音效采样。
- 本项目遵循 [MIT 许可证](LICENSE) 开源。欢迎提交 PR 和 Issue！

---

<div align="center">
Made with ❤️ by <a href="https://blog.yibi.host">刘一笔 (OrangeSAM)</a>
</div>

