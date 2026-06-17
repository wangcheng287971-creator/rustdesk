# RustDesk 项目分析文档

## 项目概述

RustDesk 是一个开源的远程桌面软件，使用 Rust 和 Flutter 开发，支持 Windows、Linux、macOS、Android 和 iOS 等多平台。项目版本为 **1.4.6**，采用自定义的远程桌面协议实现，可完全替代 TeamViewer 等商业远程桌面软件。

### 核心特性

- **跨平台支持**: Windows、Linux、macOS、Android、iOS
- **自托管服务器**: 可部署私有服务器，无需依赖第三方服务
- **端到端加密**: 使用 NaCl (libsodium) 进行加密通信
- **P2P 直连**: 支持 NAT 穿透和打洞技术
- **多显示器支持**: 支持多显示器远程控制
- **文件传输**: 内置安全的文件传输功能
- **端口转发**: TCP/UDP 端口转发功能
- **终端访问**: 支持远程终端会话
- **摄像头查看**: 支持远程摄像头查看

---

## 目录结构树

```
rustdesk/
├── .cargo/                    # Cargo 配置
│   └── config.toml
├── .github/                   # GitHub CI/CD 配置
│   ├── workflows/             # 工作流定义
│   │   ├── bridge.yml         # Flutter Rust Bridge 生成
│   │   ├── build-android.yml  # Android 构建
│   │   ├── ci.yml             # CI 测试
│   │   ├── flutter-build.yml  # Flutter 构建
│   │   ├── flutter-ci.yml     # Flutter CI
│   │   ├── flutter-nightly.yml # 每日构建
│   │   └── flutter-tag.yml    # 标签发布构建
│   └── ISSUE_TEMPLATE/        # Issue 模板
├── appimage/                  # AppImage 构建配置
├── docs/                      # 多语言文档
├── examples/                  # 示例代码
├── fastlane/                  # Android 发布配置
├── flatpak/                   # Flatpak 构建配置
├── flutter/                   # Flutter UI (主要 UI)
│   ├── android/               # Android 平台代码
│   ├── ios/                   # iOS 平台代码
│   ├── linux/                 # Linux 平台代码
│   ├── macos/                 # macOS 平台代码
│   ├── windows/               # Windows 平台代码
│   ├── lib/                   # Dart 源代码
│   │   ├── common/            # 共享组件
│   │   ├── desktop/           # 桌面端页面
│   │   ├── mobile/            # 移动端页面
│   │   ├── models/            # 数据模型
│   │   ├── native/            # Native 交互
│   │   ├── plugin/            # 插件系统
│   │   ├── utils/             # 工具类
│   │   └── web/               # Web 支持
│   ├── assets/                # 资源文件 (字体等)
│   ├── test/                  # 测试代码
│   └── pubspec.yaml           # Flutter 依赖配置
├── libs/                      # Rust 库模块
│   ├── hbb_common/            # 共享工具库
│   │   ├── protos/            # Protobuf 定义
│   │   └── src/               # 源代码
│   ├── scrap/                 # 屏幕捕获库
│   │   ├── common/            # 通用捕获逻辑
│   │   ├── quartz/            # macOS 捕获
│   │   ├── x11/               # X11 捕获
│   │   ├── wayland/           # Wayland 捕获
│   │   └── dxgi/              # Windows DXGI 捕获
│   ├── enigo/                 # 输入控制库
│   │   ├── linux/             # Linux 输入
│   │   ├── macos/             # macOS 输入
│   │   └── win/               # Windows 输入
│   ├── clipboard/             # 剪贴板库
│   │   ├── platform/          # 平台实现
│   │   └── windows/           # Windows 剪贴板
│   ├── virtual_display/       # 虚拟显示器
│   ├── remote_printer/        # 远程打印机
│   └── portable/              # 便携版打包
├── res/                       # 资源文件
│   ├── DEBIAN/                # Debian 打包脚本
│   ├── msi/                   # Windows MSI 安装包
│   ├── pam.d/                 # PAM 配置
│   └── *.spec                 # RPM 打包配置
├── src/                       # Rust 核心应用
│   ├── client/                # 客户端逻辑
│   ├── server/                # 服务端逻辑
│   │   ├── audio_service.rs   # 音频服务
│   │   ├── video_service.rs   # 视频服务
│   │   ├── input_service.rs   # 输入服务
│   │   ├── clipboard_service.rs # 剪贴板服务
│   │   ├── display_service.rs # 显示服务
│   │   ├── connection.rs      # 连接管理
│   │   ├── terminal_service.rs # 终端服务
│   │   └── printer_service.rs # 打印服务
│   ├── platform/              # 平台特定代码
│   │   ├── linux.rs           # Linux 平台
│   │   ├── macos.rs           # macOS 平台
│   │   ├── windows.rs         # Windows 平台
│   │   └── linux_desktop_manager.rs # Linux 桌面管理
│   ├── ui/                    # Sciter UI (已弃用)
│   ├── lang/                  # 多语言支持 (50+ 语言)
│   ├── plugin/                # 插件框架
│   ├── privacy_mode/          # 隐私模式
│   ├── whiteboard/            # 白板功能
│   ├── hbbs_http/             # HTTP 服务
│   ├── ipc.rs                 # IPC 通信
│   ├── rendezvous_mediator.rs # 连接服务器通信
│   ├── client.rs              # 客户端主逻辑
│   ├── server.rs              # 服务端主逻辑
│   └── lib.rs                 # 库入口
├── Cargo.toml                 # Rust 项目配置
├── Cargo.lock                 # 依赖锁定
├── build.rs                   # 构建脚本
├── Dockerfile                 # Docker 构建
└── README.md                  # 项目说明
```

