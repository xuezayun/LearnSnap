import 'package:app/features/dictation/dictation_words.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('splits a spaced Chinese line into boxes from left to right', () {
    final pieces = splitLine('苹果 香蕉', const Rect.fromLTWH(0, 0, 100, 20));
    expect(pieces.map((piece) => piece.text).toList(), ['苹果', '香蕉']);
    expect(pieces.first.rect.left, 0);
    expect(pieces.last.rect.left, greaterThan(pieces.first.rect.left));
  });

  test('keeps Chinese tokens and English tokens apart', () {
    expect(keepToken('苹果', DictationLang.chinese), isTrue);
    expect(keepToken('apple', DictationLang.chinese), isFalse);
    expect(keepToken('apple', DictationLang.english), isTrue);
    expect(keepToken('123', DictationLang.english), isFalse);
  });

  test('sorts words by row then by left', () {
    final words = sortReadingOrder([
      const DictationWord(id: 'b', text: '右', rect: Rect.fromLTWH(80, 10, 20, 20)),
      const DictationWord(id: 'c', text: '下', rect: Rect.fromLTWH(0, 80, 20, 20)),
      const DictationWord(id: 'a', text: '左', rect: Rect.fromLTWH(0, 12, 20, 20)),
    ]);
    expect(words.map((word) => word.text).toList(), ['左', '右', '下']);
  });

  test('bounds a quad as a rectangle', () {
    final rect = rectFromPoints(const [
      Offset(10, 20),
      Offset(40, 18),
      Offset(42, 36),
      Offset(8, 34),
    ]);
    expect(rect.left, 8);
    expect(rect.top, 18);
    expect(rect.right, 42);
    expect(rect.bottom, 36);
  });

  test('point in polygon hits the center of a square', () {
    const square = [
      Offset(0, 0),
      Offset(10, 0),
      Offset(10, 10),
      Offset(0, 10),
    ];
    expect(pointInPolygon(const Offset(5, 5), square), isTrue);
    expect(pointInPolygon(const Offset(20, 5), square), isFalse);
  });

  test('maps speech pace slower on iOS', () {
    expect(speechRateForPlatform(relative: 1, ios: false), 1);
    expect(speechRateForPlatform(relative: 1, ios: true), 0.5);
  });
}
