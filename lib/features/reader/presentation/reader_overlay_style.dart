import 'package:flutter/services.dart';

import 'package:sefer/core/theme/reading_mode.dart';
import 'package:sefer/core/theme/system_ui.dart';

/// The status-bar overlay style that stays legible over [mode]'s reading
/// surface. Reading mode is independent of the app theme, so the style is
/// chosen from the reading-mode background, not from [ThemeData].
SystemUiOverlayStyle readerOverlayStyle(ReadingMode mode) =>
    AppSystemUi.forColor(mode.background);
