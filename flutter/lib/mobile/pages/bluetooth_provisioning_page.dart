import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:wifi_scan/wifi_scan.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:uuid/uuid.dart';
import '../../common.dart';
import 'home_page.dart';

// BLE UUIDs (same as server)
const String SERVICE_UUID = "0000ffe0-0000-1000-8000-00805f9b34fb";
const String WIFI_CONFIG_CHAR_UUID = "0000ffe1-0000-1000-8000-00805f9b34fb";
const String STATUS_NOTIFY_CHAR_UUID = "0000ffe2-0000-1000-8000-00805f9b34fb";
const String DEVICE_INFO_CHAR_UUID = "0000ffe3-0000-1000-8000-00805f9b34fb";

// Target device name
const String TARGET_DEVICE_NAME = "W3";

class BluetoothProvisioningPage extends StatefulWidget {
  const BluetoothProvisioningPage({Key? key}) : super(key: key);

  @override
  State<BluetoothProvisioningPage> createState() => _BluetoothProvisioningPageState();
}

class _BluetoothProvisioningPageState extends State<BluetoothProvisioningPage> {
  final Uuid _uuid = Uuid();

  // Bluetooth state
  bool _isScanning = false;
  bool _isConnected = false;
  BluetoothDevice? _connectedDevice;
  BluetoothCharacteristic? _wifiConfigCharacteristic;
  BluetoothCharacteristic? _statusCharacteristic;
  BluetoothCharacteristic? _deviceInfoCharacteristic;

  // Device list
  List<BluetoothDevice> _discoveredDevices = [];

  // WiFi list
  List<WiFiAccessPoint> _wifiNetworks = [];
  bool _isWifiScanning = false;

  // Selected WiFi
  String? _selectedWifiSsid;
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  // Connection state
  String _currentStatus = "idle";
  String _statusMessage = "准备扫描蓝牙设备";
  int _progress = 0;
  String _errorMessage = "";
  String _currentRequestId = "";

  // Received connection info
  String _receivedIp = "";
  int _receivedPort = 21116;
  String _receivedPassword = "A123456a";

  StreamSubscription? _scanSubscription;
  StreamSubscription? _statusSubscription;
  StreamSubscription? _connectionSubscription;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    // Check and request Bluetooth permissions
    final bluetoothScan = await Permission.bluetoothScan.request();
    final bluetoothConnect = await Permission.bluetoothConnect.request();
    final location = await Permission.locationWhenInUse.request();

    if (!bluetoothScan.isGranted || !bluetoothConnect.isGranted || !location.isGranted) {
      _showErrorDialog("权限不足", "需要蓝牙和定位权限才能使用此功能");
      return;
    }

