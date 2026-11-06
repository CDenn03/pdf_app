import 'package:flutter/material.dart';

/// Sefer brand palette: Teal #0F9D8E, Forest #1B5E4B, Ivory #F7F8F4,
/// Slate #64746A.
///
/// Forest carries interactive colour because white text on Teal is only
/// 3.4:1, below WCAG AA for labels; Teal is the accent for fills and icons.
abstract final class AppColors {
  // ── Brand ────────────────────────────────────────────────────────────────
  /// Primary interactive colour: buttons, active nav, links, focus rings.
  static const brand = Color(0xFF1B5E4B); // Forest

  /// Accent: collection thumbnails, icon fills, progress bars.
  static const ground = Color(0xFF0F9D8E); // Teal

  /// Light tint of [brand] — chip fills, selection backgrounds.
  static const brandTint = Color(0xFFE3EFEA);

  /// Light tint of [ground] — secondary chip fills.
  static const groundTint = Color(0xFFE0F4F1);

  /// On-brand text (white on teal/forest buttons).
  static const onBrand = Color(0xFFFFFFFF);

  // ── Launch ────────────────────────────────────────────────────────────────
  // Keep in sync with flutter_native_splash colours in pubspec.yaml.
  static const splashLight = Color(0xFF1B5E4B);
  static const splashDark = Color(0xFF0F3D31);

  // ── Light mode surfaces ───────────────────────────────────────────────────
  static const lightBackground = Color(0xFFF7F8F4); // Ivory
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightPrimaryText = Color(0xFF1C2420);
  static const lightSecondaryText = Color(0xFF64746A); // Slate
  static const lightDivider = Color(0xFFE5E5E5);

  // ── Dark mode surfaces ────────────────────────────────────────────────────
  static const darkBackground = Color(0xFF121212);
  static const darkSurface = Color(0xFF1E1E1E);
  static const darkPrimaryText = Color(0xFFEAEAEA);
  static const darkSecondaryText = Color(0xFF9A9A9A);
  static const darkDivider = Color(0xFF2A2A2A);

  // ── Sepia mode ────────────────────────────────────────────────────────────
  static const sepiaBackground = Color(0xFFF4ECD8);
  static const sepiaSurface = Color(0xFFEDE0C4);
  static const sepiaPrimaryText = Color(0xFF5B4636);
  static const sepiaSecondaryText = Color(0xFF8A6F55);

  // ── Annotation colours (the only vivid layer) ─────────────────────────────
  static const annotationYellow = Color(0xFFFFD43B);
  static const annotationGreen = Color(0xFF69DB7C);
  static const annotationBlue = Color(0xFF74C0FC);
  static const annotationPink = Color(0xFFF783AC);

  static const annotationYellowOverlay = Color(0x55FFD43B);
  static const annotationGreenOverlay = Color(0x5569DB7C);
  static const annotationBlueOverlay = Color(0x5574C0FC);
  static const annotationPinkOverlay = Color(0x55F783AC);

  static Color overlayFor(Color solid) {
    if (solid == annotationYellow) return annotationYellowOverlay;
    if (solid == annotationGreen) return annotationGreenOverlay;
    if (solid == annotationBlue) return annotationBlueOverlay;
    if (solid == annotationPink) return annotationPinkOverlay;
    return solid.withValues(alpha: 0.33);
  }

  /// Favourites cover gradient — the one deliberately warm accent.
  static const List<Color> favoritesGradient = [
    Color(0xFF8B0000),
    Color(0xFFCC2936),
  ];

  // ── Collection cover gradients ────────────────────────────────────────────
  /// Gradient presets cycled for auto-coloured collection/file thumbnails.
  static const List<List<Color>> coverGradients = [
    [Color(0xFF1B5E4B), Color(0xFF0F3D31)], // forest
    [Color(0xFF0F9D8E), Color(0xFF0A6E63)], // teal
    [Color(0xFF2C7A6B), Color(0xFF1A5248)], // forest-teal
    [Color(0xFF64746A), Color(0xFF414D46)], // slate
    [Color(0xFF0A4D6B), Color(0xFF062E41)], // ocean
    [Color(0xFF5C4A2E), Color(0xFF3A2C18)], // earth
  ];

  static List<Color> coverGradientAt(int index) =>
      coverGradients[index % coverGradients.length];
}
