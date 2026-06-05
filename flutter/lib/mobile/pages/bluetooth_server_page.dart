import 'dart:async';
import 'package:flutter/material.dart';
import 'package:network_info_plus/network_info_plus.dart';
import '../../common.dart';

class BluetoothServerPage extends StatefulWidget {
  const BluetoothServerPage({Key? key}) : super(key: key);

  @override
  State<BluetoothServerPage> createState() => _BluetoothServerPageState();
}

class _BluetoothServerPageState extends State<BluetoothServerPage> {
  final NetworkInfo _networkInfo = NetworkInfo();
  String _localIp = '';

  @override
  void initState() {
    super.initState();
    _getLocalIp();
  }

  Future<void> _getLocalIp() async {
    try {
      final ip = await _networkInfo.getWifiIP();
      if (ip != null && mounted) {
        setState(() {
          _localIp = ip;
        });
      }
    } catch (e) {
      debugPrint('Failed to get IP: $e');
    }
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
                    const Text('3. On the other device, open Quick Connect'),
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
