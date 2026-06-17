# RustDesk Flutter UI 精简版技术方案

## 一、当前功能分析

### 1.1 目录结构概览

```
flutter/lib/
├── common/              # 共享模块
│   ├── formatter/       # ID 格式化器
│   ├── hbbs/            # 服务器相关
│   ├── widgets/         # 共享组件（20个文件）
│   └── shared_state.dart # 共享状态
├── desktop/             # 桌面端模块
│   ├── pages/           # 桌面端页面（16个文件）
│   ├── screen/          # 桌面端屏幕（5个文件）
│   └── widgets/         # 桌面端组件（12个文件）
├── mobile/              # 移动端模块
│   ├── pages/           # 移动端页面（9个文件）
│   └── widgets/         # 移动端组件（5个文件）
├── models/              # 数据模型（19个文件）
├── native/              # 原生交互（3个文件）
├── plugin/              # 插件系统（8个文件）
├── utils/               # 工具类（7个文件）
├── web/                 # Web端（11个文件）
├── common.dart          # 公共函数
├── consts.dart          # 常量定义
└── main.dart            # 入口文件
```

### 1.2 桌面端页面功能分析

| 页面文件 | 功能描述 | 代码行数（估算） | 是否核心 |
|---------|---------|----------------|---------|
| `connection_page.dart` | 主连接页面，输入设备ID/IP，连接按钮 | ~615 | ✅ 核心 |
| `remote_page.dart` | 远程控制界面，显示远程桌面，输入处理 | ~1054 | ✅ 核心 |
| `remote_tab_page.dart` | 远程控制多标签页管理 | ~200 | ❌ 可移除 |
| `desktop_home_page.dart` | 桌面端主页框架 | ~100 | ✅ 核心 |
| `desktop_tab_page.dart` | 桌面端标签页框架 | ~300 | ❌ 可移除 |
| `desktop_setting_page.dart` | 设置页面 | ~800 | ❌ 可移除 |
| `file_manager_page.dart` | 文件传输管理页面 | ~1686 | ❌ 可移除 |
| `file_manager_tab_page.dart` | 文件传输标签页 | ~100 | ❌ 可移除 |
| `port_forward_page.dart` | 端口转发页面 | ~200 | ❌ 可移除 |
| `port_forward_tab_page.dart` | 端口转发标签页 | ~100 | ❌ 可移除 |
| `terminal_page.dart` | 终端页面 | ~300 | ❌ 可移除 |
| `terminal_tab_page.dart` | 终端标签页 | ~100 | ❌ 可移除 |
| `terminal_connection_manager.dart` | 终端连接管理 | ~150 | ❌ 可移除 |
| `server_page.dart` | 服务器模式页面（被控端） | ~1415 | ❌ 可移除 |
| `view_camera_page.dart` | 摄像头查看页面 | ~300 | ❌ 可移除 |
| `view_camera_tab_page.dart` | 摄像头标签页 | ~100 | ❌ 可移除 |
| `install_page.dart` | 安装引导页面 | ~200 | ❌ 可移除 |

### 1.3 移动端页面功能分析

| 页面文件 | 功能描述 | 代码行数（估算） | 是否核心 |
|---------|---------|----------------|---------|
| `home_page.dart` | 移动端主页，底部导航栏 | ~255 | ✅ 核心 |
| `connection_page.dart` | 移动端连接页面 | ~300 | ✅ 核心 |
| `remote_page.dart` | 移动端远程控制界面 | ~1428 | ✅ 核心 |
| `scan_page.dart` | 扫码连接页面 | ~150 | ❌ 可移除 |
| `server_page.dart` | 移动端服务器模式 | ~300 | ❌ 可移除 |
| `settings_page.dart` | 移动端设置页面 | ~500 | ❌ 可移除 |
| `file_manager_page.dart` | 移动端文件传输 | ~400 | ❌ 可移除 |
| `terminal_page.dart` | 移动端终端 | ~200 | ❌ 可移除 |
| `view_camera_page.dart` | 移动端摄像头查看 | ~200 | ❌ 可移除 |

