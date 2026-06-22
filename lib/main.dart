import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:zo_app_blocker/zo_app_blocker.dart';

import 'package:zo_app_blocker_demo/app_bindings.dart'; // Make sure this path is correct
import 'package:zo_app_blocker_demo/screens/initialization_screen.dart'; // Make sure this path is correct
import 'package:zo_app_blocker_demo/Screens/blocked_screen.dart';

Future<void> main() async {
  // 1. Initialize Flutter bindings
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Initialize low-level plugins
  ZoAppBlocker.instance.initialize(blockScreenCallback: onBlockScreenRequested);

  if (await DeviceAdminProtection.isDeviceOwner()) {
    await DeviceAdminProtection.blockUninstall();
  }

  // 3. Run the app
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Zo App Blocker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      // Inject global bindings (BlockerController, HomeController)
      initialBinding: AppBindings(),

      // Start the app directly on the loading screen.
      // The InitializationController will take over and route to PinScreen.
      home: const InitializationScreen(),
    );
  }
}

// --- KEEP YOUR EXISTING DEVICE ADMIN PROTECTION CLASS BELOW ---
class DeviceAdminProtection {
  static const _channel = MethodChannel(
    'com.example.zo_app_blocker_demo/device_admin',
  );

  static Future<bool> isActive() async =>
      await _channel.invokeMethod<bool>('isDeviceAdminActive') ?? false;

  static Future<void> requestActivation() =>
      _channel.invokeMethod('requestDeviceAdmin');

  static Future<bool> isDeviceOwner() async =>
      await _channel.invokeMethod<bool>('isDeviceOwner') ?? false;

  static Future<bool> blockUninstall() async {
    try {
      return await _channel.invokeMethod<bool>('blockUninstall') ?? false;
    } on PlatformException {
      return false;
    }
  }

  static Future<bool> allowUninstallTemporarily() async {
    try {
      return await _channel.invokeMethod<bool>('allowUninstallTemporarily') ??
          false;
    } on PlatformException {
      return false;
    }
  }
}
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:get/get.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:zo_app_blocker/zo_app_blocker.dart';
// import 'package:zo_app_blocker_demo/Screens/blocked_screen.dart';
// import 'package:zo_app_blocker_demo/Screens/pin_password_screen.dart';

// Future<void> main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   ZoAppBlocker.instance.initialize(blockScreenCallback: onBlockScreenRequested);

//   if (await DeviceAdminProtection.isDeviceOwner()) {
//     await DeviceAdminProtection.blockUninstall();
//   }

