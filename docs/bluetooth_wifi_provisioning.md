# 蓝牙WiFi配网技术方案

## 一、需求概述

实现通过蓝牙进行WiFi配网的功能，使设备B（控制端）可以为设备A（被控端）配置WiFi网络，并在配网成功后自动建立远程控制连接。

### 核心功能
- 设备A：启动蓝牙服务（名称：W3），接收WiFi配置，连接WiFi，回传IP地址
- 设备B：扫描蓝牙设备，发送WiFi配置，接收IP地址，发起远程连接
- 强制重连：即使设备A已连接WiFi，也要强制重新连接
- 错误处理：连接失败时，设备B弹窗显示失败原因

---

## 二、完整流程图

```
设备A（被控端）                                    设备B（控制端）
     │                                                  │
     │  1. APP启动                                      │
     │     ↓                                            │
     │  2. 检查蓝牙状态                                  │
     │     ↓                                            │
     │  3. 开启BLE广播（名称:W3）                        │  扫描蓝牙设备
     │     ↓                                            │     ↓
     │  4. 等待BLE连接                                  │  显示设备列表
     │     ↓                                            │     ↓
     │ ← BLE连接建立                                    │  选择设备W3
     │     ↓                                            │     ↓
     │ ← 接收WiFi配置                                   │  扫描WiFi列表
     │     {ssid, password, force_reconnect}            │     ↓
     │     ↓                                            │  选择WiFi+输入密码
     │  5. 断开当前WiFi（如果已连接）                    │     ↓
     │     ↓                                            │  发送配置到A
     │  6. 连接新WiFi                                   │
     │     ↓                                            │  等待状态更新
     │  7. 状态上报                                      │
     │     ├─ connecting_wifi（正在连接）                │  显示进度
     │     ├─ wifi_connected（成功）                     │     ↓
     │     │   + IP地址                                  │  收到IP → 发起远程连接
     │     ├─ wifi_failed（失败）                        │     ↓
     │     │   + 错误原因                                 │  弹窗显示错误
     │     └─ wifi_timeout（超时）                       │
     │                                                  │
```

---

## 三、状态定义

| 状态 | 说明 | 设备B显示 |
|------|------|----------|
| `idle` | 空闲，等待配置 | "等待配置..." |
| `connecting_wifi` | 正在连接WiFi | "正在连接WiFi..." |
| `wifi_connected` | WiFi连接成功 | "WiFi连接成功" |
| `getting_ip` | 正在获取IP | "正在获取IP地址..." |
| `ready` | 准备就绪，返回IP | 显示IP地址 |
| `wifi_failed` | WiFi连接失败 | 弹窗显示错误原因 |
| `wifi_timeout` | WiFi连接超时（30秒） | 弹窗提示超时 |
| `bluetooth_error` | 蓝牙通信错误 | 弹窗提示通信失败 |

---

## 四、错误码定义

| 错误码 | 错误原因 | 设备B弹窗内容 |
|--------|----------|--------------|
| `E001` | WiFi密码错误 | "WiFi密码错误，请重新输入" |
| `E002` | WiFi不存在 | "WiFi网络不存在" |
| `E003` | WiFi信号弱 | "WiFi信号太弱，无法连接" |
| `E004` | 连接超时 | "连接超时，请靠近设备或检查WiFi" |
| `E005` | 权限不足 | "设备缺少WiFi权限" |
| `E006` | 蓝牙断开 | "蓝牙连接已断开" |
| `E007` | 未知错误 | "连接失败：{详细错误信息}" |

---

## 五、数据协议

### 1. WiFi配置请求（B → A）
```json
{
  "type": "wifi_config",
  "ssid": "WiFi_SSID",
  "password": "WiFi密码",
  "force_reconnect": true,
  "request_id": "uuid-12345"
}
```

### 2. 状态更新（A → B）
```json
{
  "type": "status_update",
  "request_id": "uuid-12345",
  "status": "connecting_wifi",
  "message": "正在连接WiFi...",
  "progress": 30
}
```

### 3. 成功响应（A → B）
```json
{
  "type": "connection_ready",
  "request_id": "uuid-12345",
  "ip": "192.168.1.100",
  "port": 21116,
  "password": "A123456a",
  "ssid": "WiFi_SSID"
}
```

### 4. 失败响应（A → B）
```json
{
  "type": "connection_failed",
  "request_id": "uuid-12345",
  "error_code": "E001",
  "error_message": "WiFi密码错误",
  "retry_suggestion": "请重新输入WiFi密码"
}
```

### 5. 设备信息查询（B → A）
```json
{
  "type": "device_info_query"
}
```

### 6. 设备信息响应（A → B）
```json
{
  "type": "device_info",
  "current_wifi": "当前WiFi名称",
  "current_ip": "192.168.1.50",
  "is_connected": true,
  "battery_level": 80
}
```

---

## 六、BLE GATT Service 结构

