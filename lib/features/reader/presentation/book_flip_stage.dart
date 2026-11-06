import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

import 'package:sefer/features/reader/domain/book_flip_machine.dart';
import 'package:sefer/features/reader/presentation/book_curl_frame.dart';
import 'package:sefer/features/reader/presentation/book_curl_geometry.dart';
import 'package:sefer/features/reader/presentation/book_flip_interaction.dart';
import 'package:sefer/features/reader/presentation/book_page_curl_painter.dart';
import 'package:sefer/features/reader/presentation/book_page_shadow_painter.dart';

/// A page turn in progress. [image] is the resting page the curl is drawn
/// from; without it the live page is rotated instead.
@immutable
class BookFlipTurnView {
  const BookFlipTurnView({
    required this.direction,
    required this.textDirection,
    required this.pose,
    required this.image,
  });

  final BookFlipDirection direction;
  final TextDirection textDirection;
  final BookFlipPose pose;
  final ui.Image? image;

  int adjacentFrom(int pageNumber) => pageNumber + direction.pageDelta;

  BookCurlEdge get edge => bookFlipFreeEdgeIsRight(direction, textDirection)
      ? BookCurlEdge.right
      : BookCurlEdge.left;
}

typedef BookFlipPageBuilder =
    Widget Function(BuildContext context, int pageNumber);

/// Lays out the resting page, or the current page curling away from the
/// adjacent one that lies beneath it. Pages keep their widget identity
/// across a completed turn, so the revealed page does not reload.
class BookFlipStage extends StatelessWidget {
  const BookFlipStage({
    super.key,
    required this.currentPage,
    required this.pageRect,
    required this.pageBuilder,
    required this.contentOpacity,
    required this.edgeStretch,
    this.turn,
  });

  final int currentPage;
  final Rect pageRect;
  final BookFlipPageBuilder pageBuilder;
  final double contentOpacity;
  final double edgeStretch;
  final BookFlipTurnView? turn;

  @override
  Widget build(BuildContext context) {
    final turn = this.turn;
    final image = turn?.image;
    return Opacity(
      opacity: contentOpacity,
      child: Transform.translate(
        offset: Offset(edgeStretch, 0),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (turn != null)
              _StagePage(
                key: ValueKey(turn.adjacentFrom(currentPage)),
                interactive: false,
                child: pageBuilder(context, turn.adjacentFrom(currentPage)),
              ),
            _StagePage(
              key: ValueKey(currentPage),
              interactive: turn == null,
              visible: image == null || turn == null,
              rotation: image == null ? turn : null,
              child: pageBuilder(context, currentPage),
            ),
            if (turn != null && image != null)
              _CurlLayer(pageRect: pageRect, turn: turn, image: image),
          ],
        ),
      ),
    );
  }
}

class _CurlLayer extends StatelessWidget {
  const _CurlLayer({
    required this.pageRect,
    required this.turn,
    required this.image,
  });

  final Rect pageRect;
  final BookFlipTurnView turn;
  final ui.Image image;

  @override
  Widget build(BuildContext context) {
    final frame = BookCurlGeometry.build(
      size: pageRect.size,
      edge: turn.edge,
      pose: turn.pose,
    );
    return Positioned.fromRect(
      rect: pageRect,
      child: CustomPaint(
        painter: BookPageShadowPainter(shadow: frame.shadow),
        foregroundPainter: BookPageCurlPainter(image: image, frame: frame),
      ),
    );
  }
}

class _StagePage extends StatelessWidget {
  const _StagePage({
    super.key,
    required this.interactive,
    required this.child,
    this.visible = true,
    this.rotation,
  });

  final bool interactive;
  final bool visible;
  final BookFlipTurnView? rotation;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final rotation = this.rotation;
    final hingeOnLeft = rotation?.edge == BookCurlEdge.right;
    final angle = (rotation?.pose.turnFraction ?? 0) * math.pi / 2;
    final grabHeight = rotation?.pose.start.dy ?? 0.5;
    return IgnorePointer(
      ignoring: !interactive,
      child: Opacity(
        opacity: visible ? 1 : 0,
        child: Transform(
          alignment: Alignment(
            hingeOnLeft ? -1 : 1,
            (grabHeight * 2 - 1).clamp(-1.0, 1.0),
          ),
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..rotateY(hingeOnLeft ? -angle : angle),
          child: child,
        ),
      ),
    );
  }
}
