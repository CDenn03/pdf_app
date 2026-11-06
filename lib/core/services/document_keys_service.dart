import 'dart:developer' as developer;

import 'package:sefer/core/database/annotation_dao.dart';
import 'package:sefer/core/services/reading_progress_service.dart';
import 'package:sefer/core/services/recents_service.dart';

class KeyMigrationFailure {
  const KeyMigrationFailure(this.store, this.error);

  final String store;
  final Object error;
}

/// Moves or erases every piece of per-document state that keys off the file
/// path: annotations (and their note entries), reading progress, and recents.
abstract class DocumentKeyStore {
  /// Moves every piece of per-document state from [oldPath] to [newPath],
  /// returning the stores that could not be moved.
  Future<List<KeyMigrationFailure>> moveDocument({
    required String oldPath,
    required String newPath,
    required String newName,
  });

  /// Erases every piece of per-document state for [path].
  Future<void> purgeDocument(String path);
}

/// Composes the three path-keyed stores behind one move/purge API.
///
/// Partial failure is handled best-effort, not abort-on-first-error: the
/// callers are a rename and a delete, where a half-migrated document — rows
/// still keyed to a path that no longer exists — is the worst outcome. Each
/// store is attempted regardless of whether an earlier one threw, so a single
/// failure cannot leave the other two stores stranded; failures are
/// logged and reported to the caller. The progress and recents stores never throw by
/// contract, so in practice only the annotation DAO can fail here.
class DocumentKeyService implements DocumentKeyStore {
  DocumentKeyService({
    required AnnotationDao annotationDao,
    required ReadingProgressStore progress,
    required RecentsStore recents,
  }) : _annotationDao = annotationDao,
       _progress = progress,
       _recents = recents;

  final AnnotationDao _annotationDao;
  final ReadingProgressStore _progress;
  final RecentsStore _recents;

  @override
  Future<List<KeyMigrationFailure>> moveDocument({
    required String oldPath,
    required String newPath,
    required String newName,
  }) {
    return _runAll('moveDocument', {
      'annotations': () => _annotationDao.reassignPdfId(oldPath, newPath),
      'reading progress': () => _progress.movePage(oldPath, newPath),
      'recents': () => _recents.moveEntry(
        oldPath: oldPath,
        newPath: newPath,
        newName: newName,
      ),
    });
  }

  @override
  Future<void> purgeDocument(String path) async {
    await _runAll('purgeDocument', {
      'annotations': () => _annotationDao.purgeForPdf(path),
      'reading progress': () => _progress.clear(path),
      'recents': () => _recents.remove(path),
    });
  }

  Future<List<KeyMigrationFailure>> _runAll(
    String operation,
    Map<String, Future<void> Function()> steps,
  ) async {
    final failures = <KeyMigrationFailure>[];
    for (final MapEntry(key: store, value: step) in steps.entries) {
      try {
        await step();
      } catch (e, s) {
        failures.add(KeyMigrationFailure(store, e));
        developer.log(
          '$operation step failed; continuing with remaining stores',
          name: 'sefer.documentKeys',
          level: 900,
          error: e,
          stackTrace: s,
        );
      }
    }
    return failures;
  }
}
