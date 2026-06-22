package com.example.zo_app_blocker_demo

import android.app.admin.DevicePolicyManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.zo_app_blocker_demo/device_admin"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val dpm = getSystemService(Context.DEVICE_POLICY_SERVICE) as DevicePolicyManager
        val adminComponent = ComponentName(this, MyAdminReceiver::class.java)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {

                // ── FIX: Send the device to the home screen ──────────────────
                // Called by the block-screen overlay's Exit button so that the
                // blocked app is no longer in the foreground.  Without this the
                // monitoring service immediately re-triggers the overlay after
                // onDismiss() is called, causing an infinite loop.
                "goHome" -> {
                    val intent = Intent(Intent.ACTION_MAIN).apply {
                        addCategory(Intent.CATEGORY_HOME)
                        flags = Intent.FLAG_ACTIVITY_NEW_TASK
                    }
                    applicationContext.startActivity(intent)
                    result.success(null)
                }

                "isDeviceOwner" -> result.success(dpm.isDeviceOwnerApp(packageName))

                "blockUninstall" -> {
                    try {
                        dpm.setUninstallBlocked(adminComponent, packageName, true)
                        result.success(true)
                    } catch (e: SecurityException) {
                        result.error("NOT_OWNER", "Requires Device Owner mode.", e.message)
                    }
                }

                "allowUninstallTemporarily" -> {
                    try {
                        dpm.setUninstallBlocked(adminComponent, packageName, false)
                        result.success(true)
                    } catch (e: SecurityException) {
                        result.error("NOT_OWNER", "Requires Device Owner mode.", e.message)
                    }
                }

                "isDeviceAdminActive" -> result.success(dpm.isAdminActive(adminComponent))

                "requestDeviceAdmin" -> {
                    val intent = Intent(DevicePolicyManager.ACTION_ADD_DEVICE_ADMIN).apply {
                        putExtra(DevicePolicyManager.EXTRA_DEVICE_ADMIN, adminComponent)
                        putExtra(
                            DevicePolicyManager.EXTRA_ADD_EXPLANATION,
                            "This stops the app from being uninstalled in one tap."
                        )
                    }
                    startActivity(intent)
                    result.success(null)
                }

                "setUninstallBlocked" -> {
                    try {
                        dpm.setUninstallBlocked(adminComponent, packageName, true)
                        result.success(true)
                    } catch (e: SecurityException) {
                        result.error("NOT_OWNER", "Requires Device Owner mode.", e.message)
                    }
                }

                else -> result.notImplemented()
            }
        }
    }
}