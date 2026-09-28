import 'dart:math' as math;
import 'dart:ui';

enum DictationLang { chinese, english }

class DictationPiece {
  const DictationPiece(this.text, this.rect);

  final String text;
  final Rect rect;
}

class DictationWord {
  const DictationWord({
    required this.id,
    required this.text,
    required this.rect,
    this.selected = true,
  });

  final String id;
  final String text;
  final Rect rect;
  final bool selected;

  DictationWord copyWith({bool? selected}) {
    return DictationWord(
      id: id,
      text: text,
      rect: rect,
      selected: selected ?? this.selected,
    );
  }
}

/// ASCII whitespace plus the spaces OCR often emits for a printed gap,
/// including the full-width space used between Chinese words.
final _splitter = RegExp(
  r'[\s\u00A0\u1680\u2000-\u200A\u202F\u205F\u3000\uFEFF,，、;；。.!！?？:：/／|]+',
);
final _cjk = RegExp(r'[\u4e00-\u9fff]');
final _latin = RegExp(r'[A-Za-z]');

bool keepToken(String text, DictationLang lang) {
  final value = text.trim();
  if (value.isEmpty) return false;
  if (lang == DictationLang.chinese) return _cjk.hasMatch(value);
  return _latin.hasMatch(value);
}

bool prefersChineseVoice(String text) => _cjk.hasMatch(text);

List<DictationPiece> splitLine(String raw, Rect rect) {
  final parts = raw
      .split(_splitter)
      .map((part) => part.trim())
      .where((part) => part.isNotEmpty)
      .toList();
  if (parts.isEmpty || rect.width <= 0 || rect.height <= 0) return const [];
  if (parts.length == 1) return [DictationPiece(parts.first, rect)];
  final total = parts.fold<int>(0, (sum, part) => sum + part.length);
  if (total <= 0) return const [];
  var x = rect.left;
  final pieces = <DictationPiece>[];
  for (final part in parts) {
    final width = rect.width * (part.length / total);
    pieces.add(DictationPiece(part, Rect.fromLTWH(x, rect.top, width, rect.height)));
    x += width;
  }
  return pieces;
}

/// Splits one recognized token where [gapFractions] mark word spaces along
/// [rect]. Fractions are 0–1 from the left. A sentence with no gaps stays whole.
List<DictationPiece> splitByGaps(String text, Rect rect, List<double> gapFractions) {
  final token = text.trim();
  if (token.length < 2 || rect.width <= 0 || rect.height <= 0) {
    return token.isEmpty ? const [] : [DictationPiece(token, rect)];
  }
  final cuts = gapFractions.where((gap) => gap > 0.04 && gap < 0.96).toList()..sort();
  while (cuts.length >= token.length && cuts.isNotEmpty) {
    cuts.removeLast();
  }
  if (cuts.isEmpty) return [DictationPiece(token, rect)];
  final bounds = [0.0, ...cuts, 1.0];
  final pieces = <DictationPiece>[];
  var startChar = 0;
  for (var i = 0; i < bounds.length - 1; i++) {
    final isLast = i == bounds.length - 2;
    final remainingSegments = bounds.length - 2 - i;
    final endChar = isLast
        ? token.length
        : (bounds[i + 1] * token.length).round().clamp(startChar + 1, token.length - remainingSegments);
    final part = token.substring(startChar, endChar).trim();
    if (part.isNotEmpty) {
      pieces.add(
        DictationPiece(
          part,
          Rect.fromLTRB(
            rect.left + bounds[i] * rect.width,
            rect.top,
            rect.left + bounds[i + 1] * rect.width,
            rect.bottom,
          ),
        ),
      );
    }
    startChar = endChar;
  }
  return pieces.isEmpty ? [DictationPiece(token, rect)] : pieces;
}

/// Word-space positions along a text line, as fractions of [ink]'s length.
/// [ink] is the dark-pixel count of each column. Narrow letter spacing stays
/// inside a word; a wider column of white, even a small printed space, splits.
List<double> gapFractionsFromInk({
  required List<int> ink,
  required int height,
  required int charCount,
}) {
  if (ink.length < 8 || height < 8 || charCount < 2) return const [];
  final minInk = math.max(1, (height * 0.08).round());
  final gaps = <({int start, int end})>[];
  var index = 0;
  while (index < ink.length) {
    if (ink[index] >= minInk) {
      index += 1;
      continue;
    }
    final start = index;
    while (index < ink.length && ink[index] < minInk) {
      index += 1;
    }
    if (start > 1 && index < ink.length - 1) {
      gaps.add((start: start, end: index));
    }
  }
  if (gaps.isEmpty) return const [];
  final charWidth = ink.length / charCount;
  final small = [
    for (final gap in gaps)
      if ((gap.end - gap.start) < charWidth * 0.2) gap.end - gap.start,
  ]..sort();
  final letterGap = small.isEmpty ? 0.0 : small[small.length ~/ 2] * 1.8;
  final threshold = math.max(4.0, math.max(charWidth * 0.22, math.max(height * 0.10, letterGap)));
  return [
    for (final gap in gaps)
      if ((gap.end - gap.start) >= threshold) (gap.start + gap.end) / 2 / ink.length,
  ];
}

int compareReadingOrder(DictationWord a, DictationWord b) {
  final row = math.max(8.0, math.min(a.rect.height, b.rect.height) * 0.5);
  if ((a.rect.top - b.rect.top).abs() > row) {
    return a.rect.top.compareTo(b.rect.top);
  }
  return a.rect.left.compareTo(b.rect.left);
}

List<DictationWord> sortReadingOrder(List<DictationWord> words) {
  final copy = [...words];
  copy.sort(compareReadingOrder);
  return copy;
}

Rect rectFromPoints(List<Offset> points) {
  if (points.isEmpty) return Rect.zero;
  var left = points.first.dx;
  var top = points.first.dy;
  var right = left;
  var bottom = top;
  for (final point in points.skip(1)) {
    left = math.min(left, point.dx);
    top = math.min(top, point.dy);
    right = math.max(right, point.dx);
    bottom = math.max(bottom, point.dy);
  }
  if (right <= left || bottom <= top) return Rect.zero;
  return Rect.fromLTRB(left, top, right, bottom);
}

bool pointInPolygon(Offset point, List<Offset> polygon) {
  if (polygon.length < 3) return false;
  var inside = false;
  for (var i = 0, j = polygon.length - 1; i < polygon.length; j = i++) {
    final pi = polygon[i];
    final pj = polygon[j];
    final crosses = (pi.dy > point.dy) != (pj.dy > point.dy);
    if (!crosses) continue;
    final x = (pj.dx - pi.dx) * (point.dy - pi.dy) / (pj.dy - pi.dy) + pi.dx;
    if (point.dx < x) inside = !inside;
  }
  return inside;
}

/// 相对语速。Android 1.0 为系统正常速度，iOS 0.5 为系统正常速度。
double speechRateForPlatform({required double relative, required bool ios}) {
  if (ios) return (0.5 * relative).clamp(0.2, 0.55);
  return relative.clamp(0.4, 1.05);
}
