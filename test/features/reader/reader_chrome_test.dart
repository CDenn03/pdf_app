import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sefer/core/theme/app_theme.dart';
import 'package:sefer/core/theme/reading_mode.dart';
import 'package:sefer/features/reader/presentation/reader_chrome.dart';
import 'package:sefer/features/reader/presentation/reader_dialogs.dart';

Widget _host(Widget child) {
  return MaterialApp(theme: AppTheme.light, home: Scaffold(body: child));
}

void main() {
  testWidgets('ReaderAppBar shows title and toggles bookmark', (tester) async {
    var bookmarked = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          appBar: ReaderAppBar(
            title: 'My Book',
            isBookmarked: false,
            onBack: () {},
            onBookmark: () => bookmarked = true,
            readingMode: ReadingMode.light,
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
      _host(BottomActionBar(
        onSearch: () {},
        onAnnotate: () {},
        onToc: () {},
        onMore: () {},
        readingMode: ReadingMode.light,
      )),
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
      _host(ReaderMoreMenu(
        onAnnotations: () {},
        onReadingMode: () {},
        onShare: () {},
      )),
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
                  builder: (_) => const BookmarkLabelDialog(defaultLabel: 'Page 1'),
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
