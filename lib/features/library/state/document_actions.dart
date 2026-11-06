import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import 'package:sefer/core/constants.dart';
import 'package:sefer/core/providers.dart';
import 'package:sefer/core/services/file_service.dart';
import 'package:sefer/features/library/state/document_rename_result.dart';
import 'package:sefer/features/library/state/library_entry.dart';
import 'package:sefer/features/library/state/library_providers.dart';
import 'package:sefer/features/recents/state/recents_notifier.dart';
import 'package:sefer/features/device/state/device_files_providers.dart';

/// Result of a document action, carrying user-facing copy rather than an
/// exception, so every call site reports failure the same way.
class DocumentActionResult {
  const DocumentActionResult._({this.message, this.undo});

  const DocumentActionResult.success({void Function()? undo})
    : this._(undo: undo);

  /// The action did not happen. [message] is ready to show to the user.
  const DocumentActionResult.failure(String message) : this._(message: message);

  final String? message;

  /// Set only where the action is reversible (remove from library).
  final void Function()? undo;

  bool get ok => message == null;
}

/// Rename, delete and remove-from-library for a single document.
///
/// These three actions each have to touch several stores in a specific order,
/// and getting the order wrong is how documents lose their annotations. The
/// rule both mutations follow is **disk first, state second**:
///
/// - On rename, the file moves before any key migration. If the filesystem
///   refuses (name taken, permission, gone), nothing else has run, so there
///   is no state pointing at a path that does not exist.
/// - On delete, the file is removed before the purge, for the same reason
///   inverted: a purge that ran first would strip annotations off a file that
///   is then still sitting on the device.
///
/// Remove-from-library deliberately touches neither the file nor the
/// path-keyed stores: it drops the library row and nothing else, so adding
/// the file back restores its annotations and reading position. That is the
/// whole reason it is a separate action from delete rather than a softer
/// version of it.
class DocumentActions {
  DocumentActions(this._ref);

  final Ref _ref;

  /// True when [path] is the bundled sample, which cannot be renamed or
  /// deleted (it is an asset, not a file on disk).
  static bool isBundled(String path) => path == kSamplePdfPath;

  /// Renames the file at [path] to [newName] on disk, then carries every
  /// piece of per-document state across to the new path.
  ///
  /// [newName] is the stem the user typed, without an extension;
  /// [FileMutator.rename] owns extension policy.
  Future<DocumentRenameResult> rename({
    required String path,
    required String newName,
  }) async {
    if (isBundled(path)) {
      return const DocumentRenameRejected(
        'The bundled sample cannot be renamed.',
      );
    }

    final String newPath;
    try {
      newPath = await _ref.read(fileMutatorProvider).rename(path, newName);
    } on FileOperationException catch (e) {
      return DocumentRenameRejected(_renameMessage(e));
    }

    if (newPath == path) return DocumentRenameSuccess(newPath);

    final resolvedName = p.basename(newPath);

    // Annotations, notes, bookmarks, reading progress and recents are all
    // keyed by path, so they move before anything re-reads the lists.
    final failures = await _ref
        .read(documentKeyStoreProvider)
        .moveDocument(oldPath: path, newPath: newPath, newName: resolvedName);

    await _ref
        .read(libraryEntriesProvider.notifier)
        .applyRename(oldPath: path, newPath: newPath, newName: resolvedName);
    _ref
        .read(deviceFilesProvider.notifier)
        .applyRename(oldPath: path, newPath: newPath);
    await _ref.read(recentsProvider.notifier).reload();

    return failures.isEmpty
        ? DocumentRenameSuccess(newPath)
        : DocumentRenamePartiallyMigrated(newPath, failures);
  }

  /// Permanently deletes the file at [path] and erases all of its stored
  /// state: annotations, notes, bookmarks, reading progress, recents and the
  /// library entry.
  Future<DocumentActionResult> deleteFile(String path) async {
    if (isBundled(path)) {
      return const DocumentActionResult.failure(
        'The bundled sample cannot be deleted.',
      );
    }

    try {
      await _ref.read(fileMutatorProvider).delete(path);
    } on FileOperationException catch (e) {
      return DocumentActionResult.failure(_deleteMessage(e));
    }

    await _ref.read(documentKeyStoreProvider).purgeDocument(path);
    await _ref.read(libraryEntriesProvider.notifier).removeByPath(path);
    _ref.read(deviceFilesProvider.notifier).removePath(path);
    await _ref.read(recentsProvider.notifier).reload();

    return const DocumentActionResult.success();
  }

  /// Drops the library entry for [path], leaving the file and all of its
  /// annotations and reading progress untouched.
  ///
  /// Reversible: the returned [DocumentActionResult.undo] restores the exact
  /// entry that was removed, id and collection included.
  Future<DocumentActionResult> removeFromLibrary(String path) async {
    final entry = _ref
        .read(libraryEntriesProvider)
        .value
        ?.where((e) => e.path == path)
        .firstOrNull;

    if (entry == null) {
      return const DocumentActionResult.failure(
        'That file is not in your library.',
      );
    }

    await _ref.read(libraryEntriesProvider.notifier).removeByPath(path);

    return DocumentActionResult.success(undo: () => _restore(entry));
  }

  void _restore(LibraryEntry entry) {
    _ref.read(libraryEntriesProvider.notifier).restoreEntry(entry);
  }

  String _renameMessage(FileOperationException e) => switch (e.reason) {
    FileOperationReason.notFound => 'That file is no longer on the device.',
    FileOperationReason.permissionDenied =>
      'Storage permission is needed to rename this file.',
    FileOperationReason.nameTaken =>
      'A file with that name already exists in the same folder.',
    FileOperationReason.invalidName => 'That name is not valid.',
    FileOperationReason.unsupportedPath => 'This file cannot be renamed.',
    FileOperationReason.unknown => 'Could not rename the file.',
  };

  String _deleteMessage(FileOperationException e) => switch (e.reason) {
    FileOperationReason.notFound => 'That file is no longer on the device.',
    FileOperationReason.permissionDenied =>
      'Storage permission is needed to delete this file.',
    FileOperationReason.unsupportedPath => 'This file cannot be deleted.',
    FileOperationReason.nameTaken ||
    FileOperationReason.invalidName ||
    FileOperationReason.unknown => 'Could not delete the file.',
  };
}

final documentActionsProvider = Provider<DocumentActions>((ref) {
  return DocumentActions(ref);
});
