package com.carriez.flutter_hbb

import android.content.Context
import android.net.wifi.WifiConfiguration
import android.net.wifi.WifiManager
import android.net.wifi.WifiInfo
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class WifiManagerHandler(private val context: Context) : MethodChannel.MethodCallHandler {
    private val wifiManager: WifiManager = context.getSystemService(Context.WIFI_SERVICE) as WifiManager

    // Error codes
    private val ERROR_WIFI_PASSWORD = "E001"
    private val ERROR_WIFI_NOT_FOUND = "E002"
    private val ERROR_WIFI_SIGNAL_WEAK = "E003"
    private val ERROR_TIMEOUT = "E004"
    private val ERROR_PERMISSION = "E005"
    private val ERROR_BLUETOOTH_DISCONNECT = "E006"
    private val ERROR_UNKNOWN = "E007"

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "connectWifi" -> {
                val ssid = call.argument<String>("ssid")
                val password = call.argument<String>("password")
                if (ssid != null && password != null) {
                    connectWifi(ssid, password, result)
                } else {
                    result.error(ERROR_UNKNOWN, "Missing ssid or password", null)
                }
            }
            "disconnectWifi" -> {
                disconnectWifi(result)
            }
            "getCurrentWifiSsid" -> {
                getCurrentWifiSsid(result)
            }
            "isWifiConnected" -> {
                isWifiConnected(result)
            }
            else -> {
                result.notImplemented()
            }
        }
    }

    private fun connectWifi(ssid: String, password: String, result: MethodChannel.Result) {
        try {
            // Enable WiFi if disabled
            if (!wifiManager.isWifiEnabled) {
                wifiManager.isWifiEnabled = true
                Thread.sleep(1000)
            }

            // Create WiFi configuration
            val wifiConfig = WifiConfiguration()
            wifiConfig.SSID = "\"$ssid\""
            
            // Determine security type and set password
            if (password.isNotEmpty()) {
                wifiConfig.preSharedKey = "\"$password\""
            }

            // Add network
            val networkId = wifiManager.addNetwork(wifiConfig)
            
            if (networkId == -1) {
                result.success(mapOf(
                    "success" to false,
                    "error_code" to ERROR_WIFI_NOT_FOUND,
                    "error_message" to "Failed to add network configuration"
                ))
                return
            }

            // Disconnect from current network
            wifiManager.disconnect()

            // Enable the new network
            wifiManager.enableNetwork(networkId, true)

            // Reconnect
            wifiManager.reconnect()

            // Wait for connection (max 30 seconds)
            var connected = false
            var attempts = 0
            val maxAttempts = 30

            while (!connected && attempts < maxAttempts) {
                Thread.sleep(1000)
                val wifiInfo = wifiManager.connectionInfo
                val currentSsid = wifiInfo?.ssid?.replace("\"", "")
                
                if (currentSsid == ssid && wifiInfo?.networkId == networkId) {
                    connected = true
                }
                attempts++
            }

            if (connected) {
                result.success(mapOf(
                    "success" to true,
                    "error_code" to "",
                    "error_message" to ""
                ))
            } else {
                // Check for specific error conditions
                val wifiInfo = wifiManager.connectionInfo
                val supplState = wifiInfo?.supplicantState
                
                val errorCode = when (supplState) {
                    WifiInfo.SupplicantState.AUTHENTICATING -> ERROR_WIFI_PASSWORD
                    WifiInfo.SupplicantState.DISCONNECTED -> ERROR_WIFI_NOT_FOUND
                    WifiInfo.SupplicantState.INACTIVE -> ERROR_WIFI_SIGNAL_WEAK
                    else -> ERROR_TIMEOUT
                }

                result.success(mapOf(
                    "success" to false,
                    "error_code" to errorCode,
                    "error_message" to "Connection failed: $supplState"
                ))
            }

        } catch (e: Exception) {
            result.success(mapOf(
                "success" to false,
                "error_code" to ERROR_UNKNOWN,
                "error_message" to e.message ?: "Unknown error"
            ))
        }
    }

    private fun disconnectWifi(result: MethodChannel.Result) {
        try {
            wifiManager.disconnect()
            result.success(true)
        } catch (e: Exception) {
            result.success(false)
        }
    }

    private fun getCurrentWifiSsid(result: MethodChannel.Result) {
        try {
            val wifiInfo = wifiManager.connectionInfo
            val ssid = wifiInfo?.ssid?.replace("\"", "")
            result.success(ssid)
        } catch (e: Exception) {
            result.success(null)
        }
    }

    private fun isWifiConnected(result: MethodChannel.Result) {
        try {
            val wifiInfo = wifiManager.connectionInfo
            val isConnected = wifiInfo?.networkId != -1
            result.success(isConnected)
        } catch (e: Exception) {
            result.success(false)
        }
    }
}