import 'package:flutter/material.dart';

import 'app_colors.dart';

/// The three reading surface modes.
enum ReadingMode { light, dark, sepia }

extension ReadingModeX on ReadingMode {
  String get label => switch (this) {
    ReadingMode.light => 'Light',
    ReadingMode.dark => 'Dark',
    ReadingMode.sepia => 'Sepia',
  };

  /// Background color for the PDF viewport surface.
  Color get background => switch (this) {
    ReadingMode.light => AppColors.lightBackground,
    ReadingMode.dark => AppColors.darkBackground,
    ReadingMode.sepia => AppColors.sepiaBackground,
  };

  /// Control layer surface color (top/bottom bars when visible).
  Color get controlSurface => switch (this) {
    ReadingMode.light => AppColors.lightSurface,
    ReadingMode.dark => AppColors.darkSurface,
    ReadingMode.sepia => AppColors.sepiaSurface,
  };

  /// Primary text color for control layer labels.
  Color get primaryText => switch (this) {
    ReadingMode.light => AppColors.lightPrimaryText,
    ReadingMode.dark => AppColors.darkPrimaryText,
    ReadingMode.sepia => AppColors.sepiaPrimaryText,
  };

  /// Secondary text color for captions and hints.
  Color get secondaryText => switch (this) {
    ReadingMode.light => AppColors.lightSecondaryText,
    ReadingMode.dark => AppColors.darkSecondaryText,
    ReadingMode.sepia => AppColors.sepiaSecondaryText,
  };

  /// Subtle tint applied to the viewport when annotation mode is active.
  Color get annotationModeTint => switch (this) {
    ReadingMode.light => const Color(0x0AFFD43B),
    ReadingMode.dark => const Color(0x0AFFD43B),
    ReadingMode.sepia => const Color(0x0AFFD43B),
  };

  /// Search match highlight color, pre-compensated for the reading mode's
  /// color filter so the highlight is always visible after the filter is
  /// applied.
  ///
  /// Dark mode inverts colors (R' = 255 - R), so we invert the target yellow
  /// (0xFFFFE066, alpha 0x80) → blue (0xFF001F99, alpha 0x80).
  /// Sepia mode desaturates toward warm tones, so we use a vivid cyan that
  /// survives the matrix and reads as a visible teal highlight.
  /// Light mode needs no compensation.
  Color get searchMatchColor => switch (this) {
    ReadingMode.light => const Color(0x80FFE066),
    ReadingMode.dark => const Color(0x80001F99),
    ReadingMode.sepia => const Color(0x8000CFCF),
  };

  /// Active (current) search match highlight color, pre-compensated for the
  /// reading mode's color filter.
  ///
  /// Target is a vivid orange (0xFFFF8C00, alpha 0x99) in light mode.
  /// Dark inversion: 0xFF007FFF (blue-orange complement).
  /// Sepia: vivid magenta survives the warm desaturation matrix.
  Color get searchActiveMatchColor => switch (this) {
    ReadingMode.light => const Color(0x99FF8C00),
    ReadingMode.dark => const Color(0x99007FFF),
    ReadingMode.sepia => const Color(0x99CC00CC),
  };
}
