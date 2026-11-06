import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:sefer/core/providers.dart';
import 'package:sefer/core/services/library_persistence_service.dart';
import 'package:sefer/features/library/state/library_entry.dart';
import 'package:sefer/features/library/state/library_providers.dart';
import 'package:sefer/features/reader/presentation/reader_favorite_button.dart';
import 'package:sefer/core/theme/app_theme.dart';
import 'package:sefer/core/theme/reading_mode.dart';
import 'package:sefer/features/reader/presentation/reader_chrome.dart';
import 'package:sefer/features/reader/presentation/reader_dialogs.dart';

import '../../support/library_fakes.dart';

Widget _host(Widget child) {
  return MaterialApp(
    theme: AppTheme.light,
    home: Scaffold(body: child),
  );
}

List<Override> _libraryOverrides([List<PersistedEntry> entries = const []]) {
  return [
    libraryPersistenceProvider.overrideWithValue(
      FakeLibraryPersistence(initial: entries),
    ),
    fileServiceProvider.overrideWithValue(FakeFileChecker()),
  ];
}

Future<ProviderContainer> _pumpFavoriteButton(
  WidgetTester tester, {
  String path = '/docs/a.pdf',
  List<PersistedEntry> entries = const [],
}) async {
  final container = ProviderContainer(overrides: _libraryOverrides(entries));
  addTearDown(container.dispose);
  await container.read(libraryEntriesProvider.future);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: ReaderFavoriteButton(
            documentPath: path,
            readingMode: ReadingMode.light,
          ),
        ),
      ),
    ),
  );
  return container;
}

class _GatedPersistence extends FakeLibraryPersistence {
  _GatedPersistence(this.gate);

  final Completer<void> gate;
  var armed = false;

  @override
  Future<void> saveEntries(List<LibraryEntry> entries) =>
      armed ? gate.future : super.saveEntries(entries);
}

