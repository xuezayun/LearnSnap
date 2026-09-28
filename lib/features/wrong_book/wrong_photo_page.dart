import 'dart:io';

import 'package:flutter/material.dart';

import 'wrong_item.dart';

class WrongPhotoPage extends StatelessWidget {
  const WrongPhotoPage({super.key, required this.item, this.onEdit});

  final WrongItem item;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final file = File(item.localPath);
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(wrongSubjectLabel(item.subject)),
        actions: [
          if (onEdit != null)
            IconButton(
              onPressed: onEdit,
              icon: const Icon(Icons.edit_outlined),
              tooltip: '编辑',
            ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return InteractiveViewer(
            minScale: 1,
            maxScale: 5,
            child: SizedBox(
              width: constraints.maxWidth,
              height: constraints.maxHeight,
              child: file.existsSync()
                  ? Image.file(file, fit: BoxFit.contain)
                  : const Center(
                      child: Text('照片还没准备好', style: TextStyle(color: Colors.white70)),
                    ),
            ),
          );
        },
      ),
    );
  }
}
