import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image/image.dart' as img;

import '../../theme/app_colors.dart';

/// User draws a rectangle on the photo. Recognition runs only on that crop.
class DictationRegionPage extends StatefulWidget {
  const DictationRegionPage({super.key, required this.imagePath});

  final String imagePath;

  @override
  State<DictationRegionPage> createState() => _DictationRegionPageState();
}

class _DictationRegionPageState extends State<DictationRegionPage> {
  img.Image? _decoded;
  bool _busy = false;
  String? _error;
  Rect _norm = const Rect.fromLTWH(0.08, 0.16, 0.84, 0.48);

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
      if (!crop) {
        if (!mounted) return;
        Navigator.of(context).pop(widget.imagePath);
        return;
      }
      final left = (_norm.left * decoded.width).round().clamp(0, decoded.width - 1);
      final top = (_norm.top * decoded.height).round().clamp(0, decoded.height - 1);
      final width = (_norm.width * decoded.width).round().clamp(1, decoded.width - left);
      final height = (_norm.height * decoded.height).round().clamp(1, decoded.height - top);
      var output = img.copyCrop(decoded, x: left, y: top, width: width, height: height);
      if (output.width > 1600) {
        output = img.copyResize(output, width: 1600);
      }
      final jpg = Uint8List.fromList(img.encodeJpg(output, quality: 90));
      final dest = File('${widget.imagePath}.region.jpg');
      await dest.writeAsBytes(jpg, flush: true);
      if (!mounted) return;
      Navigator.of(context).pop(dest.path);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = '这块没有裁出来，请再试一次';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('框出要听的词')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
            child: Text(
              '拖动方框对准词语，拉右下角改大小。只识别方框里的字。',
              style: GoogleFonts.nunito(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.inkMuted,
                height: 1.35,
              ),
            ),
          ),
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
                    child: Text(_busy ? '处理中…' : '识别这块'),
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
            ..._dimOutside(fitted, selection),
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
              left: selection.right - 22,
              top: selection.bottom - 22,
              child: GestureDetector(
                onPanUpdate: (details) {
                  setState(() {
                    final dw = details.delta.dx / fitted.width;
                    final dh = details.delta.dy / fitted.height;
                    final width = (_norm.width + dw).clamp(0.12, 1 - _norm.left);
                    final height = (_norm.height + dh).clamp(0.08, 1 - _norm.top);
                    _norm = Rect.fromLTWH(_norm.left, _norm.top, width, height);
                  });
                },
                child: const SizedBox(
                  width: 36,
                  height: 36,
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

  List<Widget> _dimOutside(Rect image, Rect hole) {
    const color = Color(0x99000000);
    Widget band(Rect rect) {
      if (rect.width <= 0 || rect.height <= 0) return const SizedBox.shrink();
      return Positioned.fromRect(
        rect: rect,
        child: const ColoredBox(color: color),
      );
    }

    return [
      band(Rect.fromLTRB(image.left, image.top, image.right, hole.top)),
      band(Rect.fromLTRB(image.left, hole.bottom, image.right, image.bottom)),
      band(Rect.fromLTRB(image.left, hole.top, hole.left, hole.bottom)),
      band(Rect.fromLTRB(hole.right, hole.top, image.right, hole.bottom)),
    ];
  }

  Rect _fitted(Size box, int imageWidth, int imageHeight) {
    final scale = math.min(box.width / imageWidth, box.height / imageHeight);
    final width = imageWidth * scale;
    final height = imageHeight * scale;
    return Rect.fromLTWH((box.width - width) / 2, (box.height - height) / 2, width, height);
  }
}
