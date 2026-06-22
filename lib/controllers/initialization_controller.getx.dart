import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart'; // Import permission handler
import 'package:zo_app_blocker_demo/controllers/blocker_controller.getx.dart';
import 'package:zo_app_blocker_demo/Screens/pin_password_screen.dart';

class InitializationController extends GetxController {
  final RxBool isInitialized = false.obs;
  final RxString loadingStatus = 'Starting app...'.obs;

  @override
  void onReady() {
    super.onReady();
    initializeApp();
  }

  Future<void> initializeApp() async {
    try {
      // Step 1: Request required permissions directly from the app
      loadingStatus.value = 'Checking system permissions...';
      await _requestAppPermissions();

      // Step 2: Ensure core blocker engine is ready
      loadingStatus.value = 'Initializing background blockers...';
      final blockerController = Get.find<BlockerController>();
      await blockerController.refreshAll();
      await blockerController.loadTimeLimits();

      // Step 3: Check SharedPreferences for the User PIN
      loadingStatus.value = 'Checking security settings...';
      final prefs = await SharedPreferences.getInstance();
      final hasPin = prefs.containsKey('user_pin');

      loadingStatus.value = 'Verifying setup status...';
      await Future.delayed(const Duration(milliseconds: 500));

      isInitialized.value = true;
      Get.off(() => PinScreen(isCreating: !hasPin));
    } catch (e) {
      loadingStatus.value = 'Initialization failed! Retrying...';
      Get.snackbar(
        'Initialization Error',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  // Native Permission Request Logic
  Future<void> _requestAppPermissions() async {
    // 1. Request 'Draw Over Other Apps' (Crucial for App Blockers to prevent OS termination)
    if (!await Permission.systemAlertWindow.isGranted) {
      loadingStatus.value = 'Please grant Overlay permission...';
      await Permission.systemAlertWindow.request();
    }

    // 2. Request 'Bypass Battery Optimizations' (Stops TECNO/Infinix from aggressive killing)
    if (!await Permission.ignoreBatteryOptimizations.isGranted) {
      loadingStatus.value = 'Please disable Battery Optimizations...';
      await Permission.ignoreBatteryOptimizations.request();
    }
  }
}
// import 'package:get/get.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:zo_app_blocker_demo/controllers/blocker_controller.getx.dart';
// import 'package:zo_app_blocker_demo/Screens/pin_password_screen.dart'; // Ensure this path matches

// class InitializationController extends GetxController {
//   final RxBool isInitialized = false.obs;
//   final RxString loadingStatus = 'Starting app...'.obs;

//   @override
//   void onReady() {
//     super.onReady();
//     initializeApp();
//   }

//   Future<void> initializeApp() async {
//     try {
//       // Step 1: Ensure core controller is fully spun up and checked
//       loadingStatus.value = 'Initializing background blockers...';
//       final blockerController = Get.find<BlockerController>();
//       await blockerController.refreshAll();
//       await blockerController.loadTimeLimits();

//       // Step 2: Check SharedPreferences for the User PIN
//       loadingStatus.value = 'Checking security settings...';
//       final prefs = await SharedPreferences.getInstance();
//       final hasPin = prefs.containsKey('user_pin');

//       // Step 3: Final validation checks
//       loadingStatus.value = 'Verifying setup status...';
//       await Future.delayed(
//         const Duration(milliseconds: 500),
//       ); // Brief pause for UX

//       // Mark initialization as flawless
//       isInitialized.value = true;

//       // Navigate to PinScreen based on whether they have a PIN or not
//       Get.off(() => PinScreen(isCreating: !hasPin));
//     } catch (e) {
//       loadingStatus.value = 'Initialization failed! Retrying...';
//       // Use GetX native snackbar since we don't have BuildContext here
//       Get.snackbar(
//         'Initialization Error',
//         e.toString(),
//         snackPosition: SnackPosition.BOTTOM,
//       );
//     }
//   }
// }
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:zo_app_blocker_demo/controllers/blocker_controller.getx.dart';
// import 'package:zo_app_blocker_demo/screens/home_screen.dart';

// class InitializationController extends GetxController {
//   final RxBool isInitialized = false.obs;
//   final RxString loadingStatus = 'Starting app...'.obs;

//   @override
//   void onReady() {
//     super.onReady();
//     initializeApp();
//   }

//   Future<void> initializeApp() async {
//     try {
//       // Step 1: Simulate or check local storage/shared preferences setup
//       loadingStatus.value = 'Loading configuration...';
//       await Future.delayed(const Duration(seconds: 1));

//       // Step 2: Ensure core controller is fully spun up and checked
//       loadingStatus.value = 'Initializing background blockers...';

//       // We can grab our pre-injected BlockerController safely using Get.find()
//       final blockerController = Get.find<BlockerController>();

//       // Force it to load its background processes/configs
//       await blockerController.refreshAll();
//       await blockerController.loadTimeLimits();

//       // Step 3: Final validation checks
//       loadingStatus.value = 'Verifying setup status...';
//       await Future.delayed(const Duration(milliseconds: 500));

//       // Mark initialization as flawless
//       isInitialized.value = true;

//       // Navigate to HomeScreen and wipe the splash screen out of the navigation stack
//       Get.off(() => const HomeScreen());
//     } catch (e) {
//       loadingStatus.value = 'Initialization failed! Retrying...';
//       SnackBar(content: Text('Initialization Error: $e'));
//       // Optional: Add recovery logic or error dialog triggers here
//     }
//   }
// }
