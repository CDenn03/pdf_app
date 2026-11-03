import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sefer/core/constants.dart';
import 'package:sefer/core/models/file_status.dart';
import 'package:sefer/core/providers.dart';
import 'package:sefer/core/services/document_keys_service.dart';
import 'package:sefer/core/services/file_service.dart';
import 'package:sefer/core/services/library_persistence_service.dart';
import 'package:sefer/core/services/recents_service.dart';
import 'package:sefer/features/library/state/document_actions.dart';
import 'package:sefer/features/library/state/library_entry.dart';
import 'package:sefer/features/library/state/library_providers.dart';
import 'package:sefer/features/recents/state/recents_notifier.dart';

/// Shared ordered log, so the tests can assert that disk work happens before
/// state work rather than merely that both happened.
late List<String> log;

class _FakeMutator implements FileMutator {
  _FakeMutator({this.renameFailure, this.deleteFailure});

  final FileOperationException? renameFailure;
  final FileOperationException? deleteFailure;

  @override
  Future<String> rename(String path, String newName) async {
    if (renameFailure != null) {
      log.add('rename:refused');
      throw renameFailure!;
    }
    log.add('rename:disk');
    final dir = path.substring(0, path.lastIndexOf('/'));
    return '$dir/$newName.pdf';
  }

  @override
  Future<void> delete(String path) async {
    if (deleteFailure != null) {
      log.add('delete:refused');
      throw deleteFailure!;
    }
    log.add('delete:disk');
  }
}

class _FakeKeyStore implements DocumentKeyStore {
  @override
  Future<void> moveDocument({
    required String oldPath,
    required String newPath,
    required String newName,
  }) async {
    log.add('keys:move:$oldPath->$newPath');
  }

  @override
  Future<void> purgeDocument(String path) async {
    log.add('keys:purge:$path');
  }
}

class _FakePersistence implements LibraryPersistence {
  _FakePersistence(this._entries);

  List<PersistedEntry> _entries;

  @override
  Future<List<PersistedEntry>> loadEntries() async => _entries;

  @override
  Future<void> saveEntries(List<LibraryEntry> entries) async {
    _entries = entries
        .map(
          (e) => PersistedEntry(
            id: e.id,
            name: e.name,
            path: e.path,
            collectionId: e.collectionId,
            isFavorite: e.isFavorite,
          ),
        )
        .toList();
    log.add('library:save:${entries.map((e) => e.path).join(",")}');
  }
}

class _FakeRecents implements RecentsStore {
  @override
  Future<List<RecentEntry>> load() async => [];
  @override
  Future<void> recordOpened(String path, String name) async {}
  @override
  Future<void> moveEntry({
    required String oldPath,
    required String newPath,
    required String newName,
  }) async {}
  @override
  Future<void> remove(String path) async {}
}

class _FakeChecker implements FileChecker {
  @override
  Future<FileStatus> checkFile(String path) async => FileStatus.ok;
}

