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

  Future<void> _openAddSheet() async {
    final adder = _AddButton(
      size: double.infinity,
      onCamera:
          _imageCount < checkinMaxImages ? () => _addPhoto(ImageSource.camera) : null,
      onGallery:
          _imageCount < checkinMaxImages ? () => _addPhoto(ImageSource.gallery) : null,
      onRecordVideo: _videoCount < checkinMaxVideos ? _recordVideo : null,
      onPickVideo: _videoCount < checkinMaxVideos ? _pickVideo : null,
    );
    await adder.showSheet(context);
  }

  @override
  Widget build(BuildContext context) {
    final tablet = isTablet(context);
    final canAddMore =
        _imageCount < checkinMaxImages || _videoCount < checkinMaxVideos;
    final itemCount = _media.length + (canAddMore ? 1 : 0);
    final pad = pagePadding(context);

    return Scaffold(
      extendBodyBehindAppBar: false,
      appBar: AppBar(
        title: Text(widget.revise ? '修订打卡' : '习惯打卡'),
      ),
      body: AppScaffoldBackground(
        child: Column(
          children: [
            Expanded(
              child: AdaptiveBody(
                padding: EdgeInsets.fromLTRB(pad, pad, pad, 0),
                child: CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
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
                            widget.title,
                            style: GoogleFonts.nunito(
                              fontSize: tablet ? 26 : 22,
                              fontWeight: FontWeight.w800,
                              color: AppColors.ink,
                              height: 1.25,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            widget.revise ? '更新今日打卡内容' : '记录你的学习成果',
                            style: GoogleFonts.nunito(
                              fontSize: tablet ? 16 : 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.inkMuted,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _QuotaBar(
                            imageCount: _imageCount,
                            videoCount: _videoCount,
                            maxImages: checkinMaxImages,
                            maxVideos: checkinMaxVideos,
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                    if (_loadingExisting)
                      const SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (_media.isEmpty && canAddMore)
                      SliverToBoxAdapter(
                        child: _EmptyMediaCard(onAdd: _openAddSheet),
                      )
                    else
                      SliverGrid(
                        gridDelegate: mediaGridDelegate(context),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            if (index == _media.length) {
                              return _AddButton(
                                size: double.infinity,
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
                                bytes: item.bytes,
                                remoteUrl: item.remoteUrl,
                                onRemove: () =>
                                    setState(() => _media.removeAt(index)),
                              );
                            }
                            return _VideoThumb(
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
                              onRemove: () =>
                                  setState(() => _media.removeAt(index)),
                            );
                          },
                          childCount: itemCount,
                        ),
                      ),
                    if (_error != null)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: _ErrorBanner(message: _error!),
                        ),
                      ),
                    const SliverToBoxAdapter(child: SizedBox(height: 24)),
                  ],
                ),
              ),
            ),
            AdaptiveBottomBar(
              child: FilledButton(
                onPressed:
                    (_submitting || _loadingExisting || _media.isEmpty)
                        ? null
                        : _submit,
                style: FilledButton.styleFrom(
                  minimumSize:
                      Size(double.infinity, primaryButtonHeight(context)),
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
    required this.onRemove,
    this.bytes,
    this.remoteUrl,
  });

  final Uint8List? bytes;
  final String? remoteUrl;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final Widget image;
    if (bytes != null) {
      image = Image.memory(bytes!, fit: BoxFit.cover);
    } else if (remoteUrl != null && remoteUrl!.isNotEmpty) {
      image = Image.network(
        sanitizeMediaUrl(remoteUrl!),
        fit: BoxFit.cover,
        errorBuilder: (_, error, stackTrace) => ColoredBox(
          color: const Color(0xFFE8ECF0),
          child: Center(
            child: Icon(Icons.broken_image_outlined, color: AppColors.inkFaint),
          ),
        ),
      );
    } else {
      image = ColoredBox(
        color: const Color(0xFFE8ECF0),
        child: Center(
          child: Icon(Icons.image_outlined, color: AppColors.inkFaint),
        ),
      );
    }
    return Stack(
      fit: StackFit.expand,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: image,
        ),
        Positioned(
          top: 6,
          right: 6,
          child: _RemoveBtn(onRemove: onRemove),
        ),
      ],
    );
  }
}