### 1.4 共享组件分析

| 组件文件 | 功能描述 | 是否核心 |
|---------|---------|---------|
| `address_book.dart` | 地址簿管理 | ❌ 可移除 |
| `chat_page.dart` | 聊天功能 | ❌ 可移除 |
| `peer_card.dart` | 设备卡片显示 | ✅ 核心（简化版） |
| `peer_tab_page.dart` | 设备标签页（最近/收藏/发现/地址簿/群组） | ❌ 可移除 |
| `peers_view.dart` | 设备列表视图 | ❌ 可移除 |
| `my_group.dart` | 我的群组 | ❌ 可移除 |
| `dialog.dart` | 对话框组件 | ✅ 核心 |
| `toolbar.dart` | 工具栏组件 | ✅ 核心（简化版） |
| `remote_input.dart` | 远程输入处理 | ✅ 核心 |
| `overlay.dart` | 覆盖层组件 | ✅ 核心 |
| `login.dart` | 登录组件 | ❌ 可移除 |
| `setting_widgets.dart` | 设置相关组件 | ❌ 可移除 |
| `autocomplete.dart` | 自动补全 | ✅ 核心 |
| `connection_page_title.dart` | 连接页面标题 | ✅ 核心 |
| `custom_password.dart` | 密码输入 | ✅ 核心 |
| `gestures.dart` | 手势处理 | ✅ 核心 |
| `audio_input.dart` | 音频输入 | ❌ 可移除 |

### 1.5 数据模型分析

| 模型文件 | 功能描述 | 是否核心 |
|---------|---------|---------|
| `model.dart` | FFI核心模型，包含FfiModel、ImageModel、CanvasModel、CursorModel等 | ✅ 核心 |
| `input_model.dart` | 输入处理模型 | ✅ 核心 |
| `peer_model.dart` | 设备数据模型 | ✅ 核心（简化版） |
| `platform_model.dart` | 平台相关模型 | ✅ 核心 |
| `state_model.dart` | 全局状态模型 | ✅ 核心 |
| `native_model.dart` | 原生交互模型 | ✅ 核心 |
| `server_model.dart` | 服务器模式模型 | ❌ 可移除 |
| `chat_model.dart` | 聊天模型 | ❌ 可移除 |
| `file_model.dart` | 文件传输模型 | ❌ 可移除 |
| `cm_file_model.dart` | 连接管理文件模型 | ❌ 可移除 |
| `ab_model.dart` | 地址簿模型 | ❌ 可移除 |
| `group_model.dart` | 群组模型 | ❌ 可移除 |
| `peer_tab_model.dart` | 设备标签页模型 | ❌ 可移除 |
| `user_model.dart` | 用户模型 | ❌ 可移除 |
| `terminal_model.dart` | 终端模型 | ❌ 可移除 |
| `printer_model.dart` | 打印机模型 | ❌ 可移除 |
| `relative_mouse_model.dart` | 相对鼠标模型 | ✅ 核心（可选） |
| `web_model.dart` | Web端模型 | ❌ 可移除 |
| `desktop_render_texture.dart` | 桌面渲染纹理 | ✅ 核心 |

---

## 二、功能分类总结

### 2.1 核心功能（必须保留）

| 功能模块 | 描述 |
|---------|-----|
| **设备连接** | 输入设备ID/IP，发起连接请求 |
| **远程控制界面** | 显示远程桌面画面，处理用户输入 |
| **基本连接状态** | 显示连接状态、错误提示 |
| **远程输入处理** | 键盘、鼠标、触摸输入转发 |
| **画面渲染** | 远程桌面画面渲染（Texture/CustomPaint） |
| **光标显示** | 远程光标同步显示 |
| **基本工具栏** | 连接/断开、画面缩放、质量切换 |

