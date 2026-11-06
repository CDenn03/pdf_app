import 'dart:io';

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

/// Shares a PDF file from [path] using the platform share sheet.
///
/// Shows a [SnackBar] if the file is not found rather than throwing.
Future<void> sharePdf(BuildContext context, String path) async {
  if (!File(path).existsSync()) {
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('File not found.')));
    }
    return;
  }
  await SharePlus.instance.share(ShareParams(files: [XFile(path)]));
}

/// Shows a dialog to rename a PDF.
///
/// The field is seeded with [currentName] minus a single trailing `.pdf`, so
/// the user edits the stem rather than the extension. Returns that stem,
/// trimmed, or null if the user cancelled or left it empty.
///
/// The returned value carries **no extension**: appending and de-duplicating
/// `.pdf` is [FileMutator.rename]'s job, and doing it here as well is how a
/// name like `report.pdf.backup.pdf` used to come back mangled (a global
/// `replaceAll('.pdf', '')` struck the middle occurrence too).
Future<String?> showRenameDialog(
  BuildContext context, {
  required String currentName,
}) {
  final ctrl = TextEditingController(text: _stripPdfSuffix(currentName));

  void submit(BuildContext ctx) {
    final name = ctrl.text.trim();
    Navigator.pop(ctx, name.isEmpty ? null : name);
  }

  return showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Rename'),
      content: TextField(
        controller: ctrl,
        autofocus: true,
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          suffixText: '.pdf',
        ),
        onSubmitted: (_) => submit(ctx),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: () => submit(ctx), child: const Text('Rename')),
      ],
    ),
  );
}

/// Removes one trailing `.pdf` (case-insensitive), leaving any other
/// occurrence in the name intact.
String _stripPdfSuffix(String name) {
  if (name.length > 4 && name.toLowerCase().endsWith('.pdf')) {
    return name.substring(0, name.length - 4);
  }
  return name;
}
