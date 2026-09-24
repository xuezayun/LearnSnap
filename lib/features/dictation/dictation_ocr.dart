import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_paddle_ocr/flutter_paddle_ocr.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'dictation_words.dart';

const _modelNames = ['det_db.nb', 'rec_crnn.nb', 'cls.nb', 'ppocr_keys_v1.txt'];

PaddleOcr? _engine;
Future<PaddleOcr>? _opening;

Future<List<DictationWord>> recognizeDictationWords({
  required String path,
  required DictationLang lang,
}) async {
  final engine = await _ocrEngine();
  final bytes = await File(path).readAsBytes();
  final lines = await engine.recognize(
    bytes,
    maxSideLen: 1600,
    runClassification: true,
  );
  final found = <DictationWord>[];
  var index = 0;
  for (final line in lines) {
    if (line.confidence < 0.3) continue;
    final rect = rectFromPoints(line.points);
    for (final piece in splitLine(line.text, rect)) {
      if (!keepToken(piece.text, lang)) continue;
      found.add(DictationWord(id: 'w$index', text: piece.text, rect: piece.rect));
      index += 1;
    }
  }
  return sortReadingOrder(found);
}

Future<PaddleOcr> _ocrEngine() {
  final existing = _engine;
  if (existing != null) return Future.value(existing);
  final opening = _opening;
  if (opening != null) return opening;
  final future = _openEngine();
  _opening = future;
  return future;
}

Future<PaddleOcr> _openEngine() async {
  try {
    final paths = <String, String>{};
    for (final name in _modelNames) {
      paths[name] = await _copyModel(name);
    }
    final engine = await PaddleOcr.create(
      source: ModelSource.filePaths(
        det: paths['det_db.nb']!,
        rec: paths['rec_crnn.nb']!,
        cls: paths['cls.nb']!,
        dict: paths['ppocr_keys_v1.txt']!,
      ),
    );
    _engine = engine;
    return engine;
  } catch (_) {
    _opening = null;
    throw Exception('本机文字识别还没准备好，请稍后再试');
  }
}

Future<String> _copyModel(String name) async {
  final root = await getApplicationSupportDirectory();
  final file = File(p.join(root.path, 'ocr_models', name));
  if (await file.exists() && await file.length() > 0) return file.path;
  final data = await rootBundle.load('assets/ocr/$name');
  await file.parent.create(recursive: true);
  await file.writeAsBytes(
    data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
    flush: true,
  );
  return file.path;
}
