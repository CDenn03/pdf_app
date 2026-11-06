import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

import 'package:sefer/features/reader/presentation/book_curl_frame.dart';

/// The shadow a lifting page casts on the page beneath it, darkest at the
/// fold and fading toward where it lands.
class BookPageShadowPainter extends CustomPainter {
  const BookPageShadowPainter({required this.shadow});

  final BookCurlShadow shadow;

  @override
  void paint(Canvas canvas, Size size) {
    if (shadow.opacity <= 0 || shadow.footprint.length < 3) return;
    final opacity = shadow.opacity.clamp(0.0, 1.0);
    final paint = Paint()
      ..shader = ui.Gradient.linear(shadow.foldPoint, shadow.castPoint, [
        Color.fromRGBO(0, 0, 0, opacity),
        const Color(0x00000000),
      ])
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, shadow.blurSigma);
    canvas
      ..save()
      ..clipRect(Offset.zero & size)
      ..drawPath(Path()..addPolygon(shadow.footprint, true), paint)
      ..restore();
  }

  @override
  bool shouldRepaint(BookPageShadowPainter oldDelegate) =>
      !identical(oldDelegate.shadow, shadow);
}
