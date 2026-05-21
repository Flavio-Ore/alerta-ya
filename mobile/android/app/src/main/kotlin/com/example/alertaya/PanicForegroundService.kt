package com.example.alertaya

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Intent
import android.os.IBinder
import androidx.core.app.NotificationCompat

class PanicForegroundService : Service() {

    companion object {
        const val CHANNEL_ID = "panic_channel"
        const val NOTIFICATION_ID = 1001
        const val ACTION_START = "START_PANIC"
        const val ACTION_STOP = "STOP_PANIC"
        const val EXTRA_ELAPSED = "elapsed_seconds"
    }

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_START -> {
                try {
                    val elapsed = intent.getLongExtra(EXTRA_ELAPSED, 0L)
                    startForeground(NOTIFICATION_ID, buildNotification(elapsed))
                } catch (e: SecurityException) {
                    // Permiso de micrófono no concedido — continuar sin FGS
                    stopSelf()
                }
            }
            ACTION_STOP -> {
                stopForeground(STOP_FOREGROUND_REMOVE)
                stopSelf()
            }
        }
        return START_STICKY
    }

    override fun onBind(intent: Intent?): IBinder? = null

    private fun buildNotification(elapsedSeconds: Long): Notification {
        // Intent para abrir la app al tocar la notificación
        val openIntent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_SINGLE_TOP
        }
        val pendingIntent = PendingIntent.getActivity(
            this, 0, openIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val hh = elapsedSeconds / 3600
        val mm = (elapsedSeconds % 3600) / 60
        val ss = elapsedSeconds % 60
        val timeStr = "%02d:%02d:%02d".format(hh, mm, ss)

        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("🚨 MODO PÁNICO ACTIVO")
            .setContentText("Grabando · $timeStr · Toca para desactivar")
            .setSmallIcon(android.R.drawable.ic_dialog_alert)
            .setContentIntent(pendingIntent)
            .setOngoing(true)
            .setPriority(NotificationCompat.PRIORITY_MAX)
            .setCategory(NotificationCompat.CATEGORY_ALARM)
            .build()
    }

    private fun createNotificationChannel() {
        val channel = NotificationChannel(
            CHANNEL_ID,
            "Pánico Activo",
            NotificationManager.IMPORTANCE_HIGH
        ).apply {
            description = "Notificación persistente durante emergencia activa"
            setShowBadge(true)
        }
        val manager = getSystemService(NotificationManager::class.java)
        manager.createNotificationChannel(channel)
    }
}