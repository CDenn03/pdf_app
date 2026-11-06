import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sefer/core/models/collection.dart';
import 'package:sefer/core/models/file_status.dart';
import 'package:sefer/core/theme/app_theme.dart';
import 'package:sefer/features/library/presentation/library_collection_grid.dart';
import 'package:sefer/features/library/presentation/library_entry_tile.dart';
import 'package:sefer/features/library/state/library_entry.dart';

LibraryEntry _entry({
  String id = 'e1',
  String name = 'Doc.pdf',
  bool favorite = false,
  String? collectionId,
  FileStatus status = FileStatus.ok,
}) {
  return LibraryEntry(
    id: id,
    name: name,
    path: '/x/$id.pdf',
    status: status,
    isFavorite: favorite,
    collectionId: collectionId,
  );
}

Widget _sliverHost(Widget sliver) {
  return ProviderScope(
    child: MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(body: CustomScrollView(slivers: [sliver])),
    ),
  );
}

Widget _tileHost(Widget child) {
  return ProviderScope(
    child: MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(body: child),
    ),
  );
}

void main() {
  group('CollectionGrid', () {
    testWidgets('shows Favorites card first with favorite count', (
      tester,
    ) async {
      await tester.pumpWidget(
        _sliverHost(
          CollectionGrid(
            collections: const [],
            entries: [
              _entry(favorite: true),
              _entry(id: 'e2', favorite: true),
            ],
          ),
        ),
      );
      expect(find.text('Favorites'), findsOneWidget);
      expect(find.text('2 files'), findsOneWidget);
    });

    testWidgets('renders collection cards with per-collection counts', (
      tester,
    ) async {
      await tester.pumpWidget(
        _sliverHost(
          CollectionGrid(
            collections: const [
              PdfCollection(id: 'c1', name: 'Papers'),
              PdfCollection(id: 'c2', name: 'Novels'),
            ],
            entries: [
              _entry(id: 'a', collectionId: 'c1'),
              _entry(id: 'b', collectionId: 'c1'),
              _entry(id: 'c', collectionId: 'c2'),
            ],
          ),
        ),
      );
      expect(find.text('Papers'), findsOneWidget);
      expect(find.text('Novels'), findsOneWidget);
      expect(find.text('2 files'), findsOneWidget); // Papers
      expect(find.text('1 file'), findsOneWidget); // Novels
    });

    testWidgets('singular file label', (tester) async {
      await tester.pumpWidget(
        _sliverHost(
          CollectionGrid(
            collections: const [],
            entries: [_entry(favorite: true)],
          ),
        ),
      );
      expect(find.text('1 file'), findsOneWidget);
    });
  });

  group('LibraryEntryTile', () {
    testWidgets('shows favorite tag and heart trailing', (tester) async {
      await tester.pumpWidget(
        _tileHost(LibraryEntryTile(entry: _entry(favorite: true))),
      );
      expect(find.text('Doc.pdf'), findsOneWidget);
      expect(find.text('Favorite'), findsOneWidget);
      expect(find.byIcon(Icons.favorite), findsOneWidget);
    });

    testWidgets('unavailable entry shows unavailable label', (tester) async {
      await tester.pumpWidget(
        _tileHost(LibraryEntryTile(entry: _entry(status: FileStatus.missing))),
      );
      expect(find.text('File unavailable'), findsOneWidget);
    });
  });
}
