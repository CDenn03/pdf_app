import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/widgets.dart';

import 'package:sefer/features/reader/domain/external_link_opener.dart';
import 'package:sefer/features/reader/domain/reader_page_link.dart';
import 'package:sefer/features/reader/domain/reader_page_navigation.dart';
import 'package:sefer/features/reader/presentation/reader_page_geometry.dart';

/// Tap targets for a page's links, placed over [geometry]'s rendered rect.
class PageLinkLayer extends StatefulWidget {
  const PageLinkLayer({
    super.key,
    required this.geometry,
    required this.source,
    required this.navigation,
    required this.linkOpener,
  });

  final ReaderPageGeometry geometry;
  final ReaderPageLinkSource source;
  final ReaderPageNavigation navigation;
  final ExternalLinkOpener linkOpener;

  @override
  State<PageLinkLayer> createState() => _PageLinkLayerState();
}

class _PageLinkLayerState extends State<PageLinkLayer> {
  List<ReaderPageLink> _links = const [];

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    final pageNumber = widget.geometry.pageNumber;
    try {
      final links = await widget.source.linksOn(pageNumber);
      if (mounted) setState(() => _links = links);
    } catch (error, stack) {
      developer.log(
        'Loading links on page $pageNumber failed',
        name: 'sefer.reader',
        level: 1000,
        error: error,
        stackTrace: stack,
      );
    }
  }

  void _follow(ReaderLinkTarget target) => switch (target) {
    PageLinkTarget(:final pageNumber) => unawaited(
      widget.navigation.goToPage(pageNumber),
    ),
    UriLinkTarget(:final uri) => unawaited(widget.linkOpener.open(uri)),
  };

  String _labelOf(ReaderLinkTarget target) => switch (target) {
    PageLinkTarget(:final pageNumber) => 'Go to page $pageNumber',
    UriLinkTarget(:final uri) =>
      'Open link ${uri.host.isEmpty ? uri.path : uri.host}',
  };

  @override
  Widget build(BuildContext context) {
    final size = widget.geometry.renderedRect.size;
    return Stack(
      children: [
        for (final link in _links)
          for (final bounds in link.normalizedBounds)
            Positioned.fromRect(
              rect: Rect.fromLTRB(
                bounds.left * size.width,
                bounds.top * size.height,
                bounds.right * size.width,
                bounds.bottom * size.height,
              ),
              child: Semantics(
                link: true,
                label: _labelOf(link.target),
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: () => _follow(link.target),
                ),
              ),
            ),
      ],
    );
  }
}
