import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

import 'package:sefer/features/reader/presentation/book_curl_frame.dart';
import 'package:sefer/features/reader/presentation/book_curl_shading.dart';

/// Draws [image], the resting page, as the sheet described by [frame].
class BookPageCurlPainter extends CustomPainter {
  const BookPageCurlPainter({
    required this.image,
    required this.frame,
    this.style = const BookCurlStyle(),
  });

  final ui.Image image;
  final BookCurlFrame frame;
  final BookCurlStyle style;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final shader = ImageShader(
      image,
      TileMode.clamp,
      TileMode.clamp,
      Matrix4.identity().storage,
    );
    final paint = Paint()
      ..shader = shader
      ..filterQuality = FilterQuality.medium;
    final positions = Float32List(frame.vertices.length * 2);
    final textureCoordinates = Float32List(frame.vertices.length * 2);
    _fillCoordinates(size, positions, textureCoordinates);
    _draw(
      canvas,
      paint,
      positions,
      textureCoordinates,
      frame.frontIndices,
      BookCurlShading.front(frame.vertices),
    );
    _draw(
      canvas,
      paint,
      positions,
      textureCoordinates,
      frame.backIndices,
      BookCurlShading.back(frame.vertices, style),
    );
    shader.dispose();
  }

  void _fillCoordinates(
    Size size,
    Float32List positions,
    Float32List textureCoordinates,
  ) {
    final scaleX = image.width / size.width;
    final scaleY = image.height / size.height;
    for (var i = 0; i < frame.vertices.length; i++) {
      final vertex = frame.vertices[i];
      positions[i * 2] = vertex.position.dx;
      positions[i * 2 + 1] = vertex.position.dy;
      textureCoordinates[i * 2] = vertex.texturePosition.dx * scaleX;
      textureCoordinates[i * 2 + 1] = vertex.texturePosition.dy * scaleY;
    }
  }

  void _draw(
    Canvas canvas,
    Paint paint,
    Float32List positions,
    Float32List textureCoordinates,
    Uint16List indices,
    Int32List colors,
  ) {
    if (indices.isEmpty) return;
    final vertices = ui.Vertices.raw(
      ui.VertexMode.triangles,
      positions,
      textureCoordinates: textureCoordinates,
      colors: colors,
      indices: indices,
    );
    canvas.drawVertices(vertices, BlendMode.modulate, paint);
    vertices.dispose();
  }

  @override
  bool shouldRepaint(BookPageCurlPainter oldDelegate) =>
      !identical(oldDelegate.image, image) ||
      !identical(oldDelegate.frame, frame) ||
      oldDelegate.style != style;
}
