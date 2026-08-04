import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/api_client.dart';
import '../../core/device_layout.dart';
import '../../core/media_url.dart';
import '../../core/video_compressor.dart';
import '../../models/checkin_media.dart';
import '../../models/checkin_photo.dart';
import '../../services/learn_snap_api.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_scaffold_bg.dart';
import '../../widgets/child_name_badge.dart';
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
    this.nickname,
    this.childId,
    this.initialMedia = const [],
  });

  final int assignmentId;
  final String title;
  final LearnSnapApi? api;
  final bool revise;
  final int? checkinId;
  final String? nickname;
  final int? childId;
  final List<CheckinMediaItem> initialMedia;

  @override
  State<CheckinPage> createState() => _CheckinPageState();
}

class _CheckinPageState extends State<CheckinPage> {
  final _picker = ImagePicker();
  late final LearnSnapApi _api = widget.api ?? LearnSnapApi();
  final List<CheckinMediaItem> _media = [];
  bool _submitting = false;
  bool _loadingExisting = false;
  String? _error;
  String? _idempotencyKey;

  @override
  void initState() {
    super.initState();
    if (widget.initialMedia.isNotEmpty) {
      _media.addAll(widget.initialMedia);
    }
    if (widget.revise && widget.checkinId != null && widget.initialMedia.isEmpty) {
      _loadExistingMedia(widget.checkinId!);
    }
  }

