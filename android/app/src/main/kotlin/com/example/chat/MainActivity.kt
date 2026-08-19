package com.example.chat

import android.app.PictureInPictureParams
import android.os.Build
import android.util.Rational
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val windowChannel = "chaty/window"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, windowChannel).setMethodCallHandler { call, result ->
            when (call.method) {
                "enterPictureInPicture" -> {
                    if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
                        result.success(false)
                        return@setMethodCallHandler
                    }
                    val width = call.argument<Int>("width") ?: 16
                    val height = call.argument<Int>("height") ?: 9
                    val safeWidth = width.coerceIn(1, 1000)
                    val safeHeight = height.coerceIn(1, 1000)
                    val params = PictureInPictureParams.Builder()
                        .setAspectRatio(Rational(safeWidth, safeHeight))
                        .build()
                    result.success(enterPictureInPictureMode(params))
                }
                "isPictureInPictureSupported" -> result.success(Build.VERSION.SDK_INT >= Build.VERSION_CODES.O)
                else -> result.notImplemented()
            }
        }
    }
}
