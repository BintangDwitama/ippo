package com.bintangdwitama.ippo

import android.app.UiModeManager
import android.content.Context
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                if (call.method == "setNightMode") {
                    setNightMode(call.arguments as? String)
                    result.success(null)
                } else {
                    result.notImplemented()
                }
            }
    }

    /**
     * Tells the system whether the app is light or dark, so that the
     * launch screen, which the system draws before the app runs, matches
     * the appearance chosen in the app. The system remembers it.
     *
     * [mode] is "light", "dark" or "system". Before Android 12 there is
     * no such setting and the launch screen follows the phone.
     */
    private fun setNightMode(mode: String?) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.S) return
        val manager = getSystemService(Context.UI_MODE_SERVICE) as UiModeManager
        manager.setApplicationNightMode(
            when (mode) {
                "light" -> UiModeManager.MODE_NIGHT_NO
                "dark" -> UiModeManager.MODE_NIGHT_YES
                // Anything but yes or no removes the app's own setting,
                // so it follows the phone again.
                else -> UiModeManager.MODE_NIGHT_AUTO
            },
        )
    }

    private companion object {
        const val CHANNEL = "ippo/launch_appearance"
    }
}
