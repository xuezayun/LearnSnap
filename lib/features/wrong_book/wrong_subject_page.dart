import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/api_client.dart';
import '../../services/learn_snap_api.dart';
import '../../theme/app_colors.dart';
import 'wrong_book_repository.dart';
import 'wrong_capture.dart';
import 'wrong_edit_page.dart';
import 'wrong_item.dart';
import 'wrong_photo_page.dart';

class WrongSubjectPage extends StatefulWidget {
  const WrongSubjectPage({
    super.key,
    required this.subject,
    required this.childId,
    required this.repository,
    required this.readItems,
    required this.onChanged,
  });

  final String subject;
  final int childId;
  final WrongBookRepository repository;
  final List<WrongItem> Function() readItems;
  final Future<void> Function() onChanged;

  @override
  State<WrongSubjectPage> createState() => _WrongSubjectPageState();
}

enum _WrongSpan { all, week, month, custom }

class _WrongSubjectPageState extends State<WrongSubjectPage> {
  _WrongSpan _span = _WrongSpan.all;
  DateTime? _customStart;
  DateTime? _customEnd;

  (DateTime?, DateTime?) get _activeRange {
    final today = wrongItemDay(DateTime.now());
    switch (_span) {
      case _WrongSpan.week:
        return (today.subtract(const Duration(days: 6)), today);
      case _WrongSpan.month:
        return (today.subtract(const Duration(days: 29)), today);
      case _WrongSpan.custom:
        return (_customStart, _customEnd);
      case _WrongSpan.all:
        return (null, null);
    }
  }

  List<WrongItem> get _photos {
    final range = _activeRange;
    return filterWrongItemsBySubject(
      widget.readItems(),
      subject: widget.subject,
      start: range.$1,
      end: range.$2,
    );
  }

  String _ymd(DateTime value) {
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '${value.year}-$month-$day';
  }

  Future<void> _printFiltered() async {
    if (_photos.isEmpty) return;
    final range = _activeRange;
    try {
      final bytes = await LearnSnapApi().downloadWrongBookPdf(
        childId: widget.childId,
        subject: widget.subject,
        start: range.$1 == null ? null : _ymd(range.$1!),
        end: range.$2 == null ? null : _ymd(range.$2!),
      );
      final dir = await getTemporaryDirectory();
      final file = File(p.join(dir.path, 'wrong-book-${widget.subject}.pdf'));
      await file.writeAsBytes(bytes, flush: true);
      if (!mounted) return;
      await Share.shareXFiles([XFile(file.path)], text: '${wrongSubjectLabel(widget.subject)}错题本');
    } catch (error) {
      if (!mounted) return;
      final message = error is ApiException ? error.message : '打印文件没有生成';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  String get _rangeLabel {
    if (_span != _WrongSpan.custom || _customStart == null || _customEnd == null) {
      return '';
    }
    String day(DateTime value) =>
        '${value.month}月${value.day}日';
    return '${day(_customStart!)} – ${day(_customEnd!)}';
  }

  Future<void> _pickRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 3),
      lastDate: DateTime(now.year, now.month, now.day),
      initialDateRange: _customStart != null && _customEnd != null
          ? DateTimeRange(start: _customStart!, end: _customEnd!)
          : null,
    );
    if (picked == null || !mounted) return;
    setState(() {
      _span = _WrongSpan.custom;
      _customStart = picked.start;
      _customEnd = picked.end;
    });
  }

  Future<void> _openPhoto(WrongItem item) async {
    final file = File(item.localPath);
    if (!file.existsSync()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('照片还在同步，稍后再看')),
      );
      return;
    }
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (photoContext) => WrongPhotoPage(
          item: item,
          onEdit: () async {
            Navigator.of(photoContext).pop();
            await _edit(item);
          },
        ),
      ),
    );
  }

  Future<void> _edit(WrongItem item) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => WrongEditPage(
          childId: widget.childId,
          repository: widget.repository,
          existing: item,
        ),
      ),
    );
    if (saved == true) await _reload();
  }

  Future<void> _reload() async {
    await widget.onChanged();
    if (mounted) setState(() {});
  }

  Future<void> _add() async {
    final source = await pickWrongImageSource(context);
    if (source == null || !mounted) return;
    final saved = await captureWrongItem(
      context: context,
      childId: widget.childId,
      repository: widget.repository,
      source: source,
      subject: widget.subject,
    );
    if (saved) await _reload();
  }

  @override
  Widget build(BuildContext context) {
    final photos = _photos;
    return Scaffold(
      appBar: AppBar(
        title: Text(wrongSubjectLabel(widget.subject)),
        actions: [
          IconButton(
            onPressed: _photos.isEmpty ? null : _printFiltered,
            icon: const Icon(Icons.print_rounded),
            tooltip: '打印当前筛选',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _add,
        icon: const Icon(Icons.add_a_photo_rounded),
        label: const Text('收录'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              children: [
                _chip('全部', _WrongSpan.all),
                _chip('近7天', _WrongSpan.week),
                _chip('近30天', _WrongSpan.month),
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: const Text('自定义'),
                    selected: _span == _WrongSpan.custom,
                    onSelected: (_) => _pickRange(),
                  ),
                ),
              ],
            ),
          ),
          if (_rangeLabel.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
              child: Text(
                _rangeLabel,
                style: GoogleFonts.nunito(fontSize: 13, color: AppColors.inkMuted),
              ),
            ),
          Expanded(
            child: photos.isEmpty
                ? const Center(child: Text('这个时间里还没有错题照片'))
                : GridView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 96),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      mainAxisSpacing: 6,
                      crossAxisSpacing: 6,
                    ),
                    itemCount: photos.length,
                    itemBuilder: (context, index) {
                      final item = photos[index];
                      final file = File(item.localPath);
                      final note = item.note.trim();
                      return GestureDetector(
                        onTap: () => _openPhoto(item),
                        onLongPress: () => _edit(item),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: ColoredBox(
                            color: AppColors.brandSoft,
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                if (file.existsSync())
                                  Image.file(file, fit: BoxFit.cover)
                                else
                                  const Center(
                                    child: Icon(Icons.image_outlined, color: AppColors.inkFaint),
                                  ),
                                if (note.isNotEmpty)
                                  Positioned(
                                    left: 0,
                                    right: 0,
                                    bottom: 0,
                                    child: ColoredBox(
                                      color: const Color(0xC01F2A2E),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                        child: Text(
                                          note,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 11,
                                            height: 1.25,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, _WrongSpan span) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: _span == span,
        onSelected: (_) => setState(() => _span = span),
      ),
    );
  }
}
