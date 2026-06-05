import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../common.dart';
import '../../common/formatter/id_formatter.dart';
import '../../consts.dart';
import 'home_page.dart';

class BluetoothProvisioningPage extends StatefulWidget {
  const BluetoothProvisioningPage({Key? key}) : super(key: key);

  @override
  State<BluetoothProvisioningPage> createState() => _BluetoothProvisioningPageState();
}

class _BluetoothProvisioningPageState extends State<BluetoothProvisioningPage> {
  final _ipController = TextEditingController();
  final _passwordController = TextEditingController(text: 'A123456a');
  final _portController = TextEditingController(text: '21116');
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _ipController.dispose();
    _passwordController.dispose();
    _portController.dispose();
    super.dispose();
  }

  void _connect() {
    if (_formKey.currentState!.validate()) {
      final address = '${_ipController.text}:${_portController.text}';
      final password = _passwordController.text;
      
      // Save the home page context if available
      BuildContext? safeContext;
      if (HomePage.homeKey.currentContext != null) {
        safeContext = HomePage.homeKey.currentContext;
      }
      
      // Switch to connection page first
      if (HomePage.homeKey.currentState != null) {
        HomePage.homeKey.currentState!.switchToConnectionPage();
      }
      
      // Close this page
      Navigator.of(context).pop();
      
      // Connect after a short delay
      Future.delayed(const Duration(milliseconds: 300), () {
        // Set ID controller if available
        if (Get.isRegistered<IDTextEditingController>()) {
          try {
            final idController = Get.find<IDTextEditingController>();
            idController.text = address;
          } catch (e) {
            debugPrint('Failed to set ID controller: $e');
          }
        }
        
        // Connect using the safe context we saved
        if (safeContext != null && safeContext.mounted) {
          connect(safeContext, address, password: password);
        } else if (Get.context != null && Get.context!.mounted) {
          connect(Get.context!, address, password: password);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quick Connect'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Instructions
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Instructions',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      const Text('1. Make sure both devices are on the same WiFi network'),
                      const Text('2. Get the IP address from the target device'),
                      const Text('3. Enter the IP address below'),
                      const Text('4. Click Connect'),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Connection form
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Connection Details',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      
                      // IP Address
                      TextFormField(
                        controller: _ipController,
                        decoration: const InputDecoration(
                          labelText: 'IP Address',
                          hintText: '192.168.1.100',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.wifi),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter IP address';
                          }
                          // Simple IP validation
                          final parts = value.split('.');
                          if (parts.length != 4) {
                            return 'Invalid IP address';
                          }
                          return null;
                        },
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Port
                      TextFormField(
                        controller: _portController,
                        decoration: const InputDecoration(
                          labelText: 'Port',
                          hintText: '21116',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.settings_input_component),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter port';
                          }
                          return null;
                        },
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Password
                      TextFormField(
                        controller: _passwordController,
                        decoration: const InputDecoration(
                          labelText: 'Password',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.lock),
                        ),
                        obscureText: true,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter password';
                          }
                          return null;
                        },
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Connect button
                      ElevatedButton.icon(
                        onPressed: _connect,
                        icon: const Icon(Icons.connected_tv),
                        label: const Text('Connect'),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 50),
                          backgroundColor: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Default password info
              Card(
                color: Colors.blue.shade50,
                child: const Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Default Password',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'The default password is "A123456a". You can change it on the target device.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
