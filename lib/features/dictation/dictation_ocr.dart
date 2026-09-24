import 'dart:io';

import 'package:flutter/services.dart';
import 'package:paddle_ocr_flutter/paddle_ocr_flutter.dart';

import 'dictation_words.dart';

const _platform = MethodChannel('learnsnap/platform');

final _androidOcr = PaddleOcrFlutter();
Future<void>? _androidOpening;

Future<List<DictationWord>> recognizeDictationWords({
  required String path,
  required DictationLang lang,
}) async {
  final bytes = await File(path).readAsBytes();
  if (Platform.isIOS) {
    return _recognizeWithVision(bytes: bytes, lang: lang);
  }
  await _ensureAndroidOcr();
  final lines = await _androidOcr.recognize(path, maxSizeLen: 1600);
  final found = <DictationWord>[];
  var index = 0;
  for (final line in lines) {
    if (line.confidence < 0.3) continue;
    final rect = rectFromPoints([
      for (final point in line.points) Offset(point.x.toDouble(), point.y.toDouble()),
    ]);
    for (final piece in splitLine(line.text, rect)) {
      if (!keepToken(piece.text, lang)) continue;
      found.add(DictationWord(id: 'w$index', text: piece.text, rect: piece.rect));
      index += 1;
    }
  }
  return sortReadingOrder(found);
}

Future<void> _ensureAndroidOcr() {
  final opening = _androidOpening;
  if (opening != null) return opening;
  final future = _openAndroidOcr();
  _androidOpening = future;
  return future;
}

Future<void> _openAndroidOcr() async {
  try {
    await _androidOcr.init();
  } catch (_) {
    _androidOpening = null;
    throw Exception('本机文字识别还没准备好，请稍后再试');
  }
}

Future<List<DictationWord>> _recognizeWithVision({
  required Uint8List bytes,
  required DictationLang lang,
}) async {
  final raw = await _platform.invokeMethod<List<dynamic>>('recognizeText', {
    'bytes': bytes,
    'lang': lang == DictationLang.english ? 'en' : 'zh',
  });
  final found = <DictationWord>[];
  var index = 0;
  for (final item in raw ?? const []) {
    if (item is! Map) continue;
    final text = item['text']?.toString() ?? '';
    final rect = Rect.fromLTRB(
      (item['left'] as num?)?.toDouble() ?? 0,
      (item['top'] as num?)?.toDouble() ?? 0,
      (item['right'] as num?)?.toDouble() ?? 0,
      (item['bottom'] as num?)?.toDouble() ?? 0,
    );
    for (final piece in splitLine(text, rect)) {
      if (!keepToken(piece.text, lang)) continue;
      found.add(DictationWord(id: 'w$index', text: piece.text, rect: piece.rect));
      index += 1;
    }
  }
  return sortReadingOrder(found);
}
