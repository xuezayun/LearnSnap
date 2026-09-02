import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../core/api_client.dart';
import '../../core/checkin_media_cache.dart';
import '../../core/device_layout.dart';
import '../../widgets/remote_checkin_image.dart';

/// Full-screen image viewer with pinch / double-tap zoom.
class ImagePreviewPage extends StatefulWidget {
  const ImagePreviewPage({
    super.key,
    this.bytes,
    this.filePath,
    this.networkUrl,
    this.mediaId,
    this.objectKey,
  }) : assert(
          bytes != null ||
              (filePath != null && filePath.length > 0) ||
              (networkUrl != null && networkUrl.length > 0) ||
              (mediaId != null && mediaId > 0),
          'bytes, filePath, networkUrl or mediaId required',
        );

  final Uint8List? bytes;
  final String? filePath;
  final String? networkUrl;
  final int? mediaId;
  final String? objectKey;

  @override
  State<ImagePreviewPage> createState() => _ImagePreviewPageState();
}

class _ImagePreviewPageState extends State<ImagePreviewPage>
    with SingleTickerProviderStateMixin {
  static const double _minScale = 1.0;
  static const double _maxScale = 5.0;
  static const double _doubleTapScale = 2.5;

  final TransformationController _transform = TransformationController();
  AnimationController? _animController;
  Animation<Matrix4>? _animation;
  TapDownDetails? _doubleTapDetails;
  Uint8List? _fetched;
  String? _cachedPath;
  bool _fetching = false;

  @override
  void initState() {
    super.initState();
    final path = widget.filePath?.trim() ?? '';
    if (widget.bytes != null || path.isNotEmpty) {
      return;
    }
    _fetching = true;
    _load();
  }

  Future<void> _load() async {
    final id = widget.mediaId ?? 0;
    final key = widget.objectKey?.trim() ?? '';
    try {
      final cached = await CheckinMediaCache.pathFor(mediaId: id, objectKey: key);
      if (!mounted) return;
      if (cached != null) {
        setState(() {
          _cachedPath = cached;
          _fetching = false;
        });
        return;
      }
      if (id > 0) {
        final bytes = await ApiClient().getBytes('/checkins/media/$id/content');
        await CheckinMediaCache.putBytes(bytes, mediaId: id, objectKey: key);
        if (!mounted) return;
        setState(() {
          _fetched = bytes;
          _fetching = false;
        });
        return;
      }
    } catch (_) {
      // fall through
    }
    if (!mounted) return;
    setState(() => _fetching = false);
  }

  @override
  void dispose() {
    _animation?.removeListener(_onAnimate);
    _animController?.dispose();
    _transform.dispose();
    super.dispose();
  }

  void _onAnimate() {
    final animation = _animation;
    if (animation == null) return;
    _transform.value = animation.value;
  }

  void _animateTo(Matrix4 target) {
    _animation?.removeListener(_onAnimate);
    _animController?.dispose();
    final controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );
    _animController = controller;
    _animation = Matrix4Tween(
      begin: _transform.value,
      end: target,
    ).animate(CurvedAnimation(parent: controller, curve: Curves.easeOut));
    _animation!.addListener(_onAnimate);
    controller.forward();
  }

  void _handleDoubleTap() {
    final current = _transform.value.getMaxScaleOnAxis();
    if (current > 1.05) {
      _animateTo(Matrix4.identity());
      return;
    }
    final position = _doubleTapDetails?.localPosition;
    if (position == null) {
      _animateTo(
        Matrix4.identity()..scaleByDouble(_doubleTapScale, _doubleTapScale, 1, 1),
      );
      return;
    }
    final zoom = _doubleTapScale;
    _animateTo(
      Matrix4.identity()
        ..translateByDouble(
          -position.dx * (zoom - 1),
          -position.dy * (zoom - 1),
          0,
          1,
        )
        ..scaleByDouble(zoom, zoom, 1, 1),
    );
  }

  Widget _buildImage() {
    if (_fetching) {
      return const Center(child: CircularProgressIndicator(color: Colors.white));
    }
    final bytes = widget.bytes ?? _fetched;
    if (bytes != null) {
      return Image.memory(bytes, fit: BoxFit.contain);
    }
    final local = widget.filePath?.trim().isNotEmpty == true
        ? widget.filePath!.trim()
        : (_cachedPath ?? '');
    if (local.isNotEmpty) {
      return Image.file(File(local), fit: BoxFit.contain);
    }
    final url = widget.networkUrl?.trim() ?? '';
    if (url.isEmpty) {
      return const Center(
        child: Text('图片加载失败', style: TextStyle(color: Colors.white70)),
      );
    }
    return RemoteCheckinImage(
      url: url,
      mediaId: widget.mediaId,
      objectKey: widget.objectKey,
      fit: BoxFit.contain,
      error: const Center(
        child: Text('图片加载失败', style: TextStyle(color: Colors.white70)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final maxImageWidth = isTablet(context) ? 900.0 : double.infinity;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('查看图片'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxImageWidth),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return GestureDetector(
                onDoubleTapDown: (details) => _doubleTapDetails = details,
                onDoubleTap: _handleDoubleTap,
                child: InteractiveViewer(
                  transformationController: _transform,
                  minScale: _minScale,
                  maxScale: _maxScale,
                  child: SizedBox(
                    width: constraints.maxWidth,
                    height: constraints.maxHeight,
                    child: _buildImage(),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
