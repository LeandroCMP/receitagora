package com.example.receitagora

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.TimeZone

class MainActivity : FlutterActivity() {
    private val channelName = "receitagora/device_timezone"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getLocalTimezone" -> {
                        val timezone = TimeZone.getDefault().id
                        result.success(timezone)
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
