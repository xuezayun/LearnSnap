import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/app_colors.dart';
import 'dictation_play_page.dart';
import 'dictation_settings.dart';
import 'dictation_settings_page.dart';
import 'dictation_words.dart';

enum _PickMode { tap, draw }

class DictationSelectPage extends StatefulWidget {
  const DictationSelectPage({
    super.key,
    required this.imagePath,
    required this.words,
    required this.lang,
    required this.initialSettings,
  });

  final String imagePath;
  final List<DictationWord> words;
  final DictationLang lang;
  final DictationSettings initialSettings;

  @override
  State<DictationSelectPage> createState() => _DictationSelectPageState();
}

class _DictationSelectPageState extends State<DictationSelectPage> {
  final _settingsStore = DictationSettingsStore();
  late List<DictationWord> _words = [...widget.words];
  late DictationSettings _settings = widget.initialSettings;
  Size? _imageSize;
  _PickMode _mode = _PickMode.tap;
  List<Offset> _lasso = const [];
  var _nextId = 0;

  @override
  void initState() {
    super.initState();
    _nextId = _words.length;
    _loadImageSize();
  }

  Future<void> _loadImageSize() async {
    final bytes = await File(widget.imagePath).readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    final size = Size(
      frame.image.width.toDouble(),
      frame.image.height.toDouble(),
    );
    frame.image.dispose();
    codec.dispose();
    if (!mounted) return;
    setState(() => _imageSize = size);
  }

  List<DictationWord> get _selected =>
      _words.where((word) => word.selected).toList();

  void _toggleAt(Offset imagePoint) {
    var hit = -1;
    var bestArea = double.infinity;
    for (var i = 0; i < _words.length; i++) {
      final rect = _words[i].rect;
      if (rect.width <= 0 || !rect.contains(imagePoint)) continue;
      final area = rect.width * rect.height;
      if (area < bestArea) {
        bestArea = area;
        hit = i;
      }
    }
    if (hit < 0) return;
    final word = _words[hit];
    setState(() {
      _words[hit] = word.copyWith(selected: !word.selected);
    });
  }