  Future<void> _loadExistingMedia(int checkinId) async {
    setState(() {
      _loadingExisting = true;
      _error = null;
    });
    try {
      final items = await _api.fetchCheckinMedia(checkinId);
      if (!mounted) return;
      setState(() {
        _media
          ..clear()
          ..addAll(items);
        _loadingExisting = false;
        if (items.isEmpty) {
          _error = '暂无已提交的图片或视频，可重新添加';
        }
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingExisting = false;
        _error = e.message;
      });
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingExisting = false;
        _error = e.message ?? '加载已提交内容失败';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingExisting = false;
        _error = '加载已提交内容失败';
      });
    }
  }

  int get _imageCount => _media.where((m) => m.isImage).length;
  int get _videoCount => _media.where((m) => m.isVideo).length;

  Future<void> _addPhoto(ImageSource source) async {
    if (_imageCount >= checkinMaxImages) {
      setState(() => _error = '单次打卡最多 $checkinMaxImages 张图片');
      return;
    }
    if (source == ImageSource.camera) {
      final photo = await _picker.pickImage(
        source: source,
        imageQuality: 92,
        maxWidth: 2400,
      );
      if (photo == null || !mounted) return;
      final bytes = await photo.readAsBytes();
      setState(() {
        _error = null;
        _media.add(
          CheckinPhoto(bytes: bytes, filename: photo.name).toMediaItem(),
        );
      });
      return;
    }
    final remaining = checkinMaxImages - _imageCount;
    final photos = await _picker.pickMultiImage(imageQuality: 92, maxWidth: 2400);
    var added = 0;
    for (final photo in photos) {
      if (!mounted) return;
      if (added >= remaining) {
        setState(() => _error = '单次打卡最多 $checkinMaxImages 张图片');
        break;
      }
      final bytes = await photo.readAsBytes();
      setState(() {
        _error = null;
        _media.add(
          CheckinPhoto(bytes: bytes, filename: photo.name).toMediaItem(),
        );
      });
      added += 1;
    }
  }

  Future<void> _recordVideo() async {
    if (_videoCount >= checkinMaxVideos) {
      setState(() => _error = '单次打卡最多 $checkinMaxVideos 段视频');
      return;
    }
    final result = await Navigator.of(context).push<VideoRecordResult>(
      MaterialPageRoute(builder: (_) => const VideoRecordPage()),
    );
    if (result == null || !mounted) return;
    await _confirmVideo(result.filePath, result.duration);
  }

  Future<void> _pickVideo() async {
    if (_videoCount >= checkinMaxVideos) {
      setState(() => _error = '单次打卡最多 $checkinMaxVideos 段视频');
      return;
    }
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
    if (_videoCount >= checkinMaxVideos) {
      setState(() => _error = '单次打卡最多 $checkinMaxVideos 段视频');
      return;
    }
    final ok = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => VideoPreviewPage(filePath: path)),
    );
    if (ok != true || !mounted) return;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const PopScope(
        canPop: false,
        child: Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 28, vertical: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('正在压缩视频…'),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    try {
      final compressed = await compressCheckinVideo(path);
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      setState(() {
        _error = null;
        _media.add(
          CheckinMediaItem.video(
            filePath: compressed.path,
            filename: ensureVideoFilename(
              'video_${DateTime.now().millisecondsSinceEpoch}.mp4',
            ),
            duration: duration,
            fileSizeBytes: compressed.bytes,
          ),
        );
      });
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      final message = e is Exception
          ? e.toString().replaceFirst('Exception: ', '')
          : '压缩失败，请重试或重录';
      setState(() => _error = message.isNotEmpty ? message : '压缩失败，请重试或重录');
    }
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
    final canAddMore =
        _imageCount < checkinMaxImages || _videoCount < checkinMaxVideos;
    final itemCount = _media.length + (canAddMore ? 1 : 0);

    return Scaffold(
      extendBodyBehindAppBar: false,
      appBar: AppBar(
        title: Text(widget.revise ? '修订 · ${widget.title}' : widget.title),
      ),
      body: AppScaffoldBackground(
        child: Column(
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
                    if (widget.nickname != null &&
                        widget.nickname!.trim().isNotEmpty) ...[
                      ChildNameBadge(
                        nickname: widget.nickname!,
                        childId: widget.childId,
                        size: ChildNameBadgeSize.md,
                      ),
                      const SizedBox(height: 14),
                    ],
                    Text(
                      widget.revise ? '更新今日打卡内容' : '记录你的学习成果',
                      style: GoogleFonts.nunito(
                        fontSize: tablet ? 24 : 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.revise
                          ? '可删除已提交的照片/视频，也可继续添加（最多 $checkinMaxImages 张图 + $checkinMaxVideos 段视频）'
                          : '最多 $checkinMaxImages 张图 + $checkinMaxVideos 段视频（视频最长 2 分钟，≤50MB）',
                      style: GoogleFonts.nunito(
                        color: AppColors.inkMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (_loadingExisting)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 32),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else
                      GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: mediaGridDelegate(context),
                    itemCount: itemCount,
                    itemBuilder: (context, index) {
                      if (index == _media.length) {
                        return _AddButton(
                          size: thumbSize,
                          onCamera: _imageCount < checkinMaxImages
                              ? () => _addPhoto(ImageSource.camera)
                              : null,
                          onGallery: _imageCount < checkinMaxImages
                              ? () => _addPhoto(ImageSource.gallery)
                              : null,
                          onRecordVideo: _videoCount < checkinMaxVideos
                              ? _recordVideo
                              : null,
                          onPickVideo: _videoCount < checkinMaxVideos
                              ? _pickVideo
                              : null,
                        );
                      }
                      final item = _media[index];
                      if (item.isImage) {
                        return _ImageThumb(
                          size: thumbSize,
                          bytes: item.bytes,
                          remoteUrl: item.remoteUrl,
                          onRemove: () => setState(() => _media.removeAt(index)),
                        );
                      }
                      return _VideoThumb(
                        size: thumbSize,
                        duration: item.duration,
                        fileSizeBytes: item.fileSizeBytes,
                        onTap: () => Navigator.of(context).push<void>(
                          MaterialPageRoute(
                            builder: (_) => VideoPreviewPage(
                              filePath: item.filePath,
                              networkUrl: item.remoteUrl,
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
              onPressed: (_submitting || _loadingExisting) ? null : _submit,
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
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '提交中…',
                          style: GoogleFonts.nunito(
                            fontSize: tablet ? 20 : 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    )
                  : Text(
                      widget.revise ? '提交修订' : '提交打卡',
                      style: GoogleFonts.nunito(
                        fontSize: tablet ? 20 : 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
            ),
          ),
        ],
        ),
      ),
    );
  }
}

class _ImageThumb extends StatelessWidget {
  const _ImageThumb({
    required this.size,
    required this.onRemove,
    this.bytes,
    this.remoteUrl,
  });

  final double size;
  final Uint8List? bytes;
  final String? remoteUrl;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final Widget image;
    if (bytes != null) {
      image = Image.memory(bytes!, width: size, height: size, fit: BoxFit.cover);
    } else if (remoteUrl != null && remoteUrl!.isNotEmpty) {
      image = Image.network(
        sanitizeMediaUrl(remoteUrl!),
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, error, stackTrace) => Container(
          width: size,
          height: size,
          color: const Color(0xFFE8ECF0),
          alignment: Alignment.center,
          child: const Icon(Icons.broken_image_outlined),
        ),
      );
    } else {
      image = Container(
        width: size,
        height: size,
        color: const Color(0xFFE8ECF0),
        alignment: Alignment.center,
        child: const Icon(Icons.image_outlined),
      );
    }
    return Stack(
      clipBehavior: Clip.none,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: image,
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
    this.fileSizeBytes,
  });

  final double size;
  final Duration? duration;
  final int? fileSizeBytes;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final d = duration;
    final timeLabel = d == null
        ? null
        : '${d.inMinutes}:${d.inSeconds.remainder(60).toString().padLeft(2, '0')}';
    final sizeLabel =
        fileSizeBytes != null && fileSizeBytes! > 0 ? formatFileSize(fileSizeBytes!) : null;
    final parts = <String>[
      ?timeLabel,
      ?sizeLabel,
    ];
    final label = parts.isEmpty ? '视频' : parts.join(' · ');
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
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                ),
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
    this.onCamera,
    this.onGallery,
    this.onRecordVideo,
    this.onPickVideo,
  });

  final double size;
  final VoidCallback? onCamera;
  final VoidCallback? onGallery;
  final VoidCallback? onRecordVideo;
  final VoidCallback? onPickVideo;

  Future<void> _showAddSheet(BuildContext context) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _AddMediaSheet(
        allowImage: onCamera != null || onGallery != null,
        allowVideo: onRecordVideo != null || onPickVideo != null,
      ),
    );
    _handleAction(action);
  }

  void _handleAction(String? action) {
    switch (action) {
      case 'camera':
        onCamera?.call();
      case 'gallery':
        onGallery?.call();
      case 'record':
        onRecordVideo?.call();
      case 'pick_video':
        onPickVideo?.call();
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
    return GestureDetector(
      onTap: () => _showAddSheet(context),
      child: _buildTile(),
    );
  }
}

