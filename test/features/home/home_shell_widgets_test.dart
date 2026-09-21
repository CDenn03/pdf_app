import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sefer/core/theme/app_theme.dart';
import 'package:sefer/features/home/presentation/home_shell.dart';

Widget _host(Widget child, {required Brightness brightness}) {
  return MaterialApp(
    theme: brightness == Brightness.dark ? AppTheme.dark : AppTheme.light,
    home: Scaffold(body: child),
  );
}

void main() {
  group('GreetingHeader', () {
    for (final brightness in Brightness.values) {
      testWidgets('renders title and subtitle ($brightness)', (tester) async {
        await tester.pumpWidget(
          _host(
            const GreetingHeader(title: 'Library', subtitle: 'Good morning'),
            brightness: brightness,
          ),
        );
        expect(find.text('Library'), findsOneWidget);
        expect(find.text('Good morning'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('renders trailing action', (tester) async {
      await tester.pumpWidget(
        _host(
          GreetingHeader(
            title: 'Device',
            action: IconButton(icon: const Icon(Icons.refresh), onPressed: () {}),
          ),
          brightness: Brightness.light,
        ),
      );
      expect(find.byIcon(Icons.refresh), findsOneWidget);
    });
  });

  group('PageSearchBar', () {
    for (final brightness in Brightness.values) {
      testWidgets('renders and reports changes ($brightness)', (tester) async {
        final controller = TextEditingController();
        String? changed;
        await tester.pumpWidget(
          _host(
            PageSearchBar(
              controller: controller,
              onChanged: (v) => changed = v,
              hintText: 'Search library…',
            ),
            brightness: brightness,
          ),
        );
        expect(find.text('Search library…'), findsOneWidget);
        await tester.enterText(find.byType(TextField), 'report');
        expect(changed, 'report');
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('clear button appears with text and clears', (tester) async {
      final controller = TextEditingController(text: 'x');
      String? changed;
      await tester.pumpWidget(
        _host(
          PageSearchBar(controller: controller, onChanged: (v) => changed = v),
          brightness: Brightness.light,
        ),
      );
      expect(find.byIcon(Icons.close), findsOneWidget);
      await tester.tap(find.byIcon(Icons.close));
      expect(changed, '');
      expect(controller.text, '');
    });
  });

  group('SectionLabel', () {
    testWidgets('uppercases its text', (tester) async {
      await tester.pumpWidget(
        _host(const SectionLabel('collections'), brightness: Brightness.dark),
      );
      expect(find.text('COLLECTIONS'), findsOneWidget);
    });
  });
}