void main() {
  group('ReaderFavoriteButton', () {
    testWidgets('adds a document outside the library to favorites', (
      tester,
    ) async {
      final container = await _pumpFavoriteButton(tester);
      expect(find.byTooltip('Add to favorites'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.favorite_border));
      await tester.pump();
      await tester.pump();

      expect(container.read(favoritePathsProvider), {'/docs/a.pdf'});
      expect(find.byTooltip('Remove from favorites'), findsOneWidget);
      expect(find.byIcon(Icons.favorite), findsOneWidget);
    });

    testWidgets('removes an existing favorite and keeps the entry', (
      tester,
    ) async {
      final container = await _pumpFavoriteButton(
        tester,
        entries: const [
          PersistedEntry(
            id: 'a',
            name: 'a.pdf',
            path: '/docs/a.pdf',
            isFavorite: true,
          ),
        ],
      );
      expect(find.byTooltip('Remove from favorites'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.favorite));
      await tester.pump();
      await tester.pump();

      expect(container.read(favoritePathsProvider), isEmpty);
      expect(container.read(libraryEntriesProvider).value, hasLength(1));
      expect(find.byTooltip('Add to favorites'), findsOneWidget);
    });

    testWidgets('reflects favorite changes made elsewhere', (tester) async {
      final container = await _pumpFavoriteButton(tester);

      await container.read(libraryEntriesProvider.notifier).setFavoriteForPaths(
        {'/docs/a.pdf'},
        favorite: true,
      );
      await tester.pump();

      expect(find.byIcon(Icons.favorite), findsOneWidget);
    });

    testWidgets('works for a bundled asset path', (tester) async {
      final container = await _pumpFavoriteButton(
        tester,
        path: 'assets/sample.pdf',
      );

      await tester.tap(find.byIcon(Icons.favorite_border));
      await tester.pump();
      await tester.pump();

      expect(container.read(favoritePathsProvider), {'assets/sample.pdf'});
    });

    testWidgets('is disabled while the save is in flight', (tester) async {
      final gate = Completer<void>();
      final persistence = _GatedPersistence(gate);
      final container = ProviderContainer(
        overrides: [
          libraryPersistenceProvider.overrideWithValue(persistence),
          fileServiceProvider.overrideWithValue(FakeFileChecker()),
        ],
      );
      addTearDown(container.dispose);
      await container.read(libraryEntriesProvider.future);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: ReaderFavoriteButton(
                documentPath: '/docs/a.pdf',
                readingMode: ReadingMode.light,
              ),
            ),
          ),
        ),
      );
      final button = find.byType(IconButton);
      persistence.armed = true;

      await tester.tap(button);
      await tester.pump();
      expect(tester.widget<IconButton>(button).onPressed, isNull);

      gate.complete();
      await tester.pump();
      await tester.pump();
      expect(tester.widget<IconButton>(button).onPressed, isNotNull);
    });
  });

  testWidgets('ReaderMoreMenu hides Rename without a handler', (tester) async {
    await tester.pumpWidget(
      _host(
        ReaderMoreMenu(
          onAnnotations: () {},
          onReadingMode: () {},
          onShare: () {},
        ),
      ),
    );
    expect(find.text('Rename'), findsNothing);
  });

  testWidgets('ReaderMoreMenu shows Rename when a handler is given', (
    tester,
  ) async {
    var renamed = false;
    await tester.pumpWidget(
      _host(
        ReaderMoreMenu(
          onAnnotations: () {},
          onReadingMode: () {},
          onShare: () {},
          onRename: () => renamed = true,
        ),
      ),
    );
    await tester.tap(find.text('Rename'));
    expect(renamed, isTrue);
  });

  testWidgets('ReaderAppBar shows title and toggles bookmark', (tester) async {
    var bookmarked = false;
    await tester.pumpWidget(
      ProviderScope(
        overrides: _libraryOverrides(),
        child: MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            appBar: ReaderAppBar(
              title: 'My Book',
              isBookmarked: false,
              documentPath: '/docs/a.pdf',
              onBack: () {},
              onBookmark: () => bookmarked = true,
              readingMode: ReadingMode.light,
            ),
          ),
        ),
      ),
    );
    expect(find.text('My Book'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.bookmark_outline));
    expect(bookmarked, isTrue);
  });

  testWidgets('BottomActionBar exposes the four actions', (tester) async {
    await tester.pumpWidget(
      _host(
        BottomActionBar(
          onSearch: () {},
          onAnnotate: () {},
          onToc: () {},
          onMore: () {},
          readingMode: ReadingMode.light,
        ),
      ),
    );
    expect(find.text('Search'), findsOneWidget);
    expect(find.text('Annotate'), findsOneWidget);
    expect(find.text('Contents'), findsOneWidget);
    expect(find.text('More'), findsOneWidget);
  });

  testWidgets('PageIndicator renders current/total', (tester) async {
    await tester.pumpWidget(
      _host(PageIndicator(currentPage: 3, totalPages: 42, onTap: () {})),
    );
    expect(find.text('3 / 42'), findsOneWidget);
  });

  testWidgets('ReaderMoreMenu lists its entries', (tester) async {
    await tester.pumpWidget(
      _host(
        ReaderMoreMenu(
          onAnnotations: () {},
          onReadingMode: () {},
          onShare: () {},
        ),
      ),
    );
    expect(find.text('Annotations'), findsOneWidget);
    expect(find.text('Reading mode'), findsOneWidget);
    expect(find.text('Share'), findsOneWidget);
  });

  group('JumpToPageDialog', () {
    testWidgets('accepts an in-range page', (tester) async {
      int? result;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  result = await showDialog<int>(
                    context: context,
                    builder: (_) => JumpToPageDialog(
                      controller: TextEditingController(text: '5'),
                      totalPages: 10,
                    ),
                  );
                },
                child: const Text('go'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('go'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Go'));
      await tester.pumpAndSettle();
      expect(result, 5);
    });
  });

  testWidgets('BookmarkLabelDialog returns typed label', (tester) async {
    String? label;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                label = await showDialog<String>(
                  context: context,
                  builder: (_) =>
                      const BookmarkLabelDialog(defaultLabel: 'Page 1'),
                );
              },
              child: const Text('add'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('add'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Chapter 2');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(label, 'Chapter 2');
  });
}
