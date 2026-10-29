import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sefer/features/reader/presentation/reader_viewport_inset.dart';

/// Reproduces the reader's body structure: a Scaffold with
/// `extendBodyBehindAppBar: true` whose body insets the viewport exactly once
/// via [ReaderViewportInset]. The viewport's top must not move when the app
/// bar toggles.
Widget _host({required bool barVisible, required double statusBar}) {
  return MediaQuery(
    data: MediaQueryData(padding: EdgeInsets.only(top: statusBar)),
    child: Directionality(
      textDirection: TextDirection.ltr,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: barVisible
            ? AppBar(title: const Text('t'))
            : null,
        body: ReaderViewportInset(
          topInset: statusBar,
          child: const SizedBox.expand(key: Key('viewport')),
        ),
      ),
    ),
  );
}

void main() {
  const statusBar = 32.0;

  Future<double> viewportTop(WidgetTester tester,
      {required bool barVisible}) async {
    await tester.pumpWidget(
      MaterialApp(home: _host(barVisible: barVisible, statusBar: statusBar)),
    );
    return tester.getTopLeft(find.byKey(const Key('viewport'))).dy;
  }

  testWidgets('viewport top equals the status bar inset with bars visible',
      (tester) async {
    final top = await viewportTop(tester, barVisible: true);
    expect(top, statusBar);
  });

  testWidgets('viewport top equals the status bar inset with bars hidden',
      (tester) async {
    final top = await viewportTop(tester, barVisible: false);
    expect(top, statusBar);
  });

  testWidgets('viewport top is identical whether bars are shown or hidden',
      (tester) async {
    final shown = await viewportTop(tester, barVisible: true);
    final hidden = await viewportTop(tester, barVisible: false);
    expect(shown, hidden);
    expect(shown, statusBar);
  });
}
