# RustDesk Android UI 精简方案

## 概述

本方案旨在为 Android 平台设计 UI 精简方案，确保完全不影响其他平台（Windows、Linux、macOS、Web）。

## 1. 平台隔离方案

### 1.1 现有平台检测机制

项目已在 `common.dart` 中实现了完善的平台检测体系：

```dart
// flutter/lib/common.dart
final isAndroid = isAndroid_;
final isIOS = isIOS_;
final isWindows = isWindows_;
final isMacOS = isMacOS_;
final isLinux = isLinux_;
final isDesktop = isDesktop_;
final isWeb = isWeb_;
var isMobile = isAndroid || isIOS;
```

### 1.2 平台隔离原则

1. **只修改移动端专用目录**：`flutter/lib/mobile/`
2. **使用 `isAndroid` 进行条件判断**：在需要区分 Android 和 iOS 时使用
3. **避免修改共享文件**：除非确认仅移动端使用，不修改 `common/`、`models/`、`utils/`
4. **创建移动端专用配置**：在 `mobile/` 目录下创建 Android 专用配置

### 1.3 条件编译方案

Flutter 不支持真正的条件编译，但可以通过以下方式实现平台隔离：

```dart
// 运行时检测
if (isAndroid) {
  // Android 特定代码
}

// 或者使用 assert + debug 模式
assert(() {
  // 仅在调试时执行
  return true;
}());
```

---

## 2. 仅移动端修改清单

### 2.1 可安全修改的文件

#### `flutter/lib/mobile/pages/` 目录

| 文件 | 说明 | 修改范围 |
|------|------|---------|
| `home_page.dart` | 移动端主页 | UI 精简、页面结构 |
| `settings_page.dart` | 设置页面 | 设置项过滤、简化 |
| `connection_page.dart` | 连接页面 | 连接 UI 精简 |
| `server_page.dart` | 服务器页面 | 服务器功能 |
| `remote_page.dart` | 远程控制页面 | 远程控制 UI |
| `file_manager_page.dart` | 文件管理页面 | 文件传输 UI |
| `view_camera_page.dart` | 摄像头页面 | 摄像头查看 UI |
| `terminal_page.dart` | 终端页面 | 终端功能 |
| `scan_page.dart` | 扫描页面 | 二维码扫描 |

#### `flutter/lib/mobile/widgets/` 目录

| 文件 | 说明 | 修改范围 |
|------|------|---------|
| `custom_scale_widget.dart` | 自定义缩放组件 | 缩放控制 |
| `dialog.dart` | 对话框 | 对话框精简 |
| `floating_mouse.dart` | 浮动鼠标 | Android 特定 |
| `floating_mouse_widgets.dart` | 浮动鼠标部件 | Android 特定 |
| `gesture_help.dart` | 手势帮助 | 手势提示 |

### 2.2 需要谨慎修改的文件

以下文件虽在 `mobile/` 目录下，但被多个平台或通过共享状态引用：

- `server_page.dart` - 移动端服务器功能，被 `common.dart` 引用

### 2.3 避免修改的文件

| 文件 | 原因 |
|------|------|
| `flutter/lib/common/` | 共享组件，多平台使用 |
| `flutter/lib/models/` | 数据模型，跨平台 |
| `flutter/lib/utils/` | 工具类，跨平台 |
| `flutter/lib/desktop/` | 桌面端专用 |
| `flutter/lib/web/` | Web 专用 |
| `flutter/lib/main.dart` | 应用入口，影响全局 |

---

## 3. 配置实现

### 3.1 创建 Android 专用配置文件

建议在 `flutter/lib/mobile/` 下创建 `android_config.dart`：

```dart
import 'package:flutter/foundation.dart';
import '../../common.dart';

/// Android 平台特定配置
/// 用于 Android UI 精简方案
class AndroidConfig {
  AndroidConfig._();

  /// 是否启用精简模式
  /// 可通过远程配置覆盖
  static bool get isLiteMode {
    // 默认值，可以从远程配置读取
    return kDebugMode;
  }

  /// Android 特定的 UI 配置
  static const AndroidUIConfig ui = AndroidUIConfig();
}

/// Android UI 配置常量
class AndroidUIConfig {
  const AndroidUIConfig();

  // ========== 主页配置 ==========

  /// 是否显示快捷操作图标
  /// 精简模式可隐藏
  bool get showQuickActions => !AndroidConfig.isLiteMode;

  /// 是否显示最近会话
  bool get showRecentSessions => !AndroidConfig.isLiteMode;

  // ========== 设置页面配置 ==========

  /// 需要隐藏的设置项
  Set<String> get hiddenSettings => {
        if (AndroidConfig.isLiteMode) ...{
          'enable-record-session',
          'enable-hwcodec',
          'allow-auto-record-incoming',
          'allow-auto-record-outgoing',
        }
      };

  /// 需要简化的设置类别
  bool get simplifySecuritySettings => AndroidConfig.isLiteMode;

  // ========== 工具栏配置 ==========

  /// 远程控制工具栏按钮
  List<String> get remoteToolbarButtons => [
        'keyboard',
        'screenshot',
        'file_transfer',
        if (!AndroidConfig.isLiteMode) 'record_session',
        'fullscreen',
        'mute',
      ];

  /// 精简模式隐藏的按钮
  Set<String> get hiddenToolbarButtons => AndroidConfig.isLiteMode
      ? {
          'record_session',
          'screenshot',
          'connection_info',
        }
      : {};
}
```

