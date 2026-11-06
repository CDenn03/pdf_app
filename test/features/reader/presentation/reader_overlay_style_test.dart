import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sefer/core/theme/reading_mode.dart';
import 'package:sefer/core/theme/system_ui.dart';
import 'package:sefer/features/reader/presentation/reader_overlay_style.dart';

void main() {
  group('readerOverlayStyle', () {
    SystemUiOverlayStyle styleFor(ReadingMode mode) => readerOverlayStyle(mode);

    test('dark reading mode asks for light icons', () {
      expect(styleFor(ReadingMode.dark), AppSystemUi.lightIcons);
    });

    test('light reading mode asks for dark icons', () {
      expect(styleFor(ReadingMode.light), AppSystemUi.darkIcons);
    });

    test('sepia reading mode asks for dark icons', () {
      expect(styleFor(ReadingMode.sepia), AppSystemUi.darkIcons);
    });
  });

  group('AnnotatedRegion wiring', () {
    Future<SystemUiOverlayStyle> resolvedStyle(
      WidgetTester tester,
      ReadingMode mode,
    ) async {
      await tester.pumpWidget(
        AnnotatedRegion<SystemUiOverlayStyle>(
          value: readerOverlayStyle(mode),
          child: const SizedBox.shrink(),
        ),
      );
      final region = tester.widget<AnnotatedRegion<SystemUiOverlayStyle>>(
        find.byType(AnnotatedRegion<SystemUiOverlayStyle>),
      );
      return region.value;
    }

    testWidgets('dark mode region carries light icons', (tester) async {
      expect(
        await resolvedStyle(tester, ReadingMode.dark),
        AppSystemUi.lightIcons,
      );
    });

    testWidgets('light and sepia regions carry dark icons', (tester) async {
      expect(
        await resolvedStyle(tester, ReadingMode.light),
        AppSystemUi.darkIcons,
      );
      expect(
        await resolvedStyle(tester, ReadingMode.sepia),
        AppSystemUi.darkIcons,
      );
    });
  });
}
