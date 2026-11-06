import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sefer/shared/widgets/selection_action_bar.dart';

Future<List<bool>> _pump(
  WidgetTester tester, {
  required Set<String> selected,
  required Set<String> favorites,
  List<Widget> extra = const [],
}) async {
  final calls = <bool>[];
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SelectionActionBar(
          selectedPaths: selected,
          favoritePaths: favorites,
          onSetFavorite: calls.add,
          extraActions: extra,
        ),
      ),
    ),
  );
  return calls;
}

void main() {
  testWidgets('mixed selection shows both favorite actions', (tester) async {
    await _pump(tester, selected: {'/a', '/b'}, favorites: {'/a'});

    expect(find.text('Mark favorite'), findsOneWidget);
    expect(find.text('Remove favorite'), findsOneWidget);
  });

  testWidgets('all favorites shows only Remove favorite', (tester) async {
    await _pump(tester, selected: {'/a'}, favorites: {'/a', '/z'});

    expect(find.text('Mark favorite'), findsNothing);
    expect(find.text('Remove favorite'), findsOneWidget);
  });

  testWidgets('no favorites shows only Mark favorite and extras', (
    tester,
  ) async {
    final calls = await _pump(
      tester,
      selected: {'/a'},
      favorites: {},
      extra: [TextButton(onPressed: () {}, child: const Text('Extra'))],
    );

    await tester.tap(find.text('Mark favorite'));

    expect(find.text('Remove favorite'), findsNothing);
    expect(find.text('Extra'), findsOneWidget);
    expect(calls, [true]);
  });
}