### 3.2 在现有文件中集成 Android 配置

#### 在 `home_page.dart` 中使用

```dart
import 'android_config.dart'; // 新建文件

class HomePageState extends State<HomePage> {
  // ...

  void initPages() {
    _pages.clear();
    if (!bind.isIncomingOnly()) {
      _pages.add(ConnectionPage(appBarActions: []));
    }
    if (isAndroid && !bind.isOutgoingOnly()) {
      _chatPageTabIndex = _pages.length;
      _pages.addAll([
        ChatPage(type: ChatPageType.mobileMain),
        ServerPage()
      ]);
    }
    _pages.add(SettingsPage());
  }

  // 使用 Android 配置控制 UI 显示
  Widget _buildQuickActions() {
    if (!AndroidConfig.ui.showQuickActions) {
      return SizedBox.shrink();
    }
    // ... 原有代码
  }
}
```

#### 在 `settings_page.dart` 中使用

```dart
import 'android_config.dart';

class _SettingsState extends State<SettingsPage> {
  // ...

  @override
  Widget build(BuildContext context) {
    // ...
    final hiddenSettings = AndroidConfig.ui.hiddenSettings;

    // 隐藏设置项
    if (hiddenSettings.contains('enable-record-session')) {
      // 隐藏录屏设置
    }

    // 简化安全设置
    if (AndroidConfig.ui.simplifySecuritySettings) {
      // 显示简化版安全设置
    }
  }
}
```

---

## 4. 实施步骤

### 步骤 1：创建 Android 配置文件

创建 `flutter/lib/mobile/android_config.dart`，定义所有 Android 特定的配置常量。

### 步骤 2：修改移动端页面

按以下优先级修改移动端页面：

1. **`settings_page.dart`** - 设置页面（最复杂，需要逐项检查）
2. **`home_page.dart`** - 主页（快速操作、最近会话）
3. **`remote_page.dart`** - 远程控制页面（工具栏）
4. **`connection_page.dart`** - 连接页面

### 步骤 3：验证不影响其他平台

每次修改后验证：

```bash
# 验证桌面端构建
cd flutter && flutter build macos

# 验证 Web 端构建
flutter build web

# 验证 Linux 构建
flutter build linux
```

### 步骤 4：创建 Android 特定 Widget

如需创建 Android 专用的 Widget，建议放在 `mobile/widgets/android/` 目录下：

```
mobile/widgets/android/
├── android_toolbar.dart
├── android_simplified_dialog.dart
└── android_quick_actions.dart
```

---

## 5. 注意事项

### 5.1 不要修改的部分

1. **共享状态管理** (`common.dart` 中的全局状态)
2. **数据模型** (`models/` 目录)
3. **平台通道** (`utils/platform_channel.dart`)
4. **桌面端 UI** (`desktop/` 目录)
5. **Web 端 UI** (`web/` 目录)

### 5.2 平台检测最佳实践

```dart
// ✅ 推荐：明确检测 Android
if (isAndroid) {
  // Android 特定代码
}

// ✅ 推荐：检测移动端（Android + iOS）
if (isMobile) {
  // 移动端通用代码
}

// ❌ 避免：使用否定检测
if (!isDesktop && !isWeb) {
  // 这种写法容易出错
}
```

### 5.3 远程配置支持

建议在 `AndroidConfig` 中预留远程配置接口：

```dart
static bool get isLiteMode {
  // 优先使用远程配置
  final remoteValue = bind.mainGetBuildinOption('android_lite_mode');
  if (remoteValue.isNotEmpty) {
    return remoteValue == 'Y';
  }
  // 回退到默认值
  return kDebugMode;
}
```

---

## 6. 文件修改清单

### 6.1 新建文件

| 文件路径 | 说明 |
|---------|------|
| `flutter/lib/mobile/android_config.dart` | Android 专用配置 |

### 6.2 修改文件

| 文件路径 | 修改内容 |
|---------|---------|
| `flutter/lib/mobile/pages/home_page.dart` | 使用 AndroidConfig 控制快速操作显示 |
| `flutter/lib/mobile/pages/settings_page.dart` | 使用 AndroidConfig 过滤设置项 |

### 6.3 验证文件（不修改）

| 文件路径 | 说明 |
|---------|------|
| `flutter/lib/common.dart` | 确认平台检测未被修改 |
| `flutter/lib/main.dart` | 确认入口未被修改 |
| `flutter/lib/models/*` | 确认模型未被修改 |

---

## 7. 测试清单

### 7.1 Android 平台

- [ ] 主页面快速操作正确隐藏（精简模式）
- [ ] 设置页面精简项正确隐藏
- [ ] 远程控制工具栏按钮正确
- [ ] 对话框显示正确

### 7.2 其他平台验证

- [ ] macOS 桌面端构建正常
- [ ] Windows 桌面端构建正常
- [ ] Linux 桌面端构建正常
- [ ] Web 端构建正常

---

*文档版本：1.0*
*最后更新：2026-06-16*