---

## 核心模块详解

### 1. src/ - Rust 核心应用

#### 主要文件

| 文件 | 功能描述 |
|------|----------|
| `lib.rs` | 库入口，导出所有模块 |
| `server.rs` | 服务端核心，管理连接和服务 |
| `client.rs` | 客户端核心，处理远程连接 |
| `rendezvous_mediator.rs` | 与 rustdesk-server 通信的中介 |
| `ipc.rs` | 进程间通信 (IPC) |
| `common.rs` | 通用工具函数 |
| `lang.rs` | 多语言支持 |
| `tray.rs` | 系统托盘 |
| `updater.rs` | 自动更新 |

#### server/ - 服务端服务模块

| 服务 | 文件 | 功能 |
|------|------|------|
| **视频服务** | `video_service.rs` | 屏幕捕获和视频编码传输 |
| **音频服务** | `audio_service.rs` | 音频捕获和传输 (Opus 编码) |
| **输入服务** | `input_service.rs` | 键盘/鼠标输入处理 |
| **剪贴板服务** | `clipboard_service.rs` | 剪贴板同步 |
| **显示服务** | `display_service.rs` | 显示器管理 |
| **终端服务** | `terminal_service.rs` | 远程终端会话 |
| **打印服务** | `printer_service.rs` | 远程打印 |
| **连接管理** | `connection.rs` | TCP/UDP 连接处理 |

#### platform/ - 平台特定代码

| 平台 | 文件 | 特殊功能 |
|------|------|----------|
| **Windows** | `windows.rs`, `windows.cc` | DXGI 捕获、服务安装、UAC 处理 |
| **macOS** | `macos.rs`, `macos.mm` | Quartz 捕获、权限管理 |
| **Linux** | `linux.rs` | X11/Wayland 捕获、uinput 输入 |

#### ui/ - Sciter UI (已弃用)

旧版 Sciter UI 代码，已被 Flutter UI 替代，包含：
- `remote.tis` - 远程控制界面
- `file_transfer.tis` - 文件传输界面
- `cm.tis` - 连接管理界面
- `port_forward.tis` - 端口转发界面

---

### 2. libs/ - 库模块

#### hbb_common/ - 共享工具库

核心共享库，提供基础功能：

| 模块 | 功能 |
|------|------|
| `config.rs` | 配置管理 (所有选项定义) |
| `protos/` | Protobuf 协议定义 |
| `tcp.rs` | TCP 连接和加密 |
| `udp.rs` | UDP 通信 |
| `socket_client.rs` | Socket 客户端 |
| `compress.rs` | 数据压缩 |
| `password_security.rs` | 密码安全处理 |
| `fs.rs` | 文件系统操作 |
| `stream.rs` | 流处理 |
| `websocket.rs` | WebSocket 支持 |
| `verifier.rs` | 验证器 |

**Protobuf 协议定义** (`protos/`):
- `message.proto` - 消息定义 (视频帧、登录请求、控制消息等)
- `rendezvous.proto` - 连接协议 (注册、打洞、中继等)

