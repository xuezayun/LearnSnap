import 'dart:typed_data';

import 'checkin_media.dart';

class CheckinPhoto {
  const CheckinPhoto({required this.bytes, required this.filename});

  final Uint8List bytes;
  final String filename;

  CheckinMediaItem toMediaItem() =>
      CheckinMediaItem.image(bytes: bytes, filename: filename);
}
