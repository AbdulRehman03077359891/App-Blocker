// ─────────────────────────────────────────────────────────────────────────────
// Time Limit Tile
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:zo_app_blocker/zo_app_blocker.dart';
import 'package:zo_app_blocker_demo/widgets/app_icon.dart';

class TimeLimitTile extends StatelessWidget {
  const TimeLimitTile({
    super.key,
    required this.limit,
    required this.plugin,
    required this.onChanged,
  });

  final AppTimeLimit limit;
  final ZoAppBlocker plugin;
  final VoidCallback onChanged;

  String _fmtSeconds(int s) {
    if (s >= 60) return '${s ~/ 60}m ${s % 60}s';
    return '${s}s';
  }

  @override
  Widget build(BuildContext context) {
    final color = limit.isExhausted
        ? Colors.red
        : limit.usageRatio > 0.75
        ? Colors.orange
        : Theme.of(context).colorScheme.primary;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                AppIcon(packageName: limit.packageName, size: 36),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        limit.packageName.split('.').last,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        limit.packageName,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.black45,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (limit.isExhausted)
                  const Chip(
                    label: Text(
                      'BLOCKED',
                      style: TextStyle(fontSize: 11, color: Colors.white),
                    ),
                    backgroundColor: Colors.red,
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: limit.usageRatio,
                minHeight: 8,
                color: color,
                backgroundColor: color.withOpacity(0.15),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  limit.isExhausted
                      ? 'Budget exhausted'
                      : '${_fmtSeconds(limit.remainingSeconds)} remaining',
                  style: TextStyle(
                    fontSize: 12,
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${_fmtSeconds(limit.usedSeconds)} / ${_fmtSeconds(limit.dailyLimitSeconds)}',
                  style: const TextStyle(fontSize: 12, color: Colors.black45),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      await plugin.resetAppUsage(limit.packageName);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Usage reset to 0')),
                      );
                      onChanged();
                    },
                    icon: const Icon(Icons.restart_alt, size: 16),
                    label: const Text('Reset', style: TextStyle(fontSize: 13)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      await plugin.removeAppTimeLimit(limit.packageName);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Time limit removed')),
                      );
                      onChanged();
                    },
                    icon: const Icon(Icons.delete_outline, size: 16),
                    label: const Text('Remove', style: TextStyle(fontSize: 13)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      foregroundColor: Colors.red,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
