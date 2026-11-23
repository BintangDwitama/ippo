package com.bintangdwitama.ippo

import android.app.UiModeManager
import android.content.Context
import android.content.Intent
import android.os.Build
import android.provider.Settings
import android.speech.tts.TextToSpeech
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
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SPEECH_CHANNEL)
            .setMethodCallHandler { call, result ->
                if (call.method == "openVoiceDownload") {
                    result.success(openVoiceDownload())
                } else {
                    result.notImplemented()
                }
            }
    }

    /**
     * Opens the speech engine's screen for downloading voice data, and
     * says whether it could be opened. The engine in use is tried first,
     * so a phone with two engines goes to the right one; then any engine.
     */
    private fun openVoiceDownload(): Boolean {
        val engine = Settings.Secure.getString(contentResolver, "tts_default_synth")
        val attempts = listOfNotNull(
            engine?.takeIf { it.isNotBlank() }?.let { installIntent().setPackage(it) },
            installIntent(),
        )
        for (intent in attempts) {
            try {
                startActivity(intent)
                return true
            } catch (e: Exception) {
                // No such screen in this engine, or not allowed: try the next.
            }
        }
        return false
    }

    private fun installIntent(): Intent =
        Intent(TextToSpeech.Engine.ACTION_INSTALL_TTS_DATA)
            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)

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
        const val SPEECH_CHANNEL = "ippo/speech_setup"
    }
}
