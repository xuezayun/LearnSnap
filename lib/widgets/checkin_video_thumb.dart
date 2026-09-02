import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/checkin_media_cache.dart';
import '../core/device_layout.dart';
import '../core/video_compressor.dart';

/// Video grid tile with a local first-frame cover when the file is on disk.
class CheckinVideoThumb extends StatefulWidget {
  const CheckinVideoThumb({
    super.key,
    required this.onTap,
    this.filePath,
    this.mediaId,
    this.objectKey,
    this.duration,
    this.fileSizeBytes,
  });

  final String? filePath;
  final int? mediaId;
  final String? objectKey;
  final Duration? duration;
  final int? fileSizeBytes;
  final VoidCallback onTap;

  @override
  State<CheckinVideoThumb> createState() => _CheckinVideoThumbState();
}

class _CheckinVideoThumbState extends State<CheckinVideoThumb> {
  String? _thumbPath;
  Uint8List? _thumbBytes;
  int _gen = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(CheckinVideoThumb oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.filePath != widget.filePath ||
        oldWidget.mediaId != widget.mediaId ||
        oldWidget.objectKey != widget.objectKey) {
      _load();
    }
  }

  Future<void> _load() async {
    final gen = ++_gen;
    final id = widget.mediaId ?? 0;
    final key = widget.objectKey?.trim() ?? '';
    final path = widget.filePath?.trim() ?? '';

    final cached = await CheckinMediaCache.thumbPathFor(
      mediaId: id,
      objectKey: key,
      localPath: path,
    );
    if (!mounted || gen != _gen) return;
    if (cached != null) {
      setState(() {
        _thumbPath = cached;
        _thumbBytes = null;
      });
      return;
    }

    if (path.isEmpty) {
      setState(() {
        _thumbPath = null;
        _thumbBytes = null;
      });
      return;
    }

    final bytes = await extractVideoThumbnail(path);
    if (!mounted || gen != _gen) return;
    if (bytes == null || bytes.isEmpty) {
      setState(() {
        _thumbPath = null;
        _thumbBytes = null;
      });
      return;
    }
    await CheckinMediaCache.putThumbBytes(
      bytes,
      mediaId: id,
      objectKey: key,
      localPath: path,
    );
    if (!mounted || gen != _gen) return;
    setState(() {
      _thumbBytes = bytes;
      _thumbPath = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.duration;
    final timeLabel = d == null
        ? null
        : '${d.inMinutes}:${d.inSeconds.remainder(60).toString().padLeft(2, '0')}';
    final sizeLabel = widget.fileSizeBytes != null && widget.fileSizeBytes! > 0
        ? formatFileSize(widget.fileSizeBytes!)
        : null;
    final parts = <String>[
      ?timeLabel,
      ?sizeLabel,
    ];
    final label = parts.isEmpty ? '视频' : parts.join(' · ');
    final iconSize = isTablet(context) ? 40.0 : 34.0;

    Widget? cover;
    if (_thumbPath != null) {
      cover = Image.file(File(_thumbPath!), fit: BoxFit.cover);
    } else if (_thumbBytes != null) {
      cover = Image.memory(_thumbBytes!, fit: BoxFit.cover);
    }

    return Material(
      color: const Color(0xFF1A2A2E),
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: widget.onTap,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ?cover,
            const ColoredBox(color: Color(0x66000000)),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.play_circle_fill_rounded,
                  color: Colors.white,
                  size: iconSize,
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.nunito(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