    _startBluetoothScan();
  }

  Future<void> _startBluetoothScan() async {
    try {
      // Check if Bluetooth is available
      if (await FlutterBluePlus.isAvailable == false) {
        _showErrorDialog("蓝牙不可用", "此设备不支持蓝牙");
        return;
      }

      // Turn on Bluetooth if it's off
      if (await FlutterBluePlus.adapterState.first == BluetoothAdapterState.off) {
        await FlutterBluePlus.turnOn();
        await Future.delayed(const Duration(seconds: 1));
      }

      setState(() {
        _isScanning = true;
        _statusMessage = "正在扫描蓝牙设备...";
        _discoveredDevices.clear();
      });

      // Start scanning
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 10));

      // Listen for scan results
      _scanSubscription = FlutterBluePlus.scanResults.listen((results) {
        for (var result in results) {
          // Filter for target device
          if (result.device.localName == TARGET_DEVICE_NAME ||
              result.device.localName.contains("W3")) {
            if (!_discoveredDevices.contains(result.device)) {
              setState(() {
                _discoveredDevices.add(result.device);
              });
            }
          }
        }
      });

      // Wait for scan to complete
      await Future.delayed(const Duration(seconds: 10));

      setState(() {
        _isScanning = false;
        _statusMessage = _discoveredDevices.isEmpty
            ? "未找到设备 W3，请确保目标设备已开启蓝牙"
            : "找到 ${_discoveredDevices.length} 个设备";
      });

      await FlutterBluePlus.stopScan();

    } catch (e) {
      setState(() {
        _isScanning = false;
        _statusMessage = "扫描失败: $e";
      });
    }
  }

  Future<void> _connectToDevice(BluetoothDevice device) async {
    try {
      setState(() {
        _statusMessage = "正在连接设备...";
        _progress = 10;
      });

      // Connect to device
      await device.connect(timeout: const Duration(seconds: 10));

      setState(() {
        _isConnected = true;
        _connectedDevice = device;
        _statusMessage = "已连接到 ${device.localName}";
        _progress = 20;
      });

      // Listen for disconnection
      _connectionSubscription = device.connectionState.listen((state) {
        if (state == BluetoothDeviceState.disconnected) {
          setState(() {
            _isConnected = false;
            _connectedDevice = null;
            _currentStatus = "idle";
            _statusMessage = "设备已断开连接";
            _progress = 0;
          });
          _showErrorDialog("连接断开", "蓝牙连接已断开，请重新连接");
        }
      });

      // Discover services
      await device.discoverServices();

      // Find characteristics
      for (var service in device.services) {
        if (service.uuid.toString().toLowerCase() == SERVICE_UUID.toLowerCase()) {
          for (var characteristic in service.characteristics) {
            if (characteristic.uuid.toString().toLowerCase() == WIFI_CONFIG_CHAR_UUID.toLowerCase()) {
              _wifiConfigCharacteristic = characteristic;
            } else if (characteristic.uuid.toString().toLowerCase() == STATUS_NOTIFY_CHAR_UUID.toLowerCase()) {
              _statusCharacteristic = characteristic;
              // Enable notifications
              await characteristic.setNotifyValue(true);
              // Listen for status updates
              _statusSubscription = characteristic.value.listen(_handleStatusUpdate);
            } else if (characteristic.uuid.toString().toLowerCase() == DEVICE_INFO_CHAR_UUID.toLowerCase()) {
              _deviceInfoCharacteristic = characteristic;
            }
          }
        }
      }

      setState(() {
        _progress = 30;
        _statusMessage = "已连接，准备扫描WiFi";
      });

      // Start WiFi scan
      await _startWifiScan();

    } catch (e) {
      _showErrorDialog("连接失败", "无法连接到设备: $e");
      setState(() {
        _isConnected = false;
        _connectedDevice = null;
        _progress = 0;
      });
    }
  }

  Future<void> _startWifiScan() async {
    try {
      setState(() {
        _isWifiScanning = true;
        _statusMessage = "正在扫描WiFi网络...";
      });

      // Check if WiFi scan is supported
      final canScan = await WiFiScan.instance.canStartScanning();
      if (canScan != CanStartScanning.yes) {
        _showErrorDialog("WiFi扫描不可用", "无法扫描WiFi网络: $canScan");
        return;
      }

      // Start WiFi scan
      await WiFiScan.instance.startScanning();

      // Get scan results
      final results = await WiFiScan.instance.getScannedResults();
      
      setState(() {
        _wifiNetworks = results;
        _isWifiScanning = false;
        _statusMessage = "找到 ${results.length} 个WiFi网络";
        _progress = 40;
      });

    } catch (e) {
      setState(() {
        _isWifiScanning = false;
        _statusMessage = "WiFi扫描失败: $e";
      });
      _showErrorDialog("WiFi扫描失败", "无法扫描WiFi网络: $e");
    }
  }

  void _handleStatusUpdate(List<int> data) {
    try {
      final jsonStr = utf8.decode(data);
      final response = jsonDecode(jsonStr) as Map<String, dynamic>;

      final type = response['type'] as String?;
      final requestId = response['request_id'] as String?;

      if (requestId != _currentRequestId) return;

      switch (type) {
        case 'status_update':
          final status = response['status'] as String?;
          final message = response['message'] as String?;
          final progress = response['progress'] as int?;
          
          setState(() {
            _currentStatus = status ?? "";
            _statusMessage = message ?? "";
            _progress = progress ?? 0;
          });
          break;

        case 'connection_ready':
          final ip = response['ip'] as String?;
          final port = response['port'] as int?;
          final password = response['password'] as String?;
          final ssid = response['ssid'] as String?;

          setState(() {
            _currentStatus = "ready";
            _statusMessage = "配网成功！";
            _progress = 100;
            _receivedIp = ip ?? "";
            _receivedPort = port ?? 21116;
            _receivedPassword = password ?? "A123456a";
          });

          // Show success dialog and connect
          _showSuccessAndConnect();
          break;

        case 'connection_failed':
          final errorCode = response['error_code'] as String?;
          final errorMessage = response['error_message'] as String?;
          final retrySuggestion = response['retry_suggestion'] as String?;

          setState(() {
            _currentStatus = "failed";
            _errorMessage = errorMessage ?? "";
            _progress = 0;
          });

          _showErrorDialog(
            "配网失败 ($errorCode)",
            "${errorMessage ?? '未知错误'}\n\n${retrySuggestion ?? '请重试'}",
          );
          break;
      }
    } catch (e) {
      debugPrint('Failed to parse status update: $e');
    }
  }

  Future<void> _sendWifiConfig() async {
    if (!_formKey.currentState!.validate()) return;
    if (_wifiConfigCharacteristic == null) {
      _showErrorDialog("错误", "蓝牙连接未建立");
      return;
    }

    _currentRequestId = _uuid.v4();

    final config = {
      'type': 'wifi_config',
      'request_id': _currentRequestId,
      'ssid': _selectedWifiSsid!,
      'password': _passwordController.text,
      'force_reconnect': true,
    };

    try {
      setState(() {
        _currentStatus = "connecting_wifi";
        _statusMessage = "正在发送WiFi配置...";
        _progress = 50;
      });

      final jsonData = jsonEncode(config);
      final bytes = Uint8List.fromList(utf8.encode(jsonData));

      // Send WiFi config
      await _wifiConfigCharacteristic!.write(bytes);

      setState(() {
        _statusMessage = "已发送WiFi配置，等待响应...";
        _progress = 60;
      });

    } catch (e) {
      _showErrorDialog("发送失败", "无法发送WiFi配置: $e");
      setState(() {
        _progress = 0;
      });
    }
  }

  void _showSuccessAndConnect() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text('配网成功'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('设备已成功连接WiFi'),
            const SizedBox(height: 16),
            Text('IP地址: ${_receivedIp}:${_receivedPort}'),
            Text('密码: ${_receivedPassword}'),
            const SizedBox(height: 16),
            const Text('是否立即连接远程控制？'),
          ],
        ),
        actions: [
          TextButton(
            child: const Text('稍后连接'),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            child: const Text('立即连接'),
            onPressed: () {
              Navigator.pop(context);
              _connectRemote();
            },
          ),
        ],
      ),
    );
  }

  void _connectRemote() {
    // Disconnect Bluetooth first
    if (_connectedDevice != null) {
      _connectedDevice!.disconnect();
    }

    // Switch to connection page
    if (HomePage.homeKey.currentState != null) {
      HomePage.homeKey.currentState!.switchToConnectionPage();
    }

    // Close this page
    Navigator.of(context).pop();

    // Connect after delay
    Future.delayed(const Duration(milliseconds: 300), () {
      final address = '${_receivedIp}:${_receivedPort}';
      
      // Set ID controller if available
      if (Get.isRegistered<IDTextEditingController>()) {
        try {
          final idController = Get.find<IDTextEditingController>();
          idController.text = address;
        } catch (e) {
          debugPrint('Failed to set ID controller: $e');
        }
      }

      // Connect using saved context
      if (HomePage.homeKey.currentContext != null && 
          HomePage.homeKey.currentContext!.mounted) {
        connect(
          HomePage.homeKey.currentContext!,
          address,
          password: _receivedPassword,
        );
      }
    });
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.error, color: Colors.red),
            const SizedBox(width: 8),
            Text(title),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            child: const Text('取消'),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            child: const Text('重试'),
            onPressed: () {
              Navigator.pop(context);
              if (!_isConnected && _discoveredDevices.isNotEmpty) {
                _startBluetoothScan();
              } else if (_isConnected && _wifiNetworks.isEmpty) {
                _startWifiScan();
              }
            },
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _scanSubscription?.cancel();
    _statusSubscription?.cancel();
    _connectionSubscription?.cancel();
    _passwordController.dispose();
    
    if (_connectedDevice != null) {
      _connectedDevice!.disconnect();
    }
    
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('蓝牙配网'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isScanning ? null : _startBluetoothScan,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Progress indicator
            if (_progress > 0) _buildProgressCard(),
            
            const SizedBox(height: 16),
            
            // Bluetooth scan section
            if (!_isConnected) _buildBluetoothScanSection(),
            
            // WiFi selection section (after connected)
            if (_isConnected && _wifiConfigCharacteristic != null)
              _buildWifiSelectionSection(),
            
            const SizedBox(height: 16),
            
            // Instructions
            _buildInstructionsCard(),
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
                  _currentStatus == "failed" ? Icons.error : Icons.sync,
                  color: _currentStatus == "failed" ? Colors.red : Colors.blue,
                ),
                const SizedBox(width: 8),
                Expanded(child: Text(_statusMessage)),
              ],
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: _progress / 100,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(
                _currentStatus == "failed" ? Colors.red : Colors.blue,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBluetoothScanSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  _isScanning ? Icons.bluetooth_searching : Icons.bluetooth,
                  color: _isScanning ? Colors.blue : Colors.grey,
                ),
                const SizedBox(width: 8),
                Text(
                  '蓝牙设备',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            if (_isScanning)
              const Center(child: CircularProgressIndicator())
            else if (_discoveredDevices.isEmpty)
              Center(
                child: Column(
                  children: [
                    const Icon(Icons.bluetooth_disabled, size: 48, color: Colors.grey),
                    const SizedBox(height: 8),
                    Text(_statusMessage),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _startBluetoothScan,
                      icon: const Icon(Icons.refresh),
                      label: const Text('重新扫描'),
                    ),
                  ],
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _discoveredDevices.length,
                itemBuilder: (context, index) {
                  final device = _discoveredDevices[index];
                  return ListTile(
                    leading: const Icon(Icons.devices),
                    title: Text(device.localName),
                    subtitle: Text('RSSI: ${device.rssi ?? "N/A"}'),
                    trailing: ElevatedButton(
                      child: const Text('连接'),
                      onPressed: () => _connectToDevice(device),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildWifiSelectionSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(Icons.wifi),
                  const SizedBox(width: 8),
                  Text(
                    'WiFi网络',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: _isWifiScanning ? null : _startWifiScan,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // WiFi list
              if (_isWifiScanning)
                const Center(child: CircularProgressIndicator())
              else if (_wifiNetworks.isEmpty)
                Center(
                  child: Column(
                    children: [
                      const Icon(Icons.wifi_off, size: 48, color: Colors.grey),
                      const SizedBox(height: 8),
                      const Text('未找到WiFi网络'),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _startWifiScan,
                        icon: const Icon(Icons.refresh),
                        label: const Text('重新扫描'),
                      ),
                    ],
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _wifiNetworks.length,
                  itemBuilder: (context, index) {
                    final wifi = _wifiNetworks[index];
                    final isSelected = _selectedWifiSsid == wifi.ssid;
                    return ListTile(
                      leading: Icon(
                        Icons.wifi,
                        color: _getSignalColor(wifi.level),
                      ),
                      title: Text(wifi.ssid),
                      subtitle: Text('信号强度: ${wifi.level}%'),
                      trailing: isSelected
                          ? const Icon(Icons.check_circle, color: Colors.green)
                          : null,
                      selected: isSelected,
                      onTap: () {
                        setState(() {
                          _selectedWifiSsid = wifi.ssid;
                        });
                      },
                    );
                  },
                ),
              
              const SizedBox(height: 16),
              
              // Password input
              if (_selectedWifiSsid != null)
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(
                    labelText: 'WiFi密码',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock),
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '请输入WiFi密码';
                    }
                    return null;
                  },
                ),
              
              const SizedBox(height: 16),
              
              // Send button
              if (_selectedWifiSsid != null)
                ElevatedButton.icon(
                  onPressed: _sendWifiConfig,
                  icon: const Icon(Icons.send),
                  label: const Text('发送配置'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                    backgroundColor: Colors.blue,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getSignalColor(int level) {
    if (level >= 80) return Colors.green;
    if (level >= 50) return Colors.orange;
    return Colors.red;
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
            const Text('1. 确保目标设备已开启蓝牙（名称: W3）'),
            const Text('2. 扫描并选择目标设备'),
            const Text('3. 选择WiFi网络并输入密码'),
            const Text('4. 发送配置并等待配网完成'),
            const Text('5. 配网成功后自动连接远程控制'),
          ],
        ),
      ),
    );
  }
}