ProviderContainer makeContainer({
  FileOperationException? renameFailure,
  FileOperationException? deleteFailure,
  List<PersistedEntry> entries = const [],
}) {
  final container = ProviderContainer(
    overrides: [
      fileMutatorProvider.overrideWithValue(
        _FakeMutator(
          renameFailure: renameFailure,
          deleteFailure: deleteFailure,
        ),
      ),
      documentKeyStoreProvider.overrideWithValue(_FakeKeyStore()),
      libraryPersistenceProvider.overrideWithValue(_FakePersistence(entries)),
      recentsStoreProvider.overrideWithValue(_FakeRecents()),
      fileServiceProvider.overrideWithValue(_FakeChecker()),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

const _entry = PersistedEntry(
  id: 'e1',
  name: 'old.pdf',
  path: '/docs/old.pdf',
  collectionId: 'c1',
  isFavorite: true,
);

void main() {
  setUp(() => log = []);

  group('rename', () {
    test('renames on disk before touching any path-keyed state', () async {
      final container = makeContainer(entries: [_entry]);
      await container.read(libraryEntriesProvider.future);
      log.clear();

      final result = await container
          .read(documentActionsProvider)
          .rename(path: '/docs/old.pdf', newName: 'new');

      expect(result.ok, isTrue);
      expect(result.newPath, '/docs/new.pdf');
      // The ordering is the contract: state must never be migrated to a path
      // the filesystem has not actually produced yet.
      expect(log.first, 'rename:disk');
      expect(log, contains('keys:move:/docs/old.pdf->/docs/new.pdf'));
      expect(
        log.indexOf('rename:disk'),
        lessThan(log.indexWhere((e) => e.startsWith('keys:move'))),
      );
    });

    test('carries the library entry across, preserving collection and '
        'favorite', () async {
      final container = makeContainer(entries: [_entry]);
      await container.read(libraryEntriesProvider.future);

      await container
          .read(documentActionsProvider)
          .rename(path: '/docs/old.pdf', newName: 'new');

      final entries = container.read(libraryEntriesProvider).value!;
      final moved = entries.single;
      expect(moved.path, '/docs/new.pdf');
      expect(moved.name, 'new.pdf');
      expect(moved.id, 'e1', reason: 'the entry moves, it is not recreated');
      expect(moved.collectionId, 'c1');
      expect(moved.isFavorite, isTrue);
    });

    test('leaves every store untouched when the disk rename fails', () async {
      final container = makeContainer(
        entries: [_entry],
        renameFailure: const FileOperationException(
          FileOperationReason.nameTaken,
          'taken',
        ),
      );
      await container.read(libraryEntriesProvider.future);
      log.clear();

      final result = await container
          .read(documentActionsProvider)
          .rename(path: '/docs/old.pdf', newName: 'new');

      expect(result.ok, isFalse);
      expect(
        result.message,
        'A file with that name already exists in the same folder.',
      );
      // Nothing after the refusal ran, so no store points at a path that
      // does not exist.
      expect(log, ['rename:refused']);
      expect(
        container.read(libraryEntriesProvider).value!.single.path,
        '/docs/old.pdf',
      );
    });

    test('refuses the bundled sample without touching the filesystem', () async {
      final container = makeContainer();

      final result = await container
          .read(documentActionsProvider)
          .rename(path: kSamplePdfPath, newName: 'new');

      expect(result.ok, isFalse);
      expect(result.message, contains('cannot be renamed'));
      expect(log, isEmpty);
    });

    test('renames a file that has no library entry', () async {
      final container = makeContainer();
      await container.read(libraryEntriesProvider.future);
      log.clear();

      final result = await container
          .read(documentActionsProvider)
          .rename(path: '/docs/loose.pdf', newName: 'tidy');

      expect(result.ok, isTrue);
      expect(result.newPath, '/docs/tidy.pdf');
      // State still migrates: annotations can exist for a file that was only
      // ever opened from the Device tab.
      expect(log, contains('keys:move:/docs/loose.pdf->/docs/tidy.pdf'));
    });
  });

  group('deleteFile', () {
    test('deletes from disk before purging state', () async {
      final container = makeContainer(entries: [_entry]);
      await container.read(libraryEntriesProvider.future);
      log.clear();

      final result = await container
          .read(documentActionsProvider)
          .deleteFile('/docs/old.pdf');

      expect(result.ok, isTrue);
      expect(log.first, 'delete:disk');
      expect(log, contains('keys:purge:/docs/old.pdf'));
      expect(container.read(libraryEntriesProvider).value, isEmpty);
    });

    test('keeps all state when the disk delete fails', () async {
      final container = makeContainer(
        entries: [_entry],
        deleteFailure: const FileOperationException(
          FileOperationReason.permissionDenied,
          'denied',
        ),
      );
      await container.read(libraryEntriesProvider.future);
      log.clear();

      final result = await container
          .read(documentActionsProvider)
          .deleteFile('/docs/old.pdf');

      expect(result.ok, isFalse);
      expect(result.message, contains('permission'));
      // A purge that ran anyway would strip annotations off a file still
      // sitting on the device.
      expect(log, ['delete:refused']);
      expect(container.read(libraryEntriesProvider).value, hasLength(1));
    });

    test('refuses the bundled sample', () async {
      final container = makeContainer();

      final result = await container
          .read(documentActionsProvider)
          .deleteFile(kSamplePdfPath);

      expect(result.ok, isFalse);
      expect(log, isEmpty);
    });
  });

  group('removeFromLibrary', () {
    test('drops the entry without touching the file or its state', () async {
      final container = makeContainer(entries: [_entry]);
      await container.read(libraryEntriesProvider.future);
      log.clear();

      final result = await container
          .read(documentActionsProvider)
          .removeFromLibrary('/docs/old.pdf');

      expect(result.ok, isTrue);
      expect(container.read(libraryEntriesProvider).value, isEmpty);
      // This is the whole distinction from delete: no disk call, no purge.
      expect(log.where((e) => e.startsWith('delete')), isEmpty);
      expect(log.where((e) => e.startsWith('keys:')), isEmpty);
    });

    test('undo restores the entry verbatim', () async {
      final container = makeContainer(entries: [_entry]);
      await container.read(libraryEntriesProvider.future);

      final result = await container
          .read(documentActionsProvider)
          .removeFromLibrary('/docs/old.pdf');
      expect(result.undo, isNotNull);

      result.undo!();
      await Future<void>.delayed(Duration.zero);

      final restored = container.read(libraryEntriesProvider).value!.single;
      expect(restored.id, 'e1');
      expect(restored.path, '/docs/old.pdf');
      expect(restored.collectionId, 'c1');
      expect(restored.isFavorite, isTrue);
    });

    test('reports a failure when the file is not in the library', () async {
      final container = makeContainer();
      await container.read(libraryEntriesProvider.future);

      final result = await container
          .read(documentActionsProvider)
          .removeFromLibrary('/docs/absent.pdf');

      expect(result.ok, isFalse);
      expect(result.undo, isNull);
    });
  });
}
