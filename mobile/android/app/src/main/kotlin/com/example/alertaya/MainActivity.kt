package com.example.alertaya

import android.content.Intent
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
                    val intent = Intent(this, PanicForegroundService::class.java).apply {
                        action = PanicForegroundService.ACTION_START
                        putExtra(PanicForegroundService.EXTRA_ELAPSED, elapsed.toLong())
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
                else -> result.notImplemented()
            }
        }
    }
}