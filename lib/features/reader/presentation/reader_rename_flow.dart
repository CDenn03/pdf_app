import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:path/path.dart' as p;

import 'package:sefer/core/utils/share_utils.dart';
import 'package:sefer/features/reader/domain/reader_route_arguments.dart';
import 'package:sefer/features/reader/state/open_document_rename_coordinator.dart';

Future<void> renameOpenDocument(
  BuildContext context, {
  required OpenDocumentRenameCoordinator coordinator,
  required String path,
}) async {
  final newName = await showRenameDialog(
    context,
    currentName: p.basename(path),
  );
  if (newName == null || !context.mounted) return;

  final messenger = ScaffoldMessenger.of(context);
  final router = GoRouter.of(context);
  final outcome = await coordinator.rename(path: path, newName: newName);

  switch (outcome) {
    case null:
      return;
    case OpenDocumentRenameFailed(:final message):
      messenger.showSnackBar(SnackBar(content: Text(message)));
    case OpenDocumentRenamed(:final newPath, :final page, :final warning):
      unawaited(
        router.replace(
          '/reader',
          extra: ReaderRouteArguments(
            path: newPath,
            initialPage: page,
            recordOpened: false,
          ),
        ),
      );
      messenger.showSnackBar(SnackBar(content: Text(warning ?? 'Renamed.')));
  }
}

class RenameProgressOverlay extends StatelessWidget {
  const RenameProgressOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Semantics(
        label: 'Renaming document',
        child: const AbsorbPointer(
          child: ColoredBox(
            color: Color(0x66000000),
            child: Center(child: CircularProgressIndicator()),
          ),
        ),
      ),
    );
  }
}
