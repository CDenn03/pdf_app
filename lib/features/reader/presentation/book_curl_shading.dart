import 'dart:math' as math;
import 'dart:typed_data';

import 'package:sefer/features/reader/presentation/book_curl_frame.dart';

/// Per-vertex brightness of a curled sheet as packed ARGB, meant to modulate
/// the page texture so a flat sheet keeps its colours exactly.
abstract final class BookCurlShading {
  static const _ambient = 0.62;
  static const _lightX = -0.35;
  static const _lightY = -0.35;
  static const _paperTone = (0.93, 0.93, 0.94);

  static final double _lightZ = math.sqrt(
    1 - _lightX * _lightX - _lightY * _lightY,
  );
  static final double _flatLevel = _ambient + (1 - _ambient) * _lightZ;

  /// Light facing surfaces clamp to full brightness, which reads as the
  /// highlight along the fold; surfaces turned away darken.
  static Int32List front(List<BookCurlVertex> vertices) {
    final colors = Int32List(vertices.length);
    for (var i = 0; i < colors.length; i++) {
      colors[i] = _pack(_lambert(vertices[i].normal), 1, 1, 1);
    }
    return colors;
  }

  /// The reverse side is a neutral gray, lit from the other face.
  static Int32List back(List<BookCurlVertex> vertices, BookCurlStyle style) {
    final colors = Int32List(vertices.length);
    for (var i = 0; i < colors.length; i++) {
      final lit = _lambert(vertices[i].normal.reversed);
      final level = style.backBase + style.backHighlight * (lit - 0.5);
      colors[i] = _pack(level, _paperTone.$1, _paperTone.$2, _paperTone.$3);
    }
    return colors;
  }

  static double _lambert(BookCurlNormal normal) {
    final facing = math.max(
      0.0,
      normal.x * _lightX + normal.y * _lightY + normal.z * _lightZ,
    );
    return (_ambient + (1 - _ambient) * facing) / _flatLevel;
  }

  static int _pack(double level, double red, double green, double blue) {
    int channel(double tone) => ((level * tone).clamp(0.0, 1.0) * 255).round();
    return 0xFF000000 |
        channel(red) << 16 |
        channel(green) << 8 |
        channel(blue);
  }
}
