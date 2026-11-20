import 'package:sefer/core/models/annotation.dart';

/// One annotation that matched a global search, with the text to display.
class AnnotationSearchRow {
  const AnnotationSearchRow({required this.annotation, required this.snippet});

  final Annotation annotation;
  final String snippet;
}

/// Builds a SQL `LIKE` pattern that treats `%`, `_`, and `\` as literals.
String likeQueryPattern(String query) {
  final escaped = query
      .replaceAll(r'\', r'\\')
      .replaceAll('%', r'\%')
      .replaceAll('_', r'\_');
  return '%$escaped%';
}

/// Picks the first field that contains [query], case-insensitively.
String snippetForAnnotation(
  Annotation annotation,
  String query, {
  String? noteText,
}) {
  final q = query.toLowerCase();
  bool matches(String? value) =>
      value != null && value.toLowerCase().contains(q);
  if (matches(annotation.selectedText)) return annotation.selectedText!;
  if (matches(annotation.text)) return annotation.text!;
  if (matches(annotation.label)) return annotation.label!;
  if (matches(noteText)) return noteText!;
  return annotation.selectedText ??
      annotation.text ??
      annotation.label ??
      noteText ??
      '';
}

/// Collapses whitespace and truncates a snippet for a result row.
String compactSnippet(String text, {int maxChars = 160}) {
  final compact = text.replaceAll(RegExp(r'\s+'), ' ').trim();
  if (compact.length <= maxChars) return compact;
  return '${compact.substring(0, maxChars).trimRight()}…';
}
