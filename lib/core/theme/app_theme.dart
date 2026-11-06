import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Centralized theme configuration.
///
/// Fraunces (serif) is used for display/title headings; DM Sans for
/// all body and UI text. Together they pair the "indie-publisher" warmth
/// of Fraunces with the crisp legibility of DM Sans.
abstract final class AppTheme {
  static const fontSerif = 'Fraunces';
  static const fontSans = 'DM Sans';

  static ThemeData get light => _build(
    brightness: Brightness.light,
    background: AppColors.lightBackground,
    surface: AppColors.lightSurface,
    onSurface: AppColors.lightPrimaryText,
    secondary: AppColors.lightSecondaryText,
    divider: AppColors.lightDivider,
  );

  static ThemeData get dark => _build(
    brightness: Brightness.dark,
    background: AppColors.darkBackground,
    surface: AppColors.darkSurface,
    onSurface: AppColors.darkPrimaryText,
    secondary: AppColors.darkSecondaryText,
    divider: AppColors.darkDivider,
  );

  static ThemeData _build({
    required Brightness brightness,
    required Color background,
    required Color surface,
    required Color onSurface,
    required Color secondary,
    required Color divider,
  }) {
    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: AppColors.brand,
          brightness: brightness,
          surface: surface,
        ).copyWith(
          primary: AppColors.brand,
          onPrimary: AppColors.onBrand,
          secondary: AppColors.ground,
          onSecondary: AppColors.onBrand,
          surface: surface,
          onSurface: onSurface,
          onSurfaceVariant: secondary,
          surfaceContainerHighest: background,
        );

    // Type scale: DM Sans body/UI in four steps (11 / 13 / 15 / 16),
    // Fraunces for display/headings. Both families are bundled assets;
    // Fraunces ships 600/700 with matching italics.
    final textTheme = TextTheme(
      bodyLarge: _sans(16, onSurface, height: 1.5),
      bodyMedium: _sans(15, onSurface, height: 1.5),
      bodySmall: _sans(13, secondary, height: 1.4),
      labelLarge: _sans(15, onSurface, weight: FontWeight.w500),
      labelMedium: _sans(13, secondary, weight: FontWeight.w500),
      labelSmall: _sans(
        11,
        secondary,
        weight: FontWeight.w500,
        letterSpacing: 0.8,
      ),
      titleMedium: _sans(16, onSurface, weight: FontWeight.w500),
      titleSmall: _sans(15, onSurface, weight: FontWeight.w500),
      displayLarge: _serif(32, onSurface, letterSpacing: -0.5),
      displayMedium: _serif(26, onSurface, letterSpacing: -0.3),
      headlineLarge: _serif(22, onSurface, letterSpacing: -0.2),
      headlineMedium: _serif(18, onSurface, weight: FontWeight.w600),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: textTheme,
      scaffoldBackgroundColor: background,
      dividerColor: divider,
      dividerTheme: DividerThemeData(color: divider, space: 1, thickness: 1),
      cardTheme: CardThemeData(
        elevation: 0,
        color: surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: divider),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        dragHandleColor: secondary.withValues(alpha: 0.4),
        dragHandleSize: const Size(40, 4),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: onSurface,
        contentTextStyle: TextStyle(color: surface, fontSize: 13),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size(44, 44),
          tapTargetSize: MaterialTapTargetSize.padded,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: _sans(16, onSurface, weight: FontWeight.w600),
        iconTheme: IconThemeData(color: onSurface),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        indicatorColor: AppColors.brandTint,
        labelTextStyle: WidgetStateProperty.all(
          _sans(12, onSurface, weight: FontWeight.w500),
        ),
      ),
    );
  }

  static TextStyle _sans(
    double size,
    Color color, {
    FontWeight? weight,
    double? height,
    double? letterSpacing,
  }) => TextStyle(
    fontFamily: fontSans,
    fontSize: size,
    color: color,
    fontWeight: weight,
    height: height,
    letterSpacing: letterSpacing,
  );

  static TextStyle _serif(
    double size,
    Color color, {
    FontWeight weight = FontWeight.w700,
    double? letterSpacing,
  }) => TextStyle(
    fontFamily: fontSerif,
    fontSize: size,
    color: color,
    fontWeight: weight,
    letterSpacing: letterSpacing,
  );
}
