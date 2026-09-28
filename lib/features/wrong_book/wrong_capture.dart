import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../core/harmony_os.dart';
import 'wrong_book_repository.dart';
import 'wrong_crop_page.dart';
import 'wrong_edit_page.dart';

Future<ImageSource?> pickWrongImageSource(BuildContext context) {
  return showModalBottomSheet<ImageSource>(
    context: context,
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.photo_camera_rounded),
            title: const Text('拍照'),
            onTap: () => Navigator.pop(context, ImageSource.camera),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_rounded),
            title: const Text('从相册选'),
            onTap: () => Navigator.pop(context, ImageSource.gallery),
          ),
        ],
      ),
    ),
  );
}

Future<bool> captureWrongItem({
  required BuildContext context,
  required int childId,
  required WrongBookRepository repository,
  required ImageSource source,
  String? subject,
}) async {
  final harmony = await HarmonyOs.isHarmonyOs();
  if (!context.mounted) return false;
  final skipCompress = harmony || Platform.isIOS;
  final photo = await ImagePicker().pickImage(
    source: source,
    imageQuality: skipCompress ? null : 90,
    maxWidth: skipCompress ? null : 2000,
  );
  if (photo == null || !context.mounted) return false;
  final support = await getApplicationSupportDirectory();
  final copied = File(
    p.join(support.path, 'wrong_book', 'inbox_${DateTime.now().millisecondsSinceEpoch}.jpg'),
  );
  await copied.parent.create(recursive: true);
  await File(photo.path).copy(copied.path);
  if (!context.mounted) return false;
  final cropped = await Navigator.of(context).push<String>(
    MaterialPageRoute(builder: (_) => WrongCropPage(imagePath: copied.path)),
  );
  if (cropped == null || !context.mounted) return false;
  final saved = await Navigator.of(context).push<bool>(
    MaterialPageRoute(
      builder: (_) => WrongEditPage(
        childId: childId,
        repository: repository,
        imagePath: cropped,
        initialSubject: subject,
      ),
    ),
  );
  return saved == true;
}
