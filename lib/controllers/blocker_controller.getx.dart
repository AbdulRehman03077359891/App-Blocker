import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:zo_app_blocker/zo_app_blocker.dart';
import 'package:zo_app_blocker_demo/main.dart';

class BlockerController extends GetxController with WidgetsBindingObserver {
  final plugin = ZoAppBlocker.instance;

  // Observable State
  var usageStatsStatus = 'Unknown'.obs;
  var overlayStatus = 'Unknown'.obs;
  var blockedApps = <Map<String, dynamic>>[].obs;
  var timeLimits = <AppTimeLimit>[].obs;
  var adminActive = false.obs;
  var isDeviceOwner = false.obs;

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    plugin.setNotificationConfig(
      notificationBannerTitle: 'Stop Right There!',
      notificationBannerDescription: 'You blocked this app. Get back to work!',
    );
    refreshAll();
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      refreshAdminStatus();
      checkPermission();
    }
  }

  Future<void> refreshAll() async {
    await Future.wait([
      refreshAdminStatus(),
      checkPermission(),
      loadBlockedApps(),
      loadTimeLimits(),
    ]);
  }

  Future<void> refreshAdminStatus() async {
    adminActive.value = await DeviceAdminProtection.isActive();
    isDeviceOwner.value = await DeviceAdminProtection.isDeviceOwner();
  }

  Future<void> checkPermission() async {
    usageStatsStatus.value = await plugin.checkUsageStatsPermission();
    overlayStatus.value = await plugin.checkOverlayPermission();
  }

  Future<void> loadBlockedApps() async {
    blockedApps.value = await plugin.getBlockedApps();
  }

  Future<void> loadTimeLimits() async {
    timeLimits.value = await plugin.getAppTimeLimits();
  }

  Future<void> requestPermissions() async {
    if (Platform.isAndroid) {
      await plugin.requestNotificationPermission();
      final notifStatus = await plugin.checkNotificationPermission();
      if (notifStatus != 'granted') {
        Get.snackbar(
          'Permission Required',
          'Notification permission is required for the background service.',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    }
    await plugin.requestUsageStatsPermission();
    await plugin.requestOverlayPermission();
    await checkPermission();
  }

  Future<void> blockApp(String packageName) async {
    await plugin.blockApps([packageName]);
    await loadBlockedApps();
  }

  Future<void> unblockApp(String packageName) async {
    await plugin.unblockApps([packageName]);
    await loadBlockedApps();
  }

  Future<void> unblockAllApps() async {
    await plugin.unblockAll();
    await loadBlockedApps();
  }

  Future<void> clearActivityLog() async {
    await plugin.clearBlockActivityLog();
  }
}
