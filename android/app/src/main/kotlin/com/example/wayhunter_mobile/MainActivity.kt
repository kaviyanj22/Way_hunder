package com.example.wayhunter_mobile

import android.Manifest
import android.app.NotificationManager
import android.content.pm.PackageManager
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var permissionResult: MethodChannel.Result? = null
    private var pendingPermission: String? = null
    private val permissionRequestCode = 7401

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "wayhunter/device")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "mapsConfigured" -> {
                        @Suppress("DEPRECATION")
                        val info = packageManager.getApplicationInfo(packageName, PackageManager.GET_META_DATA)
                        val key = info.metaData?.getString("com.google.android.geo.API_KEY").orEmpty()
                        // Defaults permit clean builds but must never open an unauthenticated map.
                        result.success(key.isNotBlank() && key != "DEFAULT_API_KEY" &&
                            !key.startsWith("YOUR_") && !key.startsWith("REPLACE_") &&
                            !key.startsWith("\u0024{"))
                    }
                    "requestCamera" -> {
                        if (!packageManager.hasSystemFeature(PackageManager.FEATURE_CAMERA_ANY)) {
                            result.success("Unavailable. This device has no camera; demo browsing still works.")
                        } else {
                            requestRuntimePermission(Manifest.permission.CAMERA, result)
                        }
                    }
                    "requestNotifications" -> {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                            requestRuntimePermission(Manifest.permission.POST_NOTIFICATIONS, result)
                        } else {
                            val enabled = getSystemService(NotificationManager::class.java).areNotificationsEnabled()
                            result.success(if (enabled) "Granted. This prototype has no push notification service."
                                else "Denied in device settings. In-app demo notices remain available.")
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun requestRuntimePermission(permission: String, result: MethodChannel.Result) {
        if (checkSelfPermission(permission) == PackageManager.PERMISSION_GRANTED) {
            result.success(grantedMessage(permission))
            return
        }
        if (permissionResult != null) {
            result.success("Another permission request is open. Finish it first.")
            return
        }
        val preferences = getSharedPreferences("wayhunter_permissions", MODE_PRIVATE)
        if (preferences.getBoolean(permission, false) && !shouldShowRequestPermissionRationale(permission)) {
            result.success("Blocked. Enable this permission in app settings, or continue without it.")
            return
        }
        preferences.edit().putBoolean(permission, true).apply()
        permissionResult = result
        pendingPermission = permission
        requestPermissions(arrayOf(permission), permissionRequestCode)
    }

    private fun grantedMessage(permission: String): String =
        if (permission == Manifest.permission.CAMERA)
            "Granted. The camera opens only when you choose to capture."
        else "Granted. This prototype has no push notification service."

    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == permissionRequestCode) {
            val permission = pendingPermission
            val granted = grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED
            permissionResult?.success(if (granted && permission != null) grantedMessage(permission)
                else "Denied. You can continue using the demo without this permission.")
            permissionResult = null
            pendingPermission = null
        }
    }
}
