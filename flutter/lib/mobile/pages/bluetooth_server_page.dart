import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:uuid/uuid.dart';
import 'package:ble_peripheral_plus/ble_peripheral_plus.dart';
import '../../common.dart';
import '../../platform/wifi_manager.dart';

// BLE UUIDs
const String SERVICE_UUID = "0000ffe0-0000-1000-8000-00805f9b34fb";
const String WIFI_CONFIG_CHAR_UUID = "0000ffe1-0000-1000-8000-00805f9b34fb";
const String STATUS_NOTIFY_CHAR_UUID = "0000ffe2-0000-1000-8000-00805f9b34fb";
const String DEVICE_INFO_CHAR_UUID = "0000ffe3-0000-1000-8000-00805f9b34fb";

// Device name for BLE advertising
const String DEVICE_NAME = "W3";

// Status codes
const String STATUS_IDLE = "idle";
const String STATUS_CONNECTING_WIFI = "connecting_wifi";
const String STATUS_WIFI_CONNECTED = "wifi_connected";
const String STATUS_GETTING_IP = "getting_ip";
const String STATUS_READY = "ready";
const String STATUS_WIFI_FAILED = "wifi_failed";
const String STATUS_WIFI_TIMEOUT = "wifi_timeout";
const String STATUS_BLUETOOTH_ERROR = "bluetooth_error";

// Error codes
const String ERROR_WIFI_PASSWORD = "E001";
const String ERROR_WIFI_NOT_FOUND = "E002";
const String ERROR_WIFI_SIGNAL_WEAK = "E003";
const String ERROR_TIMEOUT = "E004";
const String ERROR_PERMISSION = "E005";
const String ERROR_BLUETOOTH_DISCONNECT = "E006";
const String ERROR_UNKNOWN = "E007";

class BluetoothServerPage extends StatefulWidget {
  const BluetoothServerPage({Key? key}) : super(key: key);

  @override
  State<BluetoothServerPage> createState() => _BluetoothServerPageState();
}

class _BluetoothServerPageState extends State<BluetoothServerPage> {
  final NetworkInfo _networkInfo = NetworkInfo();
  final WifiManager _wifiManager = WifiManager();
  final Uuid _uuid = Uuid();

  // BLE Peripheral state
  bool _isAdvertising = false;
  bool _isConnected = false;
  BlePeripheral? _peripheral;
  BleCharacteristic? _wifiConfigCharacteristic;
  BleCharacteristic? _statusCharacteristic;
  BleCharacteristic? _deviceInfoCharacteristic;

  String _currentStatus = STATUS_IDLE;
  String _statusMessage = "等待配置...";
  int _progress = 0;
  String _localIp = "";
  String _currentWifi = "";
  String _errorMessage = "";
  String _currentRequestId = "";

  Timer? _connectionTimer;
  StreamSubscription? _connectionSubscription;
  StreamSubscription? _writeSubscription;

  @override
  void initState() {
    super.initState();
    _getDeviceInfo();
    _startBluetoothServer();
  }

  Future<void> _getDeviceInfo() async {
    try {
      final ip = await _networkInfo.getWifiIP();
      final wifiName = await _networkInfo.getWifiName();
      if (mounted) {
        setState(() {
          _localIp = ip ?? "";
          _currentWifi = wifiName ?? "";
        });
      }
    } catch (e) {
      debugPrint('Failed to get device info: $e');
    }
  }

