import 'package:sefer/core/theme/reading_mode.dart';
import 'package:sefer/features/reader/domain/active_page_navigation.dart';
import 'package:sefer/features/reader/domain/active_search_backend.dart';
import 'package:sefer/features/reader/presentation/annotation_toolbar.dart';
import 'package:sefer/features/reader/presentation/reader_viewport_config.dart';
import 'fake_search_highlights.dart';
import 'recording_external_link_opener.dart';
import 'recording_text_sharer.dart';

class ReaderViewportFixture {
  final ActivePageNavigation navigation = ActivePageNavigation();
  final ActiveSearchBackend searchBackend = ActiveSearchBackend();
  final RecordingExternalLinkOpener linkOpener = RecordingExternalLinkOpener();
  final RecordingTextSharer textSharer = RecordingTextSharer();
  final FakeSearchHighlights highlights = FakeSearchHighlights();
  final List<int?> reportedPages = [];
  int generalTapCount = 0;

  ReaderViewportConfig config({
    int initialPage = 1,
    bool annotating = false,
    AnnotationTool activeTool = AnnotationTool.highlight,
  }) => ReaderViewportConfig(
    pdfPath: 'assets/sample.pdf',
    isAsset: true,
    readingMode: ReadingMode.values.first,
    annotating: annotating,
    activeTool: activeTool,
    sfDocument: null,
    initialPage: initialPage,
    highlights: highlights,
    navigation: navigation,
    searchBackend: searchBackend,
    linkOpener: linkOpener,
    textSharer: textSharer,
    onViewerReady: (_) async {},
    onPageChanged: reportedPages.add,
    onGeneralTap: () => generalTapCount++,
    onAddBookmark: () async {},
  );
}
