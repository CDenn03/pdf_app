import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sefer/core/services/recents_service.dart';
import 'package:sefer/features/recents/state/recents_notifier.dart';

class _FakeStore implements RecentsStore {
  _FakeStore({List<RecentEntry> initial = const [], this.loadGate})
    : _entries = [...initial];

  final Future<void>? loadGate;
  final List<RecentEntry> _entries;

  @override
  Future<List<RecentEntry>> load() async {
    await loadGate;
    return List.unmodifiable(_entries);
  }

  @override
  Future<void> recordOpened(String path, String name) async {
    _entries.removeWhere((e) => e.path == path);
    _entries.insert(
      0,
      RecentEntry(path: path, name: name, openedAt: DateTime.now()),
    );
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
    _entries[index] = RecentEntry(
      path: newPath,
      name: newName,
      openedAt: old.openedAt,
    );
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

    await container.read(recentsProvider.notifier).ready;
    expect(container.read(recentsProvider), isEmpty);
  });

  test('ready waits for a delayed store load', () async {
    final loadGate = Completer<void>();
    final openedAt = DateTime(2024);
    final store = _FakeStore(
      initial: [
        RecentEntry(path: '/book.pdf', name: 'book.pdf', openedAt: openedAt),
      ],
      loadGate: loadGate.future,
    );
    final container = ProviderContainer(
      overrides: [recentsStoreProvider.overrideWithValue(store)],
    );
    addTearDown(container.dispose);

    final notifier = container.read(recentsProvider.notifier);
    expect(container.read(recentsProvider), isEmpty);

    loadGate.complete();
    await notifier.ready;

    expect(container.read(recentsProvider).single.path, '/book.pdf');
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
