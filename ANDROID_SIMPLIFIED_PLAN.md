# RustDesk Android 端 UI 精简方案

## 一、当前 Android UI 分析

### 1.1 页面结构

Flutter 移动端页面位于 `flutter/lib/mobile/pages/` 目录：

| 页面 | 文件 | 功能说明 | 优先级 |
|------|------|----------|--------|
| 首页 | `home_page.dart` | 底部导航 + 页面容器 | 核心 |
| 连接页 | `connection_page.dart` | ID 输入 + 远程列表 | 核心 |
| 远程控制页 | `remote_page.dart` | 远程桌面控制 | 核心 |
| 设置页 | `settings_page.dart` | 应用设置 | 保留(精简) |
| 服务器页 | `server_page.dart` | 屏幕共享/接收连接 | 隐藏 |
| 文件管理 | `file_manager_page.dart` | 文件传输 | 隐藏 |
| 摄像头查看 | `view_camera_page.dart` | 摄像头远程查看 | 隐藏 |
| 扫描页 | `scan_page.dart` | QR码扫描 | 隐藏 |
| 终端页 | `terminal_page.dart` | 远程终端 | 隐藏 |

### 1.2 首页导航结构

```dart
// home_page.dart - initPages()
_pages.clear();
if (!bind.isIncomingOnly()) {
  _pages.add(ConnectionPage(appBarActions: []));  // 连接页
}
if (isAndroid && !bind.isOutgoingOnly()) {
  _chatPageTabIndex = _pages.length;
  _pages.addAll([ChatPage(type: ChatPageType.mobileMain), ServerPage()]);
}
_pages.add(SettingsPage());  // 设置页
```

### 1.3 配置模型分析

配置位于 `libs/hbb_common/src/config.rs`：

**现有隐藏配置机制：**
- `hide-server-settings` - 隐藏服务器设置
- `hide-proxy-settings` - 隐藏代理设置
- `hide-network-settings` - 隐藏网络设置
- `hide-websocket-settings` - 隐藏 WebSocket 设置
- `hide-security-settings` - 隐藏安全设置

**相关配置键：**
```rust
// keys 模块中的配置选项
OPTION_HIDE_SERVER_SETTINGS      // hide-server-settings
OPTION_HIDE_PROXY_SETTINGS       // hide-proxy-settings
OPTION_HIDE_NETWORK_SETTINGS     // hide-network-settings
OPTION_HIDE_WEBSOCKET_SETTINGS   // hide-websocket-settings
OPTION_HIDE_SECURITY_SETTINGS    // hide-security-settings
```

---

## 二、精简方案设计

### 2.1 设计目标

- **保留**：首页(简化)、连接页、远程控制页
- **隐藏**：文件管理、摄像头、终端、服务器页等入口
- **配置驱动**：使用配置变量控制显示/隐藏，不删除代码

### 2.2 页面去留策略

| 页面 | 标准模式 | 精简模式 | 隐藏方式 |
|------|----------|----------|----------|
| ConnectionPage | ✅ 显示 | ✅ 显示 | - |
| ServerPage | ✅ 显示 | ❌ 隐藏 | 底部导航移除 |
| ChatPage | ✅ 显示 | ❌ 隐藏 | 底部导航移除 |
| SettingsPage | ✅ 显示 | ⚠️ 精简 | 隐藏高级选项 |
| FileManagerPage | 需主动打开 | 需主动打开 | 远程控制页菜单隐藏 |
| TerminalPage | 需主动打开 | 需主动打开 | 远程控制页菜单隐藏 |
| ViewCameraPage | 需主动打开 | 需主动打开 | 远程控制页菜单隐藏 |
| ScanPage | AppBar 操作 | AppBar 操作 | 保持不变 |

### 2.3 配置标志设计

新增配置常量：

```dart
// Flutter 侧 - flutter/lib/consts.dart
const String kOptionSimplifiedMode = 'simplified-mode';
```

```rust
// Rust 侧 - libs/hbb_common/src/config.rs
pub const OPTION_SIMPLIFIED_MODE: &str = "simplified-mode";
```

---

## 三、具体实施方案

### 3.1 创建配置常量

**文件：** `flutter/lib/consts.dart`

添加：
```dart
const String kOptionSimplifiedMode = 'simplified-mode';
```

**Rust 侧：** `libs/hbb_common/src/config.rs`

