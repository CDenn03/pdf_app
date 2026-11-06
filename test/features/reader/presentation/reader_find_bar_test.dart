import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sefer/core/theme/reading_mode.dart';
import 'package:sefer/features/reader/presentation/reader_find_bar.dart';
import 'package:sefer/features/reader/domain/reader_search_controller.dart';
import 'package:sefer/features/reader/domain/search_excerpt.dart';

class _FakeSearch extends ChangeNotifier implements ReaderSearchController {
  List<FindMatch> _matches = const [];
  int? _currentIndex;
  final bool _isSearching = false;
  final List<int> jumped = [];

  void setResults(List<FindMatch> matches, {int? current}) {
    _matches = matches;
    _currentIndex = current;
    notifyListeners();
  }

  @override
  List<FindMatch> get matches => _matches;

  @override
  int? get currentIndex => _currentIndex;

  @override
  bool get isSearching => _isSearching;

  @override
  void startTextSearch(String query) {}

  @override
  void resetTextSearch() {
    _matches = const [];
    _currentIndex = null;
    notifyListeners();
  }

  @override
  Future<void> goToMatchAt(int index, {required double chromeMargin}) async {
    jumped.add(index);
    _currentIndex = index;
    notifyListeners();
  }

  @override
  Future<void> goToNextMatch({required double chromeMargin}) => goToMatchAt(
    (_currentIndex! + 1) % _matches.length,
    chromeMargin: chromeMargin,
  );

  @override
  Future<void> goToPreviousMatch({required double chromeMargin}) => goToMatchAt(
    _currentIndex! <= 0 ? _matches.length - 1 : _currentIndex! - 1,
    chromeMargin: chromeMargin,
  );
}

Widget _host({
  required ReaderSearchController search,
  required VoidCallback onClose,
  required VoidCallback onViewerTap,
}) {
  return MaterialApp(
    home: Scaffold(
      body: Stack(
        children: [
          // Stand-in for the interactive document beneath the find bar.
          Positioned.fill(
            child: GestureDetector(
              onTap: onViewerTap,
              child: const ColoredBox(color: Colors.white),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: ReaderFindBar(
              search: search,
              readingMode: ReadingMode.light,
              onClose: onClose,
            ),
          ),
        ],
      ),
    ),
  );
}

void main() {
  const matches = [
    FindMatch(page: 2, excerpt: SearchExcerpt.plain('first hit')),
    FindMatch(page: 5, excerpt: SearchExcerpt.plain('second hit')),
    FindMatch(
      page: 9,
      excerpt: SearchExcerpt(
        before: 'The quick ',
        match: 'third hit',
        after: ' lands.',
        hasLeadingEllipsis: true,
        hasTrailingEllipsis: true,
      ),
    ),
  ];

  testWidgets('renders counter and prev/next/close controls', (tester) async {
    final search = _FakeSearch()..setResults(matches, current: 0);
    await tester.pumpWidget(
      _host(search: search, onClose: () {}, onViewerTap: () {}),
    );
    await tester.pump();

    expect(find.text('1 of 3'), findsOneWidget);
    expect(find.byIcon(Icons.keyboard_arrow_up), findsOneWidget);
    expect(find.byIcon(Icons.keyboard_arrow_down), findsOneWidget);
    expect(find.byIcon(Icons.close), findsOneWidget);
  });

  testWidgets('next advances the active match', (tester) async {
    final search = _FakeSearch()..setResults(matches, current: 0);
    await tester.pumpWidget(
      _host(search: search, onClose: () {}, onViewerTap: () {}),
    );
    await tester.pump();

    await tester.tap(find.byIcon(Icons.keyboard_arrow_down));
    await tester.pump();
    expect(search.jumped, [1]);
    expect(find.text('2 of 3'), findsOneWidget);
  });

  testWidgets('a tap outside the bar does not dismiss it and reaches the '
      'viewer', (tester) async {
    var closed = false;
    var viewerTaps = 0;
    final search = _FakeSearch()..setResults(matches, current: 0);
    await tester.pumpWidget(
      _host(
        search: search,
        onClose: () => closed = true,
        onViewerTap: () => viewerTaps++,
      ),
    );
    await tester.pump();

    // Tap well below the find bar, in the viewer band.
    await tester.tapAt(const Offset(200, 500));
    await tester.pump();

    expect(viewerTaps, 1);
    expect(closed, isFalse);
    expect(find.byType(ReaderFindBar), findsOneWidget);
  });

  testWidgets('the active result row is styled differently from the others', (
    tester,
  ) async {
    final search = _FakeSearch()..setResults(matches, current: 1);
    await tester.pumpWidget(
      _host(search: search, onClose: () {}, onViewerTap: () {}),
    );
    await tester.pump();

    // Expand the result list.
    await tester.tap(find.byIcon(Icons.list));
    await tester.pump();

    ListTile rowOf(String text) => tester.widget<ListTile>(
      find.ancestor(
        of: find.textContaining(text, findRichText: true),
        matching: find.byType(ListTile),
      ),
    );
    expect(rowOf('second hit').selected, isTrue);
    expect(rowOf('first hit').selected, isFalse);
  });

  testWidgets('excerpt spans style before, match and after distinctly', (
    tester,
  ) async {
    final search = _FakeSearch()..setResults(matches, current: 0);
    await tester.pumpWidget(
      _host(search: search, onClose: () {}, onViewerTap: () {}),
    );
    await tester.pump();
    await tester.tap(find.byIcon(Icons.list));
    await tester.pump();

    final rich = tester.widget<RichText>(
      find.byWidgetPredicate(
        (widget) =>
            widget is RichText && widget.text.toPlainText().contains('quick'),
      ),
    );
    final root = (rich.text as TextSpan).children!.single as TextSpan;
    final spans = root.children!.cast<TextSpan>();
    final byText = {for (final span in spans) span.text: span};

    expect(byText['… '], isNotNull);
    expect(byText[' …'], isNotNull);
    expect(byText['third hit']!.style!.fontWeight, FontWeight.w600);
    expect(byText['The quick ']!.style, isNull);
    expect(root.style!.color, ReadingMode.light.secondaryText);
    expect(byText['third hit']!.style!.color, isNot(root.style!.color));
    expect(rich.maxLines, 2);
  });

  testWidgets('result row exposes one coherent semantic label', (tester) async {
    final handle = tester.ensureSemantics();
    final search = _FakeSearch()..setResults(matches, current: 0);
    await tester.pumpWidget(
      _host(search: search, onClose: () {}, onViewerTap: () {}),
    );
    await tester.pump();
    await tester.tap(find.byIcon(Icons.list));
    await tester.pump();

    expect(
      find.bySemanticsLabel('Page 9: … The quick third hit lands. …'),
      findsOneWidget,
    );
    handle.dispose();
  });

  testWidgets('tapping a result row requests a jump to it', (tester) async {
    final search = _FakeSearch()..setResults(matches, current: 0);
    await tester.pumpWidget(
      _host(search: search, onClose: () {}, onViewerTap: () {}),
    );
    await tester.pump();

    await tester.tap(find.byIcon(Icons.list));
    await tester.pump();
    await tester.tap(find.textContaining('third hit', findRichText: true));
    await tester.pump();
    expect(search.jumped, [2]);
  });
}
