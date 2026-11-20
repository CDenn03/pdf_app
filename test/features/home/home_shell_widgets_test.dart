import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sefer/core/theme/app_theme.dart';
import 'package:sefer/features/home/presentation/home_shell.dart';
import 'package:sefer/features/home/presentation/page_headers.dart';

Widget _host(Widget child, {required Brightness brightness}) {
  return MaterialApp(
    theme: brightness == Brightness.dark ? AppTheme.dark : AppTheme.light,
    home: Scaffold(body: child),
  );
}

void main() {
  group('PageHeader', () {
    for (final brightness in Brightness.values) {
      testWidgets('renders title and subtitle ($brightness)', (tester) async {
        await tester.pumpWidget(
          _host(
            const PageHeader(title: 'Settings', subtitle: 'Preferences'),
            brightness: brightness,
          ),
        );
        expect(find.text('Settings'), findsOneWidget);
        expect(find.text('Preferences'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('renders trailing action', (tester) async {
      await tester.pumpWidget(
        _host(
          PageHeader(
            title: 'PDFs on device',
            action: IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {},
            ),
          ),
          brightness: Brightness.light,
        ),
      );
      expect(find.text('PDFs on device'), findsOneWidget);
      expect(find.byIcon(Icons.refresh), findsOneWidget);
    });

    testWidgets('title tap callback fires', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        _host(
          PageHeader(title: 'Reader', onTitleTap: () => tapped = true),
          brightness: Brightness.light,
        ),
      );
      await tester.tap(find.text('Reader'));
      expect(tapped, isTrue);
    });
  });

  group('timeGreeting', () {
    test('morning before noon', () {
      expect(timeGreeting(DateTime(2026, 1, 1, 8)), 'Good morning');
    });

    test('afternoon until 17:00', () {
      expect(timeGreeting(DateTime(2026, 1, 1, 14)), 'Good afternoon');
    });

    test('evening after 17:00', () {
      expect(timeGreeting(DateTime(2026, 1, 1, 20)), 'Good evening');
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
