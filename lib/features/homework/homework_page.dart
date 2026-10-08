import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/learn_snap_api.dart';
import '../../theme/app_colors.dart';
import 'homework.dart';

class HomeworkPage extends StatefulWidget {
  const HomeworkPage({super.key, required this.api, required this.childId});

  final LearnSnapApi api;
  final int childId;

  @override
  State<HomeworkPage> createState() => _HomeworkPageState();
}

class _HomeworkPageState extends State<HomeworkPage> {
  List<HomeworkSheet> _sheets = const [];
  var _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final sheets = await widget.api.fetchHomework(childId: widget.childId);
      if (!mounted) return;
      setState(() {
        _sheets = sheets;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = '作业没有打开';
      });
    }
  }

  Future<void> _toggle(HomeworkItem item) async {
    final next = !item.done;
    setState(() {
      _sheets = [
        for (final sheet in _sheets)
          HomeworkSheet(
            id: sheet.id,
            startDate: sheet.startDate,
            endDate: sheet.endDate,
            items: [
              for (final row in sheet.items)
                row.id == item.id ? row.copyWith(done: next) : row,
            ],
          ),
      ];
    });
    try {
      await widget.api.setHomeworkDone(
        childId: widget.childId,
        itemId: item.id,
        done: next,
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('没有改成，请再试一次')),
      );
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('作业')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : _sheets.isEmpty
                  ? Center(
                      child: Text(
                        '还没有作业',
                        style: GoogleFonts.nunito(
                          fontWeight: FontWeight.w700,
                          color: AppColors.inkMuted,
                        ),
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                      children: [
                        for (final sheet in _sheets) ...[
                          Padding(
                            padding: const EdgeInsets.fromLTRB(4, 8, 4, 4),
                            child: Text(
                              '${sheet.startDate} 至 ${sheet.endDate}',
                              style: GoogleFonts.nunito(
                                fontWeight: FontWeight.w800,
                                color: AppColors.brandDeep,
                              ),
                            ),
                          ),
                          for (final item in sheet.items)
                            CheckboxListTile(
                              value: item.done,
                              onChanged: (_) => _toggle(item),
                              activeColor: AppColors.brand,
                              title: Text(
                                '${item.subjectLabel}｜${item.title}',
                                style: GoogleFonts.nunito(
                                  fontWeight: FontWeight.w700,
                                  decoration: item.done ? TextDecoration.lineThrough : null,
                                  color: item.done ? AppColors.inkFaint : AppColors.ink,
                                ),
                              ),
                            ),
                        ],
                      ],
                    ),
    );
  }
}
