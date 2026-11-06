import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sefer/core/theme/app_colors.dart';
import 'package:sefer/core/theme/system_ui.dart';

void main() {
  group('AppSystemUi', () {
    test('a dark background asks for light icons', () {
      expect(
        AppSystemUi.forBackground(Brightness.dark),
        AppSystemUi.lightIcons,
      );
    });

    test('a light background asks for dark icons', () {
      expect(
        AppSystemUi.forBackground(Brightness.light),
        AppSystemUi.darkIcons,
      );
    });

    test('Android icon brightness is the inverse of the iOS field', () {
      expect(AppSystemUi.lightIcons.statusBarIconBrightness, Brightness.light);
      expect(AppSystemUi.lightIcons.statusBarBrightness, Brightness.dark);
      expect(AppSystemUi.darkIcons.statusBarIconBrightness, Brightness.dark);
      expect(AppSystemUi.darkIcons.statusBarBrightness, Brightness.light);
    });

    test('both styles leave the status bar transparent', () {
      expect(AppSystemUi.lightIcons.statusBarColor, Colors.transparent);
      expect(AppSystemUi.darkIcons.statusBarColor, Colors.transparent);
    });

    test('forColor picks light icons over the dark app background', () {
      expect(
        AppSystemUi.forColor(AppColors.darkBackground),
        AppSystemUi.lightIcons,
      );
    });

    test('forColor picks dark icons over the light app background', () {
      expect(
        AppSystemUi.forColor(AppColors.lightBackground),
        AppSystemUi.darkIcons,
      );
    });

    test('forColor picks dark icons over the sepia reading surface', () {
      expect(
        AppSystemUi.forColor(AppColors.sepiaBackground),
        AppSystemUi.darkIcons,
      );
    });
  });
}
