import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/app_colors.dart';
import '../../widgets/app_scaffold_bg.dart';
import '../dictation/dictation_settings.dart';
import '../dictation/dictation_words.dart';
import 'oral_math.dart';

class OralPlayPage extends StatefulWidget {
  const OralPlayPage({
    super.key,
    required this.problems,
    required this.repeats,
    required this.gapSeconds,
    required this.pace,
  });

  final List<OralProblem> problems;
  final int repeats;
  final int gapSeconds;
  final DictationPace pace;

  @override
  State<OralPlayPage> createState() => _OralPlayPageState();
}

class _OralPlayPageState extends State<OralPlayPage> {
  final _tts = FlutterTts();
  final _listController = ScrollController();
  var _ready = false;
  var _playing = false;
  var _showText = false;
  var _index = 0;
  var _repeat = 0;
  var _gapLeft = 0;
  var _token = 0;
  String? _error;

  @override
  void initState() {
    super.initState();
    _prepare();
  }

  Future<void> _prepare() async {
    try {
      await _tts.awaitSpeakCompletion(true);
      await _tts.setLanguage('zh-CN');
      await _tts.setVolume(1);
      if (!mounted) return;
      setState(() => _ready = true);
      await _jump(0);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = '这台设备暂时读不出来，请到系统设置里检查文字转语音');
    }
  }

  @override
  void dispose() {
    _token += 1;
    _tts.stop();
    _listController.dispose();
    super.dispose();
  }

  Future<void> _speak(String text) async {
    await _tts.setSpeechRate(
      speechRateForPlatform(relative: widget.pace.relative, ios: Platform.isIOS),
    );
    await _tts.speak(text);
  }

  Future<bool> _wait(int token, Duration duration) async {
    var left = duration.inMilliseconds;
    if (mounted) setState(() => _gapLeft = (left / 1000).ceil());
    while (left > 0) {
      if (!mounted || token != _token) return false;
      final slice = left < 200 ? left : 200;
      await Future<void>.delayed(Duration(milliseconds: slice));
      left -= slice;
      if (mounted && token == _token) {
        setState(() => _gapLeft = (left / 1000).ceil());
      }
    }
    if (mounted && token == _token) setState(() => _gapLeft = 0);
    return mounted && token == _token;
  }

  Future<void> _jump(int index) async {
    if (widget.problems.isEmpty) return;
    _token += 1;
    final token = _token;
    await _tts.stop();
    if (!mounted || token != _token) return;
    final start = index.clamp(0, widget.problems.length - 1);
    setState(() {
      _playing = true;
      _index = start;
      _error = null;
      _gapLeft = 0;
    });
    for (var i = start; i < widget.problems.length; i++) {
      if (!mounted || token != _token) return;
      setState(() {
        _index = i;
        _repeat = 0;
        _gapLeft = 0;
      });
      _revealCurrent();
      for (var round = 0; round < widget.repeats; round++) {
        if (!mounted || token != _token) return;
        setState(() => _repeat = round + 1);
        try {
          await _speak(widget.problems[i].spoken);
        } catch (_) {
          if (!mounted || token != _token) return;
          setState(() {
            _playing = false;
            _error = '朗读中断了，请检查系统里的中文语音。';
          });
          return;
        }
        if (!mounted || token != _token) return;
        if (round + 1 < widget.repeats) {
          final ok = await _wait(token, const Duration(milliseconds: 700));
          if (!ok) return;
        }
      }
      if (i + 1 < widget.problems.length) {
        final ok = await _wait(token, Duration(seconds: widget.gapSeconds));
        if (!ok) return;
      }
    }
    if (!mounted || token != _token) return;
    setState(() => _playing = false);
  }

  Future<void> _pause() async {
    _token += 1;
    await _tts.stop();
    if (!mounted) return;
    setState(() {
      _playing = false;
      _gapLeft = 0;
    });
  }

  void _revealCurrent() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_listController.hasClients) return;
      const extent = 64.0;
      final next = (_index * extent).clamp(0.0, _listController.position.maxScrollExtent);
      _listController.animateTo(
        next,
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.problems.length;
    final current = total == 0 ? null : widget.problems[_index];
    final done = !_playing && _ready && total > 0 && _index == total - 1 && _repeat >= widget.repeats;
    return Scaffold(
      appBar: AppBar(
        title: const Text('听算'),
        actions: [
          TextButton(
            onPressed: () => setState(() => _showText = !_showText),
            child: Text(_showText ? '隐藏算式' : '显示算式'),
          ),
        ],
      ),
      body: AppScaffoldBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Column(
              children: [
                Text(
                  total == 0 ? '没有题目' : '第 ${_index + 1} / $total 题',
                  style: GoogleFonts.nunito(
                    fontWeight: FontWeight.w800,
                    color: AppColors.inkMuted,
                  ),
                ),
                const SizedBox(height: 10),
                if (_error != null)
                  Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.nunito(
                      fontWeight: FontWeight.w700,
                      color: AppColors.danger,
                      height: 1.4,
                    ),
                  )
                else
                  Text(
                    _showText
                        ? (current?.expression ?? '')
                        : (_gapLeft > 0 ? '写下得数  $_gapLeft' : '听，在纸上写'),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.nunito(
                      fontSize: _showText ? 40 : 28,
                      fontWeight: FontWeight.w800,
                      color: _showText ? AppColors.subjectMath : AppColors.ink,
                      height: 1.2,
                    ),
                  ),
                const SizedBox(height: 6),
                Text(
                  _playing
                      ? (_gapLeft > 0 ? '间隔中' : '第 $_repeat / ${widget.repeats} 遍')
                      : (done ? '这一组听完了' : '已暂停'),
                  style: GoogleFonts.nunito(
                    fontWeight: FontWeight.w700,
                    color: AppColors.inkMuted,
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView.builder(
                    controller: _listController,
                    itemExtent: 64,
                    itemCount: total,
                    itemBuilder: (context, i) {
                      final active = i == _index;
                      final passed = i < _index || (done && i == _index);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Material(
                          color: active ? const Color(0xFFF3EEFF) : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          child: InkWell(
                            onTap: !_ready ? null : () => _jump(i),
                            borderRadius: BorderRadius.circular(14),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: active ? AppColors.subjectMath : AppColors.brandSoft,
                                  width: active ? 2 : 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 36,
                                    child: Text(
                                      '${i + 1}',
                                      style: GoogleFonts.nunito(
                                        fontWeight: FontWeight.w800,
                                        color: active ? AppColors.subjectMath : AppColors.inkFaint,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      _showText ? widget.problems[i].expression : '第 ${i + 1} 题',
                                      style: GoogleFonts.nunito(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800,
                                        color: passed && !active ? AppColors.inkMuted : AppColors.ink,
                                      ),
                                    ),
                                  ),
                                  if (active)
                                    Text(
                                      _playing ? '正在听' : (done ? '听完' : '暂停'),
                                      style: GoogleFonts.nunito(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.subjectMath,
                                      ),
                                    )
                                  else if (passed)
                                    const Icon(Icons.check_rounded, size: 18, color: AppColors.success),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton.filledTonal(
                      onPressed: !_ready || _index <= 0 ? null : () => _jump(_index - 1),
                      icon: const Icon(Icons.skip_previous_rounded),
                    ),
                    const SizedBox(width: 12),
                    IconButton.filled(
                      iconSize: 36,
                      onPressed: !_ready
                          ? null
                          : () {
                              if (_playing) {
                                _pause();
                              } else {
                                _jump(done ? 0 : _index);
                              }
                            },
                      icon: Icon(_playing ? Icons.pause_rounded : Icons.play_arrow_rounded),
                    ),
                    const SizedBox(width: 12),
                    IconButton.filledTonal(
                      onPressed: !_ready || _index >= total - 1 ? null : () => _jump(_index + 1),
                      icon: const Icon(Icons.skip_next_rounded),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
