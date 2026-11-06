import 'package:flutter/widgets.dart';

/// Spacing scale on a 4px base (8px rhythm with half-steps).
abstract final class AppSpacing {
  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;

  static const EdgeInsets pageHorizontal = EdgeInsets.symmetric(horizontal: xl);
}

/// Corner-radius scale.
abstract final class AppRadius {
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;

  /// Pill / fully rounded controls (nav bar, action bar).
  static const double pill = 28;

  static const Radius smR = Radius.circular(sm);
  static const Radius mdR = Radius.circular(md);
  static const Radius lgR = Radius.circular(lg);
}
