import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../../core/device_layout.dart';
import '../../models/checkin_media.dart';

class VideoRecordResult {
  const VideoRecordResult({required this.filePath, required this.duration});

  final String filePath;
  final Duration duration;
}

class VideoRecordPage extends StatefulWidget {
  const VideoRecordPage({super.key});

  @override
  State<VideoRecordPage> createState() => _VideoRecordPageState();
}

class _VideoRecordPageState extends State<VideoRecordPage> {
  CameraController? _controller;
  bool _initializing = true;
  String? _error;
  bool _recording = false;
  bool _usingFrontCamera = false;
  Duration _elapsed = Duration.zero;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  CameraDescription _pickCamera(List<CameraDescription> cameras) {
    final backs = cameras.where((c) => c.lensDirection == CameraLensDirection.back);
    if (backs.isNotEmpty) return backs.first;
    final fronts = cameras.where((c) => c.lensDirection == CameraLensDirection.front);
    if (fronts.isNotEmpty) return fronts.first;
    return cameras.first;
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() {
          _error = '未找到可用相机';
          _initializing = false;
        });
        return;
      }
      final selected = _pickCamera(cameras);
      final usingFront = selected.lensDirection == CameraLensDirection.front;
      final controller = CameraController(
        selected,
        ResolutionPreset.high,
        enableAudio: true,
      );
      await controller.initialize();
      await controller.prepareForVideoRecording();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() {
        _controller = controller;
        _usingFrontCamera = usingFront;
        _initializing = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = '相机初始化失败，请检查相机与麦克风权限';
        _initializing = false;
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _toggleRecording() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    if (_recording) {
      await _stopRecording();
      return;
    }
    try {
      await controller.startVideoRecording();
      setState(() {
        _recording = true;
        _elapsed = Duration.zero;
      });
      _timer = Timer.periodic(const Duration(seconds: 1), (_) async {
        if (!mounted || !_recording) return;
        final next = _elapsed + const Duration(seconds: 1);
        if (next >= checkinMaxVideoDuration) {
          await _stopRecording();
          return;
        }
        setState(() => _elapsed = next);
      });
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('开始录制失败，请重试')),
        );
      }
    }
  }

  Future<void> _stopRecording() async {
    final controller = _controller;
    if (controller == null || !_recording) return;
    _timer?.cancel();
    _timer = null;
    setState(() => _recording = false);
    try {
      final file = await controller.stopVideoRecording();
      if (!mounted) return;
      Navigator.pop(
        context,
        VideoRecordResult(filePath: file.path, duration: _elapsed),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('停止录制失败，请重试')),
        );
      }
    }
  }

  String _format(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('拍一段小视频'),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_initializing) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(child: Text(_error!, style: const TextStyle(color: Colors.white70)));
    }
    final controller = _controller!;
    final remaining = checkinMaxVideoDuration - _elapsed;
    final tablet = isTablet(context);
    final recordSize = recordButtonSize(context);
    final innerIdle = tablet ? 72.0 : 58.0;
    final innerRecording = tablet ? 32.0 : 28.0;
    final timerFontSize = tablet ? 18.0 : 16.0;

    return Stack(
      fit: StackFit.expand,
      children: [
        CameraPreview(controller),
        Positioned(
          top: 16,
          left: 0,
          right: 0,
          child: Column(
            children: [
              if (_usingFrontCamera)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '正在使用前置摄像头拍摄打卡',
                    style: TextStyle(color: Colors.white, fontSize: timerFontSize),
                    textAlign: TextAlign.center,
                  ),
                ),
              if (_usingFrontCamera) const SizedBox(height: 8),
              Text(
                _recording ? '录制中 ${_format(_elapsed)}' : '最长 2 分钟',
                style: TextStyle(color: Colors.white, fontSize: timerFontSize),
              ),
              if (_recording)
                Text(
                  '剩余 ${_format(remaining.isNegative ? Duration.zero : remaining)}',
                  style: TextStyle(color: Colors.white70, fontSize: timerFontSize - 2),
                ),
            ],
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: tablet ? 48 : 32,
          child: GestureDetector(
            onTap: _toggleRecording,
            child: Center(
              child: Container(
                width: recordSize,
                height: recordSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 4),
                ),
                child: Center(
                  child: Container(
                    width: _recording ? innerRecording : innerIdle,
                    height: _recording ? innerRecording : innerIdle,
                    decoration: BoxDecoration(
                      color: _recording ? Colors.red : Colors.white,
                      borderRadius: BorderRadius.circular(_recording ? 6 : 999),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
