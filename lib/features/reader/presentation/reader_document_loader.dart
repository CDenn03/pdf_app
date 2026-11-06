import 'package:flutter/widgets.dart';
import 'package:pdfrx/pdfrx.dart';

import 'package:sefer/features/reader/data/reader_document_session.dart';
import 'package:sefer/features/reader/presentation/paged_document_status.dart';

typedef ReaderDocumentWidgetBuilder =
    Widget Function(
      BuildContext context,
      PdfDocument document,
      ReaderDocumentSession session,
    );

class ReaderDocumentLoader extends StatefulWidget {
  const ReaderDocumentLoader({
    super.key,
    required this.pdfPath,
    required this.isAsset,
    required this.builder,
  });

  final String pdfPath;
  final bool isAsset;
  final ReaderDocumentWidgetBuilder builder;

  @override
  State<ReaderDocumentLoader> createState() => _ReaderDocumentLoaderState();
}

class _ReaderDocumentLoaderState extends State<ReaderDocumentLoader> {
  late PdfDocumentRef _documentRef;
  ReaderDocumentSession? _session;

  @override
  void initState() {
    super.initState();
    _documentRef = _refFor(widget);
  }

  @override
  void didUpdateWidget(ReaderDocumentLoader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pdfPath != widget.pdfPath ||
        oldWidget.isAsset != widget.isAsset) {
      _documentRef = _refFor(widget);
    }
  }

  // pdfrx compares refs by identity: a new ref per build disposes and
  // reloads the document, which remounts the pager in a loop.
  static PdfDocumentRef _refFor(ReaderDocumentLoader widget) => widget.isAsset
      ? PdfDocumentRefAsset(widget.pdfPath)
      : PdfDocumentRefFile(widget.pdfPath);

  ReaderDocumentSession _sessionFor(PdfDocument document) {
    final current = _session;
    if (current != null && identical(current.document, document)) {
      return current;
    }
    return _session = ReaderDocumentSession(document: document);
  }

  Widget _loaded(BuildContext context, PdfDocument? document) {
    if (document == null) return const PagedDocumentLoading();
    if (document.pages.isEmpty) {
      return PagedDocumentError(
        path: widget.pdfPath,
        error: StateError('Document has no pages'),
      );
    }
    return widget.builder(context, document, _sessionFor(document));
  }

  @override
  Widget build(BuildContext context) => PdfDocumentViewBuilder(
    documentRef: _documentRef,
    builder: _loaded,
    loadingBuilder: (context) => const PagedDocumentLoading(),
    errorBuilder: (context, error, stack) => PagedDocumentError(
      path: widget.pdfPath,
      error: error,
      stackTrace: stack,
    ),
  );
}
