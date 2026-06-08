import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:pdf_app/core/models/file_status.dart';
import 'package:pdf_app/core/services/library_persistence_service.dart';
import 'package:pdf_app/features/library/state/library_entry.dart';

LibraryEntry _entry({
  required String id,
  required String path,
  bool favorite = false,
  String? collectionId,
}) => LibraryEntry(
  id: id,
  name: path.split('/').last,
  path: path,
  status: FileStatus.ok,
  isFavorite: favorite,
  collectionId: collectionId,
);

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('round-trips entries', () async {
    final service = LibraryPersistenceService();
    final entries = [
      _entry(id: '1', path: '/a.pdf', favorite: true),
      _entry(id: '2', path: '/b.pdf', collectionId: 'col-1'),
    ];

    // saveEntries is debounced; invoke _write directly via a zero-delay pump.
    await service.saveEntries(entries);
    await Future<void>.delayed(const Duration(milliseconds: 600));

    final loaded = await service.loadEntries();
    expect(loaded, hasLength(2));
    expect(loaded.first.isFavorite, isTrue);
    expect(loaded.last.collectionId, 'col-1');
  });

  test('returns empty list on corrupt JSON', () async {
    SharedPreferences.setMockInitialValues({
      'library_entries_v1': 'NOT VALID JSON}}}',
    });

    final service = LibraryPersistenceService();
    final loaded = await service.loadEntries();
    expect(loaded, isEmpty);
  });
}