#### scrap/ - 屏幕捕获库

跨平台屏幕捕获实现：

| 平台 | 模块 | 技术 |
|------|------|------|
| **Windows** | `dxgi/` | DXGI Desktop Duplication API |
| **macOS** | `quartz/` | CoreGraphics / ScreenCaptureKit |
| **Linux X11** | `x11/` | X11/XCB |
| **Linux Wayland** | `wayland/` | PipeWire / Portal |
| **Android** | `android/` | MediaProjection API |

**视频编码支持** (`common/`):
- VP8/VP9 (libvpx)
- H.264/H.265 (硬件编码)
- AV1 (libaom)
- 硬件编码 (hwcodec)

#### enigo/ - 输入控制库

跨平台输入模拟：

| 平台 | 实现 |
|------|------|
| **Windows** | Win32 API / SendInput |
| **macOS** | CoreGraphics / CGEvent |
| **Linux** | X11 / uinput / libxdo |

#### clipboard/ - 剪贴板库

跨平台剪贴板同步：

| 平台 | 实现 |
|------|------|
| **Windows** | Win32 Clipboard API |
| **macOS** | NSPasteboard |
| **Linux** | X11 clipboard / Wayland data-control |

#### virtual_display/ - 虚拟显示器

Windows 虚拟显示器驱动，用于无头 (headless) 远程控制。

#### remote_printer/ - 远程打印机

Windows 远程打印功能实现。

---

### 3. flutter/ - Flutter UI

#### lib/ 目录结构

```
lib/
├── common/                    # 共享组件
│   ├── widgets/               # 共享 UI 组件
│   │   ├── address_book.dart  # 地址簿
│   │   ├── chat_page.dart     # 聊天页面
│   │   ├── peer_card.dart     # 节点卡片
│   │   ├── dialog.dart        # 对话框
│   │   └── toolbar.dart       # 工具栏
│   ├── hbbs/                  # 服务器相关
│   └── shared_state.dart      # 共享状态
├── desktop/                   # 桌面端 UI
│   ├── pages/                 # 页面
│   │   ├── desktop_home_page.dart    # 主页
│   │   ├── desktop_setting_page.dart # 设置页
│   │   ├── remote_page.dart          # 远程控制页
│   │   ├── file_manager_page.dart    # 文件管理页
│   │   ├── port_forward_page.dart    # 端口转发页
│   │   ├── terminal_page.dart        # 终端页
│   │   ├── server_page.dart          # 服务页
│   │   └── view_camera_page.dart     # 摄像头页
│   ├── screen/                # 屏幕
│   │   ├── desktop_remote_screen.dart
│   │   ├── desktop_file_transfer_screen.dart
│   │   └── desktop_port_forward_screen.dart
│   └── widgets/               # 桌面端组件
│       ├── remote_toolbar.dart
│       ├── tabbar_widget.dart
│       └── titlebar_widget.dart
├── mobile/                    # 移动端 UI
│   ├── pages/                 # 页面
│   │   ├── home_page.dart     # 主页
│   │   ├── remote_page.dart   # 远程控制页
│   │   ├── file_manager_page.dart
│   │   ├── settings_page.dart
│   │   └── scan_page.dart     # 扫码页
│   └── widgets/               # 移动端组件
│       ├── gesture_help.dart  # 手势帮助
│       └── floating_mouse.dart
├── models/                    # 数据模型
│   ├── model.dart             # 主模型
│   ├── server_model.dart      # 服务模型
│   ├── chat_model.dart        # 聊天模型
│   ├── file_model.dart        # 文件模型
│   ├── input_model.dart       # 输入模型
│   ├── peer_model.dart        # 节点模型
│   ├── ab_model.dart          # 地址簿模型
│   ├── terminal_model.dart    # 终端模型
│   └── web_model.dart         # Web 模型
├── native/                    # Native 交互
│   ├── common.dart            # FFI 通用
│   └── custom_cursor.dart     # 自定义光标
├── plugin/                    # 插件系统
│   ├── manager.dart           # 插件管理
│   ├── handlers.dart          # 事件处理
│   └── ui_manager.dart        # UI 管理
├── utils/                     # 工具类
│   ├── multi_window_manager.dart
│   ├── event_loop.dart
│   └── http_service.dart
└── main.dart                  # 应用入口
```

