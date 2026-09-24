import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:app/core/checkin_media_prepare.dart';

void main() {
  test('detects jpeg magic', () {
    expect(isJpegBytes(Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE0])), isTrue);
    expect(isJpegBytes(Uint8List.fromList([0x00, 0x00, 0x00])), isFalse);
  });

  test('detects heic ftyp brand', () {
    final heic = Uint8List(12);
    heic.setAll(4, [0x66, 0x74, 0x79, 0x70, 0x68, 0x65, 0x69, 0x63]); // ftypheic
    expect(isHeicBytes(heic), isTrue);

    final jpeg = Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE0, 0, 0, 0, 0, 0, 0, 0, 0]);
    expect(isHeicBytes(jpeg), isFalse);
  });

  test('cos XML error bodies are rejected', () {
    expect(
      cosResponseIndicatesError(
        "<?xml version='1.0'?><Error><Code>NoSuchKey</Code></Error>",
      ),
      isTrue,
    );
    expect(cosResponseIndicatesError(''), isFalse);
    expect(cosResponseIndicatesError('ok'), isFalse);
  });

  test('image filenames are sanitized to jpg', () {
    expect(safeImageFilename('IMG_001.HEIC').endsWith('.jpg'), isTrue);
    expect(safeImageFilename(r'/storage/emulated/0/DCIM/x.jpg').endsWith('.jpg'), isTrue);
  });
}