class _AddMediaSheet extends StatelessWidget {
  const _AddMediaSheet({
    this.allowImage = true,
    this.allowVideo = true,
  });

  final bool allowImage;
  final bool allowVideo;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      padding: EdgeInsets.fromLTRB(20, 12, 20, 16 + bottom),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppColors.inkFaint.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          Text(
            '添加打卡内容',
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '最多 3 张图 + 1 段视频',
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.inkMuted,
            ),
          ),
          const SizedBox(height: 20),
          if (allowImage)
            Row(
              children: [
                Expanded(
                  child: _AddMediaOption(
                    icon: Icons.photo_camera_rounded,
                    label: '拍照',
                    hint: '现场拍一张',
                    tint: AppColors.brand,
                    soft: AppColors.brandSoft,
                    value: 'camera',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _AddMediaOption(
                    icon: Icons.photo_library_rounded,
                    label: '相册照片',
                    hint: '可多选',
                    tint: AppColors.accentLeaf,
                    soft: const Color(0xFFE8F6EC),
                    value: 'gallery',
                  ),
                ),
              ],
            ),
          if (allowImage && allowVideo) const SizedBox(height: 12),
          if (allowVideo)
            Row(
              children: [
                Expanded(
                  child: _AddMediaOption(
                    icon: Icons.videocam_rounded,
                    label: '录视频',
                    hint: '最长 2 分钟',
                    tint: AppColors.accentSun,
                    soft: const Color(0xFFFFF1E6),
                    value: 'record',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _AddMediaOption(
                    icon: Icons.video_library_rounded,
                    label: '相册视频',
                    hint: '≤50MB',
                    tint: const Color(0xFF5B8DEF),
                    soft: const Color(0xFFEEF3FC),
                    value: 'pick_video',
                  ),
                ),
              ],
            ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              '取消',
              style: GoogleFonts.nunito(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.inkMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddMediaOption extends StatelessWidget {
  const _AddMediaOption({
    required this.icon,
    required this.label,
    required this.hint,
    required this.tint,
    required this.soft,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String hint;
  final Color tint;
  final Color soft;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: soft,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: () => Navigator.pop(context, value),
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
          child: Column(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: tint, size: 28),
              ),
              const SizedBox(height: 12),
              Text(
                label,
                style: GoogleFonts.nunito(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                hint,
                style: GoogleFonts.nunito(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.inkFaint,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