  void _applyLasso(List<Offset> imagePoints) {
    if (imagePoints.length < 3) return;
    final inside = <int>{};
    for (var i = 0; i < _words.length; i++) {
      final rect = _words[i].rect;
      if (rect.width <= 0) continue;
      if (pointInPolygon(rect.center, imagePoints)) inside.add(i);
    }
    if (inside.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('圈里没有认出词语，换一块再画一次')),
      );
      return;
    }
    setState(() {
      _words = [
        for (var i = 0; i < _words.length; i++)
          _words[i].copyWith(selected: inside.contains(i)),
      ];
    });
  }

  Future<void> _addWord() async {
    final text = await showDialog<String>(
      context: context,
      builder: (context) => const _AddWordDialog(),
    );
    final value = text?.trim() ?? '';
    if (value.isEmpty || !mounted) return;
    await Future<void>.delayed(Duration.zero);
    if (!mounted) return;
    setState(() {
      _words = [
        ..._words,
        DictationWord(
          id: 'm$_nextId',
          text: value,
          rect: Rect.zero,
          selected: true,
        ),
      ];
      _nextId += 1;
    });
  }

  void _deleteWord(String id) {
    setState(() {
      _words = [for (final item in _words) if (item.id != id) item];
    });
  }

  Future<void> _openSettings() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => DictationSettingsPage(initial: _settings),
      ),
    );
    if (!mounted) return;
    final fresh = await _settingsStore.load();
    if (!mounted) return;
    setState(() => _settings = fresh);
  }

  void _start() {
    final selected = _selected;
    if (selected.isEmpty) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => DictationPlayPage(
          words: selected.map((word) => word.text).toList(),
          repeats: _settings.repeats,
          gapSeconds: _settings.gapSeconds,
          pace: _settings.pace,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selected = _selected;
    return Scaffold(
      appBar: AppBar(
        title: Text('选出要听的词 · ${selected.length}'),
        actions: [
          TextButton(onPressed: _addWord, child: const Text('补词')),
          PopupMenuButton<String>(
            tooltip: '菜单',
            onSelected: (value) {
              if (value == 'settings') _openSettings();
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'settings', child: Text('朗读设置')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            flex: 5,
            child: _imageSize == null
                ? const Center(child: CircularProgressIndicator())
                : _PhotoBoard(
                    path: widget.imagePath,
                    imageSize: _imageSize!,
                    words: _words,
                    drawing: _mode == _PickMode.draw,
                    lasso: _lasso,
                    onTapImage: _toggleAt,
                    onLasso: (points) {
                      setState(() => _lasso = points);
                    },
                    onLassoEnd: (points) {
                      setState(() => _lasso = const []);
                      _applyLasso(points);
                    },
                  ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Row(
              children: [
                _ModeChip(
                  label: '点选',
                  selected: _mode == _PickMode.tap,
                  onTap: () => setState(() => _mode = _PickMode.tap),
                ),
                const SizedBox(width: 8),
                _ModeChip(
                  label: '圈选',
                  selected: _mode == _PickMode.draw,
                  onTap: () => setState(() => _mode = _PickMode.draw),
                ),
                const Spacer(),
                Text(
                  _mode == _PickMode.tap ? '点一下加上或去掉' : '画出区域，只留里面的词',
                  style: GoogleFonts.nunito(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.inkMuted,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 4,
            child: selected.isEmpty
                ? Center(
                    child: Text(
                      _words.isEmpty ? '没有认出词语，可以点右上角补上' : '还没有选中的词',
                      style: GoogleFonts.nunito(
                        color: AppColors.inkMuted,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  )
                : SingleChildScrollView(
                    primary: false,
                    padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
                    child: Wrap(
                      spacing: 12,
                      runSpacing: 16,
                      children: [
                        for (final word in selected)
                          _WordChip(
                            text: word.text,
                            onDelete: () => _deleteWord(word.id),
                          ),
                      ],
                    ),
                  ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: selected.isEmpty ? null : _start,
                  child: Text('开始朗读（${selected.length}）'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddWordDialog extends StatefulWidget {
  const _AddWordDialog();

  @override
  State<_AddWordDialog> createState() => _AddWordDialogState();
}

class _AddWordDialogState extends State<_AddWordDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final value = _controller.text;
    FocusManager.instance.primaryFocus?.unfocus();
    Navigator.pop(context, value);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('补一个词'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        decoration: const InputDecoration(hintText: '输入没被认出的词语'),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        TextButton(
          onPressed: _submit,
          child: const Text('加入'),
        ),
      ],
    );
  }
}

class _PhotoBoard extends StatelessWidget {
  const _PhotoBoard({
    required this.path,
    required this.imageSize,
    required this.words,
    required this.drawing,
    required this.lasso,
    required this.onTapImage,
    required this.onLasso,
    required this.onLassoEnd,
  });

  final String path;
  final Size imageSize;
  final List<DictationWord> words;
  final bool drawing;
  final List<Offset> lasso;
  final ValueChanged<Offset> onTapImage;
  final ValueChanged<List<Offset>> onLasso;
  final ValueChanged<List<Offset>> onLassoEnd;

  Rect _dest(Size view) {
    final fitted = applyBoxFit(BoxFit.contain, imageSize, view);
    final size = fitted.destination;
    return Rect.fromLTWH(
      (view.width - size.width) / 2,
      (view.height - size.height) / 2,
      size.width,
      size.height,
    );
  }

  Offset _toImage(Offset local, Rect dest) {
    return Offset(
      (local.dx - dest.left) * imageSize.width / dest.width,
      (local.dy - dest.top) * imageSize.height / dest.height,
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final view = Size(constraints.maxWidth, constraints.maxHeight);
        final dest = _dest(view);
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapUp: drawing
              ? null
              : (details) {
                  if (!dest.contains(details.localPosition)) return;
                  onTapImage(_toImage(details.localPosition, dest));
                },
          onPanStart: drawing
              ? (details) {
                  if (!dest.contains(details.localPosition)) return;
                  onLasso([details.localPosition]);
                }
              : null,
          onPanUpdate: drawing
              ? (details) => onLasso([...lasso, details.localPosition])
              : null,
          onPanEnd: drawing
              ? (_) {
                  final imagePoints = [
                    for (final point in lasso)
                      if (dest.contains(point)) _toImage(point, dest),
                  ];
                  onLassoEnd(imagePoints);
                }
              : null,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.file(File(path), fit: BoxFit.contain),
              CustomPaint(
                painter: _WordPainter(
                  words: words,
                  imageSize: imageSize,
                  dest: dest,
                  lasso: lasso,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _WordPainter extends CustomPainter {
  _WordPainter({
    required this.words,
    required this.imageSize,
    required this.dest,
    required this.lasso,
  });

  final List<DictationWord> words;
  final Size imageSize;
  final Rect dest;
  final List<Offset> lasso;

  Rect _toView(Rect rect) {
    final sx = dest.width / imageSize.width;
    final sy = dest.height / imageSize.height;
    return Rect.fromLTRB(
      dest.left + rect.left * sx,
      dest.top + rect.top * sy,
      dest.left + rect.right * sx,
      dest.top + rect.bottom * sy,
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    for (final word in words) {
      if (word.rect.width <= 0) continue;
      final rect = _toView(word.rect);
      final paint = Paint()
        ..style = PaintingStyle.fill
        ..color = word.selected
            ? AppColors.brand.withValues(alpha: 0.28)
            : Colors.white.withValues(alpha: 0.18);
      final border = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = word.selected ? AppColors.brandDeep : Colors.white;
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(4)),
        paint,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(4)),
        border,
      );
    }
    if (lasso.length < 2) return;
    final path = Path()..moveTo(lasso.first.dx, lasso.first.dy);
    for (final point in lasso.skip(1)) {
      path.lineTo(point.dx, point.dy);
    }
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..color = AppColors.accentSun,
    );
  }

  @override
  bool shouldRepaint(covariant _WordPainter oldDelegate) {
    return oldDelegate.words != words ||
        oldDelegate.lasso != lasso ||
        oldDelegate.dest != dest;
  }
}

class _ModeChip extends StatelessWidget {
  const _ModeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: AppColors.brandSoft,
      labelStyle: GoogleFonts.nunito(
        fontWeight: FontWeight.w800,
        color: AppColors.brandDeep,
      ),
    );
  }
}

class _WordChip extends StatelessWidget {
  const _WordChip({required this.text, required this.onDelete});

  final String text;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, right: 10),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFFF9A3C),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              text,
              style: GoogleFonts.nunito(
                color: Colors.black,
                fontWeight: FontWeight.w800,
                fontSize: 32,
                height: 1.2,
              ),
            ),
          ),
          Positioned(
            top: -8,
            right: -8,
            child: GestureDetector(
              onTap: onDelete,
              behavior: HitTestBehavior.opaque,
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF5A3A00), width: 1.5),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x33000000),
                      blurRadius: 2,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.close_rounded,
                  size: 18,
                  color: Color(0xFF3A2A14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
