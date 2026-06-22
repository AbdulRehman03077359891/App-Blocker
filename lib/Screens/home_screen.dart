import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:zo_app_blocker_demo/controllers/blocker_controller.getx.dart';
import 'package:zo_app_blocker_demo/controllers/home_controller.getx.dart';
import 'package:zo_app_blocker_demo/main.dart'; // Make sure this path is correct for DeviceAdminProtection
import 'package:zo_app_blocker_demo/widgets/app_icon.dart';
import 'package:zo_app_blocker_demo/widgets/section_card.dart';
import 'package:zo_app_blocker_demo/widgets/time_limit_tile.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Inject both controllers. BlockerController handles core data,
    // HomeController handles the UI logic (dialogs, bottom sheets).
    final controller = Get.find<BlockerController>();
    final homeController = Get.find<HomeController>();
    // final controller = Get.put(BlockerController());
    // final homeController = Get.put(HomeController());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Zo App Blocker'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: RefreshIndicator(
        onRefresh: controller.refreshAll,
        child: Obx(() {
          final permissionsOk =
              controller.usageStatsStatus.value == 'granted' &&
              controller.overlayStatus.value == 'granted';

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // --- PERMISSIONS SECTION ---
              SectionCard(
                title: 'Permissions',
                children: [
                  if (!permissionsOk)
                    Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange.shade300),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.warning_amber_rounded,
                            color: Colors.orange.shade700,
                          ),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Required permissions are missing — blocking '
                              'will not work until you grant them.',
                              style: TextStyle(fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ListTile(
                    dense: true,
                    leading: Icon(
                      permissionsOk
                          ? Icons.check_circle
                          : Icons.warning_amber_rounded,
                      color: permissionsOk ? Colors.green : Colors.orange,
                    ),
                    title: Text(
                      'Usage Stats: ${controller.usageStatsStatus.value}\nOverlay: ${controller.overlayStatus.value}',
                    ),
                  ),
                  const SizedBox(height: 4),
                  FilledButton.icon(
                    onPressed: controller.requestPermissions,
                    icon: const Icon(Icons.security),
                    label: const Text('Grant Permissions'),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // --- UNINSTALL PROTECTION SECTION ---
              SectionCard(
                title: '🛡️ Uninstall Protection',
                children: [
                  Row(
                    children: [
                      Icon(
                        controller.adminActive.value
                            ? Icons.verified_user
                            : Icons.gpp_maybe,
                        color: controller.adminActive.value
                            ? Colors.green
                            : Colors.orange,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          controller.adminActive.value
                              ? 'Active — must deactivate admin in Settings before uninstalling.'
                              : 'Off — tap to enable.',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (!controller.adminActive.value)
                    FilledButton.icon(
                      onPressed: () =>
                          DeviceAdminProtection.requestActivation(),
                      icon: const Icon(Icons.security),
                      label: const Text('Enable Protection'),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.red.shade700,
                      ),
                    ),
                  if (controller.isDeviceOwner.value) ...[
                    const SizedBox(height: 8),
                    FilledButton.icon(
                      onPressed: () => homeController.allowUninstall(context),
                      icon: const Icon(Icons.lock_open),
                      label: const Text('Allow Uninstall (PIN required)'),
                    ),
                  ] else
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'Full uninstall blocking requires Device Owner mode (see adb setup).',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),

              // --- APP BLOCKING SECTION ---
              SectionCard(
                title: 'App Blocking',
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () =>
                              homeController.selectAndBlockApps(context),
                          icon: const Icon(Icons.block),
                          label: const Text('Block an App'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () =>
                              homeController.unblockAllApps(context),
                          icon: const Icon(Icons.lock_open),
                          label: const Text('Unblock All'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Blocked Apps (${controller.blockedApps.length})',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      TextButton(
                        onPressed: () =>
                            homeController.showActivityLog(context),
                        child: const Text('Activity Log'),
                      ),
                    ],
                  ),
                  if (controller.blockedApps.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        'No apps currently blocked.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  else
                    ...controller.blockedApps.map(
                      (app) => ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: AppIcon(
                          packageName: app['packageName'] ?? '',
                          size: 36,
                        ),
                        title: Text(app['appName'] ?? 'Unknown'),
                        subtitle: Text(
                          app['packageName'] ?? '',
                          style: const TextStyle(fontSize: 11),
                        ),
                        trailing: IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.red,
                          ),
                          onPressed: () => controller.unblockApp(
                            app['packageName'] as String,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),

              // --- DAILY TIME LIMITS SECTION ---
              SectionCard(
                title: '⏱  Daily Time Limits',
                children: [
                  const Text(
                    'Set how many minutes per day a user can spend in an app. '
                    'When the budget hits 0, the app is blocked automatically.',
                    style: TextStyle(fontSize: 13, color: Colors.black54),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: () =>
                        homeController.showSetTimeLimitSheet(context),
                    icon: const Icon(Icons.timer),
                    label: const Text('Set Time Limit for an App'),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: controller.loadTimeLimits,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Refresh Usage Stats'),
                  ),
                  const SizedBox(height: 12),
                  if (controller.timeLimits.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        'No time limits configured.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  else
                    ...controller.timeLimits.map(
                      (limit) => TimeLimitTile(
                        limit: limit,
                        plugin: controller.plugin,
                        onChanged: controller.loadTimeLimits,
                      ),
                    ),
                ],
              ),
            ],
          );
        }),
      ),
    );
  }
}
// import 'dart:io';

// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:zo_app_blocker_demo/controllers/blocker_controller.getx.dart';
// import 'package:zo_app_blocker_demo/main.dart';
// import 'package:zo_app_blocker_demo/widgets/app_icon.dart';
// import 'package:zo_app_blocker_demo/widgets/section_card.dart';
// import 'package:zo_app_blocker_demo/widgets/time_limit_sheet.dart';
// import 'package:zo_app_blocker_demo/widgets/time_limit_tile.dart';

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

//   Future<void> _selectAndBlockApps(
//     BuildContext context,
//     BlockerController controller,
//   ) async {
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
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(SnackBar(content: Text('Error: $e')));
//     }
//   }

//   Future<void> _showSetTimeLimitSheet(
//     BuildContext context,
//     BlockerController controller,
//   ) async {
//     final apps = await controller.plugin.getApps();
//     if (apps.isEmpty || !context.mounted) return;
//     showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       builder: (ctx) =>
//           SetTimeLimitSheet(apps: apps, plugin: controller.plugin),
//     ).then((_) => controller.loadTimeLimits());
//   }

//   Future<void> _showActivityLog(
//     BuildContext context,
//     BlockerController controller,
//   ) async {
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
//           final permissionsOk =
//               controller.usageStatsStatus.value == 'granted' &&
//               controller.overlayStatus.value == 'granted';

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
//                       permissionsOk
//                           ? Icons.check_circle
//                           : Icons.warning_amber_rounded,
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
//                         controller.adminActive.value
//                             ? Icons.verified_user
//                             : Icons.gpp_maybe,
//                         color: controller.adminActive.value
//                             ? Colors.green
//                             : Colors.orange,
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
//                       onPressed: () =>
//                           DeviceAdminProtection.requestActivation(),
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
//                           onPressed: () =>
//                               _selectAndBlockApps(context, controller),
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
//                               const SnackBar(
//                                 content: Text('All apps unblocked'),
//                               ),
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
//                           onPressed: () => controller.unblockApp(
//                             app['packageName'] as String,
//                           ),
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
//                     onPressed: () =>
//                         _showSetTimeLimitSheet(context, controller),
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
