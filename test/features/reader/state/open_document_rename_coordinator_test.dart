import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:sefer/core/services/document_keys_service.dart';
import 'package:sefer/features/library/state/document_rename_result.dart';
import 'package:sefer/features/reader/state/open_document_rename_coordinator.dart';

class _FakeHost implements OpenDocumentRenameHost {
  final calls = <String>[];
  @override
  int currentPage = 7;
  bool suspendThrows = false;

  @override
  Future<void> flushProgress() async => calls.add('flushProgress');

  @override
  Future<void> flushAnnotations() async => calls.add('flushAnnotations');

  @override
  void cancelSearch() => calls.add('cancelSearch');

  @override
  Future<void> suspendViewport() async {
    calls.add('suspendViewport');
    if (suspendThrows) throw StateError('boom');
  }

  @override
  void resumeViewport() => calls.add('resumeViewport');
}

void main() {
  group('OpenDocumentRenameCoordinator', () {
    test('runs steps in order and renames', () async {
      final host = _FakeHost();
      final coordinator = OpenDocumentRenameCoordinator(
        host: host,
        rename: ({required path, required newName}) async {
          host.calls.add('rename');
          return DocumentRenameSuccess('/docs/$newName.pdf');
        },
      );

      final outcome = await coordinator.rename(
        path: '/docs/old.pdf',
        newName: 'new',
      );

      expect(host.calls, [
        'flushProgress',
        'flushAnnotations',
        'cancelSearch',
        'suspendViewport',
        'rename',
      ]);
      expect(outcome, isA<OpenDocumentRenamed>());
      final renamed = outcome as OpenDocumentRenamed;
      expect(renamed.newPath, '/docs/new.pdf');
      expect(renamed.page, 7);
      expect(renamed.warning, isNull);
    });

    test('rejection resumes the viewport at the captured page', () async {
      final host = _FakeHost();
      final coordinator = OpenDocumentRenameCoordinator(
        host: host,
        rename: ({required path, required newName}) async =>
            const DocumentRenameRejected('taken'),
      );

      final outcome = await coordinator.rename(
        path: '/docs/old.pdf',
        newName: 'new',
      );

      expect(outcome, isA<OpenDocumentRenameFailed>());
      expect((outcome as OpenDocumentRenameFailed).message, 'taken');
      expect(host.calls.last, 'resumeViewport');
      expect(coordinator.busy, isFalse);
    });

    test('a failure partway through resumes the viewport', () async {
      final host = _FakeHost()..suspendThrows = true;
      final coordinator = OpenDocumentRenameCoordinator(
        host: host,
        rename: ({required path, required newName}) async =>
            const DocumentRenameSuccess('/docs/new.pdf'),
      );

      final outcome = await coordinator.rename(
        path: '/docs/old.pdf',
        newName: 'new',
      );

      expect(outcome, isA<OpenDocumentRenameFailed>());
      expect(host.calls.last, 'resumeViewport');
    });

    test('partial migration renames but carries the warning', () async {
      final host = _FakeHost();
      final coordinator = OpenDocumentRenameCoordinator(
        host: host,
        rename: ({required path, required newName}) async =>
            DocumentRenamePartiallyMigrated('/docs/new.pdf', [
              KeyMigrationFailure('annotations', StateError('db')),
            ]),
      );

      final outcome = await coordinator.rename(
        path: '/docs/old.pdf',
        newName: 'new',
      );

      expect(outcome, isA<OpenDocumentRenamed>());
      expect((outcome as OpenDocumentRenamed).warning, isNotNull);
    });

    test('a second call while busy returns null', () async {
      final host = _FakeHost();
      final completer = Completer<void>();
      final coordinator = OpenDocumentRenameCoordinator(
        host: host,
        rename: ({required path, required newName}) async {
          await completer.future;
          return DocumentRenameSuccess('/docs/$newName.pdf');
        },
      );

      final first = coordinator.rename(path: '/docs/old.pdf', newName: 'a');
      final second = await coordinator.rename(
        path: '/docs/old.pdf',
        newName: 'b',
      );

      expect(second, isNull);
      completer.complete();
      await first;
    });
  });
}
