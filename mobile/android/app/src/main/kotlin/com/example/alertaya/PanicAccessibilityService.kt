package com.example.alertaya

import android.accessibilityservice.AccessibilityService
import android.accessibilityservice.AccessibilityServiceInfo
import android.content.Intent
import android.content.SharedPreferences
import android.util.Log
import android.view.KeyEvent
import android.view.accessibility.AccessibilityEvent

class PanicAccessibilityService : AccessibilityService() {

    companion object {
        const val ACTION_TRIGGER = "com.example.alertaya.ACCESSIBILITY_VOLUME_PANIC"
        private const val PREFS_NAME = "panic_accessibility_prefs"
        private const val KEY_PENDING_PANIC = "pending_panic_timestamp"
        private const val KEY_VOLUME_ENABLED = "panic_volume_activation"
        private const val TAG = "PanicAccessibility"
    }

    private val pressTimestamps = mutableListOf<Long>()
    private val windowMs = 2000L

    override fun onServiceConnected() {
        val info = AccessibilityServiceInfo().apply {
            flags = AccessibilityServiceInfo.FLAG_REQUEST_FILTER_KEY_EVENTS
            eventTypes = 0
            feedbackType = AccessibilityServiceInfo.FEEDBACK_GENERIC
            notificationTimeout = 0
        }
        serviceInfo = info
        Log.d(TAG, "Servicio de accesibilidad conectado")
    }

    override fun onKeyEvent(event: KeyEvent): Boolean {
        if (event.action != KeyEvent.ACTION_DOWN) return false
        if (event.keyCode != KeyEvent.KEYCODE_VOLUME_UP &&
            event.keyCode != KeyEvent.KEYCODE_VOLUME_DOWN) return false

        if (!isVolumeActivationEnabled()) return false

        val now = System.currentTimeMillis()

        pressTimestamps.add(now)
        pressTimestamps.removeAll { now - it > windowMs }

        if (pressTimestamps.size >= 3) {
            pressTimestamps.clear()
            Log.d(TAG, "Triple pulsación detectada — activando pánico")
            triggerPanic()
        }

        return false // no consumir el evento; el volumen sigue funcionando normalmente
    }

    private fun triggerPanic() {
        // Guardar timestamp para que MainActivity lo lea si la app se está iniciando.
        prefs().edit()
            .putLong(KEY_PENDING_PANIC, System.currentTimeMillis())
            .apply()

        // Intentar llevar la app al frente. AccessibilityService puede lanzar
        // actividades desde background (a diferencia de servicios normales).
        val intent = Intent(this, MainActivity::class.java).apply {
            action = ACTION_TRIGGER
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP
        }
        startActivity(intent)
    }

    private fun isVolumeActivationEnabled(): Boolean {
        // Leer el flag del mismo SharedPreferences que usa Flutter (flutter_secure_storage
        // guarda en prefs individuales; leemos el fallback en las prefs del servicio).
        // Si no está configurado explícitamente como 'false', asumimos habilitado.
        val flutterPrefs = applicationContext.getSharedPreferences(
            "FlutterSecureStorage", MODE_PRIVATE
        )
        return flutterPrefs.getString(KEY_VOLUME_ENABLED, null) != "false"
    }

    private fun prefs(): SharedPreferences =
        applicationContext.getSharedPreferences(PREFS_NAME, MODE_PRIVATE)

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {}
    override fun onInterrupt() {}
}
