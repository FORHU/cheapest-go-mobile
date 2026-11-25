package com.forhu.airanggo

import android.app.ActivityManager
import android.content.Context
import android.os.Build
import androidx.appcompat.app.AppCompatDelegate
import androidx.core.os.LocaleListCompat
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

// FlutterFragmentActivity, not FlutterActivity: Stripe's payment sheet is an Android
// fragment, and it has nowhere to attach to a plain FlutterActivity — the sheet never opens
// and the SDK throws at the moment a traveller taps Pay.
class MainActivity : FlutterFragmentActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "cheapest_go/device")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    // What the map's device ladder needs to pick the 3D or the lite map.
                    "mapCapabilities" -> result.success(mapCapabilities())

                    // The app's language, handed to Android so the screens Android draws
                    // follow it. See `shared/lib/platform_locale.dart` for why the sheet
                    // needs this and an Activity-level Configuration override would not do.
                    "setLocale" -> {
                        val tag = call.argument<String>("languageTag")
                        if (tag.isNullOrBlank()) {
                            result.error("no-language-tag", "setLocale needs a languageTag.", null)
                        } else {
                            AppCompatDelegate.setApplicationLocales(
                                LocaleListCompat.forLanguageTags(tag)
                            )
                            result.success(null)
                        }
                    }

                    else -> result.notImplemented()
                }
            }
    }

    private fun mapCapabilities(): Map<String, Any> {
        val activityManager = getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
        val memory = ActivityManager.MemoryInfo()
        activityManager.getMemoryInfo(memory)
        return mapOf(
            "totalRamMb" to (memory.totalMem / (1024 * 1024)).toInt(),
            "lowRam" to activityManager.isLowRamDevice,
            "sdk" to Build.VERSION.SDK_INT,
        )
    }
}
