import 'package:sefer/features/reader/domain/search_excerpt.dart';

final _whitespaceRun = RegExp(r'\s+');
final _hyphenatedLineBreak = RegExp(
  r'(\p{L})-[ \t]*\r?\n\s*(?=\p{L})',
  unicode: true,
);

SearchExcerpt excerptAround(
  String pageText,
  int start,
  int end, {
  int maxContext = 90,
}) {
  final matchStart = start.clamp(0, pageText.length);
  final matchEnd = end.clamp(matchStart, pageText.length);

  var from = _sentenceStart(pageText, matchStart);
  var to = _sentenceEnd(pageText, matchEnd);
  final leading = matchStart - from > maxContext;
  final trailing = to - matchEnd > maxContext;
  if (leading) {
    from = _wordAligned(pageText, matchStart - maxContext, matchStart);
  }
  if (trailing) to = _wordAligned(pageText, matchEnd + maxContext, matchEnd);

  return SearchExcerpt(
    before: _normalize(pageText.substring(from, matchStart)).trimLeft(),
    match: _normalize(pageText.substring(matchStart, matchEnd)),
    after: _normalize(pageText.substring(matchEnd, to)).trimRight(),
    hasLeadingEllipsis: leading,
    hasTrailingEllipsis: trailing,
  );
}

String _normalize(String text) => text
    .replaceAllMapped(_hyphenatedLineBreak, (m) => m[1]!)
    .replaceAll(_whitespaceRun, ' ');

bool _isWhitespace(String text, int index) =>
    text.codeUnitAt(index) <= 0x20 || text[index].trim().isEmpty;

bool _endsSentence(String text, int index) {
  final char = text[index];
  if (char == '\u3002' || char == '\uFF01' || char == '\uFF1F') return true;
  if (char != '.' && char != '!' && char != '?') return false;
  return index + 1 >= text.length || _isWhitespace(text, index + 1);
}

bool _isParagraphBreak(String text, int index) =>
    text[index] == '\n' && index > 0 && text[index - 1] == '\n';

int _sentenceStart(String text, int matchStart) {
  for (var i = matchStart - 1; i >= 0; i--) {
    if (_isParagraphBreak(text, i)) return i + 1;
    if (_endsSentence(text, i)) return i + 1;
  }
  return 0;
}

int _sentenceEnd(String text, int matchEnd) {
  for (var i = matchEnd; i < text.length; i++) {
    if (_endsSentence(text, i)) return i + 1;
    if (_isParagraphBreak(text, i)) return i - 1;
  }
  return text.length;
}

/// Moves [cut] toward [anchor] to the nearest whitespace so words are not
/// split; text without whitespace (e.g. CJK) is cut exactly at [cut].
int _wordAligned(String text, int cut, int anchor) {
  final step = anchor > cut ? 1 : -1;
  for (var i = cut; i != anchor; i += step) {
    if (_isWhitespace(text, i)) return step > 0 ? i + 1 : i;
  }
  return cut;
}
