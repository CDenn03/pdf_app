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
