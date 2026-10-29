import 'dart:developer' as developer;

import 'package:sefer/core/database/annotation_dao.dart';
import 'package:sefer/core/services/reading_progress_service.dart';
import 'package:sefer/core/services/recents_service.dart';

/// Moves or erases every piece of per-document state that keys off the file
/// path: annotations (and their note entries), reading progress, and recents.
abstract class DocumentKeyStore {
  /// Moves every piece of per-document state from [oldPath] to [newPath].
  Future<void> moveDocument({
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
/// failure cannot leave the other two stores stranded; the first error is
/// logged and swallowed. The progress and recents stores never throw by
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
  Future<void> moveDocument({
    required String oldPath,
    required String newPath,
    required String newName,
  }) async {
    await _runAll('moveDocument', [
      () => _annotationDao.reassignPdfId(oldPath, newPath),
      () => _progress.movePage(oldPath, newPath),
      () => _recents.moveEntry(
        oldPath: oldPath,
        newPath: newPath,
        newName: newName,
      ),
    ]);
  }

  @override
  Future<void> purgeDocument(String path) async {
    await _runAll('purgeDocument', [
      () => _annotationDao.purgeForPdf(path),
      () => _progress.clear(path),
      () => _recents.remove(path),
    ]);
  }

  Future<void> _runAll(
    String operation,
    List<Future<void> Function()> steps,
  ) async {
    for (final step in steps) {
      try {
        await step();
      } catch (e, s) {
        developer.log(
          '$operation step failed; continuing with remaining stores',
          name: 'sefer.documentKeys',
          level: 900,
          error: e,
          stackTrace: s,
        );
      }
    }
  }
}
