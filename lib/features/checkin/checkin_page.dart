import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/api_client.dart';
import '../../core/device_layout.dart';
import '../../models/checkin_media.dart';
import '../../models/checkin_photo.dart';
import '../../services/learn_snap_api.dart';
import 'video_preview_page.dart';
import 'video_record_page.dart';

class CheckinPage extends StatefulWidget {
  const CheckinPage({
    super.key,
    required this.assignmentId,
    required this.title,
    this.api,
    this.revise = false,
    this.checkinId,
  });

  final int assignmentId;
  final String title;
  final LearnSnapApi? api;
  final bool revise;
  final int? checkinId;

  @override
  State<CheckinPage> createState() => _CheckinPageState();
}

class _CheckinPageState extends State<CheckinPage> {
  final _picker = ImagePicker();
  late final LearnSnapApi _api = widget.api ?? LearnSnapApi();
  final List<CheckinMediaItem> _media = [];
  bool _submitting = false;
  String? _error;
  String? _idempotencyKey;

  Future<void> _addPhoto(ImageSource source) async {
    if (source == ImageSource.camera) {
      final photo = await _picker.pickImage(
        source: source,
        imageQuality: 92,
        maxWidth: 2400,
      );
      if (photo == null || !mounted) return;
      final bytes = await photo.readAsBytes();
      setState(() {
        _media.add(
          CheckinPhoto(bytes: bytes, filename: photo.name).toMediaItem(),
        );
      });
      return;
    }
    final photos = await _picker.pickMultiImage(imageQuality: 92, maxWidth: 2400);
    for (final photo in photos) {
      if (!mounted) return;
      final bytes = await photo.readAsBytes();
      setState(() {
        _media.add(
          CheckinPhoto(bytes: bytes, filename: photo.name).toMediaItem(),
        );
      });
    }
  }

  Future<void> _recordVideo() async {
    final result = await Navigator.of(context).push<VideoRecordResult>(
      MaterialPageRoute(builder: (_) => const VideoRecordPage()),
    );
    if (result == null || !mounted) return;
    await _confirmVideo(result.filePath, result.duration);
  }

  Future<void> _pickVideo() async {
    final picked = await _picker.pickVideo(
      source: ImageSource.gallery,
      maxDuration: checkinMaxVideoDuration,
    );
    if (picked == null || !mounted) return;
    final bytes = await File(picked.path).length();
    if (bytes > checkinMaxVideoBytes) {
      setState(() => _error = '视频不能超过 50MB');
      return;
    }
    await _confirmVideo(picked.path, Duration.zero);
  }

  Future<void> _confirmVideo(String path, Duration duration) async {
    final ok = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => VideoPreviewPage(filePath: path)),
    );
    if (ok != true || !mounted) return;
    setState(() {
      _error = null;
      _media.add(
        CheckinMediaItem.video(
          filePath: path,
          filename: ensureVideoFilename('video_${DateTime.now().millisecondsSinceEpoch}.mp4'),
          duration: duration,
        ),
      );
    });
  }

  Future<void> _submit() async {
    if (_media.isEmpty) {
      setState(() => _error = '请至少添加一张照片或一段视频');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
      _idempotencyKey ??=
          '${widget.assignmentId}_${DateTime.now().millisecondsSinceEpoch}';
    });
    try {
      final result = await _api.submitCheckin(
        assignmentId: widget.assignmentId,
        media: _media,
        idempotencyKey: _idempotencyKey,
      );
      if (!mounted) return;
      Navigator.pop(context, result);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } on DioException catch (e) {
      setState(() => _error = e.message ?? '网络请求失败');
    } catch (e) {
      setState(() => _error = '提交失败：$e');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final thumbSize = mediaThumbSize(context);
    final tablet = isTablet(context);
    final itemCount = _media.length + 1;

    return Scaffold(
      appBar: AppBar(title: Text(widget.revise ? '修订 · ${widget.title}' : widget.title)),
      body: Column(
        children: [
          Expanded(
            child: AdaptiveBody(
              padding: EdgeInsets.fromLTRB(
                pagePadding(context),
                pagePadding(context),
                pagePadding(context),
                0,
              ),
              child: ListView(
                children: [
                  Text(
                    widget.revise ? '更新今日打卡内容' : '记录你的学习成果',
                    style: TextStyle(
                      fontSize: tablet ? 24 : 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.revise
                        ? '重新拍照或选视频后提交，将替换今日已提交的内容'
                        : '可拍照、录视频或从相册选择（视频最长 2 分钟，≤50MB）',
                    style: const TextStyle(color: Colors.black54),
                  ),
                  const SizedBox(height: 20),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: mediaGridDelegate(context),
                    itemCount: itemCount,
                    itemBuilder: (context, index) {
                      if (index == _media.length) {
                        return _AddButton(
                          size: thumbSize,
                          onCamera: () => _addPhoto(ImageSource.camera),
                          onGallery: () => _addPhoto(ImageSource.gallery),
                          onRecordVideo: _recordVideo,
                          onPickVideo: _pickVideo,
                        );
                      }
                      final item = _media[index];
                      if (item.isImage) {
                        return _ImageThumb(
                          size: thumbSize,
                          bytes: item.bytes!,
                          onRemove: () => setState(() => _media.removeAt(index)),
                        );
                      }
                      return _VideoThumb(
                        size: thumbSize,
                        duration: item.duration,
                        onTap: () => Navigator.of(context).push<void>(
                          MaterialPageRoute(
                            builder: (_) => VideoPreviewPage(
                              filePath: item.filePath!,
                              previewOnly: true,
                            ),
                          ),
                        ),
                        onRemove: () => setState(() => _media.removeAt(index)),
                      );
                    },
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 16),
                    Text(_error!, style: const TextStyle(color: Colors.red)),
                  ],
                ],
              ),
            ),
          ),
          AdaptiveBottomBar(
            child: FilledButton(
              onPressed: _submitting ? null : _submit,
              style: FilledButton.styleFrom(
                minimumSize: Size(double.infinity, primaryButtonHeight(context)),
              ),
              child: _submitting
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        const SizedBox(width: 12),
                        Text('提交中…', style: TextStyle(fontSize: tablet ? 20 : 18)),
                      ],
                    )
                  : Text(
                      widget.revise ? '提交修订' : '提交打卡',
                      style: TextStyle(fontSize: tablet ? 20 : 18),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ImageThumb extends StatelessWidget {
  const _ImageThumb({
    required this.size,
    required this.bytes,
    required this.onRemove,
  });

  final double size;
  final Uint8List bytes;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.memory(bytes, width: size, height: size, fit: BoxFit.cover),
        ),
        Positioned(top: -8, right: -8, child: _RemoveBtn(onRemove: onRemove)),
      ],
    );
  }
}

