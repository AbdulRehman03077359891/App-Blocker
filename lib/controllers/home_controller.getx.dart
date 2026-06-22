import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:zo_app_blocker_demo/controllers/blocker_controller.getx.dart';
import 'package:zo_app_blocker_demo/main.dart'; // Make sure this path is correct for DeviceAdminProtection
import 'package:zo_app_blocker_demo/widgets/app_icon.dart';
import 'package:zo_app_blocker_demo/widgets/time_limit_sheet.dart';

class HomeController extends GetxController {
  // Grab a reference to the existing core blocker controller
  BlockerController get blockerController => Get.find<BlockerController>();

  /// Asks the user for a PIN via an AlertDialog
  Future<bool> askForPin(BuildContext context) async {
    final controller = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        String error = '';
        return StatefulBuilder(
          builder: (context, setDialogState) {
            void submit() {
              if (controller.text == '459278') {
                Navigator.of(dialogContext).pop(true);
              } else {
                setDialogState(() => error = 'Incorrect PIN');
              }
            }

            return AlertDialog(
              title: const Text('Enter PIN'),
              content: TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                obscureText: true,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Enter PIN',
                  errorText: error.isNotEmpty ? error : null,
                ),
                onSubmitted: (_) => submit(),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text('Cancel'),
                ),
                FilledButton(onPressed: submit, child: const Text('Confirm')),
              ],
            );
          },
        );
      },
    );
    return result ?? false;
  }

  /// Handles the temporary uninstall allowance logic
  Future<void> allowUninstall(BuildContext context) async {
    final ok = await askForPin(context);
    if (ok) {
      await DeviceAdminProtection.allowUninstallTemporarily();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Uninstall allowed — re-locks next time the app opens.',
          ),
        ),
      );
    }
  }

  /// Shows the bottom sheet to select and block an app
  Future<void> selectAndBlockApps(BuildContext context) async {
    try {
      final apps = await blockerController.plugin.getApps();
      if (Platform.isIOS) {
        blockerController.loadBlockedApps();
        return;
      }
      if (apps.isEmpty || !context.mounted) return;

      showModalBottomSheet(
        context: context,
        builder: (sheetContext) {
          return Column(
            children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Select an app to block',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: apps.length,
                  itemBuilder: (context, index) {
                    final app = apps[index];
                    return ListTile(
                      leading: AppIcon(packageName: app['packageName'] ?? ''),
                      title: Text(app['appName'] ?? ''),
                      subtitle: Text(app['packageName'] ?? ''),
                      onTap: () async {
                        final nav = Navigator.of(context);
                        final scaffold = ScaffoldMessenger.of(context);

                        await blockerController.blockApp(app['packageName']);

                        if (!context.mounted) return;
                        nav.pop();
                        scaffold.showSnackBar(
                          SnackBar(content: Text('Blocked ${app['appName']}')),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  /// Unblocks all apps and shows a confirmation snackbar
  Future<void> unblockAllApps(BuildContext context) async {
    await blockerController.unblockAllApps();
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('All apps unblocked')));
  }

  /// Shows the bottom sheet to set a time limit
  Future<void> showSetTimeLimitSheet(BuildContext context) async {
    final apps = await blockerController.plugin.getApps();
    if (apps.isEmpty || !context.mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) =>
          SetTimeLimitSheet(apps: apps, plugin: blockerController.plugin),
    ).then((_) => blockerController.loadTimeLimits());
  }

  /// Shows the activity log bottom sheet
  Future<void> showActivityLog(BuildContext context) async {
    final log = await blockerController.plugin.getBlockActivityLog();
    if (!context.mounted) return;

    showModalBottomSheet(
      context: context,
      builder: (sheetContext) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Block Activity Log',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  TextButton(
                    onPressed: () async {
                      await blockerController.clearActivityLog();
                      if (sheetContext.mounted) {
                        Navigator.pop(sheetContext);
                        showActivityLog(context); // Refresh the log view
                      }
                    },
                    child: const Text('Clear'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: log.isEmpty
                  ? const Center(child: Text('No activity yet.'))
                  : ListView.builder(
                      itemCount: log.length,
                      itemBuilder: (context, index) {
                        final entry = log[index];
                        final packageName = entry['packageName'] as String;
                        final timestamp = entry['timestamp'] as int;
                        final date = DateTime.fromMillisecondsSinceEpoch(
                          timestamp,
                        );
                        return ListTile(
                          leading: AppIcon(packageName: packageName, size: 32),
                          title: Text(packageName),
                          subtitle: Text('${date.toLocal()}'.split('.')[0]),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}