  Future<void> _startBluetoothServer() async {
    try {
      // Initialize BLE peripheral
      _peripheral = BlePeripheral();

      // Check if BLE is available
      final isSupported = await _peripheral!.isSupported();
      if (!isSupported) {
        _showError("蓝牙不支持", "此设备不支持BLE Peripheral模式");
        return;
      }

      // Check permissions
      final hasPermissions = await _peripheral!.hasPermissions();
      if (!hasPermissions) {
        await _peripheral!.requestPermissions();
      }

      // Create GATT service and characteristics
      await _createGattServer();

      // Start advertising
      await _peripheral!.startAdvertising(
        AdvertisingData(
          localName: DEVICE_NAME,
          serviceUuids: [SERVICE_UUID],
        ),
      );

      setState(() {
        _isAdvertising = true;
        _statusMessage = "蓝牙广播已开启（名称: W3），等待连接...";
      });

      // Listen for connection state changes
      _connectionSubscription = _peripheral!.connectionState.listen((state) {
        setState(() {
          _isConnected = state == PeripheralConnectionState.connected;
          if (_isConnected) {
            _statusMessage = "设备已连接";
            _currentStatus = STATUS_IDLE;
          } else {
            _statusMessage = "等待连接...";
            _currentStatus = STATUS_IDLE;
            _progress = 0;
            _errorMessage = "";
            _cancelTimers();
          }
        });
      });

    } catch (e) {
      _showError("蓝牙服务启动失败", "无法启动BLE服务: $e");
    }
  }

  Future<void> _createGattServer() async {
    if (_peripheral == null) return;

    // Create characteristics
    _wifiConfigCharacteristic = BleCharacteristic(
      uuid: WIFI_CONFIG_CHAR_UUID,
      properties: CharacteristicProperties(
        write: true,
        writeWithoutResponse: true,
      ),
      permissions: CharacteristicPermissions(
        write: true,
      ),
    );

    _statusCharacteristic = BleCharacteristic(
      uuid: STATUS_NOTIFY_CHAR_UUID,
      properties: CharacteristicProperties(
        notify: true,
      ),
      permissions: CharacteristicPermissions(
        read: true,
      ),
    );

    _deviceInfoCharacteristic = BleCharacteristic(
      uuid: DEVICE_INFO_CHAR_UUID,
      properties: CharacteristicProperties(
        read: true,
      ),
      permissions: CharacteristicPermissions(
        read: true,
      ),
      value: Uint8List.fromList(utf8.encode(_getDeviceInfoJson())),
    );

    // Add service with characteristics
    await _peripheral!.addService(
      BleService(
        uuid: SERVICE_UUID,
        characteristics: [
          _wifiConfigCharacteristic!,
          _statusCharacteristic!,
          _deviceInfoCharacteristic!,
        ],
      ),
    );

    // Listen for write events on WiFi config characteristic
    _writeSubscription = _peripheral!.onCharacteristicWrite.listen((event) {
      if (event.characteristicUuid == WIFI_CONFIG_CHAR_UUID) {
        _handleWifiConfigRequest(event.value);
      }
    });
  }

  String _getDeviceInfoJson() {
    return jsonEncode({
      'device_name': DEVICE_NAME,
      'current_wifi': _currentWifi,
      'current_ip': _localIp,
    });
  }

  void _handleWifiConfigRequest(Uint8List value) {
    try {
      final jsonStr = utf8.decode(value);
      final request = jsonDecode(jsonStr) as Map<String, dynamic>;
      
      final requestId = request['request_id'] as String? ?? _uuid.v4();
      final ssid = request['ssid'] as String?;
      final password = request['password'] as String?;
      final forceReconnect = request['force_reconnect'] as bool? ?? true;

      if (ssid == null || password == null) {
        _sendErrorResponse(requestId, ERROR_UNKNOWN, "缺少WiFi配置信息");
        return;
      }

      _currentRequestId = requestId;
      _cancelTimers();
      _startConnectionTimeout();

      _processWifiConfig(ssid, password, forceReconnect, requestId);

    } catch (e) {
      debugPrint('Failed to parse WiFi config request: $e');
    }
  }

