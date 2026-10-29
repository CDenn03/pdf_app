import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// System bar overlay styles that keep the status bar clock, battery and
/// signal icons legible whatever is drawn behind them.
///
/// Flutter derives an overlay style automatically only from an [AppBar].
/// Surfaces built without one (the home shell, the reader with its bars
/// hidden) must declare their own, or the bars keep whatever the Android
/// launch theme left behind.
abstract final class AppSystemUi {
  /// For a light background: dark glyphs.
  ///
  /// Android reads [SystemUiOverlayStyle.statusBarIconBrightness] as the
  /// brightness of the icons themselves, iOS reads
  /// [SystemUiOverlayStyle.statusBarBrightness] as the brightness of the
  /// background behind them, so the two are always opposites.
  static const SystemUiOverlayStyle darkIcons = SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    statusBarBrightness: Brightness.light,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarIconBrightness: Brightness.dark,
    systemNavigationBarContrastEnforced: false,
  );

  /// For a dark background: light glyphs.
  static const SystemUiOverlayStyle lightIcons = SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    statusBarBrightness: Brightness.dark,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarIconBrightness: Brightness.light,
    systemNavigationBarContrastEnforced: false,
  );

  /// The style that stays readable over a surface of [background].
  static SystemUiOverlayStyle forBackground(Brightness background) =>
      background == Brightness.dark ? lightIcons : darkIcons;

  /// The style that stays readable over [color], judged by its luminance.
  static SystemUiOverlayStyle forColor(Color color) =>
      forBackground(ThemeData.estimateBrightnessForColor(color));
}
