import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

import '../../core/api_client.dart';
import '../../core/checkin_media_cache.dart';
import '../../core/device_layout.dart';
import '../../core/media_url.dart';

class VideoPreviewPage extends StatefulWidget {
  const VideoPreviewPage({
    super.key,
    this.filePath,
    this.networkUrl,
    this.mediaId,
    this.objectKey,
    this.previewOnly = false,
  }) : assert(
          (filePath != null && filePath.length > 0) ||
              (networkUrl != null && networkUrl.length > 0) ||
              (mediaId != null && mediaId > 0),
          'filePath, networkUrl or mediaId required',
        );

  final String? filePath;
  final String? networkUrl;
  final int? mediaId;
  final String? objectKey;
  final bool previewOnly;

  @override
  State<VideoPreviewPage> createState() => _VideoPreviewPageState();
}

class _VideoPreviewPageState extends State<VideoPreviewPage> {
  VideoPlayerController? _controller;
  bool _ready = false;
  String? _error;
  bool _playing = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      final controller = await _createController();
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      controller.addListener(_onPlaybackTick);
      await controller.play();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() {
        _controller = controller;
        _ready = true;
        _playing = controller.value.isPlaying;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = '视频加载失败，请检查网络或重新提交该视频');
    }
  }

  Future<VideoPlayerController> _createController() async {
    final local = widget.filePath?.trim() ?? '';
    if (local.isNotEmpty && await File(local).exists()) {
      return VideoPlayerController.file(File(local));
    }

    final id = widget.mediaId ?? 0;
    final key = widget.objectKey?.trim() ?? '';
    final cached = await CheckinMediaCache.pathFor(mediaId: id, objectKey: key);
    if (cached != null) {
      return VideoPlayerController.file(File(cached));
    }

    if (id > 0) {
      final bytes = await ApiClient().getBytes('/checkins/media/$id/content');
      await CheckinMediaCache.putBytes(bytes, mediaId: id, objectKey: key);
      final path = await CheckinMediaCache.pathFor(mediaId: id, objectKey: key);
      if (path != null) {
        return VideoPlayerController.file(File(path));
      }
    }

    final net = widget.networkUrl?.trim() ?? '';
    if (net.isNotEmpty) {
      return VideoPlayerController.networkUrl(parseMediaUri(net));
    }
    throw StateError('no video source');
  }

  void _onPlaybackTick() {
    final playing = _controller?.value.isPlaying ?? false;
    if (playing != _playing && mounted) {
      setState(() => _playing = playing);
    }
  }

  void _togglePlay() {
    final c = _controller;
    if (c == null) return;
    if (c.value.isPlaying) {
      c.pause();
    } else {
      c.play();
    }
  }

  @override
  void dispose() {
    _controller?.removeListener(_onPlaybackTick);
    _controller?.dispose();
    super.dispose();
  }

  Widget _videoLayer() {
    final controller = _controller;
    if (controller == null) {
      return const SizedBox.expand();
    }
    final size = controller.value.size;
    final width = size.width > 0 ? size.width : 16.0;
    final height = size.height > 0 ? size.height : 9.0;
    return SizedBox.expand(
      child: FittedBox(
        fit: BoxFit.contain,
        child: SizedBox(
          width: width,
          height: height,
          child: VideoPlayer(controller),
        ),
      ),
    );
  }

  Widget _topBar() {
    return Row(
      children: [
        IconButton(
          onPressed: () => Navigator.pop(context, widget.previewOnly ? null : false),
          icon: const Icon(Icons.close, color: Colors.white),
          style: IconButton.styleFrom(
            backgroundColor: const Color(0x66000000),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          widget.previewOnly ? '预览视频' : '确认视频',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _bottomBar() {
    final pad = pagePadding(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_ready)
          VideoProgressIndicator(
            _controller!,
            allowScrubbing: true,
            colors: const VideoProgressColors(
              playedColor: Colors.white,
              bufferedColor: Color(0x66FFFFFF),
              backgroundColor: Color(0x33FFFFFF),
            ),
          ),
        const SizedBox(height: 12),
        if (widget.previewOnly)
          Row(
            children: [
              if (_ready) ...[
                _PlayButton(playing: _playing, onPressed: _togglePlay),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: FilledButton(
                  onPressed: () => Navigator.pop(context),
                  style: FilledButton.styleFrom(
                    minimumSize: Size(0, primaryButtonHeight(context)),
                  ),
                  child: const Text('关闭'),
                ),
              ),
            ],
          )
        else
          Row(
            children: [
              if (_ready) ...[
                _PlayButton(playing: _playing, onPressed: _togglePlay),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context, false),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white70),
                    minimumSize: Size(0, primaryButtonHeight(context)),
                  ),
                  child: const Text('重录'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: FilledButton.styleFrom(
                    minimumSize: Size(0, primaryButtonHeight(context)),
                  ),
                  child: const Text('使用此视频'),
                ),
              ),
            ],
          ),
        SizedBox(height: pad > 16 ? 8 : 4),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          fit: StackFit.expand,
          children: [
            if (_error != null)
              Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: pagePadding(context)),
                  child: Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                ),
              )
            else if (!_ready)
              const Center(child: CircularProgressIndicator(color: Colors.white))
            else
              GestureDetector(
                onTap: _togglePlay,
                child: _videoLayer(),
              ),
            SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  pagePadding(context),
                  8,
                  pagePadding(context),
                  8,
                ),
                child: Column(
                  children: [
                    _topBar(),
                    const Spacer(),
                    if (_error == null) _bottomBar(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlayButton extends StatelessWidget {
  const _PlayButton({required this.playing, required this.onPressed});

  final bool playing;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: primaryButtonHeight(context),
      height: primaryButtonHeight(context),
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          padding: EdgeInsets.zero,
          shape: const CircleBorder(),
        ),
        child: Icon(playing ? Icons.pause : Icons.play_arrow),
      ),
    );
  }
}
