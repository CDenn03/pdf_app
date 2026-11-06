import 'package:flutter/material.dart';

/// Prompts for a new collection name. Returns the trimmed name or null.
Future<String?> showCollectionNameDialog(
  BuildContext context, {
  required String title,
  String initial = '',
  String confirmLabel = 'Create',
}) {
  final ctrl = TextEditingController(text: initial);
  return showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: ctrl,
        autofocus: true,
        decoration: const InputDecoration(
          hintText: 'Name',
          border: OutlineInputBorder(),
        ),
        onSubmitted: (_) => Navigator.pop(ctx, ctrl.text),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, ctrl.text),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
}

/// Confirms deletion of a collection. Returns true when confirmed.
Future<bool> confirmDeleteCollection(
  BuildContext context, {
  required String name,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Delete collection?'),
      content: Text('"$name" will be deleted. Files will not be removed.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Delete'),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}
