import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sefer/core/providers.dart';
import 'package:sefer/core/utils/bounded_concurrency.dart';
import 'package:sefer/features/device/data/file_metadata_reader.dart';
import 'package:sefer/features/device/state/device_files_providers.dart';
import 'package:sefer/features/library/state/library_providers.dart';

import '../../support/library_fakes.dart';

ProviderContainer _container(List<String> paths, FakeMetadataReader reader) {
  final container = ProviderContainer(
    overrides: [
      fileServiceProvider.overrideWithValue(FakeFileChecker()),
      pdfScannerProvider.overrideWithValue(FakePdfScanner(paths)),
      fileMetadataReaderProvider.overrideWithValue(reader),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  final modified = DateTime(2023, 5, 1);

  test('given metadata, when scanning, then rows carry it', () async {
    final reader = FakeMetadataReader({
      '/d/a.pdf': FileMetadata(modifiedAt: modified, sizeBytes: 42),
    });
    final container = _container(['/d/a.pdf'], reader);

    final rows = await container.read(deviceFilesProvider.future);

    expect(rows.single.modifiedAt, modified);
    expect(rows.single.sizeBytes, 42);
    expect(rows.single.name, 'a.pdf');
  });

  test('given a failed stat, then the row is kept without metadata', () async {
    final reader = FakeMetadataReader({'/d/a.pdf': null});
    final container = _container(['/d/a.pdf'], reader);

    final rows = await container.read(deviceFilesProvider.future);

    expect(rows, hasLength(1));
    expect(rows.single.modifiedAt, isNull);
    expect(rows.single.sizeBytes, isNull);
  });

  test(
    'given duplicate or unnormalized paths, then rows are deduped',
    () async {
      final reader = FakeMetadataReader({'/d/a.pdf': null});
      final container = _container([
        '/d/a.pdf',
        '/d/./a.pdf',
        '/d/x/../a.pdf',
      ], reader);

      final rows = await container.read(deviceFilesProvider.future);

      expect(rows.map((e) => e.path), ['/d/a.pdf']);
      expect(reader.reads, ['/d/a.pdf']);
    },
  );

  test('given many files, then stat concurrency is bounded', () async {
    final paths = [for (var i = 0; i < 40; i++) '/d/$i.pdf'];
    final reader = FakeMetadataReader({});
    final container = _container(paths, reader);

    final rows = await container.read(deviceFilesProvider.future);

    expect(rows, hasLength(40));
    expect(reader.maxInFlight, lessThanOrEqualTo(8));
    expect(reader.maxInFlight, greaterThan(1));
  });

  test('mapWithConcurrency keeps input order', () async {
    final result = await mapWithConcurrency<int, int>([3, 1, 2], 2, (n) async {
      await Future<void>.delayed(Duration(milliseconds: n));
      return n * 10;
    });

    expect(result, [30, 10, 20]);
  });

  test('applyRename and removePath patch rows in place', () async {
    final reader = FakeMetadataReader({});
    final container = _container(['/d/a.pdf', '/d/b.pdf'], reader);
    await container.read(deviceFilesProvider.future);
    final notifier = container.read(deviceFilesProvider.notifier);

    notifier.applyRename(oldPath: '/d/a.pdf', newPath: '/d/c.pdf');
    notifier.removePath('/d/b.pdf');

    final rows = container.read(deviceFilesProvider).value!;
    expect(rows.single.path, '/d/c.pdf');
    expect(rows.single.name, 'c.pdf');
  });
}
