import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sefer/core/providers.dart';
import 'package:sefer/core/utils/share_utils.dart';
import 'package:sefer/features/reader/presentation/more_panel.dart';
import 'package:sefer/features/reader/presentation/reader_chrome.dart';
import 'package:sefer/features/reader/presentation/reader_rename_flow.dart';
import 'package:sefer/features/reader/state/open_document_rename_coordinator.dart';

Future<void> showReaderMoreSheet(
  BuildContext context,
  WidgetRef ref, {
  required String pdfPath,
  required OpenDocumentRenameCoordinator? renameCoordinator,
  required VoidCallback onAnnotations,
  required VoidCallback onPanelClosed,
}) {
  final settings = ref.read(appSettingsProvider);
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (ctx) => ReaderMoreMenu(
      onAnnotations: () {
        Navigator.of(ctx).pop();
        onAnnotations();
      },
      onReadingMode: () {
        Navigator.of(ctx).pop();
        showMorePanel(
          context: context,
          currentMode: settings.readingMode,
          onModeChanged: (mode) =>
              ref.read(appSettingsProvider.notifier).setReadingMode(mode),
          currentLayoutMode: settings.layoutMode,
          onLayoutModeChanged: (mode) =>
              ref.read(appSettingsProvider.notifier).setReaderLayoutMode(mode),
        ).then((_) => onPanelClosed());
      },
      onShare: () {
        Navigator.of(ctx).pop();
        sharePdf(context, pdfPath);
      },
      onRename: renameCoordinator == null
          ? null
          : () {
              Navigator.of(ctx).pop();
              renameOpenDocument(
                context,
                coordinator: renameCoordinator,
                path: pdfPath,
              );
            },
    ),
  );
}
