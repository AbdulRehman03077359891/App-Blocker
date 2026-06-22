package com.example.zo_app_blocker_demo

import android.app.admin.DeviceAdminReceiver
import android.content.Context
import android.content.Intent
import android.widget.Toast

class MyAdminReceiver : DeviceAdminReceiver() {

    override fun onEnabled(context: Context, intent: Intent) {
        super.onEnabled(context, intent)
        Toast.makeText(context, "Device Admin Enabled", Toast.LENGTH_SHORT).show()
    }

    override fun onDisabled(context: Context, intent: Intent) {
        super.onDisabled(context, intent)
        Toast.makeText(context, "Device Admin Disabled", Toast.LENGTH_SHORT).show()
    }
    
    // Optional: You can intercept the user trying to disable it here and show a warning
    override fun onDisableRequested(context: Context, intent: Intent): CharSequence {
        return "Disabling this will turn off app blocking. Are you sure?"
    }
}