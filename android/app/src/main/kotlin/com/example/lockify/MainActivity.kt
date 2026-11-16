package com.example.lockify

import android.app.AppOpsManager
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.android.RenderMode
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val channel = "com.example.lockify/blocker"

    override fun getRenderMode(): RenderMode = RenderMode.texture

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channel)
            .setMethodCallHandler { call, result ->
                when (call.method) {

                    // Start the foreground blocking service
                    "startBlocking" -> {
                        val intent = Intent(this, AppBlockerService::class.java).apply {
                            action = AppBlockerService.ACTION_START_BLOCKING
                        }
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                            startForegroundService(intent)
                        } else {
                            startService(intent)
                        }
                        result.success(null)
                    }

                    // Stop the foreground blocking service
                    "stopBlocking" -> {
                        val intent = Intent(this, AppBlockerService::class.java).apply {
                            action = AppBlockerService.ACTION_STOP_BLOCKING
                        }
                        startService(intent)
                        result.success(null)
                    }

                    // Check if PACKAGE_USAGE_STATS permission is granted
                    "hasUsageStatsPermission" -> {
                        result.success(hasUsageStatsPermission())
                    }

                    // Open system settings to grant PACKAGE_USAGE_STATS
                    "requestUsageStatsPermission" -> {
                        val intent = Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS).apply {
                            // On some ROMs we can deep-link directly to our app's entry
                            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                                data = Uri.parse("package:$packageName")
                            }
                            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        }
                        startActivity(intent)
                        result.success(null)
                    }

                    // Check if SYSTEM_ALERT_WINDOW (overlay) permission is granted
                    "hasOverlayPermission" -> {
                        result.success(Settings.canDrawOverlays(this))
                    }

                    // Open system settings to grant overlay permission
                    "requestOverlayPermission" -> {
                        val intent = Intent(
                            Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                            Uri.parse("package:$packageName")
                        ).apply {
                            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        }
                        startActivity(intent)
                        result.success(null)
                    }

                    else -> result.notImplemented()
                }
            }
    }

    private fun hasUsageStatsPermission(): Boolean {
        val appOps = getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager
        val mode = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            appOps.unsafeCheckOpNoThrow(
                AppOpsManager.OPSTR_GET_USAGE_STATS,
                android.os.Process.myUid(),
                packageName
            )
        } else {
            @Suppress("DEPRECATION")
            appOps.checkOpNoThrow(
                AppOpsManager.OPSTR_GET_USAGE_STATS,
                android.os.Process.myUid(),
                packageName
            )
        }
        return mode == AppOpsManager.MODE_ALLOWED
    }
}
