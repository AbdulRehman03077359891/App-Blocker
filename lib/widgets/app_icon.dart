// ─────────────────────────────────────────────────────────────────────────────
// Shared helper widgets
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:zo_app_blocker/zo_app_blocker.dart';

class AppIcon extends StatelessWidget {
  const AppIcon({super.key, required this.packageName, this.size = 40});

  final String packageName;
  final double size;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List?>(
      future: ZoAppBlocker.instance.getAppIcon(packageName),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SizedBox(
            width: size,
            height: size,
            child: const Padding(
              padding: EdgeInsets.all(8),
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        }
        if (snapshot.hasData && snapshot.data != null) {
          return Image.memory(snapshot.data!, width: size, height: size);
        }
        return Icon(Icons.android, size: size, color: Colors.grey);
      },
    );
  }
}