在 `keys` 模块添加：
```rust
pub const OPTION_SIMPLIFIED_MODE: &str = "simplified-mode";
```

在 `KEYS_BUILDIN_SETTINGS` 数组中添加：
```rust
pub const KEYS_BUILDIN_SETTINGS: &[&str] = &[
    // ... existing items
    OPTION_SIMPLIFIED_MODE,
];
```

### 3.2 修改首页 (home_page.dart)

```dart
// 添加简化模式判断方法
bool get isSimplifiedMode {
  if (isMobile) {
    return bind.mainGetBuildinOption(key: kOptionSimplifiedMode) == 'Y';
  }
  return false;
}

void initPages() {
  _pages.clear();
  
  // 连接页 - 始终显示
  if (!bind.isIncomingOnly()) {
    _pages.add(ConnectionPage(appBarActions: []));
  }
  
  // 聊天页和服务器页 - 精简模式隐藏
  if (isAndroid && !bind.isOutgoingOnly()) {
    _chatPageTabIndex = _pages.length;
    if (!isSimplifiedMode) {
      _pages.add(ChatPage(type: ChatPageType.mobileMain));
    }
    if (!isSimplifiedMode && !isHideServerSetting()) {
      _pages.add(ServerPage());
    }
  }
  
  // 设置页 - 精简模式精简内容
  _pages.add(SettingsPage());
}
```

### 3.3 修改设置页 (settings_page.dart)

在 `_SettingsState.build()` 方法中，精简模式隐藏以下设置项：

```dart
// 需要在精简模式隐藏的设置
final hideInSimplifiedMode = isSimplifiedMode;

// 在各个 SettingsSection 中添加条件判断

// 隐藏服务器相关设置
if (!hideInSimplifiedMode && !_hideNetwork && !_hideServer)
  SettingsTile(
    title: Text(translate('ID/Relay Server')),
    ...
  ),

// 隐藏代理设置
if (!hideInSimplifiedMode && !_hideNetwork && !_hideProxy)
  SettingsTile(
    title: Text(translate('Socks5/Http(s) Proxy')),
    ...
  ),

// 隐藏 WebSocket 选项
if (!hideInSimplifiedMode && !disabledSettings && !_hideNetwork && !_hideWebSocket)
  SettingsTile.switchTile(
    title: Text(translate('Use WebSocket')),
    ...
  ),

// 隐藏 2FA 设置
if (isAndroid && !disabledSettings && !outgoingOnly && !hideSecuritySettings && !hideInSimplifiedMode)
  SettingsSection(title: Text('2FA'), tiles: tfaTiles),

// 隐藏分享屏幕设置
if (isAndroid && !disabledSettings && !outgoingOnly && !hideSecuritySettings && !hideInSimplifiedMode)
  SettingsSection(
    title: Text(translate("Share screen")),
    tiles: shareScreenTiles,
  ),

// 隐藏录制相关
if (isAndroid && !hideInSimplifiedMode)
  SettingsSection(
    title: Text(translate("Recording")),
    ...
  ),

// 隐藏硬件编解码器
if (isAndroid && !hideInSimplifiedMode)
  SettingsSection(title: Text(translate('Hardware Codec')), ...),

// 隐藏增强功能中的高级选项
if (isAndroid && !disabledSettings && !outgoingOnly && !hideSecuritySettings && !hideInSimplifiedMode)
  SettingsSection(
    title: Text(translate("Enhancements")),
    tiles: enhancementsTiles,
  ),
```

### 3.4 简化模式判断方法

**文件：** `flutter/lib/models/platform_model.dart` 或新建工具类

```dart
bool isSimplifiedMode() {
  return isMobile && bind.mainGetBuildinOption(key: kOptionSimplifiedMode) == 'Y';
}
```

### 3.5 隐藏远程控制页高级功能

**文件：** `flutter/lib/mobile/pages/remote_page.dart`

在 `showActions()` 和工具栏菜单中，精简模式隐藏：

```dart
// 隐藏文件传输入口
if (!isSimplifiedMode) {
  // 添加文件传输菜单
}

// 隐藏摄像头查看入口
if (!isSimplifiedMode) {
  // 添加摄像头菜单
}

// 隐藏终端入口
if (!isSimplifiedMode) {
  // 添加终端菜单
}
```

---

## 四、配置修改清单

### 4.1 Flutter 侧修改

