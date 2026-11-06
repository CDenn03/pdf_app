import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sefer/core/theme/app_colors.dart';

double _relativeLuminance(Color c) {
  double channel(double s) =>
      s <= 0.03928 ? s / 12.92 : math.pow((s + 0.055) / 1.055, 2.4).toDouble();
  final r = channel((c.r * 255.0).round() / 255.0);
  final g = channel((c.g * 255.0).round() / 255.0);
  final b = channel((c.b * 255.0).round() / 255.0);
  return 0.2126 * r + 0.7152 * g + 0.0722 * b;
}

double contrastRatio(Color fg, Color bg) {
  final l1 = _relativeLuminance(fg);
  final l2 = _relativeLuminance(bg);
  final lighter = math.max(l1, l2);
  final darker = math.min(l1, l2);
  return (lighter + 0.05) / (darker + 0.05);
}

void main() {
  const wcagAaNormalText = 4.5;

  group('text/background contrast meets WCAG AA', () {
    void expectAa(String label, Color fg, Color bg) {
      final ratio = contrastRatio(fg, bg);
      expect(
        ratio,
        greaterThanOrEqualTo(wcagAaNormalText),
        reason: '$label is ${ratio.toStringAsFixed(2)}:1, below AA 4.5:1',
      );
    }

    test('light secondary text', () {
      expectAa(
        'light secondary on background',
        AppColors.lightSecondaryText,
        AppColors.lightBackground,
      );
      expectAa(
        'light secondary on surface',
        AppColors.lightSecondaryText,
        AppColors.lightSurface,
      );
    });

    test('light primary text', () {
      expectAa(
        'light primary on background',
        AppColors.lightPrimaryText,
        AppColors.lightBackground,
      );
      expectAa(
        'light primary on surface',
        AppColors.lightPrimaryText,
        AppColors.lightSurface,
      );
    });

    test('dark secondary text', () {
      expectAa(
        'dark secondary on background',
        AppColors.darkSecondaryText,
        AppColors.darkBackground,
      );
      expectAa(
        'dark secondary on surface',
        AppColors.darkSecondaryText,
        AppColors.darkSurface,
      );
    });

    test('dark primary text', () {
      expectAa(
        'dark primary on background',
        AppColors.darkPrimaryText,
        AppColors.darkBackground,
      );
      expectAa(
        'dark primary on surface',
        AppColors.darkPrimaryText,
        AppColors.darkSurface,
      );
    });
  });
}