class _VideoThumb extends StatelessWidget {
  const _VideoThumb({
    required this.size,
    required this.duration,
    required this.onTap,
    required this.onRemove,
  });

  final double size;
  final Duration? duration;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final d = duration;
    final label = d == null
        ? '视频'
        : '${d.inMinutes}:${d.inSeconds.remainder(60).toString().padLeft(2, '0')}';
    final iconSize = isTablet(context) ? 36.0 : 30.0;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A2E),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.videocam, color: Colors.white, size: iconSize),
                Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
              ],
            ),
          ),
        ),
        Positioned(top: -8, right: -8, child: _RemoveBtn(onRemove: onRemove)),
      ],
    );
  }
}

class _RemoveBtn extends StatelessWidget {
  const _RemoveBtn({required this.onRemove});

  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return IconButton.filledTonal(
      style: IconButton.styleFrom(
        backgroundColor: Colors.white,
        visualDensity: VisualDensity.compact,
      ),
      onPressed: onRemove,
      icon: const Icon(Icons.close, size: 18),
    );
  }
}

class _AddButton extends StatelessWidget {
  const _AddButton({
    required this.size,
    required this.onCamera,
    required this.onGallery,
    required this.onRecordVideo,
    required this.onPickVideo,
  });

  final double size;
  final VoidCallback onCamera;
  final VoidCallback onGallery;
  final VoidCallback onRecordVideo;
  final VoidCallback onPickVideo;

  Future<void> _showTabletAddSheet(BuildContext context) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('拍照'),
              onTap: () => Navigator.pop(ctx, 'camera'),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('从相册选照片'),
              onTap: () => Navigator.pop(ctx, 'gallery'),
            ),
            ListTile(
              leading: const Icon(Icons.videocam),
              title: const Text('录制视频'),
              onTap: () => Navigator.pop(ctx, 'record'),
            ),
            ListTile(
              leading: const Icon(Icons.video_library),
              title: const Text('从相册选视频'),
              onTap: () => Navigator.pop(ctx, 'pick_video'),
            ),
          ],
        ),
      ),
    );
    _handleAction(action);
  }

  void _handleAction(String? action) {
    switch (action) {
      case 'camera':
        onCamera();
      case 'gallery':
        onGallery();
      case 'record':
        onRecordVideo();
      case 'pick_video':
        onPickVideo();
    }
  }

  Widget _buildTile() {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade400),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.add_circle_outline, size: size >= 140 ? 32 : 24),
          Text('添加', style: TextStyle(fontSize: size >= 140 ? 14 : 12)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isTablet(context)) {
      return GestureDetector(
        onTap: () => _showTabletAddSheet(context),
        child: _buildTile(),
      );
    }
    return PopupMenuButton<String>(
      onSelected: _handleAction,
      itemBuilder: (context) => const [
        PopupMenuItem(value: 'camera', child: Text('拍照')),
        PopupMenuItem(value: 'gallery', child: Text('从相册选照片')),
        PopupMenuItem(value: 'record', child: Text('录制视频')),
        PopupMenuItem(value: 'pick_video', child: Text('从相册选视频')),
      ],
      child: _buildTile(),
    );
  }
}