| UUID | 类型 | 属性 | 功能 |
|------|------|------|------|
| `0000FFE0-0000-1000-8000-00805F9B34FB` | Service | - | WiFi配置服务 |
| `0000FFE1-0000-1000-8000-00805F9B34FB` | Characteristic | Write | 接收WiFi配置 |
| `0000FFE2-0000-1000-8000-00805F9B34FB` | Characteristic | Notify | 状态更新推送 |
| `0000FFE3-0000-1000-8000-00805F9B34FB` | Characteristic | Read | 设备信息查询 |
| `0000FFE4-0000-1000-8000-00805F9B34FB` | Descriptor | Read/Write | 客户端配置（CCCD） |

---

## 七、设备A核心逻辑

### 1. WiFi强制重连流程
```
收到WiFi配置请求
    │
    ↓
检查当前WiFi状态
    │
    ├─ 已连接同一WiFi → 断开 → 重新连接
    │
    ├─ 已连接其他WiFi → 断开 → 连接新WiFi
    │
    └─ 未连接 → 直接连接新WiFi
    │
    ↓
发送状态: connecting_wifi
    │
    ↓
尝试连接（最多30秒）
    │
    ├─ 成功 → 发送状态: wifi_connected
    │           ↓
    │         获取IP地址
    │           ↓
    │         发送状态: ready + IP
    │
    └─ 失败 → 发送状态: wifi_failed + 错误码
```

### 2. 超时处理
- WiFi连接超时：30秒
- IP获取超时：10秒
- 超时后发送 `wifi_timeout` 状态

### 3. 错误检测与上报
```dart
// WiFi连接错误检测
Future<bool> connectWifi(String ssid, String password) async {
  try {
    // 1. 断开当前WiFi
    await disconnectCurrentWifi();
    
    // 2. 连接新WiFi
    final result = await wifiManager.connect(ssid, password);
    
    if (!result.success) {
      // 根据错误类型生成错误码
      final errorCode = getErrorCode(result.error);
      sendErrorToClient(errorCode, result.error);
      return false;
    }
    
    return true;
  } catch (e) {
    sendErrorToClient('E007', e.toString());
    return false;
  }
}
```

---

## 八、设备B核心逻辑

### 1. 错误处理弹窗
```dart
void handleErrorResponse(Map<String, dynamic> response) {
  final errorCode = response['error_code'];
  final errorMessage = response['error_message'];
  final retrySuggestion = response['retry_suggestion'];
  
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('连接失败'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(errorMessage),
          const SizedBox(height: 8),
          Text(
            retrySuggestion,
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
      actions: [
        TextButton(
          child: const Text('重新配置'),
          onPressed: () {
            Navigator.pop(context);
            // 返回WiFi配置页面
          },
        ),
        TextButton(
          child: const Text('取消'),
          onPressed: () => Navigator.pop(context),
        ),
      ],
    ),
  );
}
```

### 2. 进度显示
```dart
Widget buildProgressIndicator(String status, int progress) {
  return Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      LinearProgressIndicator(value: progress / 100),
      const SizedBox(height: 8),
      Text(getStatusMessage(status)),
    ],
  );
}

String getStatusMessage(String status) {
  switch (status) {
    case 'connecting_wifi':
      return '正在连接WiFi...';
    case 'wifi_connected':
      return 'WiFi连接成功';
    case 'getting_ip':
      return '正在获取IP地址...';
    case 'ready':
      return '准备就绪';
    default:
      return '处理中...';
  }
}
```

### 3. WiFi扫描与选择
```dart
Future<void> scanWifiNetworks() async {
  final wifiList = await wifiScanManager.getAvailableWifiList();
  setState(() {
    _wifiNetworks = wifiList;
  });
}

Widget buildWifiList() {
  return ListView.builder(
    itemCount: _wifiNetworks.length,
    itemBuilder: (context, index) {
      final wifi = _wifiNetworks[index];
      return ListTile(
        leading: Icon(Icons.wifi, color: getSignalColor(wifi.signalStrength)),
        title: Text(wifi.ssid),
        subtitle: Text('信号强度: ${wifi.signalStrength}%'),
        onTap: () => selectWifi(wifi.ssid),
      );
    },
  );
}
```

---

## 九、Android权限配置

### AndroidManifest.xml
```xml
<!-- 蓝牙权限 -->
<uses-permission android:name="android.permission.BLUETOOTH" />
<uses-permission android:name="android.permission.BLUETOOTH_ADMIN" />
<uses-permission android:name="android.permission.BLUETOOTH_SCAN" />
<uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />
<uses-permission android:name="android.permission.BLUETOOTH_ADVERTISE" />

<!-- WiFi权限 -->
<uses-permission android:name="android.permission.ACCESS_WIFI_STATE" />
<uses-permission android:name="android.permission.CHANGE_WIFI_STATE" />
<uses-permission android:name="android.permission.CHANGE_NETWORK_STATE" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />

<!-- 定位权限（WiFi扫描需要） -->
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />

<!-- 蓝牙硬件特性 -->
<uses-feature android:name="android.hardware.bluetooth_le" android:required="true" />
```

---

## 十、Flutter依赖配置

### pubspec.yaml
```yaml
dependencies:
  flutter_blue_plus: ^1.32.11
  wifi_scan: ^0.4.1+2
  network_info_plus: ^4.1.0
  permission_handler: ^11.3.0
```

