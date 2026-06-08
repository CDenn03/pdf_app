import 'dart:io';

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

/// Shares a PDF file from [path] using the platform share sheet.
///
/// Shows a [SnackBar] if the file is not found rather than throwing.
Future<void> sharePdf(BuildContext context, String path) async {
  if (!File(path).existsSync()) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('File not found.')),
      );
    }
    return;
  }
  await SharePlus.instance.share(
    ShareParams(files: [XFile(path)]),
  );
}

/// Shows a dialog to rename a PDF.
///
/// Returns the trimmed new name, or null if the user cancelled.
Future<String?> showRenameDialog(
  BuildContext context, {
  required String currentName,
}) {
  final ctrl = TextEditingController(
    text: currentName.replaceAll('.pdf', ''),
  );
  return showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Rename'),
      content: TextField(
        controller: ctrl,
        autofocus: true,
        decoration: const InputDecoration(border: OutlineInputBorder()),
        onSubmitted: (_) => Navigator.pop(ctx, '${ctrl.text.trim()}.pdf'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, '${ctrl.text.trim()}.pdf'),
          child: const Text('Rename'),
        ),
      ],
    ),
  );
}
