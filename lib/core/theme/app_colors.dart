import 'package:flutter/material.dart';

/// Brand colour tokens — Combo 2: Teal leads, Forest grounds.
///
/// Primary interactive colour is Midnight Teal (#0E6B72).
/// Forest Green (#1F5C38) appears in content surfaces (collection covers,
/// file icon fills, progress) so it's everywhere but never shouts.
/// Both are configurable here as the single source of truth.
abstract final class AppColors {
  // ── Brand ────────────────────────────────────────────────────────────────
  /// Primary interactive colour: buttons, active nav, links, focus rings.
  static const brand = Color(0xFF0E6B72); // Midnight Teal

  /// Ground accent: collection thumbnails, icon fills, progress bars.
  static const ground = Color(0xFF1F5C38); // Forest Green

  /// Light tint of [brand] — chip fills, selection backgrounds.
  static const brandTint = Color(0xFFE2F4F5);

  /// Light tint of [ground] — secondary chip fills.
  static const groundTint = Color(0xFFE8F5ED);

  /// On-brand text (white on teal/forest buttons).
  static const onBrand = Color(0xFFFFFFFF);

  // ── Light mode surfaces ───────────────────────────────────────────────────
  static const lightBackground = Color(0xFFF5F4F0);
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightPrimaryText = Color(0xFF1C1C1C);
  static const lightSecondaryText = Color(0xFF6B6B6B);
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

  // ── Collection cover gradients ────────────────────────────────────────────
  /// Gradient presets cycled for auto-coloured collection/file thumbnails.
  static const List<List<Color>> coverGradients = [
    [Color(0xFF0E6B72), Color(0xFF073D42)], // teal
    [Color(0xFF1F5C38), Color(0xFF0D3320)], // forest
    [Color(0xFF2C7A7B), Color(0xFF1A5252)], // teal-mid
    [Color(0xFF276749), Color(0xFF134429)], // forest-mid
    [Color(0xFF0A4D6B), Color(0xFF062E41)], // ocean
    [Color(0xFF5C4A2E), Color(0xFF3A2C18)], // earth
  ];

  static List<Color> coverGradientAt(int index) =>
      coverGradients[index % coverGradients.length];
}
