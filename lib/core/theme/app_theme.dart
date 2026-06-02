import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Centralized theme configuration.
///
/// Fraunces (serif) is used for display/title headings; DM Sans for
/// all body and UI text. Together they pair the "indie-publisher" warmth
/// of Fraunces with the crisp legibility of DM Sans.
abstract final class AppTheme {
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
    final colorScheme = ColorScheme.fromSeed(
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
      surfaceContainerHighest: background,
    );

    // DM Sans for all UI text.
    final textTheme = GoogleFonts.dmSansTextTheme(
      TextTheme(
        bodyLarge: TextStyle(fontSize: 15, color: onSurface, height: 1.5),
        bodyMedium: TextStyle(fontSize: 14, color: onSurface, height: 1.5),
        bodySmall: TextStyle(fontSize: 12, color: secondary, height: 1.4),
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: onSurface,
        ),
        labelMedium: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: secondary,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: onSurface,
        ),
        titleSmall: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: onSurface,
        ),
        // Fraunces for display/heading styles.
        displayLarge: GoogleFonts.fraunces(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          color: onSurface,
          letterSpacing: -0.5,
        ),
        displayMedium: GoogleFonts.fraunces(
          fontSize: 26,
          fontWeight: FontWeight.w700,
          color: onSurface,
          letterSpacing: -0.3,
        ),
        headlineLarge: GoogleFonts.fraunces(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: onSurface,
          letterSpacing: -0.2,
        ),
        headlineMedium: GoogleFonts.fraunces(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: onSurface,
        ),
      ),
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
        titleTextStyle: GoogleFonts.dmSans(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: onSurface,
        ),
        iconTheme: IconThemeData(color: onSurface),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        indicatorColor: AppColors.brandTint,
        labelTextStyle: WidgetStateProperty.all(
          GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }
}
