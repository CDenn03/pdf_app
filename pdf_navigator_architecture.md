# PDF NAVIGATOR — AI ASSISTANT SYSTEM PROMPT
You are scaffolding a production Flutter application called pdf_navigator.
## Architecture Constraints (Non-Negotiable)
- Use Clean Architecture: core/, features/, shared/ separation.
- State management: flutter_riverpod ONLY. Do not introduce get_it or injectable.
- Use separate StateNotifiers for ReaderState and AnnotationState.
- Never merge reader and annotation state — this causes rebuild storms.
## Overlay Engine Requirements (Non-Negotiable)
- All annotation positions must use RelativeRectModel (0.0–1.0 range).
- Implement coordinate_mapper.dart with a pure toAbsolute(RelativeRectModel, Size) function.
- The Size passed to toAbsolute() must be the rendered PDF page size from
  PdfViewerController.getPageSize(), NOT the screen or viewport size.
- Render highlights with CustomPainter (HighlightPainter), never with Container widgets.
- Wrap the CustomPaint layer in IgnorePointer so gestures reach the PDF viewer.
- Only render annotations for currentPage ± 1 — never the full document set.
- Gesture handling must live in gesture_handler.dart:
    drag → highlight creation, tap → note anchor, long-press → context menu.
## Data Layer Requirements
- Annotation IDs must be UUIDs (package: uuid). Never use auto-increment integers.
- Use soft deletes only. Never hard-delete annotation rows.
- SQLite schema must include: CREATE INDEX idx_pdf_page ON annotations(pdf_id, page);
- All annotation writes must be debounced 300–500ms using Debounce in core/utils/debounce.dart.
- Annotation types are strictly separated: highlight (has rect), note (has rect + text),
  bookmark (no rect). Model with AnnotationType enum.
## File Handling Requirements
- Implement FileStatus enum: ok, missing, corrupt.
- checkFile(String path) in file_service.dart must return FileStatus without throwing.
- If FileStatus != ok, mark the library entry as unavailable — do not crash.
- Never delete annotations when a file goes missing.
## Dependencies (pubspec.yaml — exact versions)
syncfusion_flutter_pdfviewer: ^25.1.41
flutter_riverpod: ^2.5.1
go_router: ^14.2.0
sqflite: ^2.3.3
path_provider: ^2.1.3 | path: ^1.9.0
uuid: ^4.4.0 | collection: ^1.18.0
freezed_annotation: ^2.4.4 | json_annotation: ^4.9.0
## Output Format
When generating code:
  1. Emit complete file contents — no truncation, no ellipsis.
  2. Include all imports.
  3. Flag any assumption you make as a // ASSUMPTION: comment inline.
  4. If a requirement above conflicts with a Flutter/Dart API constraint,
     state the conflict explicitly before writing workaround code.