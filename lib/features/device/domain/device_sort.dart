import 'package:flutter/foundation.dart';

import 'package:sefer/features/device/domain/device_pdf_entry.dart';

enum DeviceSortField { name, modifiedAt, size }

enum SortDirection { ascending, descending }

@immutable
class DeviceSort {
  const DeviceSort(this.field, this.direction);

  static const defaultSort = DeviceSort(
    DeviceSortField.name,
    SortDirection.ascending,
  );

  static final all = [
    for (final field in DeviceSortField.values)
      for (final direction in SortDirection.values)
        DeviceSort(field, direction),
  ];

  final DeviceSortField field;
  final SortDirection direction;

  String get label {
    final ascending = direction == SortDirection.ascending;
    return switch (field) {
      DeviceSortField.name => ascending ? 'Name: A-Z' : 'Name: Z-A',
      DeviceSortField.modifiedAt =>
        ascending ? 'Modified: Oldest first' : 'Modified: Newest first',
      DeviceSortField.size =>
        ascending ? 'Size: Smallest first' : 'Size: Largest first',
    };
  }

  @override
  bool operator ==(Object other) =>
      other is DeviceSort &&
      other.field == field &&
      other.direction == direction;

  @override
  int get hashCode => Object.hash(field, direction);
}

/// Returns a sorted copy; entries with unknown values go last in both
/// directions, and ties fall back to name then path.
List<DevicePdfEntry> sortDeviceEntries(
  Iterable<DevicePdfEntry> entries,
  DeviceSort sort,
) {
  return entries.toList()..sort((a, b) => _compare(a, b, sort));
}

int _compare(DevicePdfEntry a, DevicePdfEntry b, DeviceSort sort) {
  final sign = sort.direction == SortDirection.ascending ? 1 : -1;
  final primary = switch (sort.field) {
    DeviceSortField.name => sign * _compareNames(a, b),
    DeviceSortField.modifiedAt => _compareNullable(
      a.modifiedAt,
      b.modifiedAt,
      sign,
    ),
    DeviceSortField.size => _compareNullable(a.sizeBytes, b.sizeBytes, sign),
  };
  if (primary != 0) return primary;
  final byName = _compareNames(a, b);
  return byName != 0 ? byName : a.path.compareTo(b.path);
}

int _compareNames(DevicePdfEntry a, DevicePdfEntry b) {
  final folded = a.name.toLowerCase().compareTo(b.name.toLowerCase());
  return folded != 0 ? folded : a.name.compareTo(b.name);
}

int _compareNullable<T extends Comparable<T>>(T? a, T? b, int sign) {
  if (a == null || b == null) {
    if (a == null && b == null) return 0;
    return a == null ? 1 : -1;
  }
  return sign * a.compareTo(b);
}