### 2.2 可移除功能

| 功能模块 | 描述 | 移除原因 |
|---------|-----|---------|
| **地址簿** | 设备列表管理、分组、标签 | 非核心，增加复杂度 |
| **设备管理** | 最近连接、收藏、发现设备 | 非核心，可简化为直接输入ID |
| **文件传输** | 双向文件传输管理 | 非核心，独立功能 |
| **端口转发** | TCP端口转发、RDP转发 | 非核心，独立功能 |
| **终端功能** | 远程终端执行 | 非核心，独立功能 |
| **摄像头查看** | 远程摄像头查看 | 非核心，独立功能 |
| **服务器模式** | 被控端管理界面 | 非核心，精简版仅做控制端 |
| **聊天功能** | 文字聊天、语音通话 | 非核心，增加复杂度 |
| **多标签页** | 同时管理多个连接 | 非核心，可简化为单连接 |
| **设置页面** | 详细配置选项 | 非核心，可使用默认配置 |
| **用户系统** | 登录、账户管理 | 非核心，精简版无需账户 |
| **群组管理** | 设备群组 | 非核心，依赖地址簿 |
| **插件系统** | 扩展插件 | 非核心，增加复杂度 |
| **Web端** | Web浏览器版本 | 非核心，精简版专注原生 |

---

## 三、精简版架构设计

### 3.1 简化的目录结构

```
flutter/lib/
├── common/
│   ├── formatter/
│   │   └── id_formatter.dart        # ID格式化
│   ├── widgets/
│   │   ├── dialog.dart              # 对话框（简化）
│   │   ├── toolbar.dart             # 工具栏（简化）
│   │   ├── remote_input.dart        # 远程输入
│   │   ├── overlay.dart             # 覆盖层
│   │   ├── connection_page_title.dart
│   │   └── custom_password.dart     # 密码输入
│   └── shared_state.dart            # 共享状态（简化）
├── desktop/
│   ├── pages/
│   │   ├── connection_page.dart     # 连接页面（简化）
│   │   ├── remote_page.dart         # 远程控制页面（简化）
│   │   └── desktop_home_page.dart   # 主页框架（简化）
│   ├── widgets/
│   │   ├── remote_toolbar.dart      # 远程工具栏（简化）
│   │   └── titlebar_widget.dart     # 标题栏
├── mobile/
│   ├── pages/
│   │   ├── home_page.dart           # 移动端主页（简化）
│   │   ├── connection_page.dart     # 移动端连接页面（简化）
│   │   └── remote_page.dart         # 移动端远程控制（简化）
│   ├── widgets/
│   │   ├── gesture_help.dart        # 手势帮助
│   │   └── dialog.dart              # 移动端对话框
├── models/
│   ├── model.dart                   # FFI核心模型（简化）
│   ├── input_model.dart             # 输入模型
│   ├── peer_model.dart              # 设备模型（简化）
│   ├── platform_model.dart          # 平台模型
│   ├── state_model.dart             # 状态模型（简化）
│   ├── native_model.dart            # 原生模型
│   └── desktop_render_texture.dart  # 渲染纹理
├── native/
│   ├── common.dart                  # 原生通用
│   └── custom_cursor.dart           # 自定义光标
├── utils/
│   ├── image.dart                   # 图像处理
│   └── scale.dart                   # 缩放处理
├── common.dart                      # 公共函数（简化）
├── consts.dart                      # 常量定义（简化）
└── main.dart                        # 入口文件（简化）
```

### 3.2 精简版页面结构

#### 桌面端页面流程

```
DesktopHomePage
    └── ConnectionPage（连接输入页面）
            ├── ID输入框 + 连接按钮
            ├── 连接状态显示
            └── 密码输入对话框
    └── RemotePage（远程控制页面）
            ├── 远程画面显示（ImagePaint/Texture）
            ├── 光标显示（CursorPaint）
            ├── 工具栏（RemoteToolbar - 简化版）
            └── 连接状态覆盖层
```

