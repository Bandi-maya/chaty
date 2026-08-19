package com.example.chat

import android.app.PictureInPictureParams
import android.content.ComponentName
import android.content.pm.PackageManager
import android.os.Build
import android.util.Rational
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val windowChannel = "chaty/window"
    private val iconChannel = "chaty/app_icon"

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
                    val params = PictureInPictureParams.Builder()
                        .setAspectRatio(Rational(width.coerceIn(1, 1000), height.coerceIn(1, 1000)))
                        .build()
                    result.success(enterPictureInPictureMode(params))
                }
                "isPictureInPictureSupported" -> result.success(Build.VERSION.SDK_INT >= Build.VERSION_CODES.O)
                else -> result.notImplemented()
            }
        }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, iconChannel).setMethodCallHandler { call, result ->
            when (call.method) {
                "setLauncherIcon" -> {
                    val requested = call.argument<String>("id") ?: "default"
                    try {
                        setLauncherIcon(requested)
                        result.success(true)
                    } catch (error: Exception) {
                        result.error("APP_ICON_CHANGE_FAILED", error.message, null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun setLauncherIcon(id: String) {
        val aliases = mapOf(
            "default" to "DefaultLauncher",
            "bubble" to "BubbleLauncher",
            "messages" to "MessagesLauncher",
            "secure" to "SecureLauncher",
            "minimal" to "MinimalLauncher",
            "call" to "CallLauncher"
        )
        val target = aliases[id] ?: aliases.getValue("default")
        val manager = packageManager

        // Enable the destination first so the application always retains a
        // launchable component while launchers refresh their cached icon.
        manager.setComponentEnabledSetting(
            ComponentName(this, "$packageName.$target"),
            PackageManager.COMPONENT_ENABLED_STATE_ENABLED,
            PackageManager.DONT_KILL_APP
        )

        aliases.values.filter { it != target }.forEach { alias ->
            manager.setComponentEnabledSetting(
                ComponentName(this, "$packageName.$alias"),
                PackageManager.COMPONENT_ENABLED_STATE_DISABLED,
                PackageManager.DONT_KILL_APP
            )
        }
    }
}
