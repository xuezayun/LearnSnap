import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../core/api_client.dart';
import '../core/checkin_media_cache.dart';
import '../core/media_url.dart';
import '../theme/app_colors.dart';

/// Loads check-in images from local cache first, then authenticated
/// `/checkins/media/<id>/content`, then a sanitized remote URL.
class RemoteCheckinImage extends StatefulWidget {
  const RemoteCheckinImage({
    super.key,
    this.mediaId,
    this.objectKey,
    this.url,
    this.fit = BoxFit.cover,
    this.error,
    this.api,
  });

  final int? mediaId;
  final String? objectKey;
  final String? url;
  final BoxFit fit;
  final Widget? error;
  final ApiClient? api;

  @override
  State<RemoteCheckinImage> createState() => _RemoteCheckinImageState();
}

class _RemoteCheckinImageState extends State<RemoteCheckinImage> {
  late final ApiClient _api = widget.api ?? ApiClient();
  Uint8List? _bytes;
  String? _filePath;
  bool _loading = true;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(RemoteCheckinImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.mediaId != widget.mediaId ||
        oldWidget.objectKey != widget.objectKey ||
        oldWidget.url != widget.url) {
      _load();
    }
  }

  Future<void> _load() async {
    final id = widget.mediaId ?? 0;
    final key = widget.objectKey?.trim() ?? '';
    setState(() {
      _loading = true;
      _failed = false;
      _bytes = null;
      _filePath = null;
    });

    final cachedPath = await CheckinMediaCache.pathFor(mediaId: id, objectKey: key);
    if (!mounted) return;
    if (cachedPath != null) {
      setState(() {
        _filePath = cachedPath;
        _loading = false;
        _failed = false;
      });
      return;
    }

    if (id > 0) {
      try {
        final bytes = await _api.getBytes('/checkins/media/$id/content');
        await CheckinMediaCache.putBytes(bytes, mediaId: id, objectKey: key);
        if (!mounted) return;
        setState(() {
          _bytes = bytes;
          _loading = false;
          _failed = false;
        });
        return;
      } catch (_) {
        if (!mounted) return;
      }
    }

    final url = (widget.url ?? '').trim();
    if (url.isEmpty) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _failed = true;
      });
      return;
    }
    if (!mounted) return;
    setState(() {
      _loading = false;
      _failed = false;
    });
  }

  Widget _errorBox() {
    return widget.error ??
        ColoredBox(
          color: const Color(0xFFE8ECF0),
          child: Center(
            child: Icon(Icons.broken_image_outlined, color: AppColors.inkFaint),
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const ColoredBox(
        color: Color(0xFFE8ECF0),
        child: Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }
    if (_filePath != null) {
      return Image.file(File(_filePath!), fit: widget.fit);
    }
    if (_bytes != null) {
      return Image.memory(_bytes!, fit: widget.fit);
    }
    if (_failed) {
      return _errorBox();
    }
    final url = (widget.url ?? '').trim();
    if (url.isEmpty) {
      return _errorBox();
    }
    return Image.network(
      resolveMediaUrl(url),
      fit: widget.fit,
      errorBuilder: (context, error, stackTrace) => _errorBox(),
    );
  }
}
