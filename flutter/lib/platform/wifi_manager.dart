import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

// Error codes
const String ERROR_WIFI_PASSWORD = "E001";
const String ERROR_WIFI_NOT_FOUND = "E002";
const String ERROR_WIFI_SIGNAL_WEAK = "E003";
const String ERROR_TIMEOUT = "E004";
const String ERROR_PERMISSION = "E005";
const String ERROR_BLUETOOTH_DISCONNECT = "E006";
const String ERROR_UNKNOWN = "E007";

class WifiConnectResult {
  final bool success;
  final String errorCode;
  final String errorMessage;

  WifiConnectResult({
    required this.success,
    this.errorCode = "",
    this.errorMessage = "",
  });
}

class WifiManager {
  static const MethodChannel _channel = MethodChannel('wifi_manager');

  /// Connect to a WiFi network
  /// Returns WifiConnectResult with success status and error details
  Future<WifiConnectResult> connectWifi(String ssid, String password) async {
    try {
      final result = await _channel.invokeMethod<Map<String, dynamic>>(
        'connectWifi',
        {
          'ssid': ssid,
          'password': password,
        },
      );

      if (result == null) {
        return WifiConnectResult(
          success: false,
          errorCode: ERROR_UNKNOWN,
          errorMessage: "Unknown error",
        );
      }

      final success = result['success'] as bool? ?? false;
      final errorCode = result['error_code'] as String? ?? "";
      final errorMessage = result['error_message'] as String? ?? "";

      return WifiConnectResult(
        success: success,
        errorCode: errorCode,
        errorMessage: errorMessage,
      );
    } on PlatformException catch (e) {
      return WifiConnectResult(
        success: false,
        errorCode: ERROR_UNKNOWN,
        errorMessage: e.message ?? "Platform error",
      );
    } catch (e) {
      return WifiConnectResult(
        success: false,
        errorCode: ERROR_UNKNOWN,
        errorMessage: e.toString(),
      );
    }
  }

  /// Disconnect from current WiFi network
  Future<bool> disconnectWifi() async {
    try {
      final result = await _channel.invokeMethod<bool>('disconnectWifi');
      return result ?? false;
    } on PlatformException catch (e) {
      debugPrint('Failed to disconnect WiFi: ${e.message}');
      return false;
    } catch (e) {
      debugPrint('Failed to disconnect WiFi: $e');
      return false;
    }
  }

  /// Get current WiFi SSID
  Future<String?> getCurrentWifiSsid() async {
    try {
      final result = await _channel.invokeMethod<String>('getCurrentWifiSsid');
      return result;
    } on PlatformException catch (e) {
      debugPrint('Failed to get WiFi SSID: ${e.message}');
      return null;
    } catch (e) {
      debugPrint('Failed to get WiFi SSID: $e');
      return null;
    }
  }

  /// Check if WiFi is connected
  Future<bool> isWifiConnected() async {
    try {
      final result = await _channel.invokeMethod<bool>('isWifiConnected');
      return result ?? false;
    } on PlatformException catch (e) {
      debugPrint('Failed to check WiFi connection: ${e.message}');
      return false;
    } catch (e) {
      debugPrint('Failed to check WiFi connection: $e');
      return false;
    }
  }

  /// Force reconnect to WiFi (disconnect first, then connect)
  Future<WifiConnectResult> forceReconnectWifi(String ssid, String password) async {
    try {
      // Disconnect first
      await disconnectWifi();
      
      // Wait a bit for disconnect to complete
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Connect to new WiFi
      return await connectWifi(ssid, password);
    } catch (e) {
      return WifiConnectResult(
        success: false,
        errorCode: ERROR_UNKNOWN,
        errorMessage: "Force reconnect failed: $e",
      );
    }
  }
}