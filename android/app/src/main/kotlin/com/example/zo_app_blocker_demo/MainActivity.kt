package com.example.zo_app_blocker_demo

import android.app.admin.DevicePolicyManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import androidx.core.content.ContextCompat
import android.content.BroadcastReceiver
import android.content.IntentFilter
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.zo_app_blocker_demo/device_admin"
    private val GO_HOME_ACTION = "com.example.zo_app_blocker_demo.GO_HOME"

    // ── ADD: Static companion so any part of the process can fire HOME ──────
    companion object {
        fun goHome(context: Context) {
            val intent = Intent(Intent.ACTION_MAIN).apply {
                addCategory(Intent.CATEGORY_HOME)
                flags = Intent.FLAG_ACTIVITY_NEW_TASK
            }
            context.startActivity(intent)
        }
    }

    // ── ADD: BroadcastReceiver that works across isolate boundaries ──────────
    private val goHomeReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context, intent: Intent) {
            if (intent.action == GO_HOME_ACTION) {
                goHome(applicationContext)
            }
        }
    }

    // ── ADD: Register and unregister the receiver with the activity ──────────
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        ContextCompat.registerReceiver(
            this,
            goHomeReceiver,
            IntentFilter(GO_HOME_ACTION),
            ContextCompat.RECEIVER_NOT_EXPORTED
        )
    }

    override fun onDestroy() {
        super.onDestroy()
        unregisterReceiver(goHomeReceiver)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val dpm = getSystemService(Context.DEVICE_POLICY_SERVICE) as DevicePolicyManager
        val adminComponent = ComponentName(this, MyAdminReceiver::class.java)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {

                // ── KEEP existing goHome but now it also fires the broadcast
                //    so the BroadcastReceiver handles it if MethodChannel fails ─
                "goHome" -> {
                    val intent = Intent(Intent.ACTION_MAIN).apply {
                        addCategory(Intent.CATEGORY_HOME)
                        flags = Intent.FLAG_ACTIVITY_NEW_TASK
                    }
                    context.startActivity(intent)
                    result.success(null)
                }

                // ── ADD: A broadcast-based goHome the block screen isolate can reach
                "goHomeBroadcast" -> {
                    sendBroadcast(Intent(GO_HOME_ACTION).setPackage(packageName))
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