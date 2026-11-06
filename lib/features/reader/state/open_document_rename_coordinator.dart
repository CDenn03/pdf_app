import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

import 'package:sefer/features/library/state/document_rename_result.dart';

abstract interface class OpenDocumentRenameHost {
  int get currentPage;

  Future<void> flushProgress();

  Future<void> flushAnnotations();

  void cancelSearch();

  Future<void> suspendViewport();

  void resumeViewport();
}

typedef RenameDocument =
    Future<DocumentRenameResult> Function({
      required String path,
      required String newName,
    });

sealed class OpenDocumentRenameOutcome {
  const OpenDocumentRenameOutcome();
}

class OpenDocumentRenamed extends OpenDocumentRenameOutcome {
  const OpenDocumentRenamed({
    required this.newPath,
    required this.page,
    this.warning,
  });

  final String newPath;
  final int page;
  final String? warning;
}

class OpenDocumentRenameFailed extends OpenDocumentRenameOutcome {
  const OpenDocumentRenameFailed(this.message);

  final String message;
}

class OpenDocumentRenameCoordinator extends ChangeNotifier {
  OpenDocumentRenameCoordinator({
    required OpenDocumentRenameHost host,
    required RenameDocument rename,
  }) : _host = host,
       _rename = rename;

  final OpenDocumentRenameHost _host;
  final RenameDocument _rename;
  bool _busy = false;

  bool get busy => _busy;

  /// Returns null when a rename is already in progress.
  ///
  /// After [OpenDocumentRenamed] the coordinator stays busy: the caller is
  /// about to replace the route, and the old viewport must not come back.
  Future<OpenDocumentRenameOutcome?> rename({
    required String path,
    required String newName,
  }) async {
    if (_busy) return null;
    _setBusy(true);
    final page = _host.currentPage;
    try {
      await _host.flushProgress();
      await _host.flushAnnotations();
      _host.cancelSearch();
      await _host.suspendViewport();
      final result = await _rename(path: path, newName: newName);
      return _outcomeFor(result, page);
    } catch (e, s) {
      developer.log(
        'Renaming the open document failed',
        name: 'sefer.reader',
        level: 1000,
        error: e,
        stackTrace: s,
      );
      return _resume('Could not rename the file.');
    }
  }

  OpenDocumentRenameOutcome _outcomeFor(
    DocumentRenameResult result,
    int page,
  ) => switch (result) {
    DocumentRenameSuccess(:final newPath) => OpenDocumentRenamed(
      newPath: newPath,
      page: page,
    ),
    DocumentRenamePartiallyMigrated(:final newPath) => OpenDocumentRenamed(
      newPath: newPath,
      page: page,
      warning: result.userMessage,
    ),
    DocumentRenameRejected(:final reason) => _resume(reason),
  };

  OpenDocumentRenameFailed _resume(String message) {
    _host.resumeViewport();
    _setBusy(false);
    return OpenDocumentRenameFailed(message);
  }

  void _setBusy(bool value) {
    _busy = value;
    notifyListeners();
  }
}
