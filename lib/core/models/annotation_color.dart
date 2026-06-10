import 'package:flutter/material.dart';

import 'package:sefer/core/theme/app_colors.dart';

/// The four annotation highlight colors.
enum AnnotationColor { yellow, green, blue, pink }

extension AnnotationColorX on AnnotationColor {
  /// The solid color swatch for UI pickers.
  Color get solid => switch (this) {
    AnnotationColor.yellow => AppColors.annotationYellow,
    AnnotationColor.green => AppColors.annotationGreen,
    AnnotationColor.blue => AppColors.annotationBlue,
    AnnotationColor.pink => AppColors.annotationPink,
  };

  /// The semi-transparent overlay rendered on the PDF.
  Color get overlay => switch (this) {
    AnnotationColor.yellow => AppColors.annotationYellowOverlay,
    AnnotationColor.green => AppColors.annotationGreenOverlay,
    AnnotationColor.blue => AppColors.annotationBlueOverlay,
    AnnotationColor.pink => AppColors.annotationPinkOverlay,
  };
}