class _VideoThumb extends StatelessWidget {
  const _VideoThumb({
    required this.duration,
    required this.onTap,
    required this.onRemove,
    this.fileSizeBytes,
  });

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
      if (timeLabel != null) timeLabel,
      if (sizeLabel != null) sizeLabel,
    ];
    final label = parts.isEmpty ? '视频' : parts.join(' · ');
    final iconSize = isTablet(context) ? 40.0 : 34.0;
    return Stack(
      fit: StackFit.expand,
      children: [
        Material(
          color: const Color(0xFF1A2A2E),
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.play_circle_fill_rounded,
                    color: Colors.white, size: iconSize),
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
          ),
        ),
        Positioned(
          top: 6,
          right: 6,
          child: _RemoveBtn(onRemove: onRemove),
        ),
      ],
    );
  }
}

class _RemoveBtn extends StatelessWidget {
  const _RemoveBtn({required this.onRemove});

  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 2,
      shadowColor: AppColors.ink.withValues(alpha: 0.2),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onRemove,
        child: const Padding(
          padding: EdgeInsets.all(6),
          child: Icon(Icons.close_rounded, size: 16, color: AppColors.ink),
        ),
      ),
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

  Future<void> showSheet(BuildContext context) async {
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

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.brandSoft,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () => showSheet(context),
        borderRadius: BorderRadius.circular(16),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.brand.withValues(alpha: 0.35),
              width: 1.5,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.add_photo_alternate_outlined,
                size: size == double.infinity
                    ? (isTablet(context) ? 36 : 30)
                    : (size >= 140 ? 32 : 24),
                color: AppColors.brandDeep,
              ),
              const SizedBox(height: 8),
              Text(
                '添加',
                style: GoogleFonts.nunito(
                  fontSize: isTablet(context) ? 15 : 13,
                  fontWeight: FontWeight.w800,
                  color: AppColors.brandDeep,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuotaBar extends StatelessWidget {
  const _QuotaBar({
    required this.imageCount,
    required this.videoCount,
    required this.maxImages,
    required this.maxVideos,
  });

  final int imageCount;
  final int videoCount;
  final int maxImages;
  final int maxVideos;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _QuotaChip(
          icon: Icons.photo_outlined,
          label: '图片 $imageCount/$maxImages',
          active: imageCount > 0,
        ),
        _QuotaChip(
          icon: Icons.videocam_outlined,
          label: '视频 $videoCount/$maxVideos',
          active: videoCount > 0,
        ),
        _QuotaChip(
          icon: Icons.timer_outlined,
          label: '≤2分钟·处理后≤50MB',
          active: false,
          muted: true,
        ),
      ],
    );
  }
}

class _QuotaChip extends StatelessWidget {
  const _QuotaChip({
    required this.icon,
    required this.label,
    required this.active,
    this.muted = false,
  });

  final IconData icon;
  final String label;
  final bool active;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final bg = muted
        ? const Color(0xFFF0F3F5)
        : (active ? AppColors.brandSoft : Colors.white);
    final fg = muted
        ? AppColors.inkFaint
        : (active ? AppColors.brandDeep : AppColors.inkMuted);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: muted
              ? Colors.transparent
              : (active
                  ? AppColors.brand.withValues(alpha: 0.25)
                  : const Color(0xFFE2E8EC)),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: fg),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.nunito(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyMediaCard extends StatelessWidget {
  const _EmptyMediaCard({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final tablet = isTablet(context);
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onAdd,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            horizontal: 24,
            vertical: tablet ? 48 : 36,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: AppColors.brand.withValues(alpha: 0.28),
              width: 1.5,
            ),
          ),
          child: Column(
            children: [
              Container(
                width: tablet ? 72 : 64,
                height: tablet ? 72 : 64,
                decoration: const BoxDecoration(
                  color: AppColors.brandSoft,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.camera_alt_rounded,
                  size: tablet ? 34 : 30,
                  color: AppColors.brandDeep,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '添加照片或视频',
                style: GoogleFonts.nunito(
                  fontSize: tablet ? 20 : 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '拍照 / 相册 / 录像，点这里开始',
                textAlign: TextAlign.center,
                style: GoogleFonts.nunito(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.inkMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline_rounded,
              color: AppColors.danger, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.nunito(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.danger,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
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
            '最多 $checkinMaxImages 张图 + $checkinMaxVideos 段视频',
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
                    hint: '≤2分钟 · 处理后≤50MB',
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