---

## 技术架构

### 远程桌面协议实现

RustDesk 使用自定义的远程桌面协议，主要实现在 `src/rendezvous_mediator.rs`：

```
┌─────────────────────────────────────────────────────────────────┐
│                    RustDesk 协议架构                              │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌──────────┐     ┌──────────────────┐     ┌──────────┐        │
│  │  Client  │────▶│ rustdesk-server  │────▶│  Server  │        │
│  │ (控制端)  │     │  (连接服务器)     │     │ (被控端)  │        │
│  └──────────┘     └──────────────────┘     └──────────┘        │
│       │                   │                    │               │
│       │    ┌──────────────┴──────────────┐     │               │
│       │    │  注册 / 打洞 / 中继          │     │               │
│       │    └─────────────────────────────┘     │               │
│       │                                        │               │
│       │    ┌───────────────────────────────────┴─────────────┐ │
│       │    │              P2P 直连 / 中继连接                 │ │
│       └───────────────────────────────────────────────────────┘ │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

**连接流程**:

1. **注册**: Server 向连接服务器注册 ID 和公钥
2. **发现**: Client 查询 Server 的地址
3. **打洞**: 尝试 NAT 穿透建立直连
4. **中继**: 打洞失败时使用中继服务器
5. **握手**: 加密握手 (NaCl box)
6. **会话**: 建立远程控制会话

### 端口配置

| 端口 | 用途 |
|------|------|
| 21116 | Rendezvous (UDP/TCP) |
| 21117 | Relay (TCP) |
| 21118 | WebSocket Rendezvous |
| 21119 | WebSocket Relay |

### 加密机制

- **签名**: Ed25519 (libsodium sign)
- **加密**: XSalsa20-Poly1305 (NaCl box)
- **密码**: SHA256 哈希 + Salt

---

## 功能清单

### 远程控制功能

| 功能 | 描述 |
|------|------|
| 远程桌面 | 实时屏幕共享和控制 |
| 多显示器 | 支持多显示器切换 |
| 文件传输 | 双向文件传输 |
| 端口转发 | TCP/UDP 端口映射 |
| 终端访问 | SSH/终端会话 |
| 摄像头查看 | 远程摄像头查看 |
| 聊天 | 实时文字聊天 |
| 白板 | 协作白板功能 |

### 安全功能

| 功能 | 描述 |
|------|------|
| 端到端加密 | NaCl 加密通信 |
| 密码保护 | 永久密码 / 临时密码 |
| 2FA | 双因素认证 |
| 隐私模式 | 屏幕隐私保护 |
| 权限控制 | 可配置控制权限 |
| 信任设备 | 设备信任管理 |

### 平台特性

| 平台 | 特殊功能 |
|------|----------|
| Windows | UAC 提升、服务安装、虚拟显示器 |
| macOS | 权限管理、Retina 支持 |
| Linux | Wayland 支持、uinput 输入 |
| Android | 浮动窗口、辅助服务 |
| iOS | 屏幕录制扩展 |

---

## 依赖分析

### Rust 依赖 (Cargo.toml)

#### 核心依赖

| 依赖 | 版本 | 用途 |
|------|------|------|
| `tokio` | - | 异步运行时 |
| `serde` | 1.0 | 序列化 |
| `protobuf` | - | Protobuf |
| `sodiumoxide` | - | 加密 |
| `magnum-opus` | - | Opus 音频编码 |
| `cpal` | - | 音频捕获 |
| `scrap` | path | 屏幕捕获 |
| `hbb_common` | path | 共享库 |
| `enigo` | path | 输入控制 |
| `clipboard` | path | 剪贴板 |

#### 平台特定依赖

| 平台 | 依赖 |
|------|------|
| **Windows** | `winapi`, `windows`, `winreg`, `windows-service` |
| **macOS** | `objc`, `cocoa`, `core-foundation`, `core-graphics` |
| **Linux** | `gtk`, `evdev`, `dbus`, `pam`, `pulse` |

### Flutter 依赖 (pubspec.yaml)

| 依赖 | 版本 | 用途 |
|------|------|------|
| `flutter_rust_bridge` | 1.80.1 | Rust-Flutter 桥接 |
| `provider` | 6.0.5 | 状态管理 |
| `window_manager` | git | 窗口管理 |
| `desktop_multi_window` | git | 多窗口 |
| `texture_rgba_renderer` | git | 视频渲染 |
| `flutter_gpu_texture_renderer` | git | GPU 渲染 |
| `qr_code_scanner` | 1.0.0 | 扫码 |
| `file_picker` | 5.1.0 | 文件选择 |
| `xterm` | 4.0.0 | 终端 |
| `dash_chat_2` | git | 聊天 |

---

## CI/CD 工作流

### 主要工作流

| 工作流 | 文件 | 用途 |
|------|------|------|
| **Flutter 构建** | `flutter-build.yml` | 全平台 Flutter 构建 |
| **Flutter CI** | `flutter-ci.yml` | Flutter 代码检查 |
| **CI** | `ci.yml` | Rust 代码检查 |
| **Android 构建** | `build-android.yml` | Android APK 构建 |
| **Bridge** | `bridge.yml` | Flutter Rust Bridge 生成 |
| **Nightly** | `flutter-nightly.yml` | 每日构建 |
| **Tag Release** | `flutter-tag.yml` | 版本发布 |

### 构建环境

| 平台 | 环境 |
|------|------|
| **Windows** | windows-2022, MSVC, vcpkg |
| **macOS** | macOS (Intel/ARM) |
| **Linux** | ubuntu-24.04 |
| **Android** | NDK r28c, Flutter 3.24.5 |
| **iOS** | Xcode |

### 构建版本

- Rust: 1.75 (Sciter), 1.81 (macOS)
- Flutter: 3.24.5
- Vcpkg: 2025.08.27

---

## 配置文件

### Cargo.toml 特性

| Feature | 描述 |
|---------|------|
| `flutter` | Flutter UI 支持 |
| `hwcodec` | 硬件编码 |
| `vram` | VRAM 编码 |
| `mediacodec` | MediaCodec (Android) |
| `plugin_framework` | 插件框架 |
| `cli` | 命令行模式 |
| `unix-file-copy-paste` | Unix 文件复制粘贴 |

### 配置选项 (hbb_common/src/config.rs)

主要配置选项包括：

- `rendezvous-server`: 连接服务器地址
- `relay-server`: 中继服务器地址
- `audio-input`: 音频输入设备
- `video-quality`: 视频质量
- `custom-image-quality`: 自定义图像质量
- `direct-server`: 直连服务器
- `stop-service`: 停止服务
- 等等...

---

## 多语言支持

支持 **50+** 种语言，语言文件位于 `src/lang/`:

| 语言 | 文件 |
|------|------|
| 中文 | `cn.rs` |
| 英语 | `en.rs` |
| 日语 | `ja.rs` |
| 韩语 | `ko.rs` |
| 德语 | `de.rs` |
| 法语 | `fr.rs` |
| 俄语 | `ru.rs` |
| ... | ... |

---

## 打包格式

| 格式 | 目录/文件 |
|------|----------|
| **Windows MSI** | `res/msi/` |
| **Debian/Ubuntu** | `res/DEBIAN/`, `res/*.spec` |
| **AppImage** | `appimage/` |
| **Flatpak** | `flatpak/` |
| **Android APK** | `flutter/android/` |
| **iOS IPA** | `flutter/ios/` |
| **Docker** | `Dockerfile` |

---

## 项目统计

- **总文件数**: 约 1000+ 文件
- **Rust 代码**: 约 50,000+ 行
- **Flutter/Dart 代码**: 约 30,000+ 行
- **支持平台**: 5 (Windows, Linux, macOS, Android, iOS)
- **支持语言**: 50+ 种
- **版本**: 1.4.6

---

## 开发指南

### 构建命令

```bash
# Rust 构建
cargo build --release

# Flutter 构建
cd flutter
flutter build <platform>

# Android 构建
./flutter/build_android.sh

# iOS 构建
./flutter/build_ios.sh
```

### 运行要求

- Rust 1.75+
- Flutter 3.24+
- 平台特定 SDK (Windows SDK, Xcode, Android SDK 等)

---

## 相关链接

- **GitHub**: https://github.com/rustdesk/rustdesk
- **官网**: https://rustdesk.com
- **文档**: https://rustdesk.com/docs
- **服务器**: https://github.com/rustdesk/rustdesk-server

---

*文档生成日期: 2026-06-16*
*分析版本: RustDesk 1.4.6*