| 文件 | 修改内容 |
|------|----------|
| `flutter/lib/consts.dart` | 添加 `kOptionSimplifiedMode` 常量 |
| `flutter/lib/mobile/pages/home_page.dart` | 修改 `initPages()` 根据精简模式条件添加页面 |
| `flutter/lib/mobile/pages/settings_page.dart` | 在各设置项添加精简模式条件判断 |
| `flutter/lib/models/platform_model.dart` | 添加 `isSimplifiedMode()` 函数 |

### 4.2 Rust 侧修改

| 文件 | 修改内容 |
|------|----------|
| `libs/hbb_common/src/config.rs` | 添加 `OPTION_SIMPLIFIED_MODE` 常量并加入 `KEYS_BUILDIN_SETTINGS` |

---

## 五、代码改动示例

### 5.1 首页修改示例 (home_page.dart)

```dart
// 修改前
void initPages() {
  _pages.clear();
  if (!bind.isIncomingOnly()) {
    _pages.add(ConnectionPage(appBarActions: []));
  }
  if (isAndroid && !bind.isOutgoingOnly()) {
    _chatPageTabIndex = _pages.length;
    _pages.addAll([ChatPage(type: ChatPageType.mobileMain), ServerPage()]);
  }
  _pages.add(SettingsPage());
}

// 修改后
void initPages() {
  _pages.clear();
  if (!bind.isIncomingOnly()) {
    _pages.add(ConnectionPage(appBarActions: []));
  }
  if (isAndroid && !bind.isOutgoingOnly()) {
    _chatPageTabIndex = _pages.length;
    // 精简模式隐藏聊天页
    if (!isSimplifiedMode()) {
      _pages.add(ChatPage(type: ChatPageType.mobileMain));
    }
    // 精简模式隐藏服务器页
    if (!isSimplifiedMode() && !isHideServerSetting()) {
      _pages.add(ServerPage());
    }
  }
  _pages.add(SettingsPage());
}

bool isSimplifiedMode() {
  return isMobile && bind.mainGetBuildinOption(key: kOptionSimplifiedMode) == 'Y';
}
```

### 5.2 设置页修改示例 (settings_page.dart)

```dart
// 修改前
SettingsSection(title: Text('2FA'), tiles: tfaTiles),

// 修改后
if (!isSimplifiedMode())
  SettingsSection(title: Text('2FA'), tiles: tfaTiles),
```

---

## 六、实施步骤

### 第一阶段：配置基础（1天）
1. 在 `config.rs` 添加 `OPTION_SIMPLIFIED_MODE` 配置键
2. 在 Flutter `consts.dart` 添加对应的 Dart 常量
3. 在 `platform_model.dart` 添加 `isSimplifiedMode()` 函数

### 第二阶段：首页改造（1天）
1. 修改 `home_page.dart` 的 `initPages()` 方法
2. 实现精简模式下隐藏 ServerPage 和 ChatPage
3. 测试导航切换正常

### 第三阶段：设置页精简（1天）
1. 在 `_SettingsState.build()` 中添加精简模式判断
2. 隐藏 2FA、录制、硬件编解码器、增强功能等设置项
3. 保留基础设置（语言、主题、显示设置）

### 第四阶段：远程控制页精简（0.5天）
1. 修改 `remote_page.dart` 的菜单项
2. 精简模式下隐藏文件传输、摄像头、终端入口
3. 保留核心控制功能

### 第五阶段：测试验证（0.5天）
1. 测试标准模式和精简模式切换
2. 验证各页面功能正常
3. 检查配置持久化

---

## 七、注意事项

1. **不删除代码**：所有隐藏通过配置条件实现，代码保留
2. **保持兼容性**：标准模式行为与现有完全一致
3. **配置持久化**：精简模式设置通过 `BUILTIN_SETTINGS` 机制固化
4. **渐进式隐藏**：优先隐藏整个页面/功能，而非单独设置项

---

## 八、测试用例

| 测试项 | 预期结果 |
|--------|----------|
| 标准模式启动 | 显示完整导航（连接、聊天、服务器、设置） |
| 精简模式启动 | 仅显示连接和设置导航 |
| 精简模式设置页 | 隐藏 2FA、录制、硬件编解码器等 |
| 标准模式远程控制 | 显示完整菜单（含文件、摄像头、终端） |
| 精简模式远程控制 | 菜单仅保留核心控制功能 |
