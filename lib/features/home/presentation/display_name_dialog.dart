import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sefer/core/providers.dart';
import 'package:sefer/core/services/app_settings_service.dart';

const int kDisplayNameMaxLength = 24;

/// Prompts for a new display name and persists it when confirmed.
Future<void> editDisplayName(BuildContext context, WidgetRef ref) async {
  final current = ref.read(appSettingsProvider).displayName;
  final next = await showDisplayNameDialog(context, currentName: current);
  if (next == null || !context.mounted) return;
  await ref.read(appSettingsProvider.notifier).setDisplayName(next);
}

/// Returns the trimmed name, or null if the user cancelled.
Future<String?> showDisplayNameDialog(
  BuildContext context, {
  required String currentName,
}) {
  final ctrl = TextEditingController(text: currentName);
  ctrl.selection = TextSelection(baseOffset: 0, extentOffset: ctrl.text.length);

  void submit(BuildContext ctx) {
    final name = ctrl.text.trim();
    if (name.isEmpty) return;
    Navigator.pop(ctx, name);
  }

  return showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Your name'),
      content: TextField(
        controller: ctrl,
        autofocus: true,
        textCapitalization: TextCapitalization.words,
        maxLength: kDisplayNameMaxLength,
        decoration: const InputDecoration(
          hintText: AppSettings.defaultDisplayName,
          border: OutlineInputBorder(),
          counterText: '',
        ),
        onSubmitted: (_) => submit(ctx),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: () => submit(ctx), child: const Text('Save')),
      ],
    ),
  );
}