#### 移动端页面流程

```
HomePage（底部导航）
    └── ConnectionPage（连接输入页面）
            ├── ID输入框 + 连接按钮
            └── 密码输入对话框
    └── RemotePage（远程控制页面）
            ├── 远程画面显示
            ├── 手势控制区域
            ├── 底部工具栏（简化版）
            └── 键盘帮助工具
```

### 3.3 精简版组件列表

| 组件类别 | 原版数量 | 精简版数量 | 保留组件 |
|---------|---------|-----------|---------|
| 桌面端页面 | 16 | 3 | connection_page, remote_page, desktop_home_page |
| 桌面端屏幕 | 5 | 1 | desktop_remote_screen |
| 桌面端组件 | 12 | 2 | remote_toolbar, titlebar_widget |
| 移动端页面 | 9 | 3 | home_page, connection_page, remote_page |
| 移动端组件 | 5 | 2 | gesture_help, dialog |
| 共享组件 | 20 | 8 | dialog, toolbar, remote_input, overlay, connection_page_title, custom_password, gestures, autocomplete |
| 数据模型 | 19 | 7 | model, input_model, peer_model, platform_model, state_model, native_model, desktop_render_texture |
| 原生模块 | 3 | 2 | common, custom_cursor |
| 工具类 | 7 | 2 | image, scale |
| Web模块 | 11 | 0 | 全部移除 |
| 插件模块 | 8 | 0 | 全部移除 |

---

## 四、代码量对比

### 4.1 文件数量对比

| 类别 | 原版文件数 | 精简版文件数 | 减少比例 |
|-----|-----------|-------------|---------|
| 桌面端页面 | 16 | 3 | 81% ↓ |
| 桌面端屏幕 | 5 | 1 | 80% ↓ |
| 桌面端组件 | 12 | 2 | 83% ↓ |
| 移动端页面 | 9 | 3 | 67% ↓ |
| 移动端组件 | 5 | 2 | 60% ↓ |
| 共享组件 | 20 | 8 | 60% ↓ |
| 数据模型 | 19 | 7 | 63% ↓ |
| 原生模块 | 3 | 2 | 33% ↓ |
| 工具类 | 7 | 2 | 71% ↓ |
| Web模块 | 11 | 0 | 100% ↓ |
| 插件模块 | 8 | 0 | 100% ↓ |
| **总计** | **~100** | **~28** | **72% ↓** |

### 4.2 代码行数估算对比

| 模块 | 原版行数（估算） | 精简版行数（估算） | 减少比例 |
|-----|-----------------|-------------------|---------|
| 桌面端页面 | ~5,500 | ~1,200 | 78% ↓ |
| 移动端页面 | ~3,000 | ~800 | 73% ↓ |
| 共享组件 | ~4,000 | ~1,000 | 75% ↓ |
| 数据模型 | ~8,000 | ~2,500 | 69% ↓ |
| 其他模块 | ~3,000 | ~500 | 83% ↓ |
| **总计** | **~23,500** | **~5,500** | **77% ↓** |

---

## 五、功能对比表

### 5.1 桌面端功能对比