---

## 十一、需要修改/新增的文件

| 文件路径 | 修改内容 |
|----------|---------|
| `flutter/lib/mobile/pages/bluetooth_server_page.dart` | BLE服务端完整实现 |
| `flutter/lib/mobile/pages/bluetooth_provisioning_page.dart` | BLE客户端+WiFi扫描+错误处理 |
| `flutter/lib/mobile/pages/home_page.dart` | 蓝牙服务自动启动 |
| `flutter/lib/mobile/pages/server_page.dart` | 入口按钮优化 |
| `flutter/lib/models/server_model.dart` | 保持固定密码设置 |
| `flutter/pubspec.yaml` | 添加蓝牙依赖 |
| `flutter/android/app/src/main/AndroidManifest.xml` | 添加权限 |
| `flutter/lib/platform/wifi_manager.dart` | 新增WiFi管理原生通道 |
| `flutter/android/app/src/main/kotlin/.../WifiManager.kt` | Android原生WiFi管理 |

---

## 十二、关键技术点

### 1. WiFi强制重连
使用Android原生API实现：
```kotlin
// Kotlin代码
fun forceReconnectWifi(ssid: String, password: String): Boolean {
    val wifiManager = context.getSystemService(Context.WIFI_SERVICE) as WifiManager
    
    // 1. 断开当前网络
    wifiManager.disconnect()
    
    // 2. 移除所有已配置的网络
    val configuredNetworks = wifiManager.configuredNetworks
    configuredNetworks.forEach { network ->
        wifiManager.removeNetwork(network.networkId)
    }
    
    // 3. 添加新网络配置
    val wifiConfig = WifiConfiguration()
    wifiConfig.SSID = "\"$ssid\""
    wifiConfig.preSharedKey = "\"$password\""
    
    val networkId = wifiManager.addNetwork(wifiConfig)
    wifiManager.enableNetwork(networkId, true)
    wifiManager.reconnect()
    
    return true
}
```

### 2. BLE状态通知
使用Notify特性实时推送状态：
```dart
// 发送状态更新
Future<void> sendStatusUpdate(String requestId, String status, String message, int progress) async {
  final data = {
    'type': 'status_update',
    'request_id': requestId,
    'status': status,
    'message': message,
    'progress': progress,
  };
  
  final jsonData = jsonEncode(data);
  final bytes = utf8.encode(jsonData);
  
  await notifyCharacteristic!.write(bytes);
}
```

### 3. 超时机制
使用Timer实现超时检测：
```dart
Timer? _connectionTimer;

void startConnectionTimeout() {
  _connectionTimer = Timer(Duration(seconds: 30), () {
    if (_currentStatus != 'ready') {
      sendErrorToClient('E004', '连接超时');
    }
  });
}

void cancelConnectionTimeout() {
  _connectionTimer?.cancel();
  _connectionTimer = null;
}
```

### 4. 蓝牙断开检测
监听BLE连接状态变化：
```dart
device.connectionState.listen((state) {
  if (state == BluetoothDeviceState.disconnected) {
    // 蓝牙断开，通知用户
    if (_isWaitingForResponse) {
      showErrorDialog('E006', '蓝牙连接已断开');
    }
  }
});
```

---

## 十三、测试要点

### 1. 功能测试
- [ ] 设备A蓝牙广播是否正常开启（名称：W3）
- [ ] 设备B能否扫描到设备A
- [ ] WiFi配置是否正确发送和接收
- [ ] 强制重连功能是否正常
- [ ] IP地址是否正确回传
- [ ] 远程连接是否自动建立

### 2. 错误场景测试
- [ ] WiFi密码错误时的错误提示
- [ ] WiFi不存在时的错误提示
- [ ] WiFi信号弱时的错误提示
- [ ] 连接超时时的错误提示
- [ ] 蓝牙断开时的错误提示
- [ ] 权限不足时的错误提示

### 3. 性能测试
- [ ] WiFi连接时间（应在30秒内）
- [ ] IP获取时间（应在10秒内）
- [ ] 蓝牙通信延迟
- [ ] 多次配网稳定性

---

## 十四、注意事项

1. **Android 12+ 权限**：需要在运行时请求蓝牙和定位权限
2. **WiFi扫描限制**：Android对WiFi扫描有频率限制
3. **BLE数据包大小**：BLE单次传输最大20字节，大数据需要分包
4. **设备兼容性**：不同Android设备BLE实现可能有差异
5. **后台运行**：APP在后台时蓝牙服务可能被限制
6. **电池优化**：需要处理电池优化对蓝牙的影响

---

## 十五、后续优化方向

1. **安全性增强**：添加蓝牙通信加密
2. **多设备支持**：支持同时配置多个设备
3. **配网历史**：保存已配网的WiFi信息
4. **自动重连**：蓝牙断开后自动重连
5. **二维码配网**：支持二维码快速配网
6. **iOS支持**：适配iOS平台的蓝牙配网

---

**文档版本**：v1.0
**创建日期**：2026-06-09
**作者**：Trae AI Assistant