//   runApp(const MyApp());
// }

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   Future<bool> _checkHasPin() async {
//     final prefs = await SharedPreferences.getInstance();
//     return prefs.containsKey('user_pin');
//   }

//   @override
//   Widget build(BuildContext context) {
//     return GetMaterialApp(
//       title: 'Zo App Blocker',
//       theme: ThemeData(
//         colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
//         useMaterial3: true,
//       ),
//       home: FutureBuilder<bool>(
//         future: _checkHasPin(),
//         builder: (context, snapshot) {
//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return const Scaffold(
//               body: Center(child: CircularProgressIndicator()),
//             );
//           }
//           final hasPin = snapshot.data ?? false;
//           return PinScreen(isCreating: !hasPin);
//         },
//       ),
//     );
//   }
// }

// class DeviceAdminProtection {
//   static const _channel = MethodChannel(
//     'com.example.zo_app_blocker_demo/device_admin',
//   );

//   static Future<bool> isActive() async =>
//       await _channel.invokeMethod<bool>('isDeviceAdminActive') ?? false;

//   static Future<void> requestActivation() =>
//       _channel.invokeMethod('requestDeviceAdmin');

//   static Future<bool> isDeviceOwner() async =>
//       await _channel.invokeMethod<bool>('isDeviceOwner') ?? false;

//   static Future<bool> blockUninstall() async {
//     try {
//       return await _channel.invokeMethod<bool>('blockUninstall') ?? false;
//     } on PlatformException {
//       return false;
//     }
//   }

//   static Future<bool> allowUninstallTemporarily() async {
//     try {
//       return await _channel.invokeMethod<bool>('allowUninstallTemporarily') ??
//           false;
//     } on PlatformException {
//       return false;
//     }
//   }
// }

// class HomeScreen extends StatelessWidget {
//   const HomeScreen({super.key});

//   Future<bool> _askForPin(BuildContext context) async {
//     final controller = TextEditingController();
//     final result = await showDialog<bool>(
//       context: context,
//       builder: (dialogContext) {
//         String error = '';
//         return StatefulBuilder(
//           builder: (context, setDialogState) {
//             void submit() {
//               if (controller.text == '459278') {
//                 Navigator.of(dialogContext).pop(true);
//               } else {
//                 setDialogState(() => error = 'Incorrect PIN');
//               }
//             }

//             return AlertDialog(
//               title: const Text('Enter PIN'),
//               content: TextField(
//                 controller: controller,
//                 keyboardType: TextInputType.number,
//                 obscureText: true,
//                 autofocus: true,
//                 decoration: InputDecoration(
//                   hintText: 'Enter PIN',
//                   errorText: error.isNotEmpty ? error : null,
//                 ),
//                 onSubmitted: (_) => submit(),
//               ),
//               actions: [
//                 TextButton(
//                   onPressed: () => Navigator.of(dialogContext).pop(false),
//                   child: const Text('Cancel'),
//                 ),
//                 FilledButton(onPressed: submit, child: const Text('Confirm')),
//               ],
//             );
//           },
//         );
//       },
//     );
//     return result ?? false;
//   }

//   Future<void> _selectAndBlockApps(BuildContext context, BlockerController controller) async {
//     try {
//       final apps = await controller.plugin.getApps();
//       if (Platform.isIOS) {
//         controller.loadBlockedApps();
//         return;
//       }
//       if (apps.isEmpty || !context.mounted) return;
      
//       showModalBottomSheet(
//         context: context,
//         builder: (context) {
//           return Column(
//             children: [
//               const Padding(
//                 padding: EdgeInsets.all(16.0),
//                 child: Text(
//                   'Select an app to block',
//                   style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//                 ),
//               ),
//               Expanded(
//                 child: ListView.builder(
//                   itemCount: apps.length,
//                   itemBuilder: (context, index) {
//                     final app = apps[index];
//                     return ListTile(
//                       leading: AppIcon(packageName: app['packageName'] ?? ''),
//                       title: Text(app['appName'] ?? ''),
//                       subtitle: Text(app['packageName'] ?? ''),
//                       onTap: () async {
//                         final nav = Navigator.of(context);
//                         final scaffold = ScaffoldMessenger.of(context);
                        
//                         await controller.blockApp(app['packageName']);
                        
//                         if (!context.mounted) return;
//                         nav.pop();
//                         scaffold.showSnackBar(
//                           SnackBar(content: Text('Blocked ${app['appName']}')),
//                         );
//                       },
//                     );
//                   },
//                 ),
//               ),
//             ],
//           );
//         },
//       );
//     } catch (e) {
//       if (!context.mounted) return;
//       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
//     }
//   }

//   Future<void> _showSetTimeLimitSheet(BuildContext context, BlockerController controller) async {
//     final apps = await controller.plugin.getApps();
//     if (apps.isEmpty || !context.mounted) return;
//     showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       builder: (ctx) => SetTimeLimitSheet(apps: apps, plugin: controller.plugin),
//     ).then((_) => controller.loadTimeLimits());
//   }

//   Future<void> _showActivityLog(BuildContext context, BlockerController controller) async {
//     final log = await controller.plugin.getBlockActivityLog();
//     if (!context.mounted) return;
    
//     showModalBottomSheet(
//       context: context,
//       builder: (context) {
//         return Column(
//           children: [
//             Padding(
//               padding: const EdgeInsets.all(16.0),
//               child: Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   const Text(
//                     'Block Activity Log',
//                     style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//                   ),
//                   TextButton(
//                     onPressed: () async {
//                       await controller.clearActivityLog();
//                       if (context.mounted) {
//                         Navigator.pop(context);
//                         _showActivityLog(context, controller);
//                       }
//                     },
//                     child: const Text('Clear'),
//                   ),
//                 ],
//               ),
//             ),
//             Expanded(
//               child: log.isEmpty
//                   ? const Center(child: Text('No activity yet.'))
//                   : ListView.builder(
//                       itemCount: log.length,
//                       itemBuilder: (context, index) {
//                         final entry = log[index];
//                         final packageName = entry['packageName'] as String;
//                         final timestamp = entry['timestamp'] as int;
//                         final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
//                         return ListTile(
//                           leading: AppIcon(packageName: packageName, size: 32),
//                           title: Text(packageName),
//                           subtitle: Text('${date.toLocal()}'.split('.')[0]),
//                         );
//                       },
//                     ),
//             ),
//           ],
//         );
//       },
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     // Inject the controller when HomeScreen is loaded
//     final controller = Get.put(BlockerController());

//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Zo App Blocker'),
//         backgroundColor: Theme.of(context).colorScheme.inversePrimary,
//       ),
//       body: RefreshIndicator(
//         onRefresh: controller.refreshAll,
//         child: Obx(() {
//           final permissionsOk = controller.usageStatsStatus.value == 'granted' && 
//                                 controller.overlayStatus.value == 'granted';

//           return ListView(
//             padding: const EdgeInsets.all(16),
//             children: [
//               SectionCard(
//                 title: 'Permissions',
//                 children: [
//                   if (!permissionsOk)
//                     Container(
//                       margin: const EdgeInsets.only(bottom: 8),
//                       padding: const EdgeInsets.all(12),
//                       decoration: BoxDecoration(
//                         color: Colors.orange.shade50,
//                         borderRadius: BorderRadius.circular(8),
//                         border: Border.all(color: Colors.orange.shade300),
//                       ),
//                       child: Row(
//                         children: [
//                           Icon(
//                             Icons.warning_amber_rounded,
//                             color: Colors.orange.shade700,
//                           ),
//                           const SizedBox(width: 8),
//                           const Expanded(
//                             child: Text(
//                               'Required permissions are missing — blocking '
//                               'will not work until you grant them.',
//                               style: TextStyle(fontSize: 13),
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ListTile(
//                     dense: true,
//                     leading: Icon(
//                       permissionsOk ? Icons.check_circle : Icons.warning_amber_rounded,
//                       color: permissionsOk ? Colors.green : Colors.orange,
//                     ),
//                     title: Text(
//                       'Usage Stats: ${controller.usageStatsStatus.value}\nOverlay: ${controller.overlayStatus.value}',
//                     ),
//                   ),
//                   const SizedBox(height: 4),
//                   FilledButton.icon(
//                     onPressed: controller.requestPermissions,
//                     icon: const Icon(Icons.security),
//                     label: const Text('Grant Permissions'),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 16),
//               SectionCard(
//                 title: '🛡️ Uninstall Protection',
//                 children: [
//                   Row(
//                     children: [
//                       Icon(
//                         controller.adminActive.value ? Icons.verified_user : Icons.gpp_maybe,
//                         color: controller.adminActive.value ? Colors.green : Colors.orange,
//                       ),
//                       const SizedBox(width: 8),
//                       Expanded(
//                         child: Text(
//                           controller.adminActive.value
//                               ? 'Active — must deactivate admin in Settings before uninstalling.'
//                               : 'Off — tap to enable.',
//                         ),
//                       ),
//                     ],
//                   ),
//                   const SizedBox(height: 12),
//                   if (!controller.adminActive.value)
//                     FilledButton.icon(
//                       onPressed: () => DeviceAdminProtection.requestActivation(),
//                       icon: const Icon(Icons.security),
//                       label: const Text('Enable Protection'),
//                       style: FilledButton.styleFrom(
//                         backgroundColor: Colors.red.shade700,
//                       ),
//                     ),
//                   if (controller.isDeviceOwner.value) ...[
//                     const SizedBox(height: 8),
//                     FilledButton.icon(
//                       onPressed: () async {
//                         final ok = await _askForPin(context);
//                         if (ok) {
//                           await DeviceAdminProtection.allowUninstallTemporarily();
//                           if (!context.mounted) return;
//                           ScaffoldMessenger.of(context).showSnackBar(
//                             const SnackBar(
//                               content: Text(
//                                 'Uninstall allowed — re-locks next time the app opens.',
//                               ),
//                             ),
//                           );
//                         }
//                       },
//                       icon: const Icon(Icons.lock_open),
//                       label: const Text('Allow Uninstall (PIN required)'),
//                     ),
//                   ] else
//                     Padding(
//                       padding: const EdgeInsets.only(top: 8),
//                       child: Text(
//                         'Full uninstall blocking requires Device Owner mode (see adb setup).',
//                         style: TextStyle(
//                           fontSize: 11,
//                           color: Colors.grey.shade600,
//                         ),
//                       ),
//                     ),
//                 ],
//               ),
//               const SizedBox(height: 16),
//               SectionCard(
//                 title: 'App Blocking',
//                 children: [
//                   Row(
//                     children: [
//                       Expanded(
//                         child: FilledButton.icon(
//                           onPressed: () => _selectAndBlockApps(context, controller),
//                           icon: const Icon(Icons.block),
//                           label: const Text('Block an App'),
//                         ),
//                       ),
//                       const SizedBox(width: 8),
//                       Expanded(
//                         child: OutlinedButton.icon(
//                           onPressed: () async {
//                             await controller.unblockAllApps();
//                             if (!context.mounted) return;
//                             ScaffoldMessenger.of(context).showSnackBar(
//                               const SnackBar(content: Text('All apps unblocked')),
//                             );
//                           },
//                           icon: const Icon(Icons.lock_open),
//                           label: const Text('Unblock All'),
//                         ),
//                       ),
//                     ],
//                   ),
//                   const SizedBox(height: 12),
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       Text(
//                         'Blocked Apps (${controller.blockedApps.length})',
//                         style: const TextStyle(fontWeight: FontWeight.w600),
//                       ),
//                       TextButton(
//                         onPressed: () => _showActivityLog(context, controller),
//                         child: const Text('Activity Log'),
//                       ),
//                     ],
//                   ),
//                   if (controller.blockedApps.isEmpty)
//                     const Padding(
//                       padding: EdgeInsets.symmetric(vertical: 8),
//                       child: Text(
//                         'No apps currently blocked.',
//                         style: TextStyle(color: Colors.grey),
//                       ),
//                     )
//                   else
//                     ...controller.blockedApps.map(
//                       (app) => ListTile(
//                         dense: true,
//                         contentPadding: EdgeInsets.zero,
//                         leading: AppIcon(
//                           packageName: app['packageName'] ?? '',
//                           size: 36,
//                         ),
//                         title: Text(app['appName'] ?? 'Unknown'),
//                         subtitle: Text(
//                           app['packageName'] ?? '',
//                           style: const TextStyle(fontSize: 11),
//                         ),
//                         trailing: IconButton(
//                           icon: const Icon(
//                             Icons.delete_outline,
//                             color: Colors.red,
//                           ),
//                           onPressed: () => controller.unblockApp(app['packageName'] as String),
//                         ),
//                       ),
//                     ),
//                 ],
//               ),
//               const SizedBox(height: 16),
//               SectionCard(
//                 title: '⏱  Daily Time Limits',
//                 children: [
//                   const Text(
//                     'Set how many minutes per day a user can spend in an app. '
//                     'When the budget hits 0, the app is blocked automatically.',
//                     style: TextStyle(fontSize: 13, color: Colors.black54),
//                   ),
//                   const SizedBox(height: 12),
//                   FilledButton.icon(
//                     onPressed: () => _showSetTimeLimitSheet(context, controller),
//                     icon: const Icon(Icons.timer),
//                     label: const Text('Set Time Limit for an App'),
//                   ),
//                   const SizedBox(height: 8),
//                   OutlinedButton.icon(
//                     onPressed: controller.loadTimeLimits,
//                     icon: const Icon(Icons.refresh),
//                     label: const Text('Refresh Usage Stats'),
//                   ),
//                   const SizedBox(height: 12),
//                   if (controller.timeLimits.isEmpty)
//                     const Padding(
//                       padding: EdgeInsets.symmetric(vertical: 8),
//                       child: Text(
//                         'No time limits configured.',
//                         style: TextStyle(color: Colors.grey),
//                       ),
//                     )
//                   else
//                     ...controller.timeLimits.map(
//                       (limit) => TimeLimitTile(
//                         limit: limit,
//                         plugin: controller.plugin,
//                         onChanged: controller.loadTimeLimits,
//                       ),
//                     ),
//                 ],
//               ),
//             ],
//           );
//         }),
//       ),
//     );
//   }
// }

// import 'dart:async';
// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:zo_app_blocker/zo_app_blocker.dart';

// @pragma('vm:entry-point')
// void onBlockScreenRequested() {
//   ZoBlockScreenRunner.run(
//     builder: (blockContext) {
//       final plugin = ZoAppBlocker.instance;

//       // ── FIX 1 ─────────────────────────────────────────────────────────────
//       // These MUST live outside StatefulBuilder's builder so they are NOT
//       // recreated on every setState() call.  Previously they were inside the
//       // builder, which meant:
//       //   • pinController was replaced with a fresh, empty one on every rebuild
//       //   • errorMessage was reset to '' immediately after being set, so the
//       //     error text could never actually render.
//       // ──────────────────────────────────────────────────────────────────────
//       final pinController = TextEditingController();
//       String errorMessage = '';
//       bool isProcessing = false;

//       return StatefulBuilder(
//         builder: (context, setState) {
//           // ── FIX 2 ───────────────────────────────────────────────────────────
//           // Exit used to call only blockContext.onDismiss(), which removes the
//           // overlay but leaves the blocked app in the foreground.  The service
//           // immediately detects it and re-shows the overlay — infinite loop.
//           // Solution: navigate to the home screen first so the blocked app is
//           // no longer foreground, then dismiss the overlay.
//           // ────────────────────────────────────────────────────────────────────
//           Future<void> exitToHome() async {
//             setState(() => isProcessing = true);
//             try {
//               await const MethodChannel(
//                 'com.example.zo_app_blocker_demo/device_admin',
//               ).invokeMethod('goHome');
//             } catch (_) {
//               // goHome may not be reachable in every context; fail silently.
//             }
//             blockContext.onDismiss();
//           }

//           return Scaffold(
//             backgroundColor: Colors.black87,
//             body: Center(
//               child: Padding(
//                 padding: const EdgeInsets.all(24.0),
//                 child: Column(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     if (blockContext.appIcon != null &&
//                         blockContext.appIcon!.isNotEmpty)
//                       Image.memory(
//                         blockContext.appIcon!,
//                         width: 100,
//                         height: 100,
//                       ),
//                     const SizedBox(height: 24),
//                     Text(
//                       '${blockContext.appName ?? 'App'} is Blocked!',
//                       style: const TextStyle(
//                         color: Colors.white,
//                         fontSize: 24,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                     const SizedBox(height: 12),
//                     const Text(
//                       'Enter PIN to unlock.',
//                       style: TextStyle(color: Colors.white70),
//                     ),
//                     const SizedBox(height: 24),
//                     TextField(
//                       controller: pinController,
//                       keyboardType: TextInputType.number,
//                       obscureText: true,
//                       style: const TextStyle(color: Colors.white),
//                       decoration: InputDecoration(
//                         hintText: 'Enter PIN',
//                         hintStyle: const TextStyle(color: Colors.white54),
//                         // errorMessage is now stable across rebuilds (Fix 1)
//                         errorText: errorMessage.isNotEmpty
//                             ? errorMessage
//                             : null,
//                         filled: true,
//                         fillColor: Colors.white12,
//                         border: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(8),
//                         ),
//                       ),
//                     ),
//                     const SizedBox(height: 24),

//                     // Show spinner while a navigation or async op is in progress
//                     // so the user can't double-tap and trigger two dismissals.
//                     if (isProcessing)
//                       const CircularProgressIndicator(color: Colors.white)
//                     else
//                       Row(
//                         mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                         children: [
//                           ElevatedButton.icon(
//                             onPressed: exitToHome,
//                             icon: const Icon(Icons.exit_to_app),
//                             label: const Text('Exit'),
//                           ),
//                           ElevatedButton.icon(
//                             onPressed: () async {
//                               final enteredPin = pinController.text.trim();
//                               if (enteredPin == '459278') {
//                                 setState(() => isProcessing = true);
//                                 final pkg = blockContext.packageName;
//                                 if (pkg != null) {
//                                   await plugin.resetAppUsage(pkg);
//                                 }
//                                 blockContext.onDismiss();
//                               } else {
//                                 // errorMessage persists across rebuilds (Fix 1)
//                                 setState(() {
//                                   errorMessage = 'Incorrect PIN!';
//                                   pinController.clear();
//                                 });
//                               }
//                             },
//                             icon: const Icon(Icons.lock_open),
//                             label: const Text('Unlock'),
//                           ),
//                         ],
//                       ),
//                   ],
//                 ),
//               ),
//             ),
//           );
//         },
//       );
//     },
//   );
// }

// Future<void> main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   ZoAppBlocker.instance.initialize(blockScreenCallback: onBlockScreenRequested);
//   if (await DeviceAdminProtection.isDeviceOwner()) {
//     await DeviceAdminProtection.blockUninstall();
//   }
//   runApp(const MyApp());
// }

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   Future<bool> _checkHasPin() async {
//     final prefs = await SharedPreferences.getInstance();
//     return prefs.containsKey('user_pin');
//   }

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Zo App Blocker',
//       theme: ThemeData(
//         colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
//         useMaterial3: true,
//       ),
//       home: FutureBuilder<bool>(
//         future: _checkHasPin(),
//         builder: (context, snapshot) {
//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return const Scaffold(
//               body: Center(child: CircularProgressIndicator()),
//             );
//           }
//           final hasPin = snapshot.data ?? false;
//           return PinScreen(isCreating: !hasPin);
//         },
//       ),
//     );
//   }
// }

// class PinScreen extends StatefulWidget {
//   final bool isCreating;
//   const PinScreen({super.key, required this.isCreating});

//   @override
//   State<PinScreen> createState() => _PinScreenState();
// }

// class _PinScreenState extends State<PinScreen> {
//   final TextEditingController _pinController = TextEditingController();
//   final String _masterPassword = '459278';
//   String _errorMessage = '';

//   Future<void> _submitPin() async {
//     final prefs = await SharedPreferences.getInstance();
//     final enteredPin = _pinController.text.trim();

//     if (enteredPin.isEmpty) {
//       setState(() => _errorMessage = 'PIN cannot be empty');
//       return;
//     }

//     if (widget.isCreating) {
//       await prefs.setString('user_pin', enteredPin);
//       _navigateToHome();
//     } else {
//       final savedPin = prefs.getString('user_pin');
//       if (enteredPin == savedPin || enteredPin == _masterPassword) {
//         _navigateToHome();
//       } else {
//         setState(() {
//           _errorMessage = 'Incorrect PIN';
//           _pinController.clear();
//         });
//       }
//     }
//   }

//   void _navigateToHome() {
//     Navigator.pushReplacement(
//       context,
//       MaterialPageRoute(builder: (context) => const HomeScreen()),
//     );
//   }

//   @override
//   void dispose() {
//     _pinController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text(widget.isCreating ? 'Create PIN' : 'Enter PIN'),
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(24.0),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Text(
//               widget.isCreating
//                   ? 'Please create a new PIN to secure your app.'
//                   : 'Enter your PIN to unlock.',
//               style: const TextStyle(fontSize: 18),
//               textAlign: TextAlign.center,
//             ),
//             const SizedBox(height: 30),
//             TextField(
//               controller: _pinController,
//               keyboardType: TextInputType.number,
//               obscureText: true,
//               maxLength: 6,
//               decoration: InputDecoration(
//                 border: const OutlineInputBorder(),
//                 labelText: 'PIN',
//                 errorText: _errorMessage.isEmpty ? null : _errorMessage,
//               ),
//               onSubmitted: (_) => _submitPin(),
//             ),
//             const SizedBox(height: 20),
//             ElevatedButton(
//               onPressed: _submitPin,
//               style: ElevatedButton.styleFrom(
//                 minimumSize: const Size.fromHeight(50),
//               ),
//               child: Text(widget.isCreating ? 'Save PIN' : 'Unlock'),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// class DeviceAdminProtection {
//   static const _channel = MethodChannel(
//     'com.example.zo_app_blocker_demo/device_admin',
//   );

//   static Future<bool> isActive() async =>
//       await _channel.invokeMethod<bool>('isDeviceAdminActive') ?? false;

//   static Future<void> requestActivation() =>
//       _channel.invokeMethod('requestDeviceAdmin');

//   static Future<bool> isDeviceOwner() async =>
//       await _channel.invokeMethod<bool>('isDeviceOwner') ?? false;

//   static Future<bool> blockUninstall() async {
//     try {
//       return await _channel.invokeMethod<bool>('blockUninstall') ?? false;
//     } on PlatformException {
//       return false;
//     }
//   }

//   static Future<bool> allowUninstallTemporarily() async {
//     try {
//       return await _channel.invokeMethod<bool>('allowUninstallTemporarily') ??
//           false;
//     } on PlatformException {
//       return false;
//     }
//   }
// }

// class HomeScreen extends StatefulWidget {
//   const HomeScreen({super.key});

//   @override
//   State<HomeScreen> createState() => _HomeScreenState();
// }

// class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
//   final _plugin = ZoAppBlocker.instance;
//   String _usageStatsStatus = 'Unknown';
//   String _overlayStatus = 'Unknown';
//   List<Map<String, dynamic>> _blockedApps = [];
//   List<AppTimeLimit> _timeLimits = [];
//   bool _adminActive = false;
//   bool _isDeviceOwner = false;

//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addObserver(this);

//     _plugin.setNotificationConfig(
//       notificationBannerTitle: 'Stop Right There!',
//       notificationBannerDescription: 'You blocked this app. Get back to work!',
//     );

//     Future.wait([
//       _refreshAdminStatus(),
//       _checkPermission(),
//       _loadBlockedApps(),
//       _loadTimeLimits(),
//     ]);
//   }

//   @override
//   void dispose() {
//     WidgetsBinding.instance.removeObserver(this);
//     super.dispose();
//   }

//   // ── FIX 3 ─────────────────────────────────────────────────────────────────
//   // The original only refreshed admin status on resume.  On a new device the
//   // user grants Usage Stats / Overlay permissions and returns to the app, but
//   // the status strings never updated — so the service kept running without
//   // valid permissions, making blocking unreliable.
//   // ──────────────────────────────────────────────────────────────────────────
//   @override
//   void didChangeAppLifecycleState(AppLifecycleState state) {
//     if (state == AppLifecycleState.resumed) {
//       _refreshAdminStatus();
//       _checkPermission(); // ← added: picks up newly granted permissions
//     }
//   }

//   Future<void> _refreshAdminStatus() async {
//     final active = await DeviceAdminProtection.isActive();
//     final owner = await DeviceAdminProtection.isDeviceOwner();
//     if (mounted) {
//       setState(() {
//         _adminActive = active;
//         _isDeviceOwner = owner;
//       });
//     }
//   }

//   Future<bool> _askForPin(BuildContext context) async {
//     final controller = TextEditingController();
//     final result = await showDialog<bool>(
//       context: context,
//       builder: (dialogContext) {
//         String error = '';
//         return StatefulBuilder(
//           builder: (context, setDialogState) {
//             void submit() {
//               if (controller.text == '459278') {
//                 Navigator.of(dialogContext).pop(true);
//               } else {
//                 setDialogState(() => error = 'Incorrect PIN');
//               }
//             }

//             return AlertDialog(
//               title: const Text('Enter PIN'),
//               content: TextField(
//                 controller: controller,
//                 keyboardType: TextInputType.number,
//                 obscureText: true,
//                 autofocus: true,
//                 decoration: InputDecoration(
//                   hintText: 'Enter PIN',
//                   errorText: error.isNotEmpty ? error : null,
//                 ),
//                 onSubmitted: (_) => submit(),
//               ),
//               actions: [
//                 TextButton(
//                   onPressed: () => Navigator.of(dialogContext).pop(false),
//                   child: const Text('Cancel'),
//                 ),
//                 FilledButton(onPressed: submit, child: const Text('Confirm')),
//               ],
//             );
//           },
//         );
//       },
//     );
//     return result ?? false;
//   }

//   Future<void> _checkPermission() async {
//     final usageStatus = await _plugin.checkUsageStatsPermission();
//     final overlayStatus = await _plugin.checkOverlayPermission();
//     if (mounted) {
//       setState(() {
//         _usageStatsStatus = usageStatus;
//         _overlayStatus = overlayStatus;
//       });
//     }
//   }

//   Future<void> _loadBlockedApps() async {
//     final apps = await _plugin.getBlockedApps();
//     if (mounted) setState(() => _blockedApps = apps);
//   }

//   Future<void> _loadTimeLimits() async {
//     final limits = await _plugin.getAppTimeLimits();
//     if (mounted) setState(() => _timeLimits = limits);
//   }

//   Future<void> _requestPermissions() async {
//     if (Platform.isAndroid) {
//       await _plugin.requestNotificationPermission();
//       final notifStatus = await _plugin.checkNotificationPermission();
//       if (notifStatus != 'granted' && mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Text(
//               'Notification permission is required for the background service.',
//             ),
//           ),
//         );
//       }
//     }
//     await _plugin.requestUsageStatsPermission();
//     await _plugin.requestOverlayPermission();
//     _checkPermission();
//   }

//   Future<void> _selectAndBlockApps() async {
//     try {
//       final apps = await _plugin.getApps();

//       if (Platform.isIOS) {
//         _loadBlockedApps();
//         return;
//       }

//       if (apps.isEmpty || !mounted) return;

//       showModalBottomSheet(
//         context: context,
//         builder: (context) {
//           return Column(
//             children: [
//               const Padding(
//                 padding: EdgeInsets.all(16.0),
//                 child: Text(
//                   'Select an app to block',
//                   style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//                 ),
//               ),
//               Expanded(
//                 child: ListView.builder(
//                   itemCount: apps.length,
//                   itemBuilder: (context, index) {
//                     final app = apps[index];
//                     return ListTile(
//                       leading: AppIcon(packageName: app['packageName'] ?? ''),
//                       title: Text(app['appName'] ?? ''),
//                       subtitle: Text(app['packageName'] ?? ''),
//                       onTap: () async {
//                         final nav = Navigator.of(context);
//                         final scaffold = ScaffoldMessenger.of(context);
//                         await _plugin.blockApps([app['packageName']]);
//                         if (!mounted) return;
//                         nav.pop();
//                         scaffold.showSnackBar(
//                           SnackBar(content: Text('Blocked ${app['appName']}')),
//                         );
//                         _loadBlockedApps();
//                       },
//                     );
//                   },
//                 ),
//               ),
//             ],
//           );
//         },
//       );
//     } catch (e) {
//       if (!mounted) return;
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(SnackBar(content: Text('Error: $e')));
//     }
//   }

//   Future<void> _showSetTimeLimitSheet() async {
//     final apps = await _plugin.getApps();
//     if (apps.isEmpty || !mounted) return;

//     showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       builder: (ctx) => SetTimeLimitSheet(apps: apps, plugin: _plugin),
//     ).then((_) => _loadTimeLimits());
//   }

//   Future<void> _showActivityLog() async {
//     final log = await _plugin.getBlockActivityLog();
//     if (!mounted) return;

//     showModalBottomSheet(
//       context: context,
//       builder: (context) {
//         return Column(
//           children: [
//             Padding(
//               padding: const EdgeInsets.all(16.0),
//               child: Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   const Text(
//                     'Block Activity Log',
//                     style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//                   ),
//                   TextButton(
//                     onPressed: () async {
//                       await _plugin.clearBlockActivityLog();
//                       if (context.mounted) {
//                         Navigator.pop(context);
//                         _showActivityLog();
//                       }
//                     },
//                     child: const Text('Clear'),
//                   ),
//                 ],
//               ),
//             ),
//             Expanded(
//               child: log.isEmpty
//                   ? const Center(child: Text('No activity yet.'))
//                   : ListView.builder(
//                       itemCount: log.length,
//                       itemBuilder: (context, index) {
//                         final entry = log[index];
//                         final packageName = entry['packageName'] as String;
//                         final timestamp = entry['timestamp'] as int;
//                         final date = DateTime.fromMillisecondsSinceEpoch(
//                           timestamp,
//                         );
//                         return ListTile(
//                           leading: AppIcon(packageName: packageName, size: 32),
//                           title: Text(packageName),
//                           subtitle: Text('${date.toLocal()}'.split('.')[0]),
//                         );
//                       },
//                     ),
//             ),
//           ],
//         );
//       },
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     final permissionsOk =
//         _usageStatsStatus == 'granted' && _overlayStatus == 'granted';

//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Zo App Blocker'),
//         backgroundColor: Theme.of(context).colorScheme.inversePrimary,
//       ),
//       body: RefreshIndicator(
//         onRefresh: () async {
//           await _loadBlockedApps();
//           await _loadTimeLimits();
//           await _checkPermission();
//         },
//         child: ListView(
//           padding: const EdgeInsets.all(16),
//           children: [
//             // ── Permission card ──────────────────────────────────────────────
//             SectionCard(
//               title: 'Permissions',
//               children: [
//                 // Prominent warning banner when permissions are missing
//                 if (!permissionsOk)
//                   Container(
//                     margin: const EdgeInsets.only(bottom: 8),
//                     padding: const EdgeInsets.all(12),
//                     decoration: BoxDecoration(
//                       color: Colors.orange.shade50,
//                       borderRadius: BorderRadius.circular(8),
//                       border: Border.all(color: Colors.orange.shade300),
//                     ),
//                     child: Row(
//                       children: [
//                         Icon(
//                           Icons.warning_amber_rounded,
//                           color: Colors.orange.shade700,
//                         ),
//                         const SizedBox(width: 8),
//                         const Expanded(
//                           child: Text(
//                             'Required permissions are missing — blocking '
//                             'will not work until you grant them.',
//                             style: TextStyle(fontSize: 13),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ListTile(
//                   dense: true,
//                   leading: Icon(
//                     permissionsOk
//                         ? Icons.check_circle
//                         : Icons.warning_amber_rounded,
//                     color: permissionsOk ? Colors.green : Colors.orange,
//                   ),
//                   title: Text(
//                     'Usage Stats: $_usageStatsStatus\nOverlay: $_overlayStatus',
//                   ),
//                 ),
//                 const SizedBox(height: 4),
//                 FilledButton.icon(
//                   onPressed: _requestPermissions,
//                   icon: const Icon(Icons.security),
//                   label: const Text('Grant Permissions'),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 16),

//             // ── Uninstall protection card ────────────────────────────────────
//             SectionCard(
//               title: '🛡️ Uninstall Protection',
//               children: [
//                 Row(
//                   children: [
//                     Icon(
//                       _adminActive ? Icons.verified_user : Icons.gpp_maybe,
//                       color: _adminActive ? Colors.green : Colors.orange,
//                     ),
//                     const SizedBox(width: 8),
//                     Expanded(
//                       child: Text(
//                         _adminActive
//                             ? 'Active — must deactivate admin in Settings before uninstalling.'
//                             : 'Off — tap to enable.',
//                       ),
//                     ),
//                   ],
//                 ),
//                 const SizedBox(height: 12),
//                 if (!_adminActive)
//                   FilledButton.icon(
//                     onPressed: () => DeviceAdminProtection.requestActivation(),
//                     icon: const Icon(Icons.security),
//                     label: const Text('Enable Protection'),
//                     style: FilledButton.styleFrom(
//                       backgroundColor: Colors.red.shade700,
//                     ),
//                   ),
//                 if (_isDeviceOwner) ...[
//                   const SizedBox(height: 8),
//                   FilledButton.icon(
//                     onPressed: () async {
//                       final ok = await _askForPin(context);
//                       if (ok) {
//                         await DeviceAdminProtection.allowUninstallTemporarily();
//                         if (!mounted) return;
//                         ScaffoldMessenger.of(context).showSnackBar(
//                           const SnackBar(
//                             content: Text(
//                               'Uninstall allowed — re-locks next time the app opens.',
//                             ),
//                           ),
//                         );
//                       }
//                     },
//                     icon: const Icon(Icons.lock_open),
//                     label: const Text('Allow Uninstall (PIN required)'),
//                   ),
//                 ] else
//                   Padding(
//                     padding: const EdgeInsets.only(top: 8),
//                     child: Text(
//                       'Full uninstall blocking requires Device Owner mode (see adb setup).',
//                       style: TextStyle(
//                         fontSize: 11,
//                         color: Colors.grey.shade600,
//                       ),
//                     ),
//                   ),
//               ],
//             ),
//             const SizedBox(height: 16),

//             // ── Block Apps card ──────────────────────────────────────────────
//             SectionCard(
//               title: 'App Blocking',
//               children: [
//                 Row(
//                   children: [
//                     Expanded(
//                       child: FilledButton.icon(
//                         onPressed: _selectAndBlockApps,
//                         icon: const Icon(Icons.block),
//                         label: const Text('Block an App'),
//                       ),
//                     ),
//                     const SizedBox(width: 8),
//                     Expanded(
//                       child: OutlinedButton.icon(
//                         onPressed: () async {
//                           final scaffold = ScaffoldMessenger.of(context);
//                           await _plugin.unblockAll();
//                           if (!mounted) return;
//                           scaffold.showSnackBar(
//                             const SnackBar(content: Text('All apps unblocked')),
//                           );
//                           _loadBlockedApps();
//                         },
//                         icon: const Icon(Icons.lock_open),
//                         label: const Text('Unblock All'),
//                       ),
//                     ),
//                   ],
//                 ),
//                 const SizedBox(height: 12),
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     Text(
//                       'Blocked Apps (${_blockedApps.length})',
//                       style: const TextStyle(fontWeight: FontWeight.w600),
//                     ),
//                     TextButton(
//                       onPressed: _showActivityLog,
//                       child: const Text('Activity Log'),
//                     ),
//                   ],
//                 ),
//                 if (_blockedApps.isEmpty)
//                   const Padding(
//                     padding: EdgeInsets.symmetric(vertical: 8),
//                     child: Text(
//                       'No apps currently blocked.',
//                       style: TextStyle(color: Colors.grey),
//                     ),
//                   )
//                 else
//                   ...(_blockedApps.map(
//                     (app) => ListTile(
//                       dense: true,
//                       contentPadding: EdgeInsets.zero,
//                       leading: AppIcon(
//                         packageName: app['packageName'] ?? '',
//                         size: 36,
//                       ),
//                       title: Text(app['appName'] ?? 'Unknown'),
//                       subtitle: Text(
//                         app['packageName'] ?? '',
//                         style: const TextStyle(fontSize: 11),
//                       ),
//                       trailing: IconButton(
//                         icon: const Icon(
//                           Icons.delete_outline,
//                           color: Colors.red,
//                         ),
//                         onPressed: () async {
//                           await _plugin.unblockApps([
//                             app['packageName'] as String,
//                           ]);
//                           _loadBlockedApps();
//                         },
//                       ),
//                     ),
//                   )),
//               ],
//             ),
//             const SizedBox(height: 16),

//             // ── Time Limits card ─────────────────────────────────────────────
//             SectionCard(
//               title: '⏱  Daily Time Limits',
//               children: [
//                 const Text(
//                   'Set how many minutes per day a user can spend in an app. '
//                   'When the budget hits 0, the app is blocked automatically.',
//                   style: TextStyle(fontSize: 13, color: Colors.black54),
//                 ),
//                 const SizedBox(height: 12),
//                 FilledButton.icon(
//                   onPressed: _showSetTimeLimitSheet,
//                   icon: const Icon(Icons.timer),
//                   label: const Text('Set Time Limit for an App'),
//                 ),
//                 const SizedBox(height: 8),
//                 OutlinedButton.icon(
//                   onPressed: _loadTimeLimits,
//                   icon: const Icon(Icons.refresh),
//                   label: const Text('Refresh Usage Stats'),
//                 ),
//                 const SizedBox(height: 12),
//                 if (_timeLimits.isEmpty)
//                   const Padding(
//                     padding: EdgeInsets.symmetric(vertical: 8),
//                     child: Text(
//                       'No time limits configured.',
//                       style: TextStyle(color: Colors.grey),
//                     ),
//                   )
//                 else
//                   ...(_timeLimits.map(
//                     (limit) => TimeLimitTile(
//                       limit: limit,
//                       plugin: _plugin,
//                       onChanged: _loadTimeLimits,
//                     ),
//                   )),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// // ─────────────────────────────────────────────────────────────────────────────
// // Set Time Limit Bottom Sheet
// // ─────────────────────────────────────────────────────────────────────────────

// class SetTimeLimitSheet extends StatefulWidget {
//   const SetTimeLimitSheet({required this.apps, required this.plugin});

//   final List<Map<String, dynamic>> apps;
//   final ZoAppBlocker plugin;

//   @override
//   State<SetTimeLimitSheet> createState() => SetTimeLimitSheetState();
// }

// class SetTimeLimitSheetState extends State<SetTimeLimitSheet> {
//   Map<String, dynamic>? _selectedApp;
//   int _limitMinutes = 30;
//   bool _saving = false;

//   @override
//   Widget build(BuildContext context) {
//     return DraggableScrollableSheet(
//       expand: false,
//       initialChildSize: 0.75,
//       maxChildSize: 0.95,
//       builder: (ctx, scrollController) {
//         return Padding(
//           padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.stretch,
//             children: [
//               Center(
//                 child: Container(
//                   width: 36,
//                   height: 4,
//                   margin: const EdgeInsets.only(bottom: 12),
//                   decoration: BoxDecoration(
//                     color: Colors.grey.shade300,
//                     borderRadius: BorderRadius.circular(2),
//                   ),
//                 ),
//               ),
//               const Text(
//                 'Set Daily Time Limit',
//                 style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//               ),
//               const SizedBox(height: 16),
//               const Text(
//                 '1. Pick an app',
//                 style: TextStyle(fontWeight: FontWeight.w600),
//               ),
//               const SizedBox(height: 8),
//               Expanded(
//                 child: ListView.builder(
//                   controller: scrollController,
//                   itemCount: widget.apps.length,
//                   itemBuilder: (context, index) {
//                     final app = widget.apps[index];
//                     final selected =
//                         _selectedApp?['packageName'] == app['packageName'];
//                     return ListTile(
//                       dense: true,
//                       selected: selected,
//                       selectedTileColor: Theme.of(
//                         context,
//                       ).colorScheme.primaryContainer.withOpacity(0.3),
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(8),
//                       ),
//                       leading: AppIcon(
//                         packageName: app['packageName'] ?? '',
//                         size: 36,
//                       ),
//                       title: Text(app['appName'] ?? ''),
//                       subtitle: Text(
//                         app['packageName'] ?? '',
//                         style: const TextStyle(fontSize: 11),
//                       ),
//                       trailing: selected
//                           ? Icon(
//                               Icons.check_circle,
//                               color: Theme.of(context).colorScheme.primary,
//                             )
//                           : null,
//                       onTap: () => setState(() => _selectedApp = app),
//                     );
//                   },
//                 ),
//               ),
//               if (_selectedApp != null) ...[
//                 const Divider(height: 24),
//                 Text(
//                   '2. Daily limit for ${_selectedApp!['appName']}',
//                   style: const TextStyle(fontWeight: FontWeight.w600),
//                 ),
//                 const SizedBox(height: 8),
//                 Row(
//                   children: [
//                     Expanded(
//                       child: Slider(
//                         value: _limitMinutes.toDouble(),
//                         min: 1,
//                         max: 180,
//                         divisions: 179,
//                         label: '$_limitMinutes min',
//                         onChanged: (v) =>
//                             setState(() => _limitMinutes = v.round()),
//                       ),
//                     ),
//                     const SizedBox(width: 8),
//                     SizedBox(
//                       width: 70,
//                       child: Text(
//                         '$_limitMinutes min',
//                         style: const TextStyle(
//                           fontWeight: FontWeight.bold,
//                           fontSize: 16,
//                         ),
//                         textAlign: TextAlign.center,
//                       ),
//                     ),
//                   ],
//                 ),
//                 Wrap(
//                   spacing: 8,
//                   children: [15, 30, 45, 60, 90, 120].map((m) {
//                     return ChoiceChip(
//                       label: Text('${m}m'),
//                       selected: _limitMinutes == m,
//                       onSelected: (_) => setState(() => _limitMinutes = m),
//                     );
//                   }).toList(),
//                 ),
//                 const SizedBox(height: 16),
//                 FilledButton(
//                   onPressed: _saving
//                       ? null
//                       : () async {
//                           setState(() => _saving = true);
//                           await widget.plugin.setAppTimeLimit(
//                             packageName: _selectedApp!['packageName'] as String,
//                             dailyLimitMinutes: _limitMinutes,
//                           );
//                           if (context.mounted) {
//                             ScaffoldMessenger.of(context).showSnackBar(
//                               SnackBar(
//                                 content: Text(
//                                   'Set ${_limitMinutes}m daily limit for '
//                                   '${_selectedApp!['appName']}',
//                                 ),
//                               ),
//                             );
//                             Navigator.pop(context);
//                           }
//                         },
//                   child: _saving
//                       ? const SizedBox(
//                           width: 20,
//                           height: 20,
//                           child: CircularProgressIndicator(strokeWidth: 2),
//                         )
//                       : const Text('Save Time Limit'),
//                 ),
//               ],
//             ],
//           ),
//         );
//       },
//     );
//   }
// }

// // ─────────────────────────────────────────────────────────────────────────────
// // Time Limit Tile
// // ─────────────────────────────────────────────────────────────────────────────

// class TimeLimitTile extends StatelessWidget {
//   const TimeLimitTile({
//     required this.limit,
//     required this.plugin,
//     required this.onChanged,
//   });

//   final AppTimeLimit limit;
//   final ZoAppBlocker plugin;
//   final VoidCallback onChanged;

//   String _fmtSeconds(int s) {
//     if (s >= 60) return '${s ~/ 60}m ${s % 60}s';
//     return '${s}s';
//   }

//   @override
//   Widget build(BuildContext context) {
//     final color = limit.isExhausted
//         ? Colors.red
//         : limit.usageRatio > 0.75
//         ? Colors.orange
//         : Theme.of(context).colorScheme.primary;

//     return Card(
//       margin: const EdgeInsets.only(bottom: 8),
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//       child: Padding(
//         padding: const EdgeInsets.all(12),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               children: [
//                 AppIcon(packageName: limit.packageName, size: 36),
//                 const SizedBox(width: 10),
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         limit.packageName.split('.').last,
//                         style: const TextStyle(fontWeight: FontWeight.bold),
//                         overflow: TextOverflow.ellipsis,
//                       ),
//                       Text(
//                         limit.packageName,
//                         style: const TextStyle(
//                           fontSize: 11,
//                           color: Colors.black45,
//                         ),
//                         overflow: TextOverflow.ellipsis,
//                       ),
//                     ],
//                   ),
//                 ),
//                 if (limit.isExhausted)
//                   const Chip(
//                     label: Text(
//                       'BLOCKED',
//                       style: TextStyle(fontSize: 11, color: Colors.white),
//                     ),
//                     backgroundColor: Colors.red,
//                     padding: EdgeInsets.zero,
//                     visualDensity: VisualDensity.compact,
//                   ),
//               ],
//             ),
//             const SizedBox(height: 10),
//             ClipRRect(
//               borderRadius: BorderRadius.circular(4),
//               child: LinearProgressIndicator(
//                 value: limit.usageRatio,
//                 minHeight: 8,
//                 color: color,
//                 backgroundColor: color.withOpacity(0.15),
//               ),
//             ),
//             const SizedBox(height: 6),
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 Text(
//                   limit.isExhausted
//                       ? 'Budget exhausted'
//                       : '${_fmtSeconds(limit.remainingSeconds)} remaining',
//                   style: TextStyle(
//                     fontSize: 12,
//                     color: color,
//                     fontWeight: FontWeight.w600,
//                   ),
//                 ),
//                 Text(
//                   '${_fmtSeconds(limit.usedSeconds)} / ${_fmtSeconds(limit.dailyLimitSeconds)}',
//                   style: const TextStyle(fontSize: 12, color: Colors.black45),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 8),
//             Row(
//               children: [
//                 Expanded(
//                   child: OutlinedButton.icon(
//                     onPressed: () async {
//                       await plugin.resetAppUsage(limit.packageName);
//                       ScaffoldMessenger.of(context).showSnackBar(
//                         const SnackBar(content: Text('Usage reset to 0')),
//                       );
//                       onChanged();
//                     },
//                     icon: const Icon(Icons.restart_alt, size: 16),
//                     label: const Text('Reset', style: TextStyle(fontSize: 13)),
//                     style: OutlinedButton.styleFrom(
//                       padding: const EdgeInsets.symmetric(vertical: 4),
//                     ),
//                   ),
//                 ),
//                 const SizedBox(width: 8),
//                 Expanded(
//                   child: OutlinedButton.icon(
//                     onPressed: () async {
//                       await plugin.removeAppTimeLimit(limit.packageName);
//                       ScaffoldMessenger.of(context).showSnackBar(
//                         const SnackBar(content: Text('Time limit removed')),
//                       );
//                       onChanged();
//                     },
//                     icon: const Icon(Icons.delete_outline, size: 16),
//                     label: const Text('Remove', style: TextStyle(fontSize: 13)),
//                     style: OutlinedButton.styleFrom(
//                       padding: const EdgeInsets.symmetric(vertical: 4),
//                       foregroundColor: Colors.red,
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// // ─────────────────────────────────────────────────────────────────────────────
// // Shared helper widgets
// // ─────────────────────────────────────────────────────────────────────────────

// class AppIcon extends StatelessWidget {
//   const AppIcon({required this.packageName, this.size = 40});

//   final String packageName;
//   final double size;

//   @override
//   Widget build(BuildContext context) {
//     return FutureBuilder<Uint8List?>(
//       future: ZoAppBlocker.instance.getAppIcon(packageName),
//       builder: (context, snapshot) {
//         if (snapshot.connectionState == ConnectionState.waiting) {
//           return SizedBox(
//             width: size,
//             height: size,
//             child: const Padding(
//               padding: EdgeInsets.all(8),
//               child: CircularProgressIndicator(strokeWidth: 2),
//             ),
//           );
//         }
//         if (snapshot.hasData && snapshot.data != null) {
//           return Image.memory(snapshot.data!, width: size, height: size);
//         }
//         return Icon(Icons.android, size: size, color: Colors.grey);
//       },
//     );
//   }
// }

// class SectionCard extends StatelessWidget {
//   const SectionCard({required this.title, required this.children});

//   final String title;
//   final List<Widget> children;

//   @override
//   Widget build(BuildContext context) {
//     return Card(
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//       elevation: 2,
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.stretch,
//           children: [
//             Text(
//               title,
//               style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//             ),
//             const Divider(height: 20),
//             ...children,
//           ],
//         ),
//       ),
//     );
//   }
// }
// // import 'dart:async';
// // import 'dart:io';
// // import 'package:flutter/material.dart';
// // import 'package:flutter/services.dart'; // ── NEW: Required for SystemNavigator
// // import 'package:shared_preferences/shared_preferences.dart';
// // import 'package:zo_app_blocker/zo_app_blocker.dart';

// // @pragma('vm:entry-point')
// // void onBlockScreenRequested() {
// //   ZoBlockScreenRunner.run(
// //     // 1. Rename this to 'blockContext' so it doesn't get confused
// //     // with the StatefulBuilder's context below.
// //     builder: (blockContext) {
// //       // Use the singleton instance of the plugin to perform actions
// //       final plugin = ZoAppBlocker.instance;
// //       return StatefulBuilder(
// //         builder: (context, setState) {
// //           final pinController = TextEditingController();
// //           String errorMessage = '';

// //           return Scaffold(
// //             backgroundColor: Colors.black87,
// //             body: Center(
// //               child: Padding(
// //                 padding: const EdgeInsets.all(24.0),
// //                 child: Column(
// //                   mainAxisAlignment: MainAxisAlignment.center,
// //                   children: [
// //                     // 2. We can pull the blocked app's icon directly from blockContext!
// //                     if (blockContext.appIcon != null &&
// //                         blockContext.appIcon!.isNotEmpty)
// //                       Image.memory(
// //                         blockContext.appIcon!,
// //                         width: 100,
// //                         height: 100,
// //                       ),
// //                     const SizedBox(height: 24),

// //                     // 3. We can pull the app's name directly from blockContext!
// //                     Text(
// //                       '${blockContext.appName ?? 'App'} is Blocked!',
// //                       style: const TextStyle(
// //                         color: Colors.white,
// //                         fontSize: 24,
// //                         fontWeight: FontWeight.bold,
// //                       ),
// //                     ),
// //                     const SizedBox(height: 12),
// //                     const Text(
// //                       'Ansharah Kutt Khao gi. Enter PIN to unlock.',
// //                       style: TextStyle(color: Colors.white70),
// //                     ),
// //                     const SizedBox(height: 24),

// //                     TextField(
// //                       controller: pinController,
// //                       keyboardType: TextInputType.number,
// //                       obscureText: true,
// //                       style: const TextStyle(color: Colors.white),
// //                       decoration: InputDecoration(
// //                         hintText: 'Enter PIN (e.g., 1234)',
// //                         hintStyle: const TextStyle(color: Colors.white54),
// //                         errorText: errorMessage.isNotEmpty
// //                             ? errorMessage
// //                             : null,
// //                         filled: true,
// //                         fillColor: Colors.white12,
// //                         border: OutlineInputBorder(
// //                           borderRadius: BorderRadius.circular(8),
// //                         ),
// //                       ),
// //                     ),
// //                     const SizedBox(height: 24),

// //                     Row(
// //                       mainAxisAlignment: MainAxisAlignment.spaceEvenly,
// //                       children: [
// //                         ElevatedButton.icon(
// //                           // 4. Use the package's built-in dismiss method to close the overlay
// //                           onPressed: blockContext.onDismiss,
// //                           icon: const Icon(Icons.exit_to_app),
// //                           label: const Text('Exit'),
// //                         ),
// //                         ElevatedButton.icon(
// //                           onPressed: () {
// //                             if (pinController.text == '459278') {
// //                               final pkg = blockContext
// //                                   .packageName; // verify this field name against the real source
// //                               if (pkg != null) {
// //                                 plugin.resetAppUsage(pkg);
// //                                 // plugin.unblockApps(
// //                                 //   [pkg],
// //                                 // ); // confirmed-working method, used elsewhere in your file
// //                                 // Timer(
// //                                 //   const Duration(minutes: 5),
// //                                 //   () => plugin.blockApps([pkg]),
// //                                 // );
// //                               }
// //                               blockContext.onDismiss();
// //                             } else {
// //                               setState(() => errorMessage = 'Incorrect PIN!');
// //                             }
// //                           },
// //                           icon: const Icon(Icons.lock_open),
// //                           label: const Text('Unlock'),
// //                         ),
// //                       ],
// //                     ),
// //                   ],
// //                 ),
// //               ),
// //             ),
// //           );
// //         },
// //       );
// //     },
// //   );
// // }

// // Future<void> main() async {
// //   WidgetsFlutterBinding.ensureInitialized();
// //   ZoAppBlocker.instance.initialize(blockScreenCallback: onBlockScreenRequested);
// //   if (await DeviceAdminProtection.isDeviceOwner()) {
// //     await DeviceAdminProtection.blockUninstall();
// //   }
// //   runApp(const MyApp());
// // }

// // class MyApp extends StatelessWidget {
// //   const MyApp({super.key});
// //   // Function to check if a PIN is already saved
// //   Future<bool> _checkHasPin() async {
// //     final prefs = await SharedPreferences.getInstance();
// //     return prefs.containsKey('user_pin');
// //   }

// //   @override
// //   Widget build(BuildContext context) {
// //     return MaterialApp(
// //       title: 'Zo App Blocker',
// //       theme: ThemeData(
// //         colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
// //         useMaterial3: true,
// //       ),
// //       // Use FutureBuilder to decide which screen to show on launch
// //       home: FutureBuilder<bool>(
// //         future: _checkHasPin(),
// //         builder: (context, snapshot) {
// //           if (snapshot.connectionState == ConnectionState.waiting) {
// //             return const Scaffold(
// //               body: Center(child: CircularProgressIndicator()),
// //             );
// //           }

// //           final hasPin = snapshot.data ?? false;

// //           // If a PIN exists, verify it. If not, create one.
// //           return PinScreen(isCreating: !hasPin);
// //         },
// //       ),
// //     );
// //   }
// // }

// // class PinScreen extends StatefulWidget {
// //   final bool isCreating;

// //   const PinScreen({super.key, required this.isCreating});

// //   @override
// //   State<PinScreen> createState() => _PinScreenState();
// // }

// // class _PinScreenState extends State<PinScreen> {
// //   final TextEditingController _pinController = TextEditingController();
// //   final String _masterPassword = "459278"; // <-- Set your master password here
// //   String _errorMessage = "";

// //   Future<void> _submitPin() async {
// //     final prefs = await SharedPreferences.getInstance();
// //     final enteredPin = _pinController.text.trim();

// //     if (enteredPin.isEmpty) {
// //       setState(() => _errorMessage = "PIN cannot be empty");
// //       return;
// //     }

// //     if (widget.isCreating) {
// //       // Logic for CREATING a new PIN
// //       await prefs.setString('user_pin', enteredPin);
// //       _navigateToHome();
// //     } else {
// //       // Logic for VERIFYING an existing PIN
// //       final savedPin = prefs.getString('user_pin');

// //       if (enteredPin == savedPin || enteredPin == _masterPassword) {
// //         _navigateToHome();
// //       } else {
// //         setState(() {
// //           _errorMessage = "Incorrect PIN";
// //           _pinController.clear();
// //         });
// //       }
// //     }
// //   }

// //   void _navigateToHome() {
// //     Navigator.pushReplacement(
// //       context,
// //       MaterialPageRoute(builder: (context) => const HomeScreen()),
// //     );
// //   }

// //   @override
// //   void dispose() {
// //     _pinController.dispose();
// //     super.dispose();
// //   }

// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       appBar: AppBar(
// //         title: Text(widget.isCreating ? 'Create PIN' : 'Enter PIN'),
// //       ),
// //       body: Padding(
// //         padding: const EdgeInsets.all(24.0),
// //         child: Column(
// //           mainAxisAlignment: MainAxisAlignment.center,
// //           children: [
// //             Text(
// //               widget.isCreating
// //                   ? 'Please create a new PIN to secure your app.'
// //                   : 'Enter your PIN to unlock.',
// //               style: const TextStyle(fontSize: 18),
// //               textAlign: TextAlign.center,
// //             ),
// //             const SizedBox(height: 30),
// //             TextField(
// //               controller: _pinController,
// //               keyboardType: TextInputType.number,
// //               obscureText: true, // Hides the input
// //               maxLength: 6, // Optional: Restrict PIN length
// //               decoration: InputDecoration(
// //                 border: const OutlineInputBorder(),
// //                 labelText: 'PIN',
// //                 errorText: _errorMessage.isEmpty ? null : _errorMessage,
// //               ),
// //               onSubmitted: (_) => _submitPin(), // Submit via keyboard
// //             ),
// //             const SizedBox(height: 20),
// //             ElevatedButton(
// //               onPressed: _submitPin,
// //               style: ElevatedButton.styleFrom(
// //                 minimumSize: const Size.fromHeight(50),
// //               ),
// //               child: Text(widget.isCreating ? 'Save PIN' : 'Unlock'),
// //             ),
// //           ],
// //         ),
// //       ),
// //     );
// //   }
// // }

// // class DeviceAdminProtection {
// //   static const _channel = MethodChannel(
// //     'com.example.zo_app_blocker_demo/device_admin',
// //   );

// //   static Future<bool> isActive() async =>
// //       await _channel.invokeMethod<bool>('isDeviceAdminActive') ?? false;
// //   static Future<void> requestActivation() =>
// //       _channel.invokeMethod('requestDeviceAdmin');
// //   static Future<bool> isDeviceOwner() async =>
// //       await _channel.invokeMethod<bool>('isDeviceOwner') ?? false;

// //   static Future<bool> blockUninstall() async {
// //     try {
// //       return await _channel.invokeMethod<bool>('blockUninstall') ?? false;
// //     } on PlatformException {
// //       return false;
// //     }
// //   }

// //   static Future<bool> allowUninstallTemporarily() async {
// //     try {
// //       return await _channel.invokeMethod<bool>('allowUninstallTemporarily') ??
// //           false;
// //     } on PlatformException {
// //       return false;
// //     }
// //   }
// // }

// // class HomeScreen extends StatefulWidget {
// //   const HomeScreen({super.key});

// //   @override
// //   State<HomeScreen> createState() => _HomeScreenState();
// // }

// // class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
// //   final _plugin = ZoAppBlocker.instance;
// //   String _usageStatsStatus = 'Unknown';
// //   String _overlayStatus = 'Unknown';
// //   List<Map<String, dynamic>> _blockedApps = [];
// //   List<AppTimeLimit> _timeLimits = [];
// //   bool _adminActive = false;
// //   bool _isDeviceOwner = false;

// //   // final List<String> _protectedSystemApps = [
// //   //   'com.google.android.packageinstaller',
// //   //   'com.android.settings', // (If you had this blocked)
// //   //   'com.android.vending',
// //   // ];
// //   @override
// //   void initState() {
// //     super.initState();
// //     WidgetsBinding.instance.addObserver(this);

// //     _plugin.setNotificationConfig(
// //       notificationBannerTitle: 'Stop Right There!',
// //       notificationBannerDescription: 'You blocked this app. Get back to work!',
// //     );

// //     Future.wait([
// //       _refreshAdminStatus(),
// //       _checkPermission(),
// //       _loadBlockedApps(),
// //       _loadTimeLimits(),
// //     ]);
// //   }

// //   @override
// //   void dispose() {
// //     WidgetsBinding.instance.removeObserver(this);
// //     super.dispose();
// //   }

// //   @override
// //   void didChangeAppLifecycleState(AppLifecycleState state) {
// //     if (state == AppLifecycleState.resumed) _refreshAdminStatus();
// //   }

// //   Future<void> _refreshAdminStatus() async {
// //     final active = await DeviceAdminProtection.isActive();
// //     final owner = await DeviceAdminProtection.isDeviceOwner(); // ADD THIS
// //     if (mounted) {
// //       setState(() {
// //         _adminActive = active;
// //         _isDeviceOwner = owner; // ADD THIS
// //       });
// //     }
// //   }

// //   Future<bool> _askForPin(BuildContext context) async {
// //     final controller = TextEditingController();
// //     final result = await showDialog<bool>(
// //       context: context,
// //       builder: (dialogContext) {
// //         String error = '';
// //         return StatefulBuilder(
// //           builder: (context, setDialogState) {
// //             void submit() {
// //               if (controller.text == '459278') {
// //                 Navigator.of(dialogContext).pop(true);
// //               } else {
// //                 setDialogState(() => error = 'Incorrect PIN');
// //               }
// //             }

// //             return AlertDialog(
// //               title: const Text('Enter PIN'),
// //               content: TextField(
// //                 controller: controller,
// //                 keyboardType: TextInputType.number,
// //                 obscureText: true,
// //                 autofocus: true,
// //                 decoration: InputDecoration(
// //                   hintText: 'Enter PIN',
// //                   errorText: error.isNotEmpty ? error : null,
// //                 ),
// //                 onSubmitted: (_) => submit(),
// //               ),
// //               actions: [
// //                 TextButton(
// //                   onPressed: () => Navigator.of(dialogContext).pop(false),
// //                   child: const Text('Cancel'),
// //                 ),
// //                 FilledButton(onPressed: submit, child: const Text('Confirm')),
// //               ],
// //             );
// //           },
// //         );
// //       },
// //     );
// //     return result ?? false;
// //   }

// //   // Future<void> _refreshAdminStatus() async {
// //   //   final active = await DeviceAdminProtection.isActive();
// //   //   if (mounted) setState(() => _adminActive = active);
// //   // }

// //   Future<void> _checkPermission() async {
// //     final usageStatus = await _plugin.checkUsageStatsPermission();
// //     final overlayStatus = await _plugin.checkOverlayPermission();
// //     setState(() {
// //       _usageStatsStatus = usageStatus;
// //       _overlayStatus = overlayStatus;
// //     });
// //   }

// //   Future<void> _loadBlockedApps() async {
// //     final apps = await _plugin.getBlockedApps();
// //     setState(() => _blockedApps = apps);
// //   }

// //   Future<void> _loadTimeLimits() async {
// //     final limits = await _plugin.getAppTimeLimits();
// //     setState(() => _timeLimits = limits);
// //   }

// //   Future<void> _requestPermissions() async {
// //     if (Platform.isAndroid) {
// //       await _plugin.requestNotificationPermission();
// //       final notifStatus = await _plugin.checkNotificationPermission();
// //       if (notifStatus != 'granted') {
// //         if (!mounted) return;
// //         ScaffoldMessenger.of(context).showSnackBar(
// //           const SnackBar(
// //             content: Text(
// //               'Notification permission is required for the background service.',
// //             ),
// //           ),
// //         );
// //       }
// //     }
// //     await _plugin.requestUsageStatsPermission();
// //     await _plugin.requestOverlayPermission();
// //     _checkPermission();
// //   }

// //   Future<void> _selectAndBlockApps() async {
// //     try {
// //       final apps = await _plugin.getApps();

// //       if (Platform.isIOS) {
// //         _loadBlockedApps();
// //         return;
// //       }

// //       if (apps.isEmpty) return;
// //       if (!mounted) return;

// //       showModalBottomSheet(
// //         context: context,
// //         builder: (context) {
// //           return Column(
// //             children: [
// //               const Padding(
// //                 padding: EdgeInsets.all(16.0),
// //                 child: Text(
// //                   'Select an app to block',
// //                   style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
// //                 ),
// //               ),
// //               Expanded(
// //                 child: ListView.builder(
// //                   itemCount: apps.length,
// //                   itemBuilder: (context, index) {
// //                     final app = apps[index];
// //                     return ListTile(
// //                       leading: AppIcon(packageName: app['packageName'] ?? ''),
// //                       title: Text(app['appName'] ?? ''),
// //                       subtitle: Text(app['packageName'] ?? ''),
// //                       onTap: () async {
// //                         final nav = Navigator.of(context);
// //                         final scaffold = ScaffoldMessenger.of(context);
// //                         await _plugin.blockApps([app['packageName']]);
// //                         if (!mounted) return;
// //                         nav.pop();
// //                         scaffold.showSnackBar(
// //                           SnackBar(content: Text('Blocked ${app['appName']}')),
// //                         );
// //                         _loadBlockedApps();
// //                       },
// //                     );
// //                   },
// //                 ),
// //               ),
// //             ],
// //           );
// //         },
// //       );
// //     } catch (e) {
// //       if (!mounted) return;
// //       ScaffoldMessenger.of(
// //         context,
// //       ).showSnackBar(SnackBar(content: Text('Error: $e')));
// //     }
// //   }

// //   /// Shows an app picker and then prompts for a minute limit.
// //   Future<void> _showSetTimeLimitSheet() async {
// //     final apps = await _plugin.getApps();
// //     if (apps.isEmpty || !mounted) return;

// //     showModalBottomSheet(
// //       context: context,
// //       isScrollControlled: true,
// //       builder: (ctx) => SetTimeLimitSheet(apps: apps, plugin: _plugin),
// //     ).then((_) => _loadTimeLimits());
// //   }

// //   Future<void> _showActivityLog() async {
// //     final log = await _plugin.getBlockActivityLog();
// //     if (!mounted) return;

// //     showModalBottomSheet(
// //       context: context,
// //       builder: (context) {
// //         return Column(
// //           children: [
// //             Padding(
// //               padding: const EdgeInsets.all(16.0),
// //               child: Row(
// //                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
// //                 children: [
// //                   const Text(
// //                     'Block Activity Log',
// //                     style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
// //                   ),
// //                   TextButton(
// //                     onPressed: () async {
// //                       await _plugin.clearBlockActivityLog();
// //                       if (context.mounted) {
// //                         Navigator.pop(context);
// //                         _showActivityLog();
// //                       }
// //                     },
// //                     child: const Text('Clear'),
// //                   ),
// //                 ],
// //               ),
// //             ),
// //             Expanded(
// //               child: log.isEmpty
// //                   ? const Center(child: Text('No activity yet.'))
// //                   : ListView.builder(
// //                       itemCount: log.length,
// //                       itemBuilder: (context, index) {
// //                         final entry = log[index];
// //                         final packageName = entry['packageName'] as String;
// //                         final timestamp = entry['timestamp'] as int;
// //                         final date = DateTime.fromMillisecondsSinceEpoch(
// //                           timestamp,
// //                         );
// //                         return ListTile(
// //                           leading: AppIcon(packageName: packageName, size: 32),
// //                           title: Text(packageName),
// //                           subtitle: Text('${date.toLocal()}'.split('.')[0]),
// //                         );
// //                       },
// //                     ),
// //             ),
// //           ],
// //         );
// //       },
// //     );
// //   }

// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       appBar: AppBar(
// //         title: const Text('Zo App Blocker Example'),
// //         backgroundColor: Theme.of(context).colorScheme.inversePrimary,
// //       ),
// //       body: RefreshIndicator(
// //         onRefresh: () async {
// //           await _loadBlockedApps();
// //           await _loadTimeLimits();
// //         },
// //         child: ListView(
// //           padding: const EdgeInsets.all(16),
// //           children: [
// //             // ── Permission card ──────────────────────────────────────────
// //             SectionCard(
// //               title: 'Permissions',
// //               children: [
// //                 ListTile(
// //                   dense: true,
// //                   leading: Icon(
// //                     (_usageStatsStatus == 'granted' &&
// //                             _overlayStatus == 'granted')
// //                         ? Icons.check_circle
// //                         : Icons.warning_amber_rounded,
// //                     color:
// //                         (_usageStatsStatus == 'granted' &&
// //                             _overlayStatus == 'granted')
// //                         ? Colors.green
// //                         : Colors.orange,
// //                   ),
// //                   title: Text(
// //                     'Usage Stats: $_usageStatsStatus\nOverlay: $_overlayStatus',
// //                   ),
// //                 ),
// //                 const SizedBox(height: 4),
// //                 FilledButton.icon(
// //                   onPressed: _requestPermissions,
// //                   icon: const Icon(Icons.security),
// //                   label: const Text('Request Permissions'),
// //                 ),
// //               ],
// //             ),
// //             const SizedBox(height: 16),
// //             SectionCard(
// //               title: '🛡️ Uninstall Protection',
// //               children: [
// //                 Row(
// //                   children: [
// //                     Icon(
// //                       _adminActive ? Icons.verified_user : Icons.gpp_maybe,
// //                       color: _adminActive ? Colors.green : Colors.orange,
// //                     ),
// //                     const SizedBox(width: 8),
// //                     Expanded(
// //                       child: Text(
// //                         _adminActive
// //                             ? 'Active — must deactivate admin in Settings before uninstalling.'
// //                             : 'Off — tap to enable.',
// //                       ),
// //                     ),
// //                   ],
// //                 ),
// //                 const SizedBox(height: 12),
// //                 if (!_adminActive)
// //                   FilledButton.icon(
// //                     onPressed: () => DeviceAdminProtection.requestActivation(),
// //                     icon: const Icon(Icons.security),
// //                     label: const Text('Enable Protection'),
// //                     style: FilledButton.styleFrom(
// //                       backgroundColor: Colors.red.shade700,
// //                     ),
// //                   ),

// //                 // ── ADD THIS BLOCK ──────────────────────────────────────────
// //                 if (_isDeviceOwner) ...[
// //                   const SizedBox(height: 8),
// //                   FilledButton.icon(
// //                     onPressed: () async {
// //                       final ok = await _askForPin(context);
// //                       if (ok) {
// //                         await DeviceAdminProtection.allowUninstallTemporarily();
// //                         if (!mounted) return;
// //                         ScaffoldMessenger.of(context).showSnackBar(
// //                           const SnackBar(
// //                             content: Text(
// //                               'Uninstall allowed — re-locks next time the app opens.',
// //                             ),
// //                           ),
// //                         );
// //                       }
// //                     },
// //                     icon: const Icon(Icons.lock_open),
// //                     label: const Text('Allow Uninstall (PIN required)'),
// //                   ),
// //                 ] else
// //                   Padding(
// //                     padding: const EdgeInsets.only(top: 8),
// //                     child: Text(
// //                       'Full uninstall blocking requires Device Owner mode (see adb setup).',
// //                       style: TextStyle(
// //                         fontSize: 11,
// //                         color: Colors.grey.shade600,
// //                       ),
// //                     ),
// //                   ),
// //                 // ── END ──────────────────────────────────────────────────────
// //               ],
// //             ),
// //             const SizedBox(height: 16),

// //             // ── Block Apps card ──────────────────────────────────────────
// //             SectionCard(
// //               title: 'App Blocking',
// //               children: [
// //                 Row(
// //                   children: [
// //                     Expanded(
// //                       child: FilledButton.icon(
// //                         onPressed: _selectAndBlockApps,
// //                         icon: const Icon(Icons.block),
// //                         label: const Text('Block an App'),
// //                       ),
// //                     ),
// //                     const SizedBox(width: 8),
// //                     Expanded(
// //                       child: OutlinedButton.icon(
// //                         onPressed: () async {
// //                           final scaffold = ScaffoldMessenger.of(context);
// //                           await _plugin.unblockAll();
// //                           if (!mounted) return;
// //                           scaffold.showSnackBar(
// //                             const SnackBar(content: Text('All apps unblocked')),
// //                           );
// //                           _loadBlockedApps();
// //                         },
// //                         icon: const Icon(Icons.lock_open),
// //                         label: const Text('Unblock All'),
// //                       ),
// //                     ),
// //                   ],
// //                 ),
// //                 const SizedBox(height: 12),
// //                 Row(
// //                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
// //                   children: [
// //                     Text(
// //                       'Blocked Apps (${_blockedApps.length})',
// //                       style: const TextStyle(fontWeight: FontWeight.w600),
// //                     ),
// //                     TextButton(
// //                       onPressed: _showActivityLog,
// //                       child: const Text('Activity Log'),
// //                     ),
// //                   ],
// //                 ),
// //                 if (_blockedApps.isEmpty)
// //                   const Padding(
// //                     padding: EdgeInsets.symmetric(vertical: 8),
// //                     child: Text(
// //                       'No apps currently blocked.',
// //                       style: TextStyle(color: Colors.grey),
// //                     ),
// //                   )
// //                 else
// //                   ...(_blockedApps.map(
// //                     (app) => ListTile(
// //                       dense: true,
// //                       contentPadding: EdgeInsets.zero,
// //                       leading: AppIcon(
// //                         packageName: app['packageName'] ?? '',
// //                         size: 36,
// //                       ),
// //                       title: Text(app['appName'] ?? 'Unknown'),
// //                       subtitle: Text(
// //                         app['packageName'] ?? '',
// //                         style: const TextStyle(fontSize: 11),
// //                       ),
// //                       trailing: IconButton(
// //                         icon: const Icon(
// //                           Icons.delete_outline,
// //                           color: Colors.red,
// //                         ),
// //                         onPressed: () async {
// //                           await _plugin.unblockApps([
// //                             app['packageName'] as String,
// //                           ]);
// //                           _loadBlockedApps();
// //                         },
// //                       ),
// //                     ),
// //                   )),
// //               ],
// //             ),
// //             const SizedBox(height: 16),

// //             // ── Time Limits card ─────────────────────────────────────────
// //             SectionCard(
// //               title: '⏱  Daily Time Limits',
// //               children: [
// //                 const Text(
// //                   'Set how many minutes per day a user can spend in an app. '
// //                   'The notification updates live with the countdown. '
// //                   'When the budget hits 0, the app is blocked automatically.',
// //                   style: TextStyle(fontSize: 13, color: Colors.black54),
// //                 ),
// //                 const SizedBox(height: 12),
// //                 FilledButton.icon(
// //                   onPressed: _showSetTimeLimitSheet,
// //                   icon: const Icon(Icons.timer),
// //                   label: const Text('Set Time Limit for an App'),
// //                 ),
// //                 const SizedBox(height: 8),
// //                 OutlinedButton.icon(
// //                   onPressed: _loadTimeLimits,
// //                   icon: const Icon(Icons.refresh),
// //                   label: const Text('Refresh Usage Stats'),
// //                 ),
// //                 const SizedBox(height: 12),
// //                 if (_timeLimits.isEmpty)
// //                   const Padding(
// //                     padding: EdgeInsets.symmetric(vertical: 8),
// //                     child: Text(
// //                       'No time limits configured.',
// //                       style: TextStyle(color: Colors.grey),
// //                     ),
// //                   )
// //                 else
// //                   ...(_timeLimits.map(
// //                     (limit) => TimeLimitTile(
// //                       limit: limit,
// //                       plugin: _plugin,
// //                       onChanged: _loadTimeLimits,
// //                     ),
// //                   )),
// //               ],
// //             ),
// //           ],
// //         ),
// //       ),
// //     );
// //   }
// // }

// // // ─────────────────────────────────────────────────────────────────────────────
// // // Set Time Limit Bottom Sheet
// // // ─────────────────────────────────────────────────────────────────────────────

// // class SetTimeLimitSheet extends StatefulWidget {
// //   const SetTimeLimitSheet({required this.apps, required this.plugin});

// //   final List<Map<String, dynamic>> apps;
// //   final ZoAppBlocker plugin;

// //   @override
// //   State<SetTimeLimitSheet> createState() => SetTimeLimitSheetState();
// // }

// // class SetTimeLimitSheetState extends State<SetTimeLimitSheet> {
// //   Map<String, dynamic>? _selectedApp;
// //   int _limitMinutes = 30;
// //   bool _saving = false;

// //   @override
// //   Widget build(BuildContext context) {
// //     return DraggableScrollableSheet(
// //       expand: false,
// //       initialChildSize: 0.75,
// //       maxChildSize: 0.95,
// //       builder: (ctx, scrollController) {
// //         return Padding(
// //           padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
// //           child: Column(
// //             crossAxisAlignment: CrossAxisAlignment.stretch,
// //             children: [
// //               Center(
// //                 child: Container(
// //                   width: 36,
// //                   height: 4,
// //                   margin: const EdgeInsets.only(bottom: 12),
// //                   decoration: BoxDecoration(
// //                     color: Colors.grey.shade300,
// //                     borderRadius: BorderRadius.circular(2),
// //                   ),
// //                 ),
// //               ),
// //               const Text(
// //                 'Set Daily Time Limit',
// //                 style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
// //               ),
// //               const SizedBox(height: 16),

// //               // App picker
// //               const Text(
// //                 '1. Pick an app',
// //                 style: TextStyle(fontWeight: FontWeight.w600),
// //               ),
// //               const SizedBox(height: 8),
// //               Expanded(
// //                 child: ListView.builder(
// //                   controller: scrollController,
// //                   itemCount: widget.apps.length,
// //                   itemBuilder: (context, index) {
// //                     final app = widget.apps[index];
// //                     final selected =
// //                         _selectedApp?['packageName'] == app['packageName'];
// //                     return ListTile(
// //                       dense: true,
// //                       selected: selected,
// //                       selectedTileColor: Theme.of(
// //                         context,
// //                       ).colorScheme.primaryContainer.withOpacity(0.3),
// //                       shape: RoundedRectangleBorder(
// //                         borderRadius: BorderRadius.circular(8),
// //                       ),
// //                       leading: AppIcon(
// //                         packageName: app['packageName'] ?? '',
// //                         size: 36,
// //                       ),
// //                       title: Text(app['appName'] ?? ''),
// //                       subtitle: Text(
// //                         app['packageName'] ?? '',
// //                         style: const TextStyle(fontSize: 11),
// //                       ),
// //                       trailing: selected
// //                           ? Icon(
// //                               Icons.check_circle,
// //                               color: Theme.of(context).colorScheme.primary,
// //                             )
// //                           : null,
// //                       onTap: () => setState(() => _selectedApp = app),
// //                     );
// //                   },
// //                 ),
// //               ),

// //               if (_selectedApp != null) ...[
// //                 const Divider(height: 24),
// //                 Text(
// //                   '2. Daily limit for ${_selectedApp!['appName']}',
// //                   style: const TextStyle(fontWeight: FontWeight.w600),
// //                 ),
// //                 const SizedBox(height: 8),
// //                 Row(
// //                   children: [
// //                     Expanded(
// //                       child: Slider(
// //                         value: _limitMinutes.toDouble(),
// //                         min: 1,
// //                         max: 180,
// //                         divisions: 179,
// //                         label: '$_limitMinutes min',
// //                         onChanged: (v) =>
// //                             setState(() => _limitMinutes = v.round()),
// //                       ),
// //                     ),
// //                     const SizedBox(width: 8),
// //                     SizedBox(
// //                       width: 70,
// //                       child: Text(
// //                         '$_limitMinutes min',
// //                         style: const TextStyle(
// //                           fontWeight: FontWeight.bold,
// //                           fontSize: 16,
// //                         ),
// //                         textAlign: TextAlign.center,
// //                       ),
// //                     ),
// //                   ],
// //                 ),
// //                 // Quick-pick chips
// //                 Wrap(
// //                   spacing: 8,
// //                   children: [15, 30, 45, 60, 90, 120].map((m) {
// //                     return ChoiceChip(
// //                       label: Text('${m}m'),
// //                       selected: _limitMinutes == m,
// //                       onSelected: (_) => setState(() => _limitMinutes = m),
// //                     );
// //                   }).toList(),
// //                 ),
// //                 const SizedBox(height: 16),
// //                 FilledButton(
// //                   onPressed: _saving
// //                       ? null
// //                       : () async {
// //                           setState(() => _saving = true);
// //                           await widget.plugin.setAppTimeLimit(
// //                             packageName: _selectedApp!['packageName'] as String,
// //                             dailyLimitMinutes: _limitMinutes,
// //                           );
// //                           if (context.mounted) {
// //                             ScaffoldMessenger.of(context).showSnackBar(
// //                               SnackBar(
// //                                 content: Text(
// //                                   'Set ${_limitMinutes}m daily limit for '
// //                                   '${_selectedApp!['appName']}',
// //                                 ),
// //                               ),
// //                             );
// //                             Navigator.pop(context);
// //                           }
// //                         },
// //                   child: _saving
// //                       ? const SizedBox(
// //                           width: 20,
// //                           height: 20,
// //                           child: CircularProgressIndicator(strokeWidth: 2),
// //                         )
// //                       : const Text('Save Time Limit'),
// //                 ),
// //               ],
// //             ],
// //           ),
// //         );
// //       },
// //     );
// //   }
// // }

// // // ─────────────────────────────────────────────────────────────────────────────
// // // Time Limit Tile (shows progress bar + actions)
// // // ─────────────────────────────────────────────────────────────────────────────

// // class TimeLimitTile extends StatelessWidget {
// //   const TimeLimitTile({
// //     required this.limit,
// //     required this.plugin,
// //     required this.onChanged,
// //   });

// //   final AppTimeLimit limit;
// //   final ZoAppBlocker plugin;
// //   final VoidCallback onChanged;

// //   String _fmtSeconds(int s) {
// //     if (s >= 60) return '${s ~/ 60}m ${s % 60}s';
// //     return '${s}s';
// //   }

// //   @override
// //   Widget build(BuildContext context) {
// //     final color = limit.isExhausted
// //         ? Colors.red
// //         : limit.usageRatio > 0.75
// //         ? Colors.orange
// //         : Theme.of(context).colorScheme.primary;

// //     return Card(
// //       margin: const EdgeInsets.only(bottom: 8),
// //       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
// //       child: Padding(
// //         padding: const EdgeInsets.all(12),
// //         child: Column(
// //           crossAxisAlignment: CrossAxisAlignment.start,
// //           children: [
// //             Row(
// //               children: [
// //                 AppIcon(packageName: limit.packageName, size: 36),
// //                 const SizedBox(width: 10),
// //                 Expanded(
// //                   child: Column(
// //                     crossAxisAlignment: CrossAxisAlignment.start,
// //                     children: [
// //                       Text(
// //                         limit.packageName.split('.').last,
// //                         style: const TextStyle(fontWeight: FontWeight.bold),
// //                         overflow: TextOverflow.ellipsis,
// //                       ),
// //                       Text(
// //                         limit.packageName,
// //                         style: const TextStyle(
// //                           fontSize: 11,
// //                           color: Colors.black45,
// //                         ),
// //                         overflow: TextOverflow.ellipsis,
// //                       ),
// //                     ],
// //                   ),
// //                 ),
// //                 if (limit.isExhausted)
// //                   const Chip(
// //                     label: Text(
// //                       'BLOCKED',
// //                       style: TextStyle(fontSize: 11, color: Colors.white),
// //                     ),
// //                     backgroundColor: Colors.red,
// //                     padding: EdgeInsets.zero,
// //                     visualDensity: VisualDensity.compact,
// //                   ),
// //               ],
// //             ),
// //             const SizedBox(height: 10),
// //             // Progress bar
// //             ClipRRect(
// //               borderRadius: BorderRadius.circular(4),
// //               child: LinearProgressIndicator(
// //                 value: limit.usageRatio,
// //                 minHeight: 8,
// //                 color: color,
// //                 backgroundColor: color.withOpacity(0.15),
// //               ),
// //             ),
// //             const SizedBox(height: 6),
// //             Row(
// //               mainAxisAlignment: MainAxisAlignment.spaceBetween,
// //               children: [
// //                 Text(
// //                   limit.isExhausted
// //                       ? 'Budget exhausted'
// //                       : '${_fmtSeconds(limit.remainingSeconds)} remaining',
// //                   style: TextStyle(
// //                     fontSize: 12,
// //                     color: color,
// //                     fontWeight: FontWeight.w600,
// //                   ),
// //                 ),
// //                 Text(
// //                   '${_fmtSeconds(limit.usedSeconds)} / ${_fmtSeconds(limit.dailyLimitSeconds)}',
// //                   style: const TextStyle(fontSize: 12, color: Colors.black45),
// //                 ),
// //               ],
// //             ),
// //             const SizedBox(height: 8),
// //             // Action buttons
// //             Row(
// //               children: [
// //                 Expanded(
// //                   child: OutlinedButton.icon(
// //                     onPressed: () async {
// //                       await plugin.resetAppUsage(limit.packageName);
// //                       ScaffoldMessenger.of(context).showSnackBar(
// //                         const SnackBar(content: Text('Usage reset to 0')),
// //                       );
// //                       onChanged();
// //                     },
// //                     icon: const Icon(Icons.restart_alt, size: 16),
// //                     label: const Text('Reset', style: TextStyle(fontSize: 13)),
// //                     style: OutlinedButton.styleFrom(
// //                       padding: const EdgeInsets.symmetric(vertical: 4),
// //                     ),
// //                   ),
// //                 ),
// //                 const SizedBox(width: 8),
// //                 Expanded(
// //                   child: OutlinedButton.icon(
// //                     onPressed: () async {
// //                       await plugin.removeAppTimeLimit(limit.packageName);
// //                       ScaffoldMessenger.of(context).showSnackBar(
// //                         const SnackBar(content: Text('Time limit removed')),
// //                       );
// //                       onChanged();
// //                     },
// //                     icon: const Icon(Icons.delete_outline, size: 16),
// //                     label: const Text('Remove', style: TextStyle(fontSize: 13)),
// //                     style: OutlinedButton.styleFrom(
// //                       padding: const EdgeInsets.symmetric(vertical: 4),
// //                       foregroundColor: Colors.red,
// //                     ),
// //                   ),
// //                 ),
// //               ],
// //             ),
// //           ],
// //         ),
// //       ),
// //     );
// //   }
// // }

// // // ─────────────────────────────────────────────────────────────────────────────
// // // Shared helper widgets
// // // ─────────────────────────────────────────────────────────────────────────────

// // class AppIcon extends StatelessWidget {
// //   const AppIcon({required this.packageName, this.size = 40});

// //   final String packageName;
// //   final double size;

// //   @override
// //   Widget build(BuildContext context) {
// //     return FutureBuilder<Uint8List?>(
// //       future: ZoAppBlocker.instance.getAppIcon(packageName),
// //       builder: (context, snapshot) {
// //         if (snapshot.connectionState == ConnectionState.waiting) {
// //           return SizedBox(
// //             width: size,
// //             height: size,
// //             child: const Padding(
// //               padding: EdgeInsets.all(8),
// //               child: CircularProgressIndicator(strokeWidth: 2),
// //             ),
// //           );
// //         }
// //         if (snapshot.hasData && snapshot.data != null) {
// //           return Image.memory(snapshot.data!, width: size, height: size);
// //         }
// //         return Icon(Icons.android, size: size, color: Colors.grey);
// //       },
// //     );
// //   }
// // }

// // class SectionCard extends StatelessWidget {
// //   const SectionCard({required this.title, required this.children});

// //   final String title;
// //   final List<Widget> children;

// //   @override
// //   Widget build(BuildContext context) {
// //     return Card(
// //       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
// //       elevation: 2,
// //       child: Padding(
// //         padding: const EdgeInsets.all(16),
// //         child: Column(
// //           crossAxisAlignment: CrossAxisAlignment.stretch,
// //           children: [
// //             Text(
// //               title,
// //               style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
// //             ),
// //             const Divider(height: 20),
// //             ...children,
// //           ],
// //         ),
// //       ),
// //     );
// //   }
// // }

// // // import 'dart:io';
// // // import 'package:flutter/material.dart';
// // // import 'dart:typed_data';
// // // import 'package:zo_app_blocker/zo_app_blocker.dart';

// // // // ─── Block Screen entry point ─────────────────────────────────────────────────

// // // @pragma('vm:entry-point')
// // // void onBlockScreenRequested() {
// // //   ZoBlockScreenRunner.run(
// // //     builder: (blockContext) => _BlockOverlay(blockContext: blockContext),
// // //   );
// // // }

// // // /// FIX 1 & 2: Replaced the broken StatefulBuilder approach with a proper
// // // /// StatefulWidget.
// // // ///
// // // /// Root cause of the original bugs:
// // // ///   • [pinController] and [errorMessage] were declared **inside** the
// // // ///     StatefulBuilder's builder callback, so every setState() call re-ran the
// // // ///     builder from scratch, wiping them back to their initial values.
// // // ///     This made it impossible to show the error text or retain what the user
// // // ///     had typed.
// // // ///   • plugin.unlockApp() was commented out, so the Unlock button did nothing.
// // // class _BlockOverlay extends StatefulWidget {
// // //   const _BlockOverlay({required this.blockContext});

// // //   // Type is provided by zo_app_blocker; exposes .appIcon, .appName, .onDismiss.
// // //   final dynamic blockContext;

// // //   @override
// // //   State<_BlockOverlay> createState() => _BlockOverlayState();
// // // }

// // // class _BlockOverlayState extends State<_BlockOverlay> {
// // //   // Declared here (not inside build) so they survive rebuilds.
// // //   final _pinController = TextEditingController();
// // //   String _errorMessage = '';
// // //   bool _unlocking = false;

// // //   @override
// // //   void dispose() {
// // //     _pinController.dispose();
// // //     super.dispose();
// // //   }

// // //   Future<void> _tryUnlock() async {
// // //     setState(() => _errorMessage = '');

// // //     if (_pinController.text.trim() == '1234') {
// // //       setState(() => _unlocking = true);

// // //       // Use the official session unlock method provided by the block context
// // //       final granted =
// // //           await widget.blockContext.onRequestTemporarySessionUnlock?.call() ??
// // //           false;

// // //       if (mounted) setState(() => _unlocking = false);

// // //       if (!granted && mounted) {
// // //         setState(() => _errorMessage = 'Unlock failed. Try again.');
// // //       }
// // //     } else {
// // //       setState(() => _errorMessage = 'Incorrect PIN. Try again.');
// // //     }
// // //   }
// // //   // Future<void> _tryUnlock() async {
// // //   //   // Clear any previous error as soon as the user tries again.
// // //   //   setState(() => _errorMessage = '');

// // //   //   if (_pinController.text.trim() == '1234') {
// // //   //     setState(() => _unlocking = true);
// // //   //     // FIX 2: Actually call unlockApp() — was commented out in the original.
// // //   //     await ZoAppBlocker.instance.unlockApp(
// // //   //       duration: const Duration(minutes: 15),
// // //   //     );
// // //   //     // The plugin dismisses the overlay on success; guard against mounted anyway.
// // //   //     if (mounted) setState(() => _unlocking = false);
// // //   //   } else {
// // //   //     setState(() => _errorMessage = 'Incorrect PIN. Try again.');
// // //   //   }
// // //   // }

// // //   @override
// // //   Widget build(BuildContext context) {
// // //     final bc = widget.blockContext;
// // //     final Uint8List? icon = bc.appIcon as Uint8List?;

// // //     return Scaffold(
// // //       backgroundColor: Colors.black87,
// // //       body: Center(
// // //         child: SingleChildScrollView(
// // //           padding: const EdgeInsets.all(24),
// // //           child: Column(
// // //             mainAxisAlignment: MainAxisAlignment.center,
// // //             children: [
// // //               if (icon != null && icon.isNotEmpty)
// // //                 ClipRRect(
// // //                   borderRadius: BorderRadius.circular(20),
// // //                   child: Image.memory(icon, width: 96, height: 96),
// // //                 ),
// // //               const SizedBox(height: 24),
// // //               Text(
// // //                 '${bc.appName ?? 'This App'} is Blocked',
// // //                 textAlign: TextAlign.center,
// // //                 style: const TextStyle(
// // //                   color: Colors.white,
// // //                   fontSize: 22,
// // //                   fontWeight: FontWeight.bold,
// // //                 ),
// // //               ),
// // //               const SizedBox(height: 8),
// // //               const Text(
// // //                 'Enter the PIN to unlock for 15 minutes.',
// // //                 textAlign: TextAlign.center,
// // //                 style: TextStyle(color: Colors.white70),
// // //               ),
// // //               const SizedBox(height: 28),
// // //               TextField(
// // //                 controller: _pinController,
// // //                 keyboardType: TextInputType.number,
// // //                 obscureText: true,
// // //                 autofocus: true,
// // //                 style: const TextStyle(color: Colors.white),
// // //                 // Allow submitting via keyboard action.
// // //                 onSubmitted: (_) => _tryUnlock(),
// // //                 // Clear error while the user is typing a new attempt.
// // //                 onChanged: (_) {
// // //                   if (_errorMessage.isNotEmpty) {
// // //                     setState(() => _errorMessage = '');
// // //                   }
// // //                 },
// // //                 decoration: InputDecoration(
// // //                   hintText: 'Enter PIN',
// // //                   hintStyle: const TextStyle(color: Colors.white38),
// // //                   errorText: _errorMessage.isNotEmpty ? _errorMessage : null,
// // //                   errorStyle: const TextStyle(color: Colors.orangeAccent),
// // //                   filled: true,
// // //                   fillColor: Colors.white12,
// // //                   border: OutlineInputBorder(
// // //                     borderRadius: BorderRadius.circular(10),
// // //                     borderSide: BorderSide.none,
// // //                   ),
// // //                   focusedBorder: OutlineInputBorder(
// // //                     borderRadius: BorderRadius.circular(10),
// // //                     borderSide: const BorderSide(color: Colors.white38),
// // //                   ),
// // //                 ),
// // //               ),
// // //               const SizedBox(height: 24),
// // //               Row(
// // //                 mainAxisAlignment: MainAxisAlignment.spaceEvenly,
// // //                 children: [
// // //                   OutlinedButton.icon(
// // //                     onPressed: bc.onDismiss as VoidCallback?,
// // //                     icon: const Icon(Icons.exit_to_app, color: Colors.white70),
// // //                     label: const Text(
// // //                       'Go Back',
// // //                       style: TextStyle(color: Colors.white70),
// // //                     ),
// // //                     style: OutlinedButton.styleFrom(
// // //                       side: const BorderSide(color: Colors.white38),
// // //                     ),
// // //                   ),
// // //                   FilledButton.icon(
// // //                     onPressed: _unlocking ? null : _tryUnlock,
// // //                     icon: _unlocking
// // //                         ? const SizedBox(
// // //                             width: 16,
// // //                             height: 16,
// // //                             child: CircularProgressIndicator(
// // //                               strokeWidth: 2,
// // //                               color: Colors.white,
// // //                             ),
// // //                           )
// // //                         : const Icon(Icons.lock_open),
// // //                     label: Text(_unlocking ? 'Unlocking…' : 'Unlock'),
// // //                   ),
// // //                 ],
// // //               ),
// // //             ],
// // //           ),
// // //         ),
// // //       ),
// // //     );
// // //   }
// // // }

// // // // ─── App bootstrap ────────────────────────────────────────────────────────────

// // // void main() {
// // //   WidgetsFlutterBinding.ensureInitialized();
// // //   ZoAppBlocker.instance.initialize(blockScreenCallback: onBlockScreenRequested);
// // //   runApp(const MyApp());
// // // }

// // // class MyApp extends StatelessWidget {
// // //   const MyApp({super.key});

// // //   @override
// // //   Widget build(BuildContext context) {
// // //     return MaterialApp(
// // //       title: 'Zo App Blocker',
// // //       theme: ThemeData(
// // //         colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
// // //         useMaterial3: true,
// // //       ),
// // //       home: const HomeScreen(),
// // //     );
// // //   }
// // // }

// // // // ─── Home Screen ──────────────────────────────────────────────────────────────

// // // class HomeScreen extends StatefulWidget {
// // //   const HomeScreen({super.key});

// // //   @override
// // //   State<HomeScreen> createState() => _HomeScreenState();
// // // }

// // // // FIX 6: Added WidgetsBindingObserver so permissions are re-checked
// // // // automatically when the user returns from the Android system settings page.
// // // class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
// // //   final _plugin = ZoAppBlocker.instance;

// // //   String _usageStatsStatus = 'Unknown';
// // //   String _overlayStatus = 'Unknown';
// // //   List<Map<String, dynamic>> _blockedApps = [];
// // //   List<AppTimeLimit> _timeLimits = [];

// // //   // FIX 4: Tracks the real enabled/disabled state of uninstall protection
// // //   // instead of being a stateless fire-and-forget button.
// // //   bool _protectionEnabled = false;

// // //   /// The three packages that together close every door through which a child
// // //   /// could uninstall THIS app:
// // //   ///
// // //   ///   com.android.settings             → App Info → Uninstall in Settings
// // //   ///   com.google.android.packageinstaller → the system uninstall dialog itself
// // //   ///   com.android.vending              → Play Store uninstall button
// // //   ///
// // //   /// The zo_app_blocker overlay will appear over all three. The parent can
// // //   /// still reach them by entering the PIN.
// // //   ///
// // //   /// Note: do NOT add your own package name here — blocking it would prevent
// // //   /// this app from running.
// // //   static const List<String> _uninstallProtectionPackages = [
// // //     'com.android.settings',
// // //     'com.google.android.packageinstaller',
// // //     'com.android.vending',
// // //   ];

// // //   @override
// // //   void initState() {
// // //     super.initState();
// // //     WidgetsBinding.instance.addObserver(this); // FIX 6
// // //     _checkPermission();
// // //     _loadBlockedApps();
// // //     _loadTimeLimits();
// // //     _loadProtectionStatus(); // FIX 4

// // //     _plugin.setNotificationConfig(
// // //       notificationBannerTitle: 'Stop Right There!',
// // //       notificationBannerDescription: 'You blocked this app. Get back to work!',
// // //     );
// // //   }

// // //   @override
// // //   void dispose() {
// // //     WidgetsBinding.instance.removeObserver(this); // FIX 6: clean up observer
// // //     super.dispose();
// // //   }

// // //   // FIX 6: Refresh permissions automatically when the user returns from the
// // //   // system Settings page after granting (or denying) a permission.
// // //   @override
// // //   void didChangeAppLifecycleState(AppLifecycleState state) {
// // //     if (state == AppLifecycleState.resumed) {
// // //       _checkPermission();
// // //       _loadProtectionStatus();
// // //     }
// // //   }

// // //   Future<void> _checkPermission() async {
// // //     final usageStatus = await _plugin.checkUsageStatsPermission();
// // //     final overlayStatus = await _plugin.checkOverlayPermission();
// // //     if (mounted) {
// // //       setState(() {
// // //         _usageStatsStatus = usageStatus;
// // //         _overlayStatus = overlayStatus;
// // //       });
// // //     }
// // //   }

// // //   Future<void> _loadBlockedApps() async {
// // //     final apps = await _plugin.getBlockedApps();
// // //     if (mounted) setState(() => _blockedApps = apps);
// // //   }

// // //   Future<void> _loadTimeLimits() async {
// // //     final limits = await _plugin.getAppTimeLimits();
// // //     if (mounted) setState(() => _timeLimits = limits);
// // //   }

// // //   // FIX 4: Derives the enabled state from the actual blocked-app list so it
// // //   // survives hot-restarts and always reflects reality.
// // //   Future<void> _loadProtectionStatus() async {
// // //     final apps = await _plugin.getBlockedApps();
// // //     final blocked = apps.map((a) => a['packageName'] as String).toSet();
// // //     if (mounted) {
// // //       setState(() {
// // //         _protectionEnabled = _uninstallProtectionPackages.every(
// // //           blocked.contains,
// // //         );
// // //       });
// // //     }
// // //   }

// // //   Future<void> _requestPermissions() async {
// // //     if (Platform.isAndroid) {
// // //       await _plugin.requestNotificationPermission();
// // //       final notifStatus = await _plugin.checkNotificationPermission();
// // //       if (notifStatus != 'granted' && mounted) {
// // //         ScaffoldMessenger.of(context).showSnackBar(
// // //           const SnackBar(
// // //             content: Text(
// // //               'Notification permission is required for the background service.',
// // //             ),
// // //           ),
// // //         );
// // //       }
// // //     }
// // //     await _plugin.requestUsageStatsPermission();
// // //     await _plugin.requestOverlayPermission();
// // //     // FIX 6: didChangeAppLifecycleState now handles the re-check when the
// // //     // user comes back from the system settings page — no extra call needed.
// // //   }

// // //   // FIX 4 & 5: Toggles protection on/off and keeps the button state in sync.
// // //   Future<void> _toggleUninstallProtection() async {
// // //     if (!mounted) return;
// // //     final scaffold = ScaffoldMessenger.of(context);

// // //     if (_protectionEnabled) {
// // //       await _plugin.unblockApps(_uninstallProtectionPackages);
// // //       scaffold.showSnackBar(
// // //         const SnackBar(content: Text('Uninstall protection disabled.')),
// // //       );
// // //     } else {
// // //       await _plugin.blockApps(_uninstallProtectionPackages);
// // //       scaffold.showSnackBar(
// // //         const SnackBar(content: Text('✅ Uninstall protection enabled!')),
// // //       );
// // //     }

// // //     await _loadBlockedApps();
// // //     await _loadProtectionStatus();
// // //   }

// // //   Future<void> _selectAndBlockApps() async {
// // //     try {
// // //       final apps = await _plugin.getApps();

// // //       if (Platform.isIOS) {
// // //         // On iOS, blockApps() opens the native Screen Time family activity
// // //         // picker; getApps() returns an empty list on iOS, so we skip the
// // //         // manual list and hand off directly to the system.
// // //         await _plugin.blockApps([]);
// // //         _loadBlockedApps();
// // //         return;
// // //       }

// // //       if (apps.isEmpty || !mounted) return;

// // //       showModalBottomSheet(
// // //         context: context,
// // //         builder: (sheetContext) {
// // //           return Column(
// // //             children: [
// // //               const Padding(
// // //                 padding: EdgeInsets.all(16.0),
// // //                 child: Text(
// // //                   'Select an app to block',
// // //                   style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
// // //                 ),
// // //               ),
// // //               Expanded(
// // //                 child: ListView.builder(
// // //                   itemCount: apps.length,
// // //                   itemBuilder: (context, index) {
// // //                     final app = apps[index];
// // //                     return ListTile(
// // //                       leading: AppIcon(packageName: app['packageName'] ?? ''),
// // //                       title: Text(app['appName'] ?? ''),
// // //                       subtitle: Text(app['packageName'] ?? ''),
// // //                       onTap: () async {
// // //                         final nav = Navigator.of(sheetContext);
// // //                         final messenger = ScaffoldMessenger.of(sheetContext);
// // //                         await _plugin.blockApps([app['packageName']]);
// // //                         nav.pop();
// // //                         messenger.showSnackBar(
// // //                           SnackBar(content: Text('Blocked ${app['appName']}')),
// // //                         );
// // //                         _loadBlockedApps();
// // //                       },
// // //                     );
// // //                   },
// // //                 ),
// // //               ),
// // //             ],
// // //           );
// // //         },
// // //       );
// // //     } catch (e) {
// // //       if (!mounted) return;
// // //       ScaffoldMessenger.of(
// // //         context,
// // //       ).showSnackBar(SnackBar(content: Text('Error: $e')));
// // //     }
// // //   }

// // //   Future<void> _showSetTimeLimitSheet() async {
// // //     final apps = await _plugin.getApps();
// // //     if (apps.isEmpty || !mounted) return;

// // //     await showModalBottomSheet(
// // //       context: context,
// // //       isScrollControlled: true,
// // //       builder: (ctx) => SetTimeLimitSheet(apps: apps, plugin: _plugin),
// // //     );
// // //     _loadTimeLimits();
// // //   }

// // //   Future<void> _showActivityLog() async {
// // //     final log = await _plugin.getBlockActivityLog();
// // //     if (!mounted) return;

// // //     showModalBottomSheet(
// // //       context: context,
// // //       builder: (context) {
// // //         return Column(
// // //           children: [
// // //             Padding(
// // //               padding: const EdgeInsets.all(16.0),
// // //               child: Row(
// // //                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
// // //                 children: [
// // //                   const Text(
// // //                     'Block Activity Log',
// // //                     style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
// // //                   ),
// // //                   TextButton(
// // //                     onPressed: () async {
// // //                       await _plugin.clearBlockActivityLog();
// // //                       if (context.mounted) {
// // //                         Navigator.pop(context);
// // //                         _showActivityLog();
// // //                       }
// // //                     },
// // //                     child: const Text('Clear'),
// // //                   ),
// // //                 ],
// // //               ),
// // //             ),
// // //             Expanded(
// // //               child: log.isEmpty
// // //                   ? const Center(child: Text('No activity yet.'))
// // //                   : ListView.builder(
// // //                       itemCount: log.length,
// // //                       itemBuilder: (context, index) {
// // //                         final entry = log[index];
// // //                         final packageName = entry['packageName'] as String;
// // //                         final timestamp = entry['timestamp'] as int;
// // //                         final date = DateTime.fromMillisecondsSinceEpoch(
// // //                           timestamp,
// // //                         );
// // //                         return ListTile(
// // //                           leading: AppIcon(packageName: packageName, size: 32),
// // //                           title: Text(packageName),
// // //                           subtitle: Text('${date.toLocal()}'.split('.')[0]),
// // //                         );
// // //                       },
// // //                     ),
// // //             ),
// // //           ],
// // //         );
// // //       },
// // //     );
// // //   }

// // //   // FIX 7: Exclude protection packages from the "App Blocking" list so they
// // //   // don't create confusing duplicate entries.
// // //   List<Map<String, dynamic>> get _userBlockedApps => _blockedApps
// // //       .where(
// // //         (app) => !_uninstallProtectionPackages.contains(
// // //           app['packageName'] as String?,
// // //         ),
// // //       )
// // //       .toList();

// // //   bool get _allPermissionsGranted =>
// // //       _usageStatsStatus == 'granted' && _overlayStatus == 'granted';

// // //   @override
// // //   Widget build(BuildContext context) {
// // //     return Scaffold(
// // //       appBar: AppBar(
// // //         title: const Text('Zo App Blocker'),
// // //         backgroundColor: Theme.of(context).colorScheme.inversePrimary,
// // //         actions: [
// // //           IconButton(
// // //             icon: const Icon(Icons.refresh),
// // //             tooltip: 'Refresh all',
// // //             onPressed: () async {
// // //               await _checkPermission();
// // //               await _loadBlockedApps();
// // //               await _loadTimeLimits();
// // //               await _loadProtectionStatus();
// // //             },
// // //           ),
// // //         ],
// // //       ),
// // //       body: RefreshIndicator(
// // //         onRefresh: () async {
// // //           await _checkPermission();
// // //           await _loadBlockedApps();
// // //           await _loadTimeLimits();
// // //           await _loadProtectionStatus();
// // //         },
// // //         child: ListView(
// // //           padding: const EdgeInsets.all(16),
// // //           children: [
// // //             // ── Permission card ──────────────────────────────────────────
// // //             SectionCard(
// // //               title: 'Permissions',
// // //               children: [
// // //                 ListTile(
// // //                   dense: true,
// // //                   leading: Icon(
// // //                     _allPermissionsGranted
// // //                         ? Icons.check_circle
// // //                         : Icons.warning_amber_rounded,
// // //                     color: _allPermissionsGranted
// // //                         ? Colors.green
// // //                         : Colors.orange,
// // //                   ),
// // //                   title: Text(
// // //                     'Usage Stats: $_usageStatsStatus\n'
// // //                     'Overlay: $_overlayStatus',
// // //                   ),
// // //                 ),
// // //                 const SizedBox(height: 4),
// // //                 // FIX 8: Button disables and changes label once all permissions
// // //                 // are granted instead of always showing "Request Permissions".
// // //                 FilledButton.icon(
// // //                   onPressed: _allPermissionsGranted
// // //                       ? null
// // //                       : _requestPermissions,
// // //                   icon: Icon(
// // //                     _allPermissionsGranted ? Icons.check : Icons.security,
// // //                   ),
// // //                   label: Text(
// // //                     _allPermissionsGranted
// // //                         ? 'All Permissions Granted'
// // //                         : 'Request Permissions',
// // //                   ),
// // //                 ),
// // //               ],
// // //             ),
// // //             const SizedBox(height: 16),

// // //             // ── Uninstall Protection card ─────────────────────────────────
// // //             SectionCard(
// // //               title: '🛡️ Uninstall Protection',
// // //               children: [
// // //                 const Text(
// // //                   'Prevents children from uninstalling this app by blocking '
// // //                   'Settings (App Info → Uninstall), the Play Store, and the '
// // //                   'system uninstall dialog. You can still reach them by '
// // //                   'entering the PIN.',
// // //                   style: TextStyle(fontSize: 13, color: Colors.black54),
// // //                 ),
// // //                 const SizedBox(height: 12),
// // //                 // FIX 4 & 5: Button reflects actual state and can toggle off.
// // //                 AnimatedSwitcher(
// // //                   duration: const Duration(milliseconds: 250),
// // //                   child: FilledButton.icon(
// // //                     key: ValueKey(_protectionEnabled),
// // //                     onPressed: _toggleUninstallProtection,
// // //                     icon: Icon(
// // //                       _protectionEnabled ? Icons.shield : Icons.shield_outlined,
// // //                     ),
// // //                     label: Text(
// // //                       _protectionEnabled
// // //                           ? '✓ Protection Enabled  (tap to disable)'
// // //                           : 'Enable Protection',
// // //                     ),
// // //                     style: FilledButton.styleFrom(
// // //                       backgroundColor: _protectionEnabled
// // //                           ? Colors.green.shade700
// // //                           : Colors.red.shade700,
// // //                     ),
// // //                   ),
// // //                 ),
// // //               ],
// // //             ),
// // //             const SizedBox(height: 16),

// // //             // ── Block Apps card ──────────────────────────────────────────
// // //             SectionCard(
// // //               title: 'App Blocking',
// // //               children: [
// // //                 Row(
// // //                   children: [
// // //                     Expanded(
// // //                       child: FilledButton.icon(
// // //                         onPressed: _selectAndBlockApps,
// // //                         icon: const Icon(Icons.block),
// // //                         label: const Text('Block an App'),
// // //                       ),
// // //                     ),
// // //                     const SizedBox(width: 8),
// // //                     Expanded(
// // //                       child: OutlinedButton.icon(
// // //                         onPressed: () async {
// // //                           final scaffold = ScaffoldMessenger.of(context);
// // //                           await _plugin.unblockAll();
// // //                           if (!mounted) return;
// // //                           scaffold.showSnackBar(
// // //                             const SnackBar(content: Text('All apps unblocked')),
// // //                           );
// // //                           _loadBlockedApps();
// // //                           // FIX 9: Sync protection indicator after unblockAll.
// // //                           _loadProtectionStatus();
// // //                         },
// // //                         icon: const Icon(Icons.lock_open),
// // //                         label: const Text('Unblock All'),
// // //                       ),
// // //                     ),
// // //                   ],
// // //                 ),
// // //                 const SizedBox(height: 12),
// // //                 Row(
// // //                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
// // //                   children: [
// // //                     // FIX 7: Count only user-added blocks, not protection packages.
// // //                     Text(
// // //                       'Blocked Apps (${_userBlockedApps.length})',
// // //                       style: const TextStyle(fontWeight: FontWeight.w600),
// // //                     ),
// // //                     TextButton(
// // //                       onPressed: _showActivityLog,
// // //                       child: const Text('Activity Log'),
// // //                     ),
// // //                   ],
// // //                 ),
// // //                 if (_userBlockedApps.isEmpty)
// // //                   const Padding(
// // //                     padding: EdgeInsets.symmetric(vertical: 8),
// // //                     child: Text(
// // //                       'No apps currently blocked.',
// // //                       style: TextStyle(color: Colors.grey),
// // //                     ),
// // //                   )
// // //                 else
// // //                   ..._userBlockedApps.map(
// // //                     (app) => ListTile(
// // //                       dense: true,
// // //                       contentPadding: EdgeInsets.zero,
// // //                       leading: AppIcon(
// // //                         packageName: app['packageName'] ?? '',
// // //                         size: 36,
// // //                       ),
// // //                       title: Text(app['appName'] ?? 'Unknown'),
// // //                       subtitle: Text(
// // //                         app['packageName'] ?? '',
// // //                         style: const TextStyle(fontSize: 11),
// // //                       ),
// // //                       trailing: IconButton(
// // //                         icon: const Icon(
// // //                           Icons.delete_outline,
// // //                           color: Colors.red,
// // //                         ),
// // //                         onPressed: () async {
// // //                           await _plugin.unblockApps([
// // //                             app['packageName'] as String,
// // //                           ]);
// // //                           _loadBlockedApps();
// // //                           // FIX 9: Sync protection state when individual apps
// // //                           // are unblocked too.
// // //                           _loadProtectionStatus();
// // //                         },
// // //                       ),
// // //                     ),
// // //                   ),
// // //               ],
// // //             ),
// // //             const SizedBox(height: 16),

// // //             // ── Time Limits card ─────────────────────────────────────────
// // //             SectionCard(
// // //               title: '⏱  Daily Time Limits',
// // //               children: [
// // //                 const Text(
// // //                   'Set how many minutes per day a user can spend in an app. '
// // //                   'The notification updates live with the countdown. '
// // //                   'When the budget hits 0, the app is blocked automatically.',
// // //                   style: TextStyle(fontSize: 13, color: Colors.black54),
// // //                 ),
// // //                 const SizedBox(height: 12),
// // //                 FilledButton.icon(
// // //                   onPressed: _showSetTimeLimitSheet,
// // //                   icon: const Icon(Icons.timer),
// // //                   label: const Text('Set Time Limit for an App'),
// // //                 ),
// // //                 const SizedBox(height: 8),
// // //                 OutlinedButton.icon(
// // //                   onPressed: _loadTimeLimits,
// // //                   icon: const Icon(Icons.refresh),
// // //                   label: const Text('Refresh Usage Stats'),
// // //                 ),
// // //                 const SizedBox(height: 12),
// // //                 if (_timeLimits.isEmpty)
// // //                   const Padding(
// // //                     padding: EdgeInsets.symmetric(vertical: 8),
// // //                     child: Text(
// // //                       'No time limits configured.',
// // //                       style: TextStyle(color: Colors.grey),
// // //                     ),
// // //                   )
// // //                 else
// // //                   ..._timeLimits.map(
// // //                     (limit) => TimeLimitTile(
// // //                       limit: limit,
// // //                       plugin: _plugin,
// // //                       onChanged: _loadTimeLimits,
// // //                     ),
// // //                   ),
// // //               ],
// // //             ),
// // //           ],
// // //         ),
// // //       ),
// // //     );
// // //   }
// // // }

// // // // ─── Set Time Limit Bottom Sheet ──────────────────────────────────────────────

// // // class SetTimeLimitSheet extends StatefulWidget {
// // //   const SetTimeLimitSheet({required this.apps, required this.plugin});

// // //   final List<Map<String, dynamic>> apps;
// // //   final ZoAppBlocker plugin;

// // //   @override
// // //   State<SetTimeLimitSheet> createState() => SetTimeLimitSheetState();
// // // }

// // // class SetTimeLimitSheetState extends State<SetTimeLimitSheet> {
// // //   Map<String, dynamic>? _selectedApp;
// // //   int _limitMinutes = 30;
// // //   bool _saving = false;

// // //   @override
// // //   Widget build(BuildContext context) {
// // //     return DraggableScrollableSheet(
// // //       expand: false,
// // //       initialChildSize: 0.75,
// // //       maxChildSize: 0.95,
// // //       builder: (ctx, scrollController) {
// // //         return Padding(
// // //           padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
// // //           child: Column(
// // //             crossAxisAlignment: CrossAxisAlignment.stretch,
// // //             children: [
// // //               Center(
// // //                 child: Container(
// // //                   width: 36,
// // //                   height: 4,
// // //                   margin: const EdgeInsets.only(bottom: 12),
// // //                   decoration: BoxDecoration(
// // //                     color: Colors.grey.shade300,
// // //                     borderRadius: BorderRadius.circular(2),
// // //                   ),
// // //                 ),
// // //               ),
// // //               const Text(
// // //                 'Set Daily Time Limit',
// // //                 style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
// // //               ),
// // //               const SizedBox(height: 16),

// // //               const Text(
// // //                 '1. Pick an app',
// // //                 style: TextStyle(fontWeight: FontWeight.w600),
// // //               ),
// // //               const SizedBox(height: 8),
// // //               Expanded(
// // //                 child: ListView.builder(
// // //                   controller: scrollController,
// // //                   itemCount: widget.apps.length,
// // //                   itemBuilder: (context, index) {
// // //                     final app = widget.apps[index];
// // //                     final selected =
// // //                         _selectedApp?['packageName'] == app['packageName'];
// // //                     return ListTile(
// // //                       dense: true,
// // //                       selected: selected,
// // //                       selectedTileColor: Theme.of(
// // //                         context,
// // //                       ).colorScheme.primaryContainer.withOpacity(0.3),
// // //                       shape: RoundedRectangleBorder(
// // //                         borderRadius: BorderRadius.circular(8),
// // //                       ),
// // //                       leading: AppIcon(
// // //                         packageName: app['packageName'] ?? '',
// // //                         size: 36,
// // //                       ),
// // //                       title: Text(app['appName'] ?? ''),
// // //                       subtitle: Text(
// // //                         app['packageName'] ?? '',
// // //                         style: const TextStyle(fontSize: 11),
// // //                       ),
// // //                       trailing: selected
// // //                           ? Icon(
// // //                               Icons.check_circle,
// // //                               color: Theme.of(context).colorScheme.primary,
// // //                             )
// // //                           : null,
// // //                       onTap: () => setState(() => _selectedApp = app),
// // //                     );
// // //                   },
// // //                 ),
// // //               ),

// // //               if (_selectedApp != null) ...[
// // //                 const Divider(height: 24),
// // //                 Text(
// // //                   '2. Daily limit for ${_selectedApp!['appName']}',
// // //                   style: const TextStyle(fontWeight: FontWeight.w600),
// // //                 ),
// // //                 const SizedBox(height: 8),
// // //                 Row(
// // //                   children: [
// // //                     Expanded(
// // //                       child: Slider(
// // //                         value: _limitMinutes.toDouble(),
// // //                         min: 1,
// // //                         max: 180,
// // //                         divisions: 179,
// // //                         label: '$_limitMinutes min',
// // //                         onChanged: (v) =>
// // //                             setState(() => _limitMinutes = v.round()),
// // //                       ),
// // //                     ),
// // //                     const SizedBox(width: 8),
// // //                     SizedBox(
// // //                       width: 70,
// // //                       child: Text(
// // //                         '$_limitMinutes min',
// // //                         style: const TextStyle(
// // //                           fontWeight: FontWeight.bold,
// // //                           fontSize: 16,
// // //                         ),
// // //                         textAlign: TextAlign.center,
// // //                       ),
// // //                     ),
// // //                   ],
// // //                 ),
// // //                 Wrap(
// // //                   spacing: 8,
// // //                   children: [15, 30, 45, 60, 90, 120].map((m) {
// // //                     return ChoiceChip(
// // //                       label: Text('${m}m'),
// // //                       selected: _limitMinutes == m,
// // //                       onSelected: (_) => setState(() => _limitMinutes = m),
// // //                     );
// // //                   }).toList(),
// // //                 ),
// // //                 const SizedBox(height: 16),
// // //                 FilledButton(
// // //                   onPressed: _saving
// // //                       ? null
// // //                       : () async {
// // //                           setState(() => _saving = true);
// // //                           await widget.plugin.setAppTimeLimit(
// // //                             packageName: _selectedApp!['packageName'] as String,
// // //                             dailyLimitMinutes: _limitMinutes,
// // //                           );
// // //                           if (context.mounted) {
// // //                             ScaffoldMessenger.of(context).showSnackBar(
// // //                               SnackBar(
// // //                                 content: Text(
// // //                                   'Set ${_limitMinutes}m daily limit for '
// // //                                   '${_selectedApp!['appName']}',
// // //                                 ),
// // //                               ),
// // //                             );
// // //                             Navigator.pop(context);
// // //                           }
// // //                         },
// // //                   child: _saving
// // //                       ? const SizedBox(
// // //                           width: 20,
// // //                           height: 20,
// // //                           child: CircularProgressIndicator(strokeWidth: 2),
// // //                         )
// // //                       : const Text('Save Time Limit'),
// // //                 ),
// // //               ],
// // //             ],
// // //           ),
// // //         );
// // //       },
// // //     );
// // //   }
// // // }

// // // // ─── Time Limit Tile ──────────────────────────────────────────────────────────

// // // class TimeLimitTile extends StatelessWidget {
// // //   const TimeLimitTile({
// // //     required this.limit,
// // //     required this.plugin,
// // //     required this.onChanged,
// // //   });

// // //   final AppTimeLimit limit;
// // //   final ZoAppBlocker plugin;
// // //   final VoidCallback onChanged;

// // //   String _fmtSeconds(int s) {
// // //     if (s >= 60) return '${s ~/ 60}m ${s % 60}s';
// // //     return '${s}s';
// // //   }

// // //   @override
// // //   Widget build(BuildContext context) {
// // //     final color = limit.isExhausted
// // //         ? Colors.red
// // //         : limit.usageRatio > 0.75
// // //         ? Colors.orange
// // //         : Theme.of(context).colorScheme.primary;

// // //     return Card(
// // //       margin: const EdgeInsets.only(bottom: 8),
// // //       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
// // //       child: Padding(
// // //         padding: const EdgeInsets.all(12),
// // //         child: Column(
// // //           crossAxisAlignment: CrossAxisAlignment.start,
// // //           children: [
// // //             Row(
// // //               children: [
// // //                 AppIcon(packageName: limit.packageName, size: 36),
// // //                 const SizedBox(width: 10),
// // //                 Expanded(
// // //                   child: Column(
// // //                     crossAxisAlignment: CrossAxisAlignment.start,
// // //                     children: [
// // //                       Text(
// // //                         limit.packageName.split('.').last,
// // //                         style: const TextStyle(fontWeight: FontWeight.bold),
// // //                         overflow: TextOverflow.ellipsis,
// // //                       ),
// // //                       Text(
// // //                         limit.packageName,
// // //                         style: const TextStyle(
// // //                           fontSize: 11,
// // //                           color: Colors.black45,
// // //                         ),
// // //                         overflow: TextOverflow.ellipsis,
// // //                       ),
// // //                     ],
// // //                   ),
// // //                 ),
// // //                 if (limit.isExhausted)
// // //                   const Chip(
// // //                     label: Text(
// // //                       'BLOCKED',
// // //                       style: TextStyle(fontSize: 11, color: Colors.white),
// // //                     ),
// // //                     backgroundColor: Colors.red,
// // //                     padding: EdgeInsets.zero,
// // //                     visualDensity: VisualDensity.compact,
// // //                   ),
// // //               ],
// // //             ),
// // //             const SizedBox(height: 10),
// // //             ClipRRect(
// // //               borderRadius: BorderRadius.circular(4),
// // //               child: LinearProgressIndicator(
// // //                 value: limit.usageRatio,
// // //                 minHeight: 8,
// // //                 color: color,
// // //                 backgroundColor: color.withOpacity(0.15),
// // //               ),
// // //             ),
// // //             const SizedBox(height: 6),
// // //             Row(
// // //               mainAxisAlignment: MainAxisAlignment.spaceBetween,
// // //               children: [
// // //                 Text(
// // //                   limit.isExhausted
// // //                       ? 'Budget exhausted'
// // //                       : '${_fmtSeconds(limit.remainingSeconds)} remaining',
// // //                   style: TextStyle(
// // //                     fontSize: 12,
// // //                     color: color,
// // //                     fontWeight: FontWeight.w600,
// // //                   ),
// // //                 ),
// // //                 Text(
// // //                   '${_fmtSeconds(limit.usedSeconds)} / '
// // //                   '${_fmtSeconds(limit.dailyLimitSeconds)}',
// // //                   style: const TextStyle(fontSize: 12, color: Colors.black45),
// // //                 ),
// // //               ],
// // //             ),
// // //             const SizedBox(height: 8),
// // //             Row(
// // //               children: [
// // //                 Expanded(
// // //                   child: OutlinedButton.icon(
// // //                     onPressed: () async {
// // //                       await plugin.resetAppUsage(limit.packageName);
// // //                       // FIX 10: Guard context after async gap.
// // //                       if (!context.mounted) return;
// // //                       ScaffoldMessenger.of(context).showSnackBar(
// // //                         const SnackBar(content: Text('Usage reset to 0')),
// // //                       );
// // //                       onChanged();
// // //                     },
// // //                     icon: const Icon(Icons.restart_alt, size: 16),
// // //                     label: const Text('Reset', style: TextStyle(fontSize: 13)),
// // //                     style: OutlinedButton.styleFrom(
// // //                       padding: const EdgeInsets.symmetric(vertical: 4),
// // //                     ),
// // //                   ),
// // //                 ),
// // //                 const SizedBox(width: 8),
// // //                 Expanded(
// // //                   child: OutlinedButton.icon(
// // //                     onPressed: () async {
// // //                       await plugin.removeAppTimeLimit(limit.packageName);
// // //                       // FIX 10: Guard context after async gap.
// // //                       if (!context.mounted) return;
// // //                       ScaffoldMessenger.of(context).showSnackBar(
// // //                         const SnackBar(content: Text('Time limit removed')),
// // //                       );
// // //                       onChanged();
// // //                     },
// // //                     icon: const Icon(Icons.delete_outline, size: 16),
// // //                     label: const Text('Remove', style: TextStyle(fontSize: 13)),
// // //                     style: OutlinedButton.styleFrom(
// // //                       padding: const EdgeInsets.symmetric(vertical: 4),
// // //                       foregroundColor: Colors.red,
// // //                     ),
// // //                   ),
// // //                 ),
// // //               ],
// // //             ),
// // //           ],
// // //         ),
// // //       ),
// // //     );
// // //   }
// // // }

// // // // ─── Shared helper widgets ────────────────────────────────────────────────────

// // // class AppIcon extends StatelessWidget {
// // //   const AppIcon({required this.packageName, this.size = 40});

// // //   final String packageName;
// // //   final double size;

// // //   @override
// // //   Widget build(BuildContext context) {
// // //     return FutureBuilder<Uint8List?>(
// // //       future: ZoAppBlocker.instance.getAppIcon(packageName),
// // //       builder: (context, snapshot) {
// // //         if (snapshot.connectionState == ConnectionState.waiting) {
// // //           return SizedBox(
// // //             width: size,
// // //             height: size,
// // //             child: const Padding(
// // //               padding: EdgeInsets.all(8),
// // //               child: CircularProgressIndicator(strokeWidth: 2),
// // //             ),
// // //           );
// // //         }
// // //         if (snapshot.hasData && snapshot.data != null) {
// // //           return Image.memory(snapshot.data!, width: size, height: size);
// // //         }
// // //         return Icon(Icons.android, size: size, color: Colors.grey);
// // //       },
// // //     );
// // //   }
// // // }

// // // class SectionCard extends StatelessWidget {
// // //   const SectionCard({required this.title, required this.children});

// // //   final String title;
// // //   final List<Widget> children;

// // //   @override
// // //   Widget build(BuildContext context) {
// // //     return Card(
// // //       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
// // //       elevation: 2,
// // //       child: Padding(
// // //         padding: const EdgeInsets.all(16),
// // //         child: Column(
// // //           crossAxisAlignment: CrossAxisAlignment.stretch,
// // //           children: [
// // //             Text(
// // //               title,
// // //               style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
// // //             ),
// // //             const Divider(height: 20),
// // //             ...children,
// // //           ],
// // //         ),
// // //       ),
// // //     );
// // //   }
// // // }
// // // import 'dart:io';
// // // import 'package:flutter/material.dart';
// // // import 'dart:typed_data';
// // // import 'package:flutter/services.dart'; // ── NEW: Required for SystemNavigator
// // // import 'package:zo_app_blocker/zo_app_blocker.dart';

// // // @pragma('vm:entry-point')
// // // void onBlockScreenRequested() {
// // //   ZoBlockScreenRunner.run(
// // //     // 1. Rename this to 'blockContext' so it doesn't get confused
// // //     // with the StatefulBuilder's context below.
// // //     builder: (blockContext) {
// // //       // Use the singleton instance of the plugin to perform actions
// // //       final plugin = ZoAppBlocker.instance;
// // //       return StatefulBuilder(
// // //         builder: (context, setState) {
// // //           final pinController = TextEditingController();
// // //           String errorMessage = '';

// // //           return Scaffold(
// // //             backgroundColor: Colors.black87,
// // //             body: Center(
// // //               child: Padding(
// // //                 padding: const EdgeInsets.all(24.0),
// // //                 child: Column(
// // //                   mainAxisAlignment: MainAxisAlignment.center,
// // //                   children: [
// // //                     // 2. We can pull the blocked app's icon directly from blockContext!
// // //                     if (blockContext.appIcon != null &&
// // //                         blockContext.appIcon!.isNotEmpty)
// // //                       Image.memory(
// // //                         blockContext.appIcon!,
// // //                         width: 100,
// // //                         height: 100,
// // //                       ),
// // //                     const SizedBox(height: 24),

// // //                     // 3. We can pull the app's name directly from blockContext!
// // //                     Text(
// // //                       '${blockContext.appName ?? 'App'} is Blocked!',
// // //                       style: const TextStyle(
// // //                         color: Colors.white,
// // //                         fontSize: 24,
// // //                         fontWeight: FontWeight.bold,
// // //                       ),
// // //                     ),
// // //                     const SizedBox(height: 12),
// // //                     const Text(
// // //                       'Ansharah Kutt Khao gi. Enter PIN to unlock.',
// // //                       style: TextStyle(color: Colors.white70),
// // //                     ),
// // //                     const SizedBox(height: 24),

// // //                     TextField(
// // //                       controller: pinController,
// // //                       keyboardType: TextInputType.number,
// // //                       obscureText: true,
// // //                       style: const TextStyle(color: Colors.white),
// // //                       decoration: InputDecoration(
// // //                         hintText: 'Enter PIN (e.g., 1234)',
// // //                         hintStyle: const TextStyle(color: Colors.white54),
// // //                         errorText: errorMessage.isNotEmpty
// // //                             ? errorMessage
// // //                             : null,
// // //                         filled: true,
// // //                         fillColor: Colors.white12,
// // //                         border: OutlineInputBorder(
// // //                           borderRadius: BorderRadius.circular(8),
// // //                         ),
// // //                       ),
// // //                     ),
// // //                     const SizedBox(height: 24),

// // //                     Row(
// // //                       mainAxisAlignment: MainAxisAlignment.spaceEvenly,
// // //                       children: [
// // //                         ElevatedButton.icon(
// // //                           // 4. Use the package's built-in dismiss method to close the overlay
// // //                           onPressed: blockContext.onDismiss,
// // //                           icon: const Icon(Icons.exit_to_app),
// // //                           label: const Text('Exit'),
// // //                         ),
// // //                         ElevatedButton.icon(
// // //                           onPressed: () {
// // //                             if (pinController.text == '1234') {
// // //                               // Use the plugin instance to grant temporary access
// // //                               // plugin.unlockApp(duration: const Duration(minutes: 15));
// // //                             } else {
// // //                               setState(() => errorMessage = 'Incorrect PIN!');
// // //                             }
// // //                           },
// // //                           icon: const Icon(Icons.lock_open),
// // //                           label: const Text('Unlock'),
// // //                         ),
// // //                       ],
// // //                     ),
// // //                   ],
// // //                 ),
// // //               ),
// // //             ),
// // //           );
// // //         },
// // //       );
// // //     },
// // //   );
// // // }

// // // void main() {
// // //   WidgetsFlutterBinding.ensureInitialized();
// // //   ZoAppBlocker.instance.initialize(blockScreenCallback: onBlockScreenRequested);
// // //   runApp(const MyApp());
// // // }

// // // class MyApp extends StatelessWidget {
// // //   const MyApp({super.key});

// // //   @override
// // //   Widget build(BuildContext context) {
// // //     return MaterialApp(
// // //       title: 'Zo App Blocker',
// // //       theme: ThemeData(
// // //         colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
// // //         useMaterial3: true,
// // //       ),
// // //       home: const HomeScreen(),
// // //     );
// // //   }
// // // }

// // // class HomeScreen extends StatefulWidget {
// // //   const HomeScreen({super.key});

// // //   @override
// // //   State<HomeScreen> createState() => _HomeScreenState();
// // // }

// // // class _HomeScreenState extends State<HomeScreen> {
// // //   final _plugin = ZoAppBlocker.instance;
// // //   String _usageStatsStatus = 'Unknown';
// // //   String _overlayStatus = 'Unknown';
// // //   List<Map<String, dynamic>> _blockedApps = [];
// // //   List<AppTimeLimit> _timeLimits = [];

// // //   // ── FIXED: Removed the main Settings app
// // //   final List<String> _protectedSystemApps = [
// // //     'com.google.android.packageinstaller', // Blocks the actual Uninstall/Install popup
// // //     'com.android.vending', // Blocks Google Play Store (so they can't uninstall from there)
// // //   ];
// // //   @override
// // //   void initState() {
// // //     super.initState();
// // //     _checkPermission();
// // //     _loadBlockedApps();
// // //     _loadTimeLimits();

// // //     _plugin.setNotificationConfig(
// // //       notificationBannerTitle: 'Stop Right There!',
// // //       notificationBannerDescription: 'You blocked this app. Get back to work!',
// // //     );
// // //   }

// // //   Future<void> _checkPermission() async {
// // //     final usageStatus = await _plugin.checkUsageStatsPermission();
// // //     final overlayStatus = await _plugin.checkOverlayPermission();
// // //     setState(() {
// // //       _usageStatsStatus = usageStatus;
// // //       _overlayStatus = overlayStatus;
// // //     });
// // //   }

// // //   Future<void> _loadBlockedApps() async {
// // //     final apps = await _plugin.getBlockedApps();
// // //     setState(() => _blockedApps = apps);
// // //   }

// // //   Future<void> _loadTimeLimits() async {
// // //     final limits = await _plugin.getAppTimeLimits();
// // //     setState(() => _timeLimits = limits);
// // //   }

// // //   Future<void> _requestPermissions() async {
// // //     if (Platform.isAndroid) {
// // //       await _plugin.requestNotificationPermission();
// // //       final notifStatus = await _plugin.checkNotificationPermission();
// // //       if (notifStatus != 'granted') {
// // //         if (!mounted) return;
// // //         ScaffoldMessenger.of(context).showSnackBar(
// // //           const SnackBar(
// // //             content: Text(
// // //               'Notification permission is required for the background service.',
// // //             ),
// // //           ),
// // //         );
// // //       }
// // //     }
// // //     await _plugin.requestUsageStatsPermission();
// // //     await _plugin.requestOverlayPermission();
// // //     _checkPermission();
// // //   }

// // //   Future<void> _selectAndBlockApps() async {
// // //     try {
// // //       final apps = await _plugin.getApps();

// // //       if (Platform.isIOS) {
// // //         _loadBlockedApps();
// // //         return;
// // //       }

// // //       if (apps.isEmpty) return;
// // //       if (!mounted) return;

// // //       showModalBottomSheet(
// // //         context: context,
// // //         builder: (context) {
// // //           return Column(
// // //             children: [
// // //               const Padding(
// // //                 padding: EdgeInsets.all(16.0),
// // //                 child: Text(
// // //                   'Select an app to block',
// // //                   style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
// // //                 ),
// // //               ),
// // //               Expanded(
// // //                 child: ListView.builder(
// // //                   itemCount: apps.length,
// // //                   itemBuilder: (context, index) {
// // //                     final app = apps[index];
// // //                     return ListTile(
// // //                       leading: AppIcon(packageName: app['packageName'] ?? ''),
// // //                       title: Text(app['appName'] ?? ''),
// // //                       subtitle: Text(app['packageName'] ?? ''),
// // //                       onTap: () async {
// // //                         final nav = Navigator.of(context);
// // //                         final scaffold = ScaffoldMessenger.of(context);
// // //                         await _plugin.blockApps([app['packageName']]);
// // //                         if (!mounted) return;
// // //                         nav.pop();
// // //                         scaffold.showSnackBar(
// // //                           SnackBar(content: Text('Blocked ${app['appName']}')),
// // //                         );
// // //                         _loadBlockedApps();
// // //                       },
// // //                     );
// // //                   },
// // //                 ),
// // //               ),
// // //             ],
// // //           );
// // //         },
// // //       );
// // //     } catch (e) {
// // //       if (!mounted) return;
// // //       ScaffoldMessenger.of(
// // //         context,
// // //       ).showSnackBar(SnackBar(content: Text('Error: $e')));
// // //     }
// // //   }

// // //   /// Shows an app picker and then prompts for a minute limit.
// // //   Future<void> _showSetTimeLimitSheet() async {
// // //     final apps = await _plugin.getApps();
// // //     if (apps.isEmpty || !mounted) return;

// // //     showModalBottomSheet(
// // //       context: context,
// // //       isScrollControlled: true,
// // //       builder: (ctx) => SetTimeLimitSheet(apps: apps, plugin: _plugin),
// // //     ).then((_) => _loadTimeLimits());
// // //   }

// // //   Future<void> _showActivityLog() async {
// // //     final log = await _plugin.getBlockActivityLog();
// // //     if (!mounted) return;

// // //     showModalBottomSheet(
// // //       context: context,
// // //       builder: (context) {
// // //         return Column(
// // //           children: [
// // //             Padding(
// // //               padding: const EdgeInsets.all(16.0),
// // //               child: Row(
// // //                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
// // //                 children: [
// // //                   const Text(
// // //                     'Block Activity Log',
// // //                     style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
// // //                   ),
// // //                   TextButton(
// // //                     onPressed: () async {
// // //                       await _plugin.clearBlockActivityLog();
// // //                       if (context.mounted) {
// // //                         Navigator.pop(context);
// // //                         _showActivityLog();
// // //                       }
// // //                     },
// // //                     child: const Text('Clear'),
// // //                   ),
// // //                 ],
// // //               ),
// // //             ),
// // //             Expanded(
// // //               child: log.isEmpty
// // //                   ? const Center(child: Text('No activity yet.'))
// // //                   : ListView.builder(
// // //                       itemCount: log.length,
// // //                       itemBuilder: (context, index) {
// // //                         final entry = log[index];
// // //                         final packageName = entry['packageName'] as String;
// // //                         final timestamp = entry['timestamp'] as int;
// // //                         final date = DateTime.fromMillisecondsSinceEpoch(
// // //                           timestamp,
// // //                         );
// // //                         return ListTile(
// // //                           leading: AppIcon(packageName: packageName, size: 32),
// // //                           title: Text(packageName),
// // //                           subtitle: Text('${date.toLocal()}'.split('.')[0]),
// // //                         );
// // //                       },
// // //                     ),
// // //             ),
// // //           ],
// // //         );
// // //       },
// // //     );
// // //   }

// // //   @override
// // //   Widget build(BuildContext context) {
// // //     return Scaffold(
// // //       appBar: AppBar(
// // //         title: const Text('Zo App Blocker Example'),
// // //         backgroundColor: Theme.of(context).colorScheme.inversePrimary,
// // //       ),
// // //       body: RefreshIndicator(
// // //         onRefresh: () async {
// // //           await _loadBlockedApps();
// // //           await _loadTimeLimits();
// // //         },
// // //         child: ListView(
// // //           padding: const EdgeInsets.all(16),
// // //           children: [
// // //             // ── Permission card ──────────────────────────────────────────
// // //             SectionCard(
// // //               title: 'Permissions',
// // //               children: [
// // //                 ListTile(
// // //                   dense: true,
// // //                   leading: Icon(
// // //                     (_usageStatsStatus == 'granted' &&
// // //                             _overlayStatus == 'granted')
// // //                         ? Icons.check_circle
// // //                         : Icons.warning_amber_rounded,
// // //                     color:
// // //                         (_usageStatsStatus == 'granted' &&
// // //                             _overlayStatus == 'granted')
// // //                         ? Colors.green
// // //                         : Colors.orange,
// // //                   ),
// // //                   title: Text(
// // //                     'Usage Stats: $_usageStatsStatus\nOverlay: $_overlayStatus',
// // //                   ),
// // //                 ),
// // //                 const SizedBox(height: 4),
// // //                 FilledButton.icon(
// // //                   onPressed: _requestPermissions,
// // //                   icon: const Icon(Icons.security),
// // //                   label: const Text('Request Permissions'),
// // //                 ),
// // //               ],
// // //             ),
// // //             const SizedBox(height: 16),
// // //             SectionCard(
// // //               title: '🛡️ Uninstall Protection',
// // //               children: [
// // //                 const Text(
// // //                   'Block device settings and the Play Store to prevent users from uninstalling this app.',
// // //                   style: TextStyle(fontSize: 13, color: Colors.black54),
// // //                 ),
// // //                 const SizedBox(height: 12),
// // //                 FilledButton.icon(
// // //                   onPressed: () async {
// // //                     // Send the system apps to the blocker engine
// // //                     await _plugin.blockApps(_protectedSystemApps);

// // //                     // Refresh the UI list
// // //                     _loadBlockedApps();

// // //                     if (!mounted) return;
// // //                     ScaffoldMessenger.of(context).showSnackBar(
// // //                       const SnackBar(
// // //                         content: Text('Uninstall Protection Enabled!'),
// // //                       ),
// // //                     );
// // //                   },
// // //                   icon: const Icon(Icons.security),
// // //                   label: const Text('Enable Protection'),
// // //                   style: FilledButton.styleFrom(
// // //                     backgroundColor: Colors.red.shade700,
// // //                   ),
// // //                 ),
// // //               ],
// // //             ),
// // //             const SizedBox(height: 16),

// // //             // ── Block Apps card ──────────────────────────────────────────
// // //             SectionCard(
// // //               title: 'App Blocking',
// // //               children: [
// // //                 Row(
// // //                   children: [
// // //                     Expanded(
// // //                       child: FilledButton.icon(
// // //                         onPressed: _selectAndBlockApps,
// // //                         icon: const Icon(Icons.block),
// // //                         label: const Text('Block an App'),
// // //                       ),
// // //                     ),
// // //                     const SizedBox(width: 8),
// // //                     Expanded(
// // //                       child: OutlinedButton.icon(
// // //                         onPressed: () async {
// // //                           final scaffold = ScaffoldMessenger.of(context);
// // //                           await _plugin.unblockAll();
// // //                           if (!mounted) return;
// // //                           scaffold.showSnackBar(
// // //                             const SnackBar(content: Text('All apps unblocked')),
// // //                           );
// // //                           _loadBlockedApps();
// // //                         },
// // //                         icon: const Icon(Icons.lock_open),
// // //                         label: const Text('Unblock All'),
// // //                       ),
// // //                     ),
// // //                   ],
// // //                 ),
// // //                 const SizedBox(height: 12),
// // //                 Row(
// // //                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
// // //                   children: [
// // //                     Text(
// // //                       'Blocked Apps (${_blockedApps.length})',
// // //                       style: const TextStyle(fontWeight: FontWeight.w600),
// // //                     ),
// // //                     TextButton(
// // //                       onPressed: _showActivityLog,
// // //                       child: const Text('Activity Log'),
// // //                     ),
// // //                   ],
// // //                 ),
// // //                 if (_blockedApps.isEmpty)
// // //                   const Padding(
// // //                     padding: EdgeInsets.symmetric(vertical: 8),
// // //                     child: Text(
// // //                       'No apps currently blocked.',
// // //                       style: TextStyle(color: Colors.grey),
// // //                     ),
// // //                   )
// // //                 else
// // //                   ...(_blockedApps.map(
// // //                     (app) => ListTile(
// // //                       dense: true,
// // //                       contentPadding: EdgeInsets.zero,
// // //                       leading: AppIcon(
// // //                         packageName: app['packageName'] ?? '',
// // //                         size: 36,
// // //                       ),
// // //                       title: Text(app['appName'] ?? 'Unknown'),
// // //                       subtitle: Text(
// // //                         app['packageName'] ?? '',
// // //                         style: const TextStyle(fontSize: 11),
// // //                       ),
// // //                       trailing: IconButton(
// // //                         icon: const Icon(
// // //                           Icons.delete_outline,
// // //                           color: Colors.red,
// // //                         ),
// // //                         onPressed: () async {
// // //                           await _plugin.unblockApps([
// // //                             app['packageName'] as String,
// // //                           ]);
// // //                           _loadBlockedApps();
// // //                         },
// // //                       ),
// // //                     ),
// // //                   )),
// // //               ],
// // //             ),
// // //             const SizedBox(height: 16),

// // //             // ── Time Limits card ─────────────────────────────────────────
// // //             SectionCard(
// // //               title: '⏱  Daily Time Limits',
// // //               children: [
// // //                 const Text(
// // //                   'Set how many minutes per day a user can spend in an app. '
// // //                   'The notification updates live with the countdown. '
// // //                   'When the budget hits 0, the app is blocked automatically.',
// // //                   style: TextStyle(fontSize: 13, color: Colors.black54),
// // //                 ),
// // //                 const SizedBox(height: 12),
// // //                 FilledButton.icon(
// // //                   onPressed: _showSetTimeLimitSheet,
// // //                   icon: const Icon(Icons.timer),
// // //                   label: const Text('Set Time Limit for an App'),
// // //                 ),
// // //                 const SizedBox(height: 8),
// // //                 OutlinedButton.icon(
// // //                   onPressed: _loadTimeLimits,
// // //                   icon: const Icon(Icons.refresh),
// // //                   label: const Text('Refresh Usage Stats'),
// // //                 ),
// // //                 const SizedBox(height: 12),
// // //                 if (_timeLimits.isEmpty)
// // //                   const Padding(
// // //                     padding: EdgeInsets.symmetric(vertical: 8),
// // //                     child: Text(
// // //                       'No time limits configured.',
// // //                       style: TextStyle(color: Colors.grey),
// // //                     ),
// // //                   )
// // //                 else
// // //                   ...(_timeLimits.map(
// // //                     (limit) => TimeLimitTile(
// // //                       limit: limit,
// // //                       plugin: _plugin,
// // //                       onChanged: _loadTimeLimits,
// // //                     ),
// // //                   )),
// // //               ],
// // //             ),
// // //           ],
// // //         ),
// // //       ),
// // //     );
// // //   }
// // // }

// // // // ─────────────────────────────────────────────────────────────────────────────
// // // // Set Time Limit Bottom Sheet
// // // // ─────────────────────────────────────────────────────────────────────────────

// // // class SetTimeLimitSheet extends StatefulWidget {
// // //   const SetTimeLimitSheet({required this.apps, required this.plugin});

// // //   final List<Map<String, dynamic>> apps;
// // //   final ZoAppBlocker plugin;

// // //   @override
// // //   State<SetTimeLimitSheet> createState() => SetTimeLimitSheetState();
// // // }

// // // class SetTimeLimitSheetState extends State<SetTimeLimitSheet> {
// // //   Map<String, dynamic>? _selectedApp;
// // //   int _limitMinutes = 30;
// // //   bool _saving = false;

// // //   @override
// // //   Widget build(BuildContext context) {
// // //     return DraggableScrollableSheet(
// // //       expand: false,
// // //       initialChildSize: 0.75,
// // //       maxChildSize: 0.95,
// // //       builder: (ctx, scrollController) {
// // //         return Padding(
// // //           padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
// // //           child: Column(
// // //             crossAxisAlignment: CrossAxisAlignment.stretch,
// // //             children: [
// // //               Center(
// // //                 child: Container(
// // //                   width: 36,
// // //                   height: 4,
// // //                   margin: const EdgeInsets.only(bottom: 12),
// // //                   decoration: BoxDecoration(
// // //                     color: Colors.grey.shade300,
// // //                     borderRadius: BorderRadius.circular(2),
// // //                   ),
// // //                 ),
// // //               ),
// // //               const Text(
// // //                 'Set Daily Time Limit',
// // //                 style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
// // //               ),
// // //               const SizedBox(height: 16),

// // //               // App picker
// // //               const Text(
// // //                 '1. Pick an app',
// // //                 style: TextStyle(fontWeight: FontWeight.w600),
// // //               ),
// // //               const SizedBox(height: 8),
// // //               Expanded(
// // //                 child: ListView.builder(
// // //                   controller: scrollController,
// // //                   itemCount: widget.apps.length,
// // //                   itemBuilder: (context, index) {
// // //                     final app = widget.apps[index];
// // //                     final selected =
// // //                         _selectedApp?['packageName'] == app['packageName'];
// // //                     return ListTile(
// // //                       dense: true,
// // //                       selected: selected,
// // //                       selectedTileColor: Theme.of(
// // //                         context,
// // //                       ).colorScheme.primaryContainer.withOpacity(0.3),
// // //                       shape: RoundedRectangleBorder(
// // //                         borderRadius: BorderRadius.circular(8),
// // //                       ),
// // //                       leading: AppIcon(
// // //                         packageName: app['packageName'] ?? '',
// // //                         size: 36,
// // //                       ),
// // //                       title: Text(app['appName'] ?? ''),
// // //                       subtitle: Text(
// // //                         app['packageName'] ?? '',
// // //                         style: const TextStyle(fontSize: 11),
// // //                       ),
// // //                       trailing: selected
// // //                           ? Icon(
// // //                               Icons.check_circle,
// // //                               color: Theme.of(context).colorScheme.primary,
// // //                             )
// // //                           : null,
// // //                       onTap: () => setState(() => _selectedApp = app),
// // //                     );
// // //                   },
// // //                 ),
// // //               ),

// // //               if (_selectedApp != null) ...[
// // //                 const Divider(height: 24),
// // //                 Text(
// // //                   '2. Daily limit for ${_selectedApp!['appName']}',
// // //                   style: const TextStyle(fontWeight: FontWeight.w600),
// // //                 ),
// // //                 const SizedBox(height: 8),
// // //                 Row(
// // //                   children: [
// // //                     Expanded(
// // //                       child: Slider(
// // //                         value: _limitMinutes.toDouble(),
// // //                         min: 1,
// // //                         max: 180,
// // //                         divisions: 179,
// // //                         label: '$_limitMinutes min',
// // //                         onChanged: (v) =>
// // //                             setState(() => _limitMinutes = v.round()),
// // //                       ),
// // //                     ),
// // //                     const SizedBox(width: 8),
// // //                     SizedBox(
// // //                       width: 70,
// // //                       child: Text(
// // //                         '$_limitMinutes min',
// // //                         style: const TextStyle(
// // //                           fontWeight: FontWeight.bold,
// // //                           fontSize: 16,
// // //                         ),
// // //                         textAlign: TextAlign.center,
// // //                       ),
// // //                     ),
// // //                   ],
// // //                 ),
// // //                 // Quick-pick chips
// // //                 Wrap(
// // //                   spacing: 8,
// // //                   children: [15, 30, 45, 60, 90, 120].map((m) {
// // //                     return ChoiceChip(
// // //                       label: Text('${m}m'),
// // //                       selected: _limitMinutes == m,
// // //                       onSelected: (_) => setState(() => _limitMinutes = m),
// // //                     );
// // //                   }).toList(),
// // //                 ),
// // //                 const SizedBox(height: 16),
// // //                 FilledButton(
// // //                   onPressed: _saving
// // //                       ? null
// // //                       : () async {
// // //                           setState(() => _saving = true);
// // //                           await widget.plugin.setAppTimeLimit(
// // //                             packageName: _selectedApp!['packageName'] as String,
// // //                             dailyLimitMinutes: _limitMinutes,
// // //                           );
// // //                           if (context.mounted) {
// // //                             ScaffoldMessenger.of(context).showSnackBar(
// // //                               SnackBar(
// // //                                 content: Text(
// // //                                   'Set ${_limitMinutes}m daily limit for '
// // //                                   '${_selectedApp!['appName']}',
// // //                                 ),
// // //                               ),
// // //                             );
// // //                             Navigator.pop(context);
// // //                           }
// // //                         },
// // //                   child: _saving
// // //                       ? const SizedBox(
// // //                           width: 20,
// // //                           height: 20,
// // //                           child: CircularProgressIndicator(strokeWidth: 2),
// // //                         )
// // //                       : const Text('Save Time Limit'),
// // //                 ),
// // //               ],
// // //             ],
// // //           ),
// // //         );
// // //       },
// // //     );
// // //   }
// // // }

// // // // ─────────────────────────────────────────────────────────────────────────────
// // // // Time Limit Tile (shows progress bar + actions)
// // // // ─────────────────────────────────────────────────────────────────────────────

// // // class TimeLimitTile extends StatelessWidget {
// // //   const TimeLimitTile({
// // //     required this.limit,
// // //     required this.plugin,
// // //     required this.onChanged,
// // //   });

// // //   final AppTimeLimit limit;
// // //   final ZoAppBlocker plugin;
// // //   final VoidCallback onChanged;

// // //   String _fmtSeconds(int s) {
// // //     if (s >= 60) return '${s ~/ 60}m ${s % 60}s';
// // //     return '${s}s';
// // //   }

// // //   @override
// // //   Widget build(BuildContext context) {
// // //     final color = limit.isExhausted
// // //         ? Colors.red
// // //         : limit.usageRatio > 0.75
// // //         ? Colors.orange
// // //         : Theme.of(context).colorScheme.primary;

// // //     return Card(
// // //       margin: const EdgeInsets.only(bottom: 8),
// // //       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
// // //       child: Padding(
// // //         padding: const EdgeInsets.all(12),
// // //         child: Column(
// // //           crossAxisAlignment: CrossAxisAlignment.start,
// // //           children: [
// // //             Row(
// // //               children: [
// // //                 AppIcon(packageName: limit.packageName, size: 36),
// // //                 const SizedBox(width: 10),
// // //                 Expanded(
// // //                   child: Column(
// // //                     crossAxisAlignment: CrossAxisAlignment.start,
// // //                     children: [
// // //                       Text(
// // //                         limit.packageName.split('.').last,
// // //                         style: const TextStyle(fontWeight: FontWeight.bold),
// // //                         overflow: TextOverflow.ellipsis,
// // //                       ),
// // //                       Text(
// // //                         limit.packageName,
// // //                         style: const TextStyle(
// // //                           fontSize: 11,
// // //                           color: Colors.black45,
// // //                         ),
// // //                         overflow: TextOverflow.ellipsis,
// // //                       ),
// // //                     ],
// // //                   ),
// // //                 ),
// // //                 if (limit.isExhausted)
// // //                   const Chip(
// // //                     label: Text(
// // //                       'BLOCKED',
// // //                       style: TextStyle(fontSize: 11, color: Colors.white),
// // //                     ),
// // //                     backgroundColor: Colors.red,
// // //                     padding: EdgeInsets.zero,
// // //                     visualDensity: VisualDensity.compact,
// // //                   ),
// // //               ],
// // //             ),
// // //             const SizedBox(height: 10),
// // //             // Progress bar
// // //             ClipRRect(
// // //               borderRadius: BorderRadius.circular(4),
// // //               child: LinearProgressIndicator(
// // //                 value: limit.usageRatio,
// // //                 minHeight: 8,
// // //                 color: color,
// // //                 backgroundColor: color.withOpacity(0.15),
// // //               ),
// // //             ),
// // //             const SizedBox(height: 6),
// // //             Row(
// // //               mainAxisAlignment: MainAxisAlignment.spaceBetween,
// // //               children: [
// // //                 Text(
// // //                   limit.isExhausted
// // //                       ? 'Budget exhausted'
// // //                       : '${_fmtSeconds(limit.remainingSeconds)} remaining',
// // //                   style: TextStyle(
// // //                     fontSize: 12,
// // //                     color: color,
// // //                     fontWeight: FontWeight.w600,
// // //                   ),
// // //                 ),
// // //                 Text(
// // //                   '${_fmtSeconds(limit.usedSeconds)} / ${_fmtSeconds(limit.dailyLimitSeconds)}',
// // //                   style: const TextStyle(fontSize: 12, color: Colors.black45),
// // //                 ),
// // //               ],
// // //             ),
// // //             const SizedBox(height: 8),
// // //             // Action buttons
// // //             Row(
// // //               children: [
// // //                 Expanded(
// // //                   child: OutlinedButton.icon(
// // //                     onPressed: () async {
// // //                       await plugin.resetAppUsage(limit.packageName);
// // //                       ScaffoldMessenger.of(context).showSnackBar(
// // //                         const SnackBar(content: Text('Usage reset to 0')),
// // //                       );
// // //                       onChanged();
// // //                     },
// // //                     icon: const Icon(Icons.restart_alt, size: 16),
// // //                     label: const Text('Reset', style: TextStyle(fontSize: 13)),
// // //                     style: OutlinedButton.styleFrom(
// // //                       padding: const EdgeInsets.symmetric(vertical: 4),
// // //                     ),
// // //                   ),
// // //                 ),
// // //                 const SizedBox(width: 8),
// // //                 Expanded(
// // //                   child: OutlinedButton.icon(
// // //                     onPressed: () async {
// // //                       await plugin.removeAppTimeLimit(limit.packageName);
// // //                       ScaffoldMessenger.of(context).showSnackBar(
// // //                         const SnackBar(content: Text('Time limit removed')),
// // //                       );
// // //                       onChanged();
// // //                     },
// // //                     icon: const Icon(Icons.delete_outline, size: 16),
// // //                     label: const Text('Remove', style: TextStyle(fontSize: 13)),
// // //                     style: OutlinedButton.styleFrom(
// // //                       padding: const EdgeInsets.symmetric(vertical: 4),
// // //                       foregroundColor: Colors.red,
// // //                     ),
// // //                   ),
// // //                 ),
// // //               ],
// // //             ),
// // //           ],
// // //         ),
// // //       ),
// // //     );
// // //   }
// // // }

// // // // ─────────────────────────────────────────────────────────────────────────────
// // // // Shared helper widgets
// // // // ─────────────────────────────────────────────────────────────────────────────

// // // class AppIcon extends StatelessWidget {
// // //   const AppIcon({required this.packageName, this.size = 40});

// // //   final String packageName;
// // //   final double size;

// // //   @override
// // //   Widget build(BuildContext context) {
// // //     return FutureBuilder<Uint8List?>(
// // //       future: ZoAppBlocker.instance.getAppIcon(packageName),
// // //       builder: (context, snapshot) {
// // //         if (snapshot.connectionState == ConnectionState.waiting) {
// // //           return SizedBox(
// // //             width: size,
// // //             height: size,
// // //             child: const Padding(
// // //               padding: EdgeInsets.all(8),
// // //               child: CircularProgressIndicator(strokeWidth: 2),
// // //             ),
// // //           );
// // //         }
// // //         if (snapshot.hasData && snapshot.data != null) {
// // //           return Image.memory(snapshot.data!, width: size, height: size);
// // //         }
// // //         return Icon(Icons.android, size: size, color: Colors.grey);
// // //       },
// // //     );
// // //   }
// // // }

// // // class SectionCard extends StatelessWidget {
// // //   const SectionCard({required this.title, required this.children});

// // //   final String title;
// // //   final List<Widget> children;

// // //   @override
// // //   Widget build(BuildContext context) {
// // //     return Card(
// // //       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
// // //       elevation: 2,
// // //       child: Padding(
// // //         padding: const EdgeInsets.all(16),
// // //         child: Column(
// // //           crossAxisAlignment: CrossAxisAlignment.stretch,
// // //           children: [
// // //             Text(
// // //               title,
// // //               style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
// // //             ),
// // //             const Divider(height: 20),
// // //             ...children,
// // //           ],
// // //         ),
// // //       ),
// // //     );
// // //   }
// // // }
