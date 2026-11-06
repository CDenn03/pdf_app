import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sefer/core/theme/app_colors.dart';
import 'package:sefer/features/home/presentation/splash_screen.dart';

const _minimumDuration = Duration(milliseconds: 100);
const _loadingDelay = Duration(milliseconds: 150);
const _exitDuration = Duration(milliseconds: 50);
const _textRevealDelay = Duration(milliseconds: 20);

Widget _host({
  required Future<void> readiness,
  required VoidCallback onDone,
  Brightness brightness = Brightness.light,
  bool disableAnimations = false,
  Duration minimumDuration = _minimumDuration,
  Duration loadingDelay = _loadingDelay,
  Duration exitDuration = _exitDuration,
}) {
  return MaterialApp(
    home: MediaQuery(
      data: MediaQueryData(
        size: const Size(800, 600),
        platformBrightness: brightness,
        disableAnimations: disableAnimations,
      ),
      child: SplashScreen(
        readiness: readiness,
        onDone: onDone,
        minimumDuration: minimumDuration,
        loadingDelay: loadingDelay,
        exitDuration: exitDuration,
        textRevealDelay: _textRevealDelay,
        textRevealDuration: const Duration(milliseconds: 30),
      ),
    ),
  );
}

Finder _logoFinder() {
  return find.byWidgetPredicate((widget) {
    if (widget is! Image || widget.image is! AssetImage) return false;
    return (widget.image as AssetImage).assetName == SplashScreen.logoAsset;
  });
}

void main() {
  group('initial frame', () {
    for (final brightness in Brightness.values) {
      testWidgets('matches native splash in $brightness mode', (tester) async {
        final readiness = Completer<void>();
        await tester.pumpWidget(
          _host(
            readiness: readiness.future,
            onDone: () {},
            brightness: brightness,
          ),
        );

        final expectedColor = brightness == Brightness.dark
            ? AppColors.splashDark
            : AppColors.splashLight;
        final background = tester.widget<ColoredBox>(
          find.byKey(const ValueKey('splash-background')),
        );
        final image = tester.widget<Image>(_logoFinder());

        expect(background.color, expectedColor);
        expect(_logoFinder(), findsOneWidget);
        expect(image.width, SplashScreen.logoExtent);
        expect(image.height, SplashScreen.logoExtent);
        expect(find.byIcon(Icons.menu_book_rounded), findsNothing);
        expect(find.text('PDF Navigator'), findsNothing);
        expect(find.text('Your personal reading library'), findsNothing);
        expect(find.text('Sefer'), findsNothing);
      });
    }
  });

  testWidgets('reveals copy without moving the logo', (tester) async {
    final readiness = Completer<void>();
    await tester.pumpWidget(_host(readiness: readiness.future, onDone: () {}));
    final initialLogoCenter = tester.getCenter(_logoFinder());
    final splashCenter = tester.getCenter(find.byType(SplashScreen));

    expect(initialLogoCenter, splashCenter);
    await tester.pump(_textRevealDelay);

    expect(find.text('Sefer'), findsOneWidget);
    expect(find.text('Read. Reflect. Understand.'), findsOneWidget);
    expect(tester.getCenter(_logoFinder()), initialLogoCenter);
  });

  testWidgets('early readiness still respects minimum and exit', (
    tester,
  ) async {
    var doneCount = 0;
    await tester.pumpWidget(
      _host(readiness: Future.value(), onDone: () => doneCount++),
    );

    await tester.pump(const Duration(milliseconds: 99));
    expect(doneCount, 0);
    await tester.pump(const Duration(milliseconds: 1));
    expect(doneCount, 0);
    await tester.pump(const Duration(milliseconds: 49));
    expect(doneCount, 0);
    await tester.pump(const Duration(milliseconds: 1));
    expect(doneCount, 1);
  });

  testWidgets('late readiness reveals loading only after threshold', (
    tester,
  ) async {
    final readiness = Completer<void>();
    var doneCount = 0;
    await tester.pumpWidget(
      _host(readiness: readiness.future, onDone: () => doneCount++),
    );

    await tester.pump(const Duration(milliseconds: 149));
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('Loading…'), findsNothing);
    await tester.pump(const Duration(milliseconds: 1));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    readiness.complete();
    await tester.pump();
    await tester.pump(_exitDuration);
    expect(doneCount, 1);
  });

  testWidgets('onDone runs once after exit', (tester) async {
    final readiness = Completer<void>();
    var doneCount = 0;
    await tester.pumpWidget(
      _host(readiness: readiness.future, onDone: () => doneCount++),
    );

    readiness.complete();
    await tester.pump(_minimumDuration);
    await tester.pump(_exitDuration);
    await tester.pump(const Duration(seconds: 1));

    expect(doneCount, 1);
  });

  testWidgets('readiness failure dismisses after the minimum', (tester) async {
    final readiness = Completer<void>();
    var doneCount = 0;
    await tester.pumpWidget(
      _host(readiness: readiness.future, onDone: () => doneCount++),
    );
    readiness.completeError(StateError('load failed'));
    await tester.pump();

    await tester.pump(_minimumDuration);
    expect(doneCount, 0);
    await tester.pump(_exitDuration);

    expect(doneCount, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('reduced motion uses static loading and immediate exit', (
    tester,
  ) async {
    final readiness = Completer<void>();
    var doneCount = 0;
    await tester.pumpWidget(
      _host(
        readiness: readiness.future,
        onDone: () => doneCount++,
        disableAnimations: true,
        loadingDelay: const Duration(milliseconds: 50),
      ),
    );

    await tester.pump(_textRevealDelay);
    final switcher = tester.widget<AnimatedSwitcher>(
      find.ancestor(
        of: find.text('Sefer'),
        matching: find.byType(AnimatedSwitcher),
      ),
    );
    expect(switcher.duration, Duration.zero);

    await tester.pump(const Duration(milliseconds: 30));
    expect(find.text('Loading…'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);

    readiness.complete();
    await tester.pump(const Duration(milliseconds: 50));
    expect(doneCount, 1);
  });

  testWidgets('disposing with pending readiness is safe', (tester) async {
    final readiness = Completer<void>();
    var doneCount = 0;
    await tester.pumpWidget(
      _host(readiness: readiness.future, onDone: () => doneCount++),
    );

    await tester.pumpWidget(const SizedBox.shrink());
    readiness.complete();
    await tester.pump(const Duration(seconds: 1));

    expect(doneCount, 0);
    expect(tester.takeException(), isNull);
  });
}
