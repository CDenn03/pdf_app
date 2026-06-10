import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:sefer/core/models/file_status.dart';
import 'package:sefer/core/providers.dart';
import 'package:sefer/core/services/file_service.dart';
import 'package:sefer/core/services/library_persistence_service.dart';
import 'package:sefer/features/library/state/library_providers.dart';

class _MockFileChecker extends Mock implements FileChecker {}

class _MockPersistence extends Mock implements LibraryPersistence {}

void main() {
  late _MockFileChecker checker;
  late _MockPersistence persistence;

  setUp(() {
    checker = _MockFileChecker();
    persistence = _MockPersistence();

    when(() => checker.checkFile(any())).thenAnswer((_) async => FileStatus.ok);
    when(() => persistence.loadEntries()).thenAnswer((_) async => []);
    when(() => persistence.saveEntries(any())).thenAnswer((_) async {});
  });

  ProviderContainer container0() => ProviderContainer(
    overrides: [
      fileServiceProvider.overrideWithValue(checker),
      libraryPersistenceProvider.overrideWithValue(persistence),
    ],
  );

  test('starts with sample when persistence is empty', () async {
    final container = container0();
    addTearDown(container.dispose);

    // Allow async build to complete.
    await container.read(libraryEntriesProvider.future);
    final entries = container.read(libraryEntriesProvider).value!;

    expect(entries, hasLength(1));
    expect(entries.first.name, 'sample.pdf');
  });

  test('addFile appends entry', () async {
    final container = container0();
    addTearDown(container.dispose);

    await container.read(libraryEntriesProvider.future);
    await container.read(libraryEntriesProvider.notifier).addFile('/docs/a.pdf');

    final entries = container.read(libraryEntriesProvider).value!;
    expect(entries.any((e) => e.path == '/docs/a.pdf'), isTrue);
  });

  test('removeFile deletes entry by id', () async {
    when(() => persistence.loadEntries()).thenAnswer(
      (_) async => [
        const PersistedEntry(id: 'x1', name: 'a.pdf', path: '/a.pdf'),
      ],
    );
    final container = container0();
    addTearDown(container.dispose);

    await container.read(libraryEntriesProvider.future);
    await container.read(libraryEntriesProvider.notifier).removeFile('x1');

    expect(container.read(libraryEntriesProvider).value, isEmpty);
  });

  test('toggleFavorite flips isFavorite', () async {
    when(() => persistence.loadEntries()).thenAnswer(
      (_) async => [
        const PersistedEntry(id: 'x2', name: 'b.pdf', path: '/b.pdf'),
      ],
    );
    final container = container0();
    addTearDown(container.dispose);

    await container.read(libraryEntriesProvider.future);
    final id = container.read(libraryEntriesProvider).value!.first.id;
    await container.read(libraryEntriesProvider.notifier).toggleFavorite(id);

    expect(
      container.read(libraryEntriesProvider).value!.first.isFavorite,
      isTrue,
    );
  });

  test('moveToCollection updates collectionId', () async {
    when(() => persistence.loadEntries()).thenAnswer(
      (_) async => [
        const PersistedEntry(id: 'x3', name: 'c.pdf', path: '/c.pdf'),
      ],
    );
    final container = container0();
    addTearDown(container.dispose);

    await container.read(libraryEntriesProvider.future);
    await container
        .read(libraryEntriesProvider.notifier)
        .moveToCollection('x3', 'col-1');

    expect(
      container.read(libraryEntriesProvider).value!.first.collectionId,
      'col-1',
    );
  });
}
