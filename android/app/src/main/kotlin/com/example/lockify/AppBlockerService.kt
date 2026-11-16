package com.example.lockify

import android.app.*
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.graphics.PixelFormat
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.provider.Settings
import android.view.Gravity
import android.view.LayoutInflater
import android.view.View
import android.view.WindowManager
import android.widget.Button
import android.widget.TextView
import androidx.core.app.NotificationCompat

class AppBlockerService : Service() {

    private val handler = Handler(Looper.getMainLooper())
    private var isBlocking = false
    private val pollInterval = 800L
    private val appPackageName by lazy { applicationContext.packageName }

    private var windowManager: WindowManager? = null
    private var overlayView: View? = null

    // ── Polling loop ──────────────────────────────────────────────────────────

    private val pollRunnable = object : Runnable {
        override fun run() {
            if (isBlocking) {
                val foregroundApp = getForegroundAppPackage()
                if (foregroundApp != null && foregroundApp != appPackageName) {
                    showOverlay()
                } else {
                    // We're back in Lockify — hide overlay but keep polling
                    hideOverlay()
                }
            }
            handler.postDelayed(this, pollInterval)
        }
    }

    // ── Lifecycle ─────────────────────────────────────────────────────────────

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
        startForeground(NOTIFICATION_ID, buildNotification())
        windowManager = getSystemService(WINDOW_SERVICE) as WindowManager
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_START_BLOCKING -> {
                isBlocking = true
                // Remove stale callbacks before posting fresh ones
                handler.removeCallbacks(pollRunnable)
                handler.post(pollRunnable)
            }
            ACTION_STOP_BLOCKING -> {
                isBlocking = false
                handler.removeCallbacks(pollRunnable)
                hideOverlay()
                stopForeground(STOP_FOREGROUND_REMOVE)
                stopSelf()
            }
        }
        // START_STICKY: if the OS kills the service, it will be restarted
        // automatically with a null intent — we re-arm blocking in that case.
        return START_STICKY
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onDestroy() {
        handler.removeCallbacks(pollRunnable)
        hideOverlay()
        super.onDestroy()
    }

    // ── Overlay ───────────────────────────────────────────────────────────────

    private fun showOverlay() {
        if (overlayView != null) return // already showing
        if (!Settings.canDrawOverlays(this)) return

        val wm = windowManager ?: return

        val type = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O)
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
        else
            @Suppress("DEPRECATION")
            WindowManager.LayoutParams.TYPE_SYSTEM_ALERT

        val params = WindowManager.LayoutParams(
            WindowManager.LayoutParams.MATCH_PARENT,
            WindowManager.LayoutParams.MATCH_PARENT,
            type,
            // FLAG_NOT_FOCUSABLE so the back button still works on older ROMs;
            // FLAG_LAYOUT_IN_SCREEN so it covers system bars
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                    WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN,
            PixelFormat.TRANSLUCENT
        ).apply {
            gravity = Gravity.TOP or Gravity.START
        }

        val view = buildOverlayView()
        overlayView = view
        wm.addView(view, params)
    }

    private fun hideOverlay() {
        val view = overlayView ?: return
        try {
            windowManager?.removeView(view)
        } catch (_: Exception) { /* view may already be detached */ }
        overlayView = null
    }

    private fun buildOverlayView(): View {
        // A full-screen dark overlay with a message and an "Open Lockify" button.
        // We build it programmatically to avoid needing a layout XML dependency.
        val container = android.widget.LinearLayout(this).apply {
            orientation = android.widget.LinearLayout.VERTICAL
            gravity = Gravity.CENTER
            setBackgroundColor(Color.argb(230, 20, 20, 40))
            setPadding(80, 80, 80, 80)
        }

        val icon = TextView(this).apply {
            text = "\uD83D\uDD12" // 🔒 emoji
            textSize = 64f
            gravity = Gravity.CENTER
        }

        val title = TextView(this).apply {
            text = "Locked"
            textSize = 32f
            setTextColor(Color.WHITE)
            gravity = Gravity.CENTER
            setPadding(0, 24, 0, 0)
        }

        val subtitle = TextView(this).apply {
            text = "Complete a work session in Lockify\nto earn screen time."
            textSize = 16f
            setTextColor(Color.argb(200, 255, 255, 255))
            gravity = Gravity.CENTER
            setPadding(0, 16, 0, 48)
        }

        val button = Button(this).apply {
            text = "Open Lockify"
            setTextColor(Color.WHITE)
            setBackgroundColor(Color.argb(255, 63, 81, 181)) // indigo
            setPadding(48, 24, 48, 24)
            setOnClickListener {
                val i = Intent(context, MainActivity::class.java).apply {
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_REORDER_TO_FRONT)
                }
                startActivity(i)
            }
        }

        container.addView(icon)
        container.addView(title)
        container.addView(subtitle)
        container.addView(button)
        return container
    }

    // ── UsageStats ────────────────────────────────────────────────────────────

    private fun getForegroundAppPackage(): String? {
        val usm = getSystemService(Context.USAGE_STATS_SERVICE) as? UsageStatsManager
            ?: return null
        val now = System.currentTimeMillis()
        val stats = usm.queryUsageStats(
            UsageStatsManager.INTERVAL_DAILY,
            now - 3000,
            now
        )
        return stats?.maxByOrNull { it.lastTimeUsed }?.packageName
    }

    // ── Notification ──────────────────────────────────────────────────────────

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Lockify Active",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Shows while Lockify is enforcing the locked state"
                setShowBadge(false)
            }
            getSystemService(NotificationManager::class.java)
                ?.createNotificationChannel(channel)
        }
    }

    private fun buildNotification(): Notification {
        val pi = PendingIntent.getActivity(
            this, 0,
            Intent(this, MainActivity::class.java),
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        )
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Lockify is active")
            .setContentText("Earn screen time by completing work sessions")
            .setSmallIcon(android.R.drawable.ic_lock_lock)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setContentIntent(pi)
            .setOngoing(true)
            .build()
    }

    companion object {
        private const val CHANNEL_ID = "lockify_blocker_channel"
        private const val NOTIFICATION_ID = 1001
        const val ACTION_START_BLOCKING = "com.example.lockify.START_BLOCKING"
        const val ACTION_STOP_BLOCKING  = "com.example.lockify.STOP_BLOCKING"
    }
}
