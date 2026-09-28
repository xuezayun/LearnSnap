import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;

import '../../theme/app_colors.dart';

class WrongCropPage extends StatefulWidget {
  const WrongCropPage({super.key, required this.imagePath});

  final String imagePath;

  @override
  State<WrongCropPage> createState() => _WrongCropPageState();
}

class _WrongCropPageState extends State<WrongCropPage> {
  img.Image? _decoded;
  bool _busy = false;
  String? _error;
  Rect _norm = const Rect.fromLTWH(0.12, 0.18, 0.76, 0.42);

  @override
  void initState() {
    super.initState();
    _decode();
  }

  Future<void> _decode() async {
    try {
      final bytes = await File(widget.imagePath).readAsBytes();
      final decoded = img.decodeImage(bytes);
      if (!mounted) return;
      if (decoded == null) {
        setState(() => _error = '这张照片打不开，请重拍一张');
        return;
      }
      setState(() => _decoded = decoded);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = '这张照片打不开，请重拍一张');
    }
  }

  Future<void> _confirm({required bool crop}) async {
    final decoded = _decoded;
    if (decoded == null || _busy) return;
    setState(() => _busy = true);
    try {
      img.Image output = decoded;
      if (crop) {
        final left = (_norm.left * decoded.width).round().clamp(0, decoded.width - 1);
        final top = (_norm.top * decoded.height).round().clamp(0, decoded.height - 1);
        final width = (_norm.width * decoded.width).round().clamp(1, decoded.width - left);
        final height = (_norm.height * decoded.height).round().clamp(1, decoded.height - top);
        output = img.copyCrop(decoded, x: left, y: top, width: width, height: height);
      }
      if (output.width > 1600) {
        output = img.copyResize(output, width: 1600);
      }
      final jpg = Uint8List.fromList(img.encodeJpg(output, quality: 82));
      final dest = File('${widget.imagePath}.crop.jpg');
      await dest.writeAsBytes(jpg, flush: true);
      if (!mounted) return;
      Navigator.of(context).pop(dest.path);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = '裁剪没有完成，请再试一次';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('圈出这道错题')),
      body: Column(
        children: [
          Expanded(child: _body()),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _busy || _decoded == null ? null : () => _confirm(crop: false),
                    child: const Text('用整张'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _busy || _decoded == null ? null : () => _confirm(crop: true),
                    child: Text(_busy ? '处理中…' : '裁好了'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _body() {
    if (_error != null) {
      return Center(child: Text(_error!));
    }
    final decoded = _decoded;
    if (decoded == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final fitted = _fitted(
          Size(constraints.maxWidth, constraints.maxHeight),
          decoded.width,
          decoded.height,
        );
        final selection = Rect.fromLTWH(
          fitted.left + _norm.left * fitted.width,
          fitted.top + _norm.top * fitted.height,
          _norm.width * fitted.width,
          _norm.height * fitted.height,
        );
        return Stack(
          children: [
            Positioned.fromRect(
              rect: fitted,
              child: Image.file(File(widget.imagePath), fit: BoxFit.fill),
            ),
            Positioned.fromRect(
              rect: selection,
              child: GestureDetector(
                onPanUpdate: (details) {
                  setState(() {
                    final dx = details.delta.dx / fitted.width;
                    final dy = details.delta.dy / fitted.height;
                    final left = (_norm.left + dx).clamp(0.0, 1 - _norm.width);
                    final top = (_norm.top + dy).clamp(0.0, 1 - _norm.height);
                    _norm = Rect.fromLTWH(left, top, _norm.width, _norm.height);
                  });
                },
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.accentSun, width: 2),
                    color: AppColors.accentSun.withValues(alpha: 0.12),
                  ),
                ),
              ),
            ),
            Positioned(
              left: selection.right - 18,
              top: selection.bottom - 18,
              child: GestureDetector(
                onPanUpdate: (details) {
                  setState(() {
                    final dw = details.delta.dx / fitted.width;
                    final dh = details.delta.dy / fitted.height;
                    final width = (_norm.width + dw).clamp(0.18, 1 - _norm.left);
                    final height = (_norm.height + dh).clamp(0.12, 1 - _norm.top);
                    _norm = Rect.fromLTWH(_norm.left, _norm.top, width, height);
                  });
                },
                child: const SizedBox(
                  width: 28,
                  height: 28,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppColors.accentSun,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Rect _fitted(Size box, int imageWidth, int imageHeight) {
    final scale = math.min(box.width / imageWidth, box.height / imageHeight);
    final width = imageWidth * scale;
    final height = imageHeight * scale;
    return Rect.fromLTWH((box.width - width) / 2, (box.height - height) / 2, width, height);
  }
}