| 功能 | 原版 | 精简版 | 说明 |
|-----|-----|-------|-----|
| 输入设备ID连接 | ✅ | ✅ | 核心功能保留 |
| 自动补全设备ID | ✅ | ✅ | 核心功能保留 |
| 连接按钮 | ✅ | ✅ | 核心功能保留 |
| 多连接类型菜单 | ✅ | ❌ | 移除文件传输/摄像头/终端选项 |
| 设备列表标签页 | ✅ | ❌ | 移除最近/收藏/发现/地址簿/群组 |
| 设备搜索 | ✅ | ❌ | 移除 |
| 设备卡片显示 | ✅ | ❌ | 移除 |
| 远程桌面显示 | ✅ | ✅ | 核心功能保留 |
| 多显示器切换 | ✅ | ❌ | 简化为单显示器 |
| 画面缩放模式 | ✅ | ✅ | 保留基本缩放 |
| 画面质量切换 | ✅ | ✅ | 保留基本质量选项 |
| 光标显示 | ✅ | ✅ | 核心功能保留 |
| 键盘输入 | ✅ | ✅ | 核心功能保留 |
| 鼠标输入 | ✅ | ✅ | 核心功能保留 |
| 触摸输入 | ✅ | ✅ | 核心功能保留 |
| 快捷键映射 | ✅ | ❌ | 移除 |
| 文件传输 | ✅ | ❌ | 移除 |
| 端口转发 | ✅ | ❌ | 移除 |
| 终端功能 | ✅ | ❌ | 移除 |
| 摄像头查看 | ✅ | ❌ | 移除 |
| 聊天功能 | ✅ | ❌ | 移除 |
| 语音通话 | ✅ | ❌ | 移除 |
| 多标签页 | ✅ | ❌ | 简化为单窗口单连接 |
| 设置页面 | ✅ | ❌ | 移除，使用默认配置 |
| 服务器模式 | ✅ | ❌ | 精简版仅做控制端 |
| 地址簿同步 | ✅ | ❌ | 移除 |
| 用户登录 | ✅ | ❌ | 移除 |

### 5.2 移动端功能对比

| 功能 | 原版 | 精简版 | 说明 |
|-----|-----|-------|-----|
| 输入设备ID连接 | ✅ | ✅ | 核心功能保留 |
| 扫码连接 | ✅ | ❌ | 移除 |
| 远程桌面显示 | ✅ | ✅ | 核心功能保留 |
| 手势控制 | ✅ | ✅ | 核心功能保留 |
| 触摸模式切换 | ✅ | ✅ | 核心功能保留 |
| 虚拟鼠标 | ✅ | ✅ | 核心功能保留 |
| 软键盘输入 | ✅ | ✅ | 核心功能保留 |
| 键盘帮助工具 | ✅ | ✅ | 核心功能保留 |
| 画面缩放 | ✅ | ✅ | 保留基本缩放 |
| 画面质量切换 | ✅ | ✅ | 保留基本质量选项 |
| 聊天功能 | ✅ | ❌ | 移除 |
| 语音通话 | ✅ | ❌ | 移除 |
| 文件传输 | ✅ | ❌ | 移除 |
| 终端功能 | ✅ | ❌ | 移除 |
| 摄像头查看 | ✅ | ❌ | 移除 |
| 服务器模式 | ✅ | ❌ | 精简版仅做控制端 |
| 设置页面 | ✅ | ❌ | 移除，使用默认配置 |
| 底部导航多页面 | ✅ | ✅ | 简化为连接页+远程页 |

---

## 六、实施步骤

### 6.1 第一阶段：移除非核心模块

1. **移除 Web 模块** (`flutter/lib/web/`)
   - 删除整个 web 目录
   - 清理 main.dart 中的 web 相关导入

2. **移除插件系统** (`flutter/lib/plugin/`)
   - 删除整个 plugin 目录
   - 清理 model.dart 中的插件相关代码

3. **移除地址簿和群组**
   - 删除 `common/widgets/address_book.dart`
   - 删除 `common/widgets/my_group.dart`
   - 删除 `common/widgets/peer_tab_page.dart`
   - 删除 `common/widgets/peers_view.dart`
   - 删除 `models/ab_model.dart`
   - 删除 `models/group_model.dart`
   - 删除 `models/peer_tab_model.dart`
   - 删除 `models/user_model.dart`

### 6.2 第二阶段：移除独立功能页面

