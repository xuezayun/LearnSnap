import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/app_colors.dart';
import '../../widgets/app_scaffold_bg.dart';
import 'dictation_settings.dart';
import 'dictation_words.dart';

class DictationPlayPage extends StatefulWidget {
  const DictationPlayPage({
    super.key,
    required this.words,
    required this.repeats,
    required this.gapSeconds,
    required this.pace,
  });

  final List<String> words;
  final int repeats;
  final int gapSeconds;
  final DictationPace pace;

  @override
  State<DictationPlayPage> createState() => _DictationPlayPageState();
}

class _DictationPlayPageState extends State<DictationPlayPage> {
  final _tts = FlutterTts();
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
      await _tts.setVolume(1);
      if (!mounted) return;
      setState(() => _ready = true);
      await _jump(0);
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = '这台设备暂时读不出来，请到系统设置里检查文字转语音');
    }
  }

  @override
  void dispose() {
    _token += 1;
    _tts.stop();
    super.dispose();
  }

  Future<void> _speak(String text) async {
    final chinese = prefersChineseVoice(text);
    final language = chinese ? 'zh-CN' : 'en-US';
    await _tts.setLanguage(language);
    await _tts.setSpeechRate(
      speechRateForPlatform(relative: widget.pace.relative, ios: Platform.isIOS),
    );
    await _tts.speak(text);
  }

  Future<bool> _wait(int token, Duration duration) async {
    var left = duration.inMilliseconds;
    if (mounted) {
      setState(() => _gapLeft = (left / 1000).ceil());
    }
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
    if (widget.words.isEmpty) return;
    _token += 1;
    final token = _token;
    await _tts.stop();
    if (!mounted || token != _token) return;
    final start = index.clamp(0, widget.words.length - 1);
    setState(() {
      _playing = true;
      _index = start;
      _error = null;
      _gapLeft = 0;
    });
    for (var i = start; i < widget.words.length; i++) {
      if (!mounted || token != _token) return;
      setState(() {
        _index = i;
        _repeat = 0;
        _gapLeft = 0;
      });
      for (var round = 0; round < widget.repeats; round++) {
        if (!mounted || token != _token) return;
        setState(() => _repeat = round + 1);
        try {
          await _speak(widget.words[i]);
        } catch (_) {
          if (!mounted || token != _token) return;
          setState(() {
            _playing = false;
            _error = '朗读中断了。若是英语，请在系统设置里下载英文语音。';
          });
          return;
        }
        if (!mounted || token != _token) return;
        if (round + 1 < widget.repeats) {
          final ok = await _wait(token, const Duration(milliseconds: 700));
          if (!ok) return;
        }
      }
      if (i + 1 < widget.words.length) {
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

  @override
  Widget build(BuildContext context) {
    final total = widget.words.length;
    final word = total == 0 ? '' : widget.words[_index];
    final done = !_playing && _ready && _index == total - 1 && _repeat >= widget.repeats;
    return Scaffold(
      appBar: AppBar(
        title: const Text('听写'),
        actions: [
          TextButton(
            onPressed: () => setState(() => _showText = !_showText),
            child: Text(_showText ? '隐藏词语' : '显示词语'),
          ),
        ],
      ),
      body: AppScaffoldBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
            child: Column(
              children: [
                Text(
                  total == 0 ? '没有词语' : '第 ${_index + 1} / $total 个',
                  style: GoogleFonts.nunito(
                    fontWeight: FontWeight.w800,
                    color: AppColors.inkMuted,
                  ),
                ),
                const Spacer(),
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
                else if (_showText)
                  Text(
                    word,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.nunito(
                      fontSize: 56,
                      fontWeight: FontWeight.w800,
                      color: AppColors.brandDeep,
                      height: 1.2,
                    ),
                  )
                else
                  Text(
                    _gapLeft > 0 ? '写下刚才的词\n$_gapLeft' : '听，先不要看',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.nunito(
                      fontSize: 36,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                      height: 1.3,
                    ),
                  ),
                const SizedBox(height: 16),
                Text(
                  _playing
                      ? (_gapLeft > 0 ? '间隔中' : '第 $_repeat / ${widget.repeats} 遍')
                      : (done ? '这一列读完了' : '已暂停'),
                  style: GoogleFonts.nunito(
                    fontWeight: FontWeight.w700,
                    color: AppColors.inkMuted,
                  ),
                ),
                const Spacer(),
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
                      icon: Icon(
                        _playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                      ),
                    ),
                    const SizedBox(width: 12),
                    IconButton.filledTonal(
                      onPressed: !_ready || _index >= total - 1
                          ? null
                          : () => _jump(_index + 1),
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