  Future<void> _processWifiConfig(String ssid, String password, bool forceReconnect, String requestId) async {
    try {
      _updateStatus(STATUS_CONNECTING_WIFI, "正在连接WiFi: $ssid", 20);

      if (forceReconnect) {
        await _wifiManager.disconnectWifi();
        await Future.delayed(const Duration(milliseconds: 500));
      }

      final connectResult = await _wifiManager.connectWifi(ssid, password);

      if (!connectResult.success) {
        _cancelTimers();
        _sendErrorResponse(requestId, connectResult.errorCode, connectResult.errorMessage);
        return;
      }

      _updateStatus(STATUS_WIFI_CONNECTED, "WiFi连接成功", 50);
      _updateStatus(STATUS_GETTING_IP, "正在获取IP地址...", 70);

      await Future.delayed(const Duration(seconds: 3));
      final ip = await _networkInfo.getWifiIP();

      if (ip == null || ip.isEmpty) {
        _cancelTimers();
        _sendErrorResponse(requestId, ERROR_TIMEOUT, "获取IP地址超时");
        return;
      }

      _cancelTimers();
      _updateStatus(STATUS_READY, "准备就绪", 100);
      _sendConnectionReadyResponse(requestId, ip, ssid);

      setState(() {
        _localIp = ip;
        _currentWifi = ssid;
      });

    } catch (e) {
      _cancelTimers();
      _sendErrorResponse(requestId, ERROR_UNKNOWN, "连接失败: $e");
    }
  }

  void _updateStatus(String status, String message, int progress) {
    setState(() {
      _currentStatus = status;
      _statusMessage = message;
      _progress = progress;
    });
    _sendStatusUpdate(status, message, progress);
  }

  Future<void> _sendStatusUpdate(String status, String message, int progress) async {
    final data = {
      'type': 'status_update',
      'request_id': _currentRequestId,
      'status': status,
      'message': message,
      'progress': progress,
    };
    await _sendDataToClient(data);
  }

  Future<void> _sendConnectionReadyResponse(String requestId, String ip, String ssid) async {
    final data = {
      'type': 'connection_ready',
      'request_id': requestId,
      'ip': ip,
      'port': 21116,
      'password': 'A123456a',
      'ssid': ssid,
    };
    await _sendDataToClient(data);
  }

  Future<void> _sendErrorResponse(String requestId, String errorCode, String errorMessage) async {
    setState(() {
      _currentStatus = STATUS_WIFI_FAILED;
      _errorMessage = errorMessage;
      _progress = 0;
    });

    final retrySuggestion = _getRetrySuggestion(errorCode);

    final data = {
      'type': 'connection_failed',
      'request_id': requestId,
      'error_code': errorCode,
      'error_message': errorMessage,
      'retry_suggestion': retrySuggestion,
    };

    await _sendDataToClient(data);
  }

  String _getRetrySuggestion(String errorCode) {
    switch (errorCode) {
      case ERROR_WIFI_PASSWORD:
        return "请重新输入WiFi密码";
      case ERROR_WIFI_NOT_FOUND:
        return "请检查WiFi名称是否正确";
      case ERROR_WIFI_SIGNAL_WEAK:
        return "请靠近WiFi热点或检查信号";
      case ERROR_TIMEOUT:
        return "请靠近设备或检查WiFi";
      case ERROR_PERMISSION:
        return "请在设置中授予WiFi权限";
      case ERROR_BLUETOOTH_DISCONNECT:
        return "请重新建立蓝牙连接";
      default:
        return "请重试或检查设备状态";
    }
  }

  Future<void> _sendDataToClient(Map<String, dynamic> data) async {
    try {
      if (_statusCharacteristic == null) return;

      final jsonData = jsonEncode(data);
      final bytes = Uint8List.fromList(utf8.encode(jsonData));

      await _peripheral!.updateCharacteristicValue(
        SERVICE_UUID,
        STATUS_NOTIFY_CHAR_UUID,
        bytes,
      );

      debugPrint("Sent data to client: $jsonData");
    } catch (e) {
      debugPrint('Failed to send data to client: $e');
    }
  }