1. **移除文件传输**
   - 删除 `desktop/pages/file_manager_page.dart`
   - 删除 `desktop/pages/file_manager_tab_page.dart`
   - 删除 `desktop/screen/desktop_file_transfer_screen.dart`
   - 删除 `mobile/pages/file_manager_page.dart`
   - 删除 `models/file_model.dart`
   - 删除 `models/cm_file_model.dart`

2. **移除端口转发**
   - 删除 `desktop/pages/port_forward_page.dart`
   - 删除 `desktop/pages/port_forward_tab_page.dart`
   - 删除 `desktop/screen/desktop_port_forward_screen.dart`

3. **移除终端功能**
   - 删除 `desktop/pages/terminal_page.dart`
   - 删除 `desktop/pages/terminal_tab_page.dart`
   - 删除 `desktop/pages/terminal_connection_manager.dart`
   - 删除 `desktop/screen/desktop_terminal_screen.dart`
   - 删除 `mobile/pages/terminal_page.dart`
   - 删除 `models/terminal_model.dart`

4. **移除摄像头查看**
   - 删除 `desktop/pages/view_camera_page.dart`
   - 删除 `desktop/pages/view_camera_tab_page.dart`
   - 删除 `desktop/screen/desktop_view_camera_screen.dart`
   - 删除 `mobile/pages/view_camera_page.dart`

5. **移除服务器模式**
   - 删除 `desktop/pages/server_page.dart`
   - 删除 `mobile/pages/server_page.dart`
   - 删除 `models/server_model.dart`

### 6.3 第三阶段：移除聊天和设置

1. **移除聊天功能**
   - 删除 `common/widgets/chat_page.dart`
   - 删除 `models/chat_model.dart`

2. **移除设置页面**
   - 删除 `desktop/pages/desktop_setting_page.dart`
   - 删除 `mobile/pages/settings_page.dart`
   - 删除 `common/widgets/setting_widgets.dart`

3. **移除扫码功能**
   - 删除 `mobile/pages/scan_page.dart`

### 6.4 第四阶段：简化核心页面

1. **简化 connection_page.dart**
   - 移除 PeerTabPage（设备列表标签页）
   - 移除连接类型菜单（文件传输/摄像头/终端）
   - 保留：ID输入框、连接按钮、连接状态显示

2. **简化 remote_page.dart**
   - 移除多显示器切换
   - 简化工具栏（移除聊天、录制等按钮）
   - 保留：画面显示、输入处理、基本工具栏

3. **简化 peer_card.dart**
   - 移除右键菜单复杂选项
   - 简化为基本连接入口

4. **简化 toolbar.dart**
   - 移除聊天、录制、文件传输等选项
   - 保留：画面缩放、质量切换、断开连接

### 6.5 第五阶段：清理依赖

1. **清理 pubspec.yaml**
   - 移除不必要的依赖包：
     - `flutter_breadcrumb`（面包屑导航）
     - `percent_indicator`（进度条）
     - `desktop_drop`（拖放）
     - `pull_down_button`（下拉按钮）
     - `xterm`（终端）
     - `flutter_keyboard_visibility`（可选保留）

2. **清理 common.dart**
   - 移除地址簿、群组相关函数
   - 移除聊天、文件传输相关函数

3. **清理 consts.dart**
   - 移除非核心常量定义

---

## 七、精简版核心代码示例

### 7.1 简化的 ConnectionPage 结构

```dart
class SimplifiedConnectionPage extends StatefulWidget {
  @override
  State<SimplifiedConnectionPage> createState() => _ConnectionPageState();
}

class _ConnectionPageState extends State<SimplifiedConnectionPage> {
  final _idController = TextEditingController();
  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ID 输入框
        TextField(
          controller: _idController,
          decoration: InputDecoration(hintText: 'Enter Remote ID'),
        ),
        // 连接按钮
        ElevatedButton(
          onPressed: () => _connect(),
          child: Text('Connect'),
        ),
        // 连接状态显示
        OnlineStatusWidget(),
      ],
    );
  }
  
  void _connect() {
    final id = _idController.text.trim();
    if (id.isNotEmpty) {
      connect(context, id);
    }
  }
}
```

