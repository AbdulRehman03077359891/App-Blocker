import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:zo_app_blocker/zo_app_blocker.dart';

@pragma('vm:entry-point')
void onBlockScreenRequested() {
  ZoBlockScreenRunner.run(
    builder: (blockContext) {
      final plugin = ZoAppBlocker.instance;
      final pinController = TextEditingController();
      String errorMessage = '';
      bool isProcessing = false;

      return StatefulBuilder(
        builder: (context, setState) {
          Future<void> exitToHome() async {
            setState(() => isProcessing = true);
            try {
              // First try: direct MethodChannel (works if main isolate handles it)
              await const MethodChannel(
                'com.example.zo_app_blocker_demo/device_admin',
              ).invokeMethod('goHome');
              FocusScope.of(context).unfocus();
              blockContext.onDismiss();
            } catch (_) {
              try {
                // Second try: broadcast path — works across isolate boundaries
                // because BroadcastReceiver operates at process level, not per-isolate
                await const MethodChannel(
                  'com.example.zo_app_blocker_demo/device_admin',
                ).invokeMethod('goHomeBroadcast');
                FocusScope.of(context).unfocus();
                blockContext.onDismiss();
              } catch (_) {
                // Last resort: dismiss anyway so the user is never stuck.
                // The monitoring service may re-show the block screen briefly,
                // but the user is not permanently trapped.
                FocusScope.of(context).unfocus();
                blockContext.onDismiss();
              }
            }
          }
          // Future<void> exitToHome() async {
          //   setState(() => isProcessing = true);
          //   try {
          //     await const MethodChannel(
          //       'com.example.zo_app_blocker_demo/device_admin',
          //     ).invokeMethod('goHome');
          //     FocusScope.of(
          //       context,
          //     ).unfocus(); // Bug 3 fix — release keyboard before dismiss
          //     blockContext
          //         .onDismiss(); // Bug 1 fix — only dismiss if goHome succeeded
          //   } catch (_) {
          //     // goHome failed on this device — reset state, do NOT dismiss
          //     setState(() {
          //       isProcessing = false;
          //       errorMessage = 'Could not go home. Try again.';
          //     });
          //   }
          // }
          // Future<void> exitToHome() async {
          //   setState(() => isProcessing = true);
          //   try {
          //     await const MethodChannel(
          //       'com.example.zo_app_blocker_demo/device_admin',
          //     ).invokeMethod('goHome');
          //   } catch (_) {}
          //   blockContext.onDismiss();
          // }

          return Scaffold(
            backgroundColor: Colors.black87,
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (blockContext.appIcon != null &&
                        blockContext.appIcon!.isNotEmpty)
                      Image.memory(
                        blockContext.appIcon!,
                        width: 100,
                        height: 100,
                      ),
                    const SizedBox(height: 24),
                    Text(
                      '${blockContext.appName ?? 'App'} is Blocked!',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Enter PIN to unlock.',
                      style: TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: pinController,
                      keyboardType: TextInputType.number,
                      obscureText: true,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Enter PIN',
                        hintStyle: const TextStyle(color: Colors.white54),
                        errorText: errorMessage.isNotEmpty
                            ? errorMessage
                            : null,
                        filled: true,
                        fillColor: Colors.white12,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (isProcessing)
                      const CircularProgressIndicator(color: Colors.white)
                    else
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton.icon(
                            onPressed: exitToHome,
                            icon: const Icon(Icons.exit_to_app),
                            label: const Text('Exit'),
                          ),
                          ElevatedButton.icon(
                            onPressed: () async {
                              final enteredPin = pinController.text.trim();
                              if (enteredPin == '459278') {
                                setState(() => isProcessing = true);
                                final pkg = blockContext.packageName;
                                await plugin.resetAppUsage(pkg);
                                FocusScope.of(
                                  context,
                                ).unfocus(); // Bug 3 fix — release keyboard before dismiss
                                blockContext.onDismiss();
                              } else {
                                setState(() {
                                  errorMessage = 'Incorrect PIN!';
                                  pinController.clear();
                                });
                              }
                            },
                            // onPressed: () async {
                            //   final enteredPin = pinController.text.trim();
                            //   if (enteredPin == '459278') {
                            //     setState(() => isProcessing = true);
                            //     final pkg = blockContext.packageName;
                            //     await plugin.resetAppUsage(pkg);
                            //     blockContext.onDismiss();
                            //   } else {
                            //     setState(() {
                            //       errorMessage = 'Incorrect PIN!';
                            //       pinController.clear();
                            //     });
                            //   }
                            // },
                            icon: const Icon(Icons.lock_open),
                            label: const Text('Unlock'),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  );
}
