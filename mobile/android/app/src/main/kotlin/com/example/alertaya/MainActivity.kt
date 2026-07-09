package com.example.alertaya

import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.Build
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import android.provider.Settings
import android.telephony.SmsManager
import android.util.Log
import android.view.KeyEvent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val channelName = "com.example.alertaya/panic"
    private var panicChannel: MethodChannel? = null

    private val volumePressTimestamps = mutableListOf<Long>()
    private val triplePresWindowMs = 2000L

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        panicChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
        panicChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "startPanic" -> {
                    val elapsed = call.argument<Int>("elapsedSeconds") ?: 0
                    val alarmSound = call.argument<Boolean>("alarmSound") ?: true
                    val mode = call.argument<String>("mode") ?: if (alarmSound) "noise" else "silent"
                    val intent = Intent(this, PanicForegroundService::class.java).apply {
                        action = PanicForegroundService.ACTION_START
                        putExtra(PanicForegroundService.EXTRA_ELAPSED, elapsed.toLong())
                        putExtra(PanicForegroundService.EXTRA_ALARM_SOUND, alarmSound)
                        putExtra(PanicForegroundService.EXTRA_MODE, mode)
                    }
                    startForegroundService(intent)
                    // Modo Silencioso: vibración corta como única confirmación de activación.
                    if (!alarmSound) vibrateConfirmation()
                    result.success(null)
                }
                "stopPanic" -> {
                    val intent = Intent(this, PanicForegroundService::class.java).apply {
                        action = PanicForegroundService.ACTION_STOP
                    }
                    startService(intent)
                    result.success(null)
                }
                "sendSms" -> {
                    val phone = call.argument<String>("phone")
                    val message = call.argument<String>("message")
                    if (phone.isNullOrBlank() || message.isNullOrBlank()) {
                        result.error("INVALID_ARGS", "phone y message son requeridos", null)
                        return@setMethodCallHandler
                    }
                    try {
                        val smsManager: SmsManager = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                            applicationContext.getSystemService(SmsManager::class.java)
                        } else {
                            @Suppress("DEPRECATION")
                            SmsManager.getDefault()
                        }

                        // PendingIntent para saber si el SMS realmente salió
                        val sentAction = "com.example.alertaya.SMS_SENT"
                        val sentPI = PendingIntent.getBroadcast(
                            applicationContext, 0,
                            Intent(sentAction),
                            PendingIntent.FLAG_ONE_SHOT or PendingIntent.FLAG_IMMUTABLE,
                        )
                        val receiver = object : BroadcastReceiver() {
                            override fun onReceive(ctx: Context?, intent: Intent?) {
                                when (resultCode) {
                                    android.app.Activity.RESULT_OK ->
                                        Log.d("SmsManager", "SMS enviado OK a $phone")
                                    SmsManager.RESULT_ERROR_GENERIC_FAILURE ->
                                        Log.e("SmsManager", "SMS FALLÓ (error genérico) — ¿tiene plan SMS la SIM?")
                                    SmsManager.RESULT_ERROR_NO_SERVICE ->
                                        Log.e("SmsManager", "SMS FALLÓ — sin servicio de red")
                                    SmsManager.RESULT_ERROR_NULL_PDU ->
                                        Log.e("SmsManager", "SMS FALLÓ — PDU nulo")
                                    SmsManager.RESULT_ERROR_RADIO_OFF ->
                                        Log.e("SmsManager", "SMS FALLÓ — radio apagada (modo avión?)")
                                    else ->
                                        Log.e("SmsManager", "SMS FALLÓ — código: $resultCode")
                                }
                                try { applicationContext.unregisterReceiver(this) } catch (_: Exception) {}
                            }
                        }
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                            applicationContext.registerReceiver(
                                receiver, IntentFilter(sentAction),
                                Context.RECEIVER_NOT_EXPORTED,
                            )
                        } else {
                            @Suppress("UnspecifiedRegisterReceiverFlag")
                            applicationContext.registerReceiver(receiver, IntentFilter(sentAction))
                        }

                        // Dividir en partes si el mensaje supera los 160 caracteres
                        val parts = smsManager.divideMessage(message)
                        if (parts.size == 1) {
                            smsManager.sendTextMessage(phone, null, message, sentPI, null)
                        } else {
                            val intents = ArrayList<PendingIntent>().apply { add(sentPI) }
                            smsManager.sendMultipartTextMessage(phone, null, parts, intents, null)
                        }
                        result.success(null)
                    } catch (e: Exception) {
                        result.error("SMS_ERROR", e.message, null)
                    }
                }
                "isAccessibilityEnabled" -> {
                    result.success(isPanicAccessibilityServiceEnabled())
                }
                "openAccessibilitySettings" -> {
                    startActivity(Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS).apply {
                        flags = Intent.FLAG_ACTIVITY_NEW_TASK
                    })
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }

        // Cuando la app se inicia desde cero por PanicAccessibilityService
        // (app estaba cerrada), el intent ya llegó en onCreate antes de que el
        // canal estuviera listo. Revisamos SharedPreferences para no perderlo.
        checkPendingAccessibilityPanic()
    }

    // Recibe el Intent disparado por PanicAccessibilityService cuando la app
    // ya está corriendo (en foreground o background reciente).
    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        if (intent.action == PanicAccessibilityService.ACTION_TRIGGER) {
            panicChannel?.invokeMethod("triggerVolumePanic", null)
        }
    }

    private fun checkPendingAccessibilityPanic() {
        val prefs = applicationContext.getSharedPreferences(
            "panic_accessibility_prefs", Context.MODE_PRIVATE
        )
        val pendingTs = prefs.getLong("pending_panic_timestamp", 0L)
        if (pendingTs == 0L) return

        val ageMs = System.currentTimeMillis() - pendingTs
        prefs.edit().remove("pending_panic_timestamp").apply()

        // Solo procesar si el trigger ocurrió en los últimos 10 segundos.
        if (ageMs <= 10_000L) {
            Log.d("MainActivity", "Pending panic desde AccessibilityService — disparando")
            panicChannel?.invokeMethod("triggerVolumePanic", null)
        }
    }

    private fun isPanicAccessibilityServiceEnabled(): Boolean {
        val enabledServices = Settings.Secure.getString(
            contentResolver,
            Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES
        ) ?: return false
        val componentName = "$packageName/.PanicAccessibilityService"
        return enabledServices.split(':').any { it.equals(componentName, ignoreCase = true) }
    }

    private fun vibrateConfirmation() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val manager = getSystemService(VIBRATOR_MANAGER_SERVICE) as VibratorManager
            manager.defaultVibrator.vibrate(VibrationEffect.createOneShot(200, 80))
        } else {
            @Suppress("DEPRECATION")
            val vibrator = getSystemService(VIBRATOR_SERVICE) as Vibrator
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                vibrator.vibrate(VibrationEffect.createOneShot(200, 80))
            } else {
                @Suppress("DEPRECATION")
                vibrator.vibrate(200)
            }
        }
    }

    // Detecta 3 pulsaciones del botón de volumen en menos de 2 segundos.
    // Solo dispara si el AccessibilityService NO está activo — cuando lo está,
    // PanicAccessibilityService ya maneja el triple-press y evita el doble disparo.
    override fun onKeyDown(keyCode: Int, event: KeyEvent?): Boolean {
        if (keyCode == KeyEvent.KEYCODE_VOLUME_UP || keyCode == KeyEvent.KEYCODE_VOLUME_DOWN) {
            // Cuando el AccessibilityService está activo él ya maneja el triple-press
            // vía onNewIntent. Si también contamos aquí dispararíamos dos veces → 409.
            if (!isPanicAccessibilityServiceEnabled()) {
                val now = System.currentTimeMillis()
                volumePressTimestamps.add(now)
                volumePressTimestamps.removeAll { now - it > triplePresWindowMs }
                if (volumePressTimestamps.size >= 3) {
                    volumePressTimestamps.clear()
                    panicChannel?.invokeMethod("triggerVolumePanic", null)
                }
            }
        }
        return super.onKeyDown(keyCode, event)
    }
}
