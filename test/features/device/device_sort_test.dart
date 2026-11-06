import 'package:flutter_test/flutter_test.dart';

import 'package:sefer/core/models/file_status.dart';
import 'package:sefer/features/device/domain/device_pdf_entry.dart';
import 'package:sefer/features/device/domain/device_sort.dart';

DevicePdfEntry _entry(
  String path, {
  DateTime? modified,
  int? size,
  String? name,
}) => DevicePdfEntry(
  path: path,
  name: name ?? path.split('/').last,
  status: FileStatus.ok,
  modifiedAt: modified,
  sizeBytes: size,
);

List<String> _paths(List<DevicePdfEntry> entries) =>
    entries.map((e) => e.path).toList();

void main() {
  final oldest = DateTime(2020);
  final newest = DateTime(2024);

  group('name', () {
    final entries = [_entry('/b.pdf'), _entry('/A.pdf'), _entry('/c.pdf')];

    test('ascending is case-insensitive', () {
      final sorted = sortDeviceEntries(entries, DeviceSort.defaultSort);

      expect(_paths(sorted), ['/A.pdf', '/b.pdf', '/c.pdf']);
    });

    test('descending reverses', () {
      final sorted = sortDeviceEntries(
        entries,
        const DeviceSort(DeviceSortField.name, SortDirection.descending),
      );

      expect(_paths(sorted), ['/c.pdf', '/b.pdf', '/A.pdf']);
    });
  });

  group('modifiedAt', () {
    final entries = [
      _entry('/unknown.pdf'),
      _entry('/new.pdf', modified: newest),
      _entry('/old.pdf', modified: oldest),
    ];

    test('ascending puts oldest first and unknown last', () {
      final sorted = sortDeviceEntries(
        entries,
        const DeviceSort(DeviceSortField.modifiedAt, SortDirection.ascending),
      );

      expect(_paths(sorted), ['/old.pdf', '/new.pdf', '/unknown.pdf']);
    });

    test('descending puts newest first and unknown still last', () {
      final sorted = sortDeviceEntries(
        entries,
        const DeviceSort(DeviceSortField.modifiedAt, SortDirection.descending),
      );

      expect(_paths(sorted), ['/new.pdf', '/old.pdf', '/unknown.pdf']);
    });
  });

  group('size', () {
    final entries = [
      _entry('/unknown.pdf'),
      _entry('/big.pdf', size: 900),
      _entry('/small.pdf', size: 10),
    ];

    test('ascending puts smallest first and unknown last', () {
      final sorted = sortDeviceEntries(
        entries,
        const DeviceSort(DeviceSortField.size, SortDirection.ascending),
      );

      expect(_paths(sorted), ['/small.pdf', '/big.pdf', '/unknown.pdf']);
    });

    test('descending puts largest first and unknown still last', () {
      final sorted = sortDeviceEntries(
        entries,
        const DeviceSort(DeviceSortField.size, SortDirection.descending),
      );

      expect(_paths(sorted), ['/big.pdf', '/small.pdf', '/unknown.pdf']);
    });
  });

  test('ties break by name then path, regardless of direction', () {
    final entries = [
      _entry('/z/same.pdf', size: 5, name: 'same.pdf'),
      _entry('/a/same.pdf', size: 5, name: 'same.pdf'),
      _entry('/m/other.pdf', size: 5, name: 'other.pdf'),
    ];

    for (final direction in SortDirection.values) {
      final sorted = sortDeviceEntries(
        entries,
        DeviceSort(DeviceSortField.size, direction),
      );

      expect(_paths(sorted), ['/m/other.pdf', '/a/same.pdf', '/z/same.pdf']);
    }
  });

  test('sorting returns a copy and leaves the input untouched', () {
    final input = [_entry('/b.pdf'), _entry('/a.pdf')];

    sortDeviceEntries(input, DeviceSort.defaultSort);

    expect(_paths(input), ['/b.pdf', '/a.pdf']);
  });

  test('every option has a distinct label', () {
    final labels = DeviceSort.all.map((s) => s.label).toSet();

    expect(labels, hasLength(6));
  });
}