### 7.2 简化的 RemotePage 结构

```dart
class SimplifiedRemotePage extends StatefulWidget {
  final String id;
  final String? password;
  
  @override
  State<SimplifiedRemotePage> createState() => _RemotePageState();
}

class _RemotePageState extends State<SimplifiedRemotePage> {
  late FFI _ffi;
  
  @override
  void initState() {
    super.initState();
    _ffi = FFI(null);
    _ffi.start(widget.id, password: widget.password);
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 远程画面
          ImagePaint(ffi: _ffi.ffiModel),
          // 光标显示
          CursorPaint(id: widget.id),
          // 简化工具栏
          SimplifiedToolbar(ffi: _ffi),
          // 连接状态覆盖层
          ConnectionStatusOverlay(ffi: _ffi),
        ],
      ),
    );
  }
}
```

### 7.3 简化的 Toolbar 结构

```dart
class SimplifiedToolbar extends StatelessWidget {
  final FFI ffi;
  
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // 断开连接
        IconButton(
          icon: Icon(Icons.close),
          onPressed: () => clientClose(ffi.sessionId, ffi),
        ),
        // 画面缩放
        IconButton(
          icon: Icon(Icons.zoom_out),
          onPressed: () => ffi.canvasModel.zoomOut(),
        ),
        IconButton(
          icon: Icon(Icons.zoom_in),
          onPressed: () => ffi.canvasModel.zoomIn(),
        ),
        // 画面质量
        PopupMenuButton(
          itemBuilder: (context) => [
            PopupMenuItem(value: 'best', child: Text('Best Quality')),
            PopupMenuItem(value: 'balanced', child: Text('Balanced')),
            PopupMenuItem(value: 'low', child: Text('Low Quality')),
          ],
          onSelected: (value) => ffi.setQuality(value),
        ),
      ],
    );
  }
}
```

---

## 八、风险评估与建议

### 8.1 潜在风险

| 风险 | 影响 | 建议 |
|-----|-----|-----|
| 依赖关系复杂 | 移除模块可能导致编译错误 | 分阶段移除，逐步测试 |
| 功能耦合 | 某些功能可能相互依赖 | 仔细分析依赖关系 |
| 用户习惯改变 | 精简版功能减少 | 明确产品定位，面向特定用户群 |
| 维护成本 | 精简版与原版分叉维护 | 考虑使用条件编译或配置开关 |

### 8.2 建议

1. **渐进式精简**：按阶段逐步移除功能，每个阶段完成后进行测试
2. **保留配置开关**：使用条件编译或配置文件，便于切换精简版和完整版
3. **独立分支开发**：建议在独立分支开发精简版，避免影响主分支
4. **文档同步更新**：同步更新开发文档和用户文档
5. **用户反馈收集**：发布后收集用户反馈，评估精简效果

---

## 九、总结

本技术方案通过系统分析 RustDesk Flutter UI 的当前架构，识别核心功能和可移除功能，设计了一套精简版架构方案：

- **文件数量减少约 72%**（从 ~100 个减少到 ~28 个）
- **代码行数减少约 77%**（从 ~23,500 行减少到 ~5,500 行）
- **保留核心功能**：设备连接、远程控制界面、基本连接状态显示
- **移除非核心功能**：地址簿、文件传输、端口转发、终端、摄像头、聊天、服务器模式、设置页面、多标签页、用户系统、插件系统、Web端

精简版适合以下场景：
- 嵌入式设备或低资源环境
- 仅需要基本远程控制功能的用户
- 快速原型开发或测试
- 特定行业定制需求

建议采用渐进式实施策略，分五个阶段逐步完成精简工作，每个阶段完成后进行充分测试，确保功能稳定。