import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sefer/core/providers.dart';
import 'package:sefer/core/services/library_persistence_service.dart';
import 'package:sefer/features/library/state/library_entry.dart';
import 'package:sefer/features/library/state/library_providers.dart';

import '../../support/library_fakes.dart';

PersistedEntry _persisted(String path, {bool favorite = false}) =>
    PersistedEntry(id: path, name: path, path: path, isFavorite: favorite);

ProviderContainer _container(FakeLibraryPersistence persistence) {
  final container = ProviderContainer(
    overrides: [
      fileServiceProvider.overrideWithValue(FakeFileChecker()),
      libraryPersistenceProvider.overrideWithValue(persistence),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

LibraryEntry? _find(ProviderContainer c, String path) => c
    .read(libraryEntriesProvider)
    .value
    ?.where((e) => e.path == path)
    .firstOrNull;

void main() {
  test('given an existing entry, when favorited, then flag is set', () async {
    final persistence = FakeLibraryPersistence(initial: [_persisted('/a.pdf')]);
    final container = _container(persistence);
    await container.read(libraryEntriesProvider.future);

    await container.read(libraryEntriesProvider.notifier).setFavoriteForPaths({
      '/a.pdf',
    }, favorite: true);

    expect(_find(container, '/a.pdf')!.isFavorite, isTrue);
    expect(container.read(favoritePathsProvider), {'/a.pdf'});
  });

  test('given a path outside the library, when favorited, then a root '
      'entry is created', () async {
    final persistence = FakeLibraryPersistence(initial: [_persisted('/a.pdf')]);
    final container = _container(persistence);
    await container.read(libraryEntriesProvider.future);

    await container.read(libraryEntriesProvider.notifier).setFavoriteForPaths({
      '/docs/new.pdf',
    }, favorite: true);

    final created = _find(container, '/docs/new.pdf')!;
    expect(created.name, 'new.pdf');
    expect(created.isFavorite, isTrue);
    expect(created.collectionId, isNull);
    expect(created.id, isNotEmpty);
  });

  test('given a favorite, when unfavorited, then the entry is kept', () async {
    final persistence = FakeLibraryPersistence(
      initial: [_persisted('/a.pdf', favorite: true)],
    );
    final container = _container(persistence);
    await container.read(libraryEntriesProvider.future);

    await container.read(libraryEntriesProvider.notifier).setFavoriteForPaths({
      '/a.pdf',
      '/unknown.pdf',
    }, favorite: false);

    expect(_find(container, '/a.pdf')!.isFavorite, isFalse);
    expect(_find(container, '/unknown.pdf'), isNull);
  });

  test('given the same call twice, then the second persists nothing', () async {
    final persistence = FakeLibraryPersistence(initial: [_persisted('/a.pdf')]);
    final container = _container(persistence);
    await container.read(libraryEntriesProvider.future);
    final notifier = container.read(libraryEntriesProvider.notifier);

    await notifier.setFavoriteForPaths({'/a.pdf', '/b.pdf'}, favorite: true);
    final savesAfterFirst = persistence.saves.length;
    final stateAfterFirst = container.read(libraryEntriesProvider).value;
    await notifier.setFavoriteForPaths({'/a.pdf', '/b.pdf'}, favorite: true);

    expect(persistence.saves.length, savesAfterFirst);
    expect(container.read(libraryEntriesProvider).value, stateAfterFirst);
    expect(container.read(libraryEntriesProvider).value, hasLength(2));
  });

  test('given many paths, then state is updated and persisted once', () async {
    final persistence = FakeLibraryPersistence(
      initial: [_persisted('/a.pdf'), _persisted('/b.pdf')],
    );
    final container = _container(persistence);
    await container.read(libraryEntriesProvider.future);
    var updates = 0;
    container.listen(libraryEntriesProvider, (_, _) => updates++);

    await container.read(libraryEntriesProvider.notifier).setFavoriteForPaths({
      '/a.pdf',
      '/b.pdf',
      '/c.pdf',
    }, favorite: true);

    expect(updates, 1);
    expect(persistence.saves, hasLength(1));
    expect(persistence.saves.single, hasLength(3));
  });

  test(
    'given the initial load is pending, then the call waits for it',
    () async {
      final gate = Completer<void>();
      final persistence = FakeLibraryPersistence(
        initial: [_persisted('/a.pdf')],
        loadGate: gate.future,
      );
      final container = _container(persistence);
      container.listen(libraryEntriesProvider, (_, _) {});

      final pending = container
          .read(libraryEntriesProvider.notifier)
          .setFavoriteForPaths({'/a.pdf'}, favorite: true);
      gate.complete();
      await pending;

      expect(_find(container, '/a.pdf')!.isFavorite, isTrue);
    },
  );
}