  void _startConnectionTimeout() {
    _connectionTimer = Timer(const Duration(seconds: 30), () {
      if (_currentStatus != STATUS_READY) {
        _sendErrorResponse(_currentRequestId, ERROR_TIMEOUT, "WiFi连接超时");
      }
    });
  }

  void _cancelTimers() {
    _connectionTimer?.cancel();
    _connectionTimer = null;
  }

  void _showError(String title, String message) {
    setState(() {
      _statusMessage = message;
      _currentStatus = STATUS_BLUETOOTH_ERROR;
    });

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            child: const Text('确定'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _cancelTimers();
    _connectionSubscription?.cancel();
    _writeSubscription?.cancel();
    
    if (_isAdvertising && _peripheral != null) {
      _peripheral!.stopAdvertising();
    }
    
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('设备信息 (W3)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _getDeviceInfo,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildBluetoothStatusCard(),
            const SizedBox(height: 16),
            _buildDeviceInfoCard(),
            const SizedBox(height: 16),
            if (_currentStatus != STATUS_IDLE) _buildProgressCard(),
            const SizedBox(height: 16),
            if (_localIp.isNotEmpty) _buildQuickConnectCard(),
            const SizedBox(height: 16),
            _buildInstructionsCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildBluetoothStatusCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  _isAdvertising ? Icons.bluetooth_searching : Icons.bluetooth_disabled,
                  color: _isAdvertising ? Colors.blue : Colors.grey,
                ),
                const SizedBox(width: 8),
                const Text(
                  '蓝牙状态',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.device_hub),
              title: const Text('设备名称'),
              subtitle: Text(DEVICE_NAME),
            ),
            const Divider(),
            ListTile(
              leading: Icon(
                _isConnected ? Icons.link : Icons.link_off,
                color: _isConnected ? Colors.green : Colors.grey,
              ),
              title: const Text('连接状态'),
              subtitle: Text(_isConnected ? '已连接' : '等待连接'),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.info),
              title: const Text('状态信息'),
              subtitle: Text(_statusMessage),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeviceInfoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              '设备信息',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.wifi),
              title: const Text('当前WiFi'),
              subtitle: Text(_currentWifi.isEmpty ? '未连接' : _currentWifi),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.network_check),
              title: const Text('本地IP'),
              subtitle: Text(_localIp.isEmpty ? '未知' : _localIp),
              trailing: IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _getDeviceInfo,
              ),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.lock),
              title: const Text('连接密码'),
              subtitle: const Text('A123456a'),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.settings_input_component),
              title: const Text('端口'),
              subtitle: const Text('21116'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  _currentStatus == STATUS_WIFI_FAILED ? Icons.error : Icons.sync,
                  color: _currentStatus == STATUS_WIFI_FAILED ? Colors.red : Colors.blue,
                ),
                const SizedBox(width: 8),
                const Text(
                  '配网进度',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: _progress / 100,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(
                _currentStatus == STATUS_WIFI_FAILED ? Colors.red : Colors.blue,
              ),
            ),
            const SizedBox(height: 8),
            Text(_statusMessage),
            if (_errorMessage.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  _errorMessage,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickConnectCard() {
    return Card(
      color: Colors.green.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              '快速连接信息',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green),
            ),
            const SizedBox(height: 16),
            Text(
              '${_localIp}:21116',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              '在另一台设备上输入此IP地址，使用密码 "A123456a" 连接',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructionsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              '使用说明',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text('1. 本设备已开启蓝牙广播（名称: W3）'),
            const Text('2. 在另一台设备上打开蓝牙配网功能'),
            const Text('3. 扫描并选择设备 W3'),
            const Text('4. 选择WiFi网络并输入密码'),
            const Text('5. 等待配网完成'),
            const Text('6. 使用显示的IP地址进行远程连接'),
          ],
        ),
      ),
    );
  }
}