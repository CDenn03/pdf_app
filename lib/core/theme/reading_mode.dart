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
}
