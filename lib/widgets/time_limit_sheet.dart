// ─────────────────────────────────────────────────────────────────────────────
// Set Time Limit Bottom Sheet
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:zo_app_blocker/zo_app_blocker.dart';
import 'package:zo_app_blocker_demo/widgets/app_icon.dart';

class SetTimeLimitSheet extends StatefulWidget {
  const SetTimeLimitSheet({
    super.key,
    required this.apps,
    required this.plugin,
  });

  final List<Map<String, dynamic>> apps;
  final ZoAppBlocker plugin;

  @override
  State<SetTimeLimitSheet> createState() => SetTimeLimitSheetState();
}

class SetTimeLimitSheetState extends State<SetTimeLimitSheet> {
  Map<String, dynamic>? _selectedApp;
  int _limitMinutes = 30;
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      builder: (ctx, scrollController) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const Text(
                'Set Daily Time Limit',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text(
                '1. Pick an app',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: widget.apps.length,
                  itemBuilder: (context, index) {
                    final app = widget.apps[index];
                    final selected =
                        _selectedApp?['packageName'] == app['packageName'];
                    return ListTile(
                      dense: true,
                      selected: selected,
                      selectedTileColor: Theme.of(
                        context,
                      ).colorScheme.primaryContainer.withOpacity(0.3),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      leading: AppIcon(
                        packageName: app['packageName'] ?? '',
                        size: 36,
                      ),
                      title: Text(app['appName'] ?? ''),
                      subtitle: Text(
                        app['packageName'] ?? '',
                        style: const TextStyle(fontSize: 11),
                      ),
                      trailing: selected
                          ? Icon(
                              Icons.check_circle,
                              color: Theme.of(context).colorScheme.primary,
                            )
                          : null,
                      onTap: () => setState(() => _selectedApp = app),
                    );
                  },
                ),
              ),
              if (_selectedApp != null) ...[
                const Divider(height: 24),
                Text(
                  '2. Daily limit for ${_selectedApp!['appName']}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Slider(
                        value: _limitMinutes.toDouble(),
                        min: 1,
                        max: 180,
                        divisions: 179,
                        label: '$_limitMinutes min',
                        onChanged: (v) =>
                            setState(() => _limitMinutes = v.round()),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 70,
                      child: Text(
                        '$_limitMinutes min',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
                Wrap(
                  spacing: 8,
                  children: [15, 30, 45, 60, 90, 120].map((m) {
                    return ChoiceChip(
                      label: Text('${m}m'),
                      selected: _limitMinutes == m,
                      onSelected: (_) => setState(() => _limitMinutes = m),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _saving
                      ? null
                      : () async {
                          setState(() => _saving = true);
                          await widget.plugin.setAppTimeLimit(
                            packageName: _selectedApp!['packageName'] as String,
                            dailyLimitMinutes: _limitMinutes,
                          );
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Set ${_limitMinutes}m daily limit for '
                                  '${_selectedApp!['appName']}',
                                ),
                              ),
                            );
                            Navigator.pop(context);
                          }
                        },
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Save Time Limit'),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
