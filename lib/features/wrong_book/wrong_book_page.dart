import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/api_client.dart';
import '../../services/learn_snap_api.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_scaffold_bg.dart';
import 'wrong_book_repository.dart';
import 'wrong_capture.dart';
import 'wrong_item.dart';
import 'wrong_subject_page.dart';

class WrongBookPage extends StatefulWidget {
  const WrongBookPage({super.key, this.api, this.repository});

  final LearnSnapApi? api;
  final WrongBookRepository? repository;

  @override
  State<WrongBookPage> createState() => _WrongBookPageState();
}

class _WrongBookPageState extends State<WrongBookPage> {
  late final LearnSnapApi _api = widget.api ?? LearnSnapApi();
  late final WrongBookRepository _repository = widget.repository ?? WrongBookRepository(api: _api);

  int? _childId;
  List<WrongItem> _items = [];
  bool _loading = true;
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
      final childId = await _api.getChildId();
      if (childId == null) {
        if (!mounted) return;
        setState(() {
          _loading = false;
          _error = '请先绑定孩子账号';
        });
        return;
      }
      final local = await _repository.loadLocal(childId);
      if (mounted) {
        setState(() {
          _childId = childId;
          _items = local;
          _loading = false;
        });
      }
      final synced = await _repository.refresh(childId);
      if (!mounted) return;
      setState(() => _items = synced);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = error is ApiException ? error.message : '错题本暂时没同步上，本机记录还在';
      });
    }
  }

  int _count(String subject) =>
      _items.where((item) => !item.deleted && item.subject == subject).length;

  Future<void> _openSubject(String subject) async {
    final childId = _childId;
    if (childId == null) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => WrongSubjectPage(
          subject: subject,
          childId: childId,
          repository: _repository,
          readItems: () => _items,
          onChanged: _load,
        ),
      ),
    );
  }

  Future<void> _add() async {
    final childId = _childId;
    if (childId == null) return;
    final source = await pickWrongImageSource(context);
    if (source == null || !mounted) return;
    final saved = await captureWrongItem(
      context: context,
      childId: childId,
      repository: _repository,
      source: source,
    );
    if (saved) await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('错题本')),
      floatingActionButton: _childId == null
          ? null
          : FloatingActionButton.extended(
              onPressed: _add,
              icon: const Icon(Icons.add_a_photo_rounded),
              label: const Text('收录'),
            ),
      body: AppScaffoldBackground(
        child: _loading && _items.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _load,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 96),
                  children: [
                    Text(
                      '按学科查看照片，最新的排在前面。',
                      style: GoogleFonts.nunito(fontSize: 14, color: AppColors.inkMuted),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 8),
                      Text(_error!, style: const TextStyle(color: AppColors.inkMuted)),
                    ],
                    const SizedBox(height: 12),
                    for (final subject in wrongSubjects)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Material(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () => _openSubject(subject),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      wrongSubjectLabel(subject),
                                      style: GoogleFonts.nunito(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.ink,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    '${_count(subject)} 张',
                                    style: const TextStyle(color: AppColors.inkMuted),
                                  ),
                                  const Icon(Icons.chevron_right_rounded, color: AppColors.inkFaint),
                                ],
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
  }
}
