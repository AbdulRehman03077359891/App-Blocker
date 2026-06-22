import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:zo_app_blocker_demo/controllers/initialization_controller.getx.dart';

class InitializationScreen extends StatelessWidget {
  const InitializationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Inject the controller responsible for driving the initialization sequence
    final initController = Get.put(InitializationController());

    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade900, Colors.blue.shade600],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App Logo or Branding Icon
            const Icon(Icons.shield_rounded, size: 100, color: Colors.white),
            const SizedBox(height: 24),
            const Text(
              'Zo App Blocker',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 48),
            // Circular loader
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
            const SizedBox(height: 24),
            // Reactive text displaying current initialization step
            Obx(
              () => Text(
                initController.loadingStatus.value,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
