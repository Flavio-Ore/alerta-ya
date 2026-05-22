package com.example.alertaya

import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.Build
import android.telephony.SmsManager
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val channel = "com.example.alertaya/panic"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            channel
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "startPanic" -> {
                    val elapsed = call.argument<Int>("elapsedSeconds") ?: 0
                    val alarmSound = call.argument<Boolean>("alarmSound") ?: true
                    val intent = Intent(this, PanicForegroundService::class.java).apply {
                        action = PanicForegroundService.ACTION_START
                        putExtra(PanicForegroundService.EXTRA_ELAPSED, elapsed.toLong())
                        putExtra(PanicForegroundService.EXTRA_ALARM_SOUND, alarmSound)
                    }
                    startForegroundService(intent)
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
                else -> result.notImplemented()
            }
        }
    }
}