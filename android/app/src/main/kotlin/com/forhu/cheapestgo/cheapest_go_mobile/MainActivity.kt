package com.forhu.cheapestgo.cheapest_go_mobile

import android.app.ActivityManager
import android.content.Context
import android.os.Build
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

// FlutterFragmentActivity, not FlutterActivity: Stripe's payment sheet is an Android
// fragment, and it has nowhere to attach to a plain FlutterActivity — the sheet never opens
// and the SDK throws at the moment a traveller taps Pay.
class MainActivity : FlutterFragmentActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // What the map's device ladder needs to pick the 3D or the lite map.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "cheapest_go/device")
            .setMethodCallHandler { call, result ->
                if (call.method != "mapCapabilities") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                val activityManager =
                    getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
                val memory = ActivityManager.MemoryInfo()
                activityManager.getMemoryInfo(memory)
                result.success(
                    mapOf(
                        "totalRamMb" to (memory.totalMem / (1024 * 1024)).toInt(),
                        "lowRam" to activityManager.isLowRamDevice,
                        "sdk" to Build.VERSION.SDK_INT,
                    )
                )
            }
    }
}
