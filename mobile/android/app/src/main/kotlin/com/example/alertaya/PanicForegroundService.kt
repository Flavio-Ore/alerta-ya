package com.example.alertaya

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Intent
import android.media.AudioAttributes
import android.media.MediaPlayer
import android.media.RingtoneManager
import android.net.Uri
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import androidx.core.app.NotificationCompat

class PanicForegroundService : Service() {

    companion object {
        const val CHANNEL_ID = "panic_channel"
        const val NOTIFICATION_ID = 1001
        const val ACTION_START = "START_PANIC"
        const val ACTION_STOP = "STOP_PANIC"
        const val EXTRA_ELAPSED = "elapsed_seconds"
        const val EXTRA_ALARM_SOUND = "alarm_sound"
    }

    private val handler = Handler(Looper.getMainLooper())
    private var elapsedSeconds = 0L
    private var mediaPlayer: MediaPlayer? = null

    private val tickRunnable = object : Runnable {
        override fun run() {
            elapsedSeconds++
            notificationManager.notify(NOTIFICATION_ID, buildNotification(elapsedSeconds))
            handler.postDelayed(this, 1000)
        }
    }

    private val notificationManager by lazy {
        getSystemService(NotificationManager::class.java)
    }

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_START -> {
                try {
                    elapsedSeconds = intent.getLongExtra(EXTRA_ELAPSED, 0L)
                    val alarmSound = intent.getBooleanExtra(EXTRA_ALARM_SOUND, true)
                    handler.removeCallbacks(tickRunnable)
                    startForeground(NOTIFICATION_ID, buildNotification(elapsedSeconds))
                    handler.postDelayed(tickRunnable, 1000)
                    if (alarmSound) startAlarmSound()
                } catch (e: SecurityException) {
                    // Permiso de micrófono no concedido — continuar sin FGS
                    stopSelf()
                }
            }
            ACTION_STOP -> {
                handler.removeCallbacks(tickRunnable)
                stopAlarmSound()
                stopForeground(STOP_FOREGROUND_REMOVE)
                stopSelf()
            }
        }
        return START_STICKY
    }

    override fun onDestroy() {
        handler.removeCallbacks(tickRunnable)
        stopAlarmSound()
        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? = null

    // ── Alarma sonora — usa STREAM_ALARM que ignora silent/vibrate ────────────

    private fun startAlarmSound() {
        try {
            val alarmUri: Uri =
                RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM)
                    ?: RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION)
                    ?: return
            mediaPlayer = MediaPlayer().apply {
                setAudioAttributes(
                    AudioAttributes.Builder()
                        .setUsage(AudioAttributes.USAGE_ALARM)
                        .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                        .build()
                )
                setDataSource(applicationContext, alarmUri)
                isLooping = true
                prepare()
                start()
            }
        } catch (_: Exception) {
            // Fail silencioso — la grabación y el servicio siguen activos
        }
    }

    private fun stopAlarmSound() {
        try {
            mediaPlayer?.let {
                if (it.isPlaying) it.stop()
                it.release()
            }
        } catch (_: Exception) {}
        mediaPlayer = null
    }

    private fun buildNotification(elapsedSeconds: Long): Notification {
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
            .setSmallIcon(R.drawable.ic_launcher_foreground)
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
        notificationManager.createNotificationChannel(channel)
    }
}