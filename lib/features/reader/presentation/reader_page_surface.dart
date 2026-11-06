import 'package:flutter/widgets.dart';

import 'package:sefer/features/reader/presentation/reader_page_geometry.dart';

typedef ReaderPageLayerBuilder =
    Widget Function(BuildContext context, ReaderPageGeometry geometry);

/// Fits one PDF page into its cell once and hands the same rect to the page
/// raster and to every overlay layer, so they cannot drift apart.
class ReaderPageSurface extends StatelessWidget {
  const ReaderPageSurface({
    super.key,
    required this.pageNumber,
    required this.pageSize,
    required this.raster,
    required this.annotationLayer,
    this.searchLayer,
    this.selectionLayer,
    this.linkLayer,
  });

  final int pageNumber;
  final Size pageSize;
  final Widget raster;
  final ReaderPageLayerBuilder annotationLayer;
  final ReaderPageLayerBuilder? searchLayer;
  final ReaderPageLayerBuilder? selectionLayer;
  final ReaderPageLayerBuilder? linkLayer;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (pageSize.isEmpty || constraints.biggest.isEmpty) {
          return const SizedBox.shrink();
        }
        final geometry = ReaderPageGeometry.fitted(
          pageNumber: pageNumber,
          pageSize: pageSize,
          available: constraints.biggest,
        );
        return Stack(
          children: [
            Positioned.fromRect(rect: geometry.renderedRect, child: raster),
            for (final layer in [
              searchLayer,
              selectionLayer,
              linkLayer,
              annotationLayer,
            ])
              if (layer != null)
                Positioned.fromRect(
                  rect: geometry.renderedRect,
                  child: layer(context, geometry),
                ),
          ],
        );
      },
    );
  }
}
