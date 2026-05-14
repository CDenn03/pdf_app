import 'package:flutter/material.dart';

/// Semantic color tokens for the app.
///
/// The document is the primary visual element — UI colors are deliberately
/// neutral and low-contrast so they never compete with PDF content.
/// Annotation colors are the only vivid layer.
abstract final class AppColors {
  // --- Light mode surfaces ---
  static const lightBackground = Color(0xFFF7F7F5); // soft paper tone
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightPrimaryText = Color(0xFF1C1C1C);
  static const lightSecondaryText = Color(0xFF6B6B6B);
  static const lightDivider = Color(0xFFE5E5E5);

  // --- Dark mode surfaces ---
  static const darkBackground = Color(0xFF121212);
  static const darkSurface = Color(0xFF1E1E1E);
  static const darkPrimaryText = Color(0xFFEAEAEA);
  static const darkSecondaryText = Color(0xFF9A9A9A);
  static const darkDivider = Color(0xFF2A2A2A);

  // --- Sepia mode ---
  static const sepiaBackground = Color(0xFFF4ECD8);
  static const sepiaSurface = Color(0xFFEDE0C4);
  static const sepiaPrimaryText = Color(0xFF5B4636);
  static const sepiaSecondaryText = Color(0xFF8A6F55);

  // --- Single accent (muted blue) ---
  /// Used only for active states, selection, and focus indicators.
  /// Never for large surfaces or decoration.
  static const accent = Color(0xFF4C6EF5);
  static const accentMuted = Color(0x144C6EF5);

  // --- Annotation colors (the only vivid layer) ---
  static const annotationYellow = Color(0xFFFFD43B);
  static const annotationGreen = Color(0xFF69DB7C);
  static const annotationBlue = Color(0xFF74C0FC);
  static const annotationPink = Color(0xFFF783AC);

  /// Semi-transparent overlays for rendered highlights.
  static const annotationYellowOverlay = Color(0x55FFD43B);
  static const annotationGreenOverlay = Color(0x5569DB7C);
  static const annotationBlueOverlay = Color(0x5574C0FC);
  static const annotationPinkOverlay = Color(0x55F783AC);

  /// Returns the overlay color for a given solid annotation color.
  static Color overlayFor(Color solid) {
    if (solid == annotationYellow) return annotationYellowOverlay;
    if (solid == annotationGreen) return annotationGreenOverlay;
    if (solid == annotationBlue) return annotationBlueOverlay;
    if (solid == annotationPink) return annotationPinkOverlay;
    return solid.withValues(alpha: 0.33);
  }
}
