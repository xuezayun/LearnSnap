import 'dart:io';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../core/device_layout.dart';
import '../../core/media_url.dart';

class VideoPreviewPage extends StatefulWidget {
  const VideoPreviewPage({
    super.key,
    this.filePath,
    this.networkUrl,
    this.previewOnly = false,
  }) : assert(
          (filePath != null && filePath.length > 0) ||
              (networkUrl != null && networkUrl.length > 0),
          'filePath or networkUrl required',
        );

  final String? filePath;
  final String? networkUrl;
  final bool previewOnly;

  @override
  State<VideoPreviewPage> createState() => _VideoPreviewPageState();
}

class _VideoPreviewPageState extends State<VideoPreviewPage> {
  VideoPlayerController? _controller;
  bool _ready = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      final VideoPlayerController controller;
      final net = widget.networkUrl?.trim();
      if (net != null && net.isNotEmpty) {
        controller = VideoPlayerController.networkUrl(parseMediaUri(net));
      } else {
        controller = VideoPlayerController.file(File(widget.filePath!));
      }
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() {
        _controller = controller;
        _ready = true;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = '视频加载失败，请检查网络或重新提交该视频');
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final maxVideoWidth = isTablet(context) ? 900.0 : double.infinity;

    return Scaffold(
      appBar: AppBar(title: Text(widget.previewOnly ? '预览视频' : '确认视频')),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: _error != null
                  ? Padding(
                      padding: EdgeInsets.symmetric(horizontal: pagePadding(context)),
                      child: Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.redAccent),
                      ),
                    )
                  : !_ready
                      ? const CircularProgressIndicator()
                      : ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: maxVideoWidth),
                          child: AspectRatio(
                            aspectRatio: _controller!.value.aspectRatio,
                            child: VideoPlayer(_controller!),
                          ),
                        ),
            ),
          ),
          if (_ready)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: pagePadding(context)),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxVideoWidth),
                child: VideoProgressIndicator(_controller!, allowScrubbing: true),
              ),
            ),
          AdaptiveBottomBar(
            child: widget.previewOnly
                ? SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () => Navigator.pop(context),
                      style: FilledButton.styleFrom(
                        minimumSize: Size(double.infinity, primaryButtonHeight(context)),
                      ),
                      child: const Text('关闭'),
                    ),
                  )
                : Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context, false),
                          style: OutlinedButton.styleFrom(
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
          ),
        ],
      ),
      floatingActionButton: _ready
          ? FloatingActionButton(
              onPressed: () {
                final c = _controller!;
                setState(() {
                  c.value.isPlaying ? c.pause() : c.play();
                });
              },
              child: Icon(
                _controller!.value.isPlaying ? Icons.pause : Icons.play_arrow,
              ),
            )
          : null,
    );
  }
}
