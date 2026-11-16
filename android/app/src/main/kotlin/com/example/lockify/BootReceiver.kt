package com.example.lockify

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.os.Build

/**
 * Restarts the blocking service after a device reboot so the lock persists
 * even if the user never opens Lockify again.
 *
 * Only re-arms if the app was in the locked state when the device shut down
 * (i.e. no active unlock session is stored in SharedPreferences).
 */
class BootReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != Intent.ACTION_BOOT_COMPLETED) return

        val prefs: SharedPreferences = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val hasActiveSession = prefs.contains(KEY_ACTIVE_SESSION)

        // If there is no stored unlock session, the phone was locked at shutdown →
        // restart the blocking service immediately.
        if (!hasActiveSession) {
            val serviceIntent = Intent(context, AppBlockerService::class.java).apply {
                action = AppBlockerService.ACTION_START_BLOCKING
            }
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(serviceIntent)
            } else {
                context.startService(serviceIntent)
            }
        }
    }

    companion object {
        // These must match the keys used in LockifyController / SharedPreferences.
        const val PREFS_NAME = "FlutterSharedPreferences"
        const val KEY_ACTIVE_SESSION = "flutter.lockify.active.session"
    }
}
