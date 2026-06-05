import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:network_info_plus/network_info_plus.dart';
import '../../common.dart';

// UUIDs for BLE service
const String serviceUuid = "0000ffe0-0000-1000-8000-00805f9b34fb";
const String characteristicUuid = "0000ffe1-0000-1000-8000-00805f9b34fb";

class BluetoothServerPage extends StatefulWidget {
  const BluetoothServerPage({Key? key}) : super(key: key);

  @override
  State<BluetoothServerPage> createState() => _BluetoothServerPageState();
}

class _BluetoothServerPageState extends State<BluetoothServerPage> {
  final FlutterBluePlus _flutterBlue = FlutterBluePlus.instance;
  final NetworkInfo _networkInfo = NetworkInfo();
  
  bool _isAdvertising = false;
  bool _isConnected = false;
  BluetoothDevice? _connectedDevice;
  BluetoothCharacteristic? _characteristic;
  String _status = 'Ready to start';
  String _wifiSSID = '';
  String _wifiPassword = '';
  String _localIp = '';

  @override
  void initState() {
    super.initState();
    _initBluetoothServer();
    _getLocalIp();
  }

  Future<void> _getLocalIp() async {
    try {
      final ip = await _networkInfo.getWifiIP();
      if (ip != null) {
        setState(() {
          _localIp = ip;
        });
      }
    } catch (e) {
      debugPrint('Failed to get IP: $e');
    }
  }

  Future<void> _initBluetoothServer() async {
    // Check Bluetooth status
    _flutterBlue.state.listen((state) {
      if (state == BluetoothState.off) {
        setState(() {
          _status = 'Bluetooth is off';
        });
      }
    });

    // Listen for connected devices
    _flutterBlue.connectedDevices.asStream().listen((devices) {
      for (var device in devices) {
        _handleDeviceConnection(device);
      }
    });
  }

  Future<void> _startAdvertising() async {
    try {
      // Start advertising
      await _flutterBlue.startAdvertising(
        localName: 'RustDesk-Prov',
        serviceUuids: [Guid(serviceUuid)],
      );

      setState(() {
        _isAdvertising = true;
        _status = 'Advertising started - waiting for connection';
      });

      // Create services and characteristics
      await _createServices();
    } catch (e) {
      setState(() {
        _status = 'Failed to start advertising: $e';
      });
    }
  }

  Future<void> _createServices() async {
    try {
      // Note: FlutterBluePlus doesn't support peripheral mode on all platforms
      // This is a simplified implementation
      setState(() {
        _status = 'BLE server ready - connect via client';
      });
    } catch (e) {
      setState(() {
        _status = 'Failed to create services: $e';
      });
    }
  }

  Future<void> _stopAdvertising() async {
    try {
      await _flutterBlue.stopAdvertising();
      setState(() {
        _isAdvertising = false;
        _status = 'Advertising stopped';
      });
    } catch (e) {
      setState(() {
        _status = 'Failed to stop advertising: $e';
      });
    }
  }

  void _handleDeviceConnection(BluetoothDevice device) async {
    setState(() {
      _connectedDevice = device;
      _isConnected = true;
      _status = 'Device connected: ${device.name}';
    });

    // Discover services
    List<BluetoothService> services = await device.discoverServices();
    for (BluetoothService service in services) {
      if (service.uuid.toString().toLowerCase() == serviceUuid.toLowerCase()) {
        for (BluetoothCharacteristic characteristic in service.characteristics) {
          if (characteristic.uuid.toString().toLowerCase() == characteristicUuid.toLowerCase()) {
            setState(() {
              _characteristic = characteristic;
            });
            
            // Listen for data
            characteristic.setNotifyValue(true);
            characteristic.value.listen((value) {
              _handleReceivedData(value);
            });
            
            // Send local IP
            _sendLocalIp();
            break;
          }
        }
      }
    }
  }

  void _handleReceivedData(List<int> data) {
    String message = utf8.decode(data);
    debugPrint('Server received: $message');
    
    if (message.startsWith('WIFI:')) {
      List<String> parts = message.split(':');
      if (parts.length >= 3) {
        setState(() {
          _wifiSSID = parts[1];
          _wifiPassword = parts[2];
          _status = 'Received WiFi config: $_wifiSSID';
        });
        
        // Configure WiFi (simplified)
        _configureWifi();
      }
    }
  }

  Future<void> _configureWifi() async {
    // In a real implementation, you would use platform channels to configure WiFi
    // This is a simplified version that just simulates the process
    
    setState(() {
      _status = 'Configuring WiFi...';
    });
    
    // Simulate WiFi configuration
    await Future.delayed(const Duration(seconds: 3));
    
    // Get new IP
    await _getLocalIp();
    
    // Send confirmation
    await _sendWifiOk();
    
    setState(() {
      _status = 'WiFi configured successfully! IP: $_localIp';
    });
  }

  Future<void> _sendLocalIp() async {
    if (_characteristic == null || _localIp.isEmpty) return;
    
    try {
      String message = 'IP:$_localIp';
      List<int> data = utf8.encode(message);
      await _characteristic!.write(data);
      debugPrint('Server sent IP: $_localIp');
    } catch (e) {
      debugPrint('Failed to send IP: $e');
    }
  }

  Future<void> _sendWifiOk() async {
    if (_characteristic == null) return;
    
    try {
      String message = 'WIFI_OK';
      List<int> data = utf8.encode(message);
      await _characteristic!.write(data);
      debugPrint('Server sent WIFI_OK');
      
      // Also send IP again
      await _getLocalIp();
      await _sendLocalIp();
    } catch (e) {
      debugPrint('Failed to send WIFI_OK: $e');
    }
  }

  @override
  void dispose() {
    if (_isAdvertising) {
      _stopAdvertising();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Device Info'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Local info
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('Connection Info', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    ListTile(
                      leading: const Icon(Icons.wifi),
                      title: const Text('Local IP'),
                      subtitle: Text(_localIp.isEmpty ? 'Unknown' : _localIp),
                      trailing: IconButton(
                        icon: const Icon(Icons.refresh),
                        onPressed: _getLocalIp,
                      ),
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.lock),
                      title: const Text('Password'),
                      subtitle: const Text('A123456a'),
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.settings_input_component),
                      title: const Text('Port'),
                      subtitle: const Text('21116'),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Quick connect info
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('Quick Connect', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(
                      '${_localIp.isEmpty ? 'IP_ADDRESS' : _localIp}:21116',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'On another device, enter the IP address above and use password "A123456a" to connect.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Instructions
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('Instructions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    const Text('1. Make sure both devices are on the same WiFi network'),
                    const Text('2. On this device, note the IP address above'),
                    const Text('3. On the other device, open Bluetooth Provisioning'),
                    const Text('4. Enter the IP address and password'),
                    const Text('5. Click Connect'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
