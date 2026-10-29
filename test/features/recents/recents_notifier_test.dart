import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sefer/core/services/recents_service.dart';
import 'package:sefer/features/recents/state/recents_notifier.dart';

class _FakeStore implements RecentsStore {
  final List<RecentEntry> _entries = [];

  @override
  Future<List<RecentEntry>> load() async => List.unmodifiable(_entries);

  @override
  Future<void> recordOpened(String path, String name) async {
    _entries.removeWhere((e) => e.path == path);
    _entries.insert(0, RecentEntry(path: path, name: name, openedAt: DateTime.now()));
  }

  @override
  Future<void> moveEntry({
    required String oldPath,
    required String newPath,
    required String newName,
  }) async {
    final index = _entries.indexWhere((e) => e.path == oldPath);
    if (index == -1) return;
    final old = _entries[index];
    _entries[index] =
        RecentEntry(path: newPath, name: newName, openedAt: old.openedAt);
  }

  @override
  Future<void> remove(String path) async {
    _entries.removeWhere((e) => e.path == path);
  }
}

void main() {
  test('load returns empty list initially', () async {
    final store = _FakeStore();
    final container = ProviderContainer(
      overrides: [recentsStoreProvider.overrideWithValue(store)],
    );
    addTearDown(container.dispose);

    await Future<void>.delayed(Duration.zero); // allow _load to complete
    expect(container.read(recentsProvider), isEmpty);
  });

  test('recordOpened prepends entry', () async {
    final store = _FakeStore();
    final container = ProviderContainer(
      overrides: [recentsStoreProvider.overrideWithValue(store)],
    );
    addTearDown(container.dispose);

    await container.read(recentsProvider.notifier).recordOpened('/a.pdf');
    await container.read(recentsProvider.notifier).recordOpened('/b.pdf');

    final recents = container.read(recentsProvider);
    expect(recents.first.path, '/b.pdf');
    expect(recents.length, 2);
  });

  test('duplicate path is deduped to top', () async {
    final store = _FakeStore();
    final container = ProviderContainer(
      overrides: [recentsStoreProvider.overrideWithValue(store)],
    );
    addTearDown(container.dispose);

    await container.read(recentsProvider.notifier).recordOpened('/a.pdf');
    await container.read(recentsProvider.notifier).recordOpened('/b.pdf');
    await container.read(recentsProvider.notifier).recordOpened('/a.pdf');

    final recents = container.read(recentsProvider);
    expect(recents.first.path, '/a.pdf');
    expect(recents.length, 2);
  });
}
