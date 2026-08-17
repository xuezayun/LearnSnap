import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/api_client.dart';
import '../../core/device_layout.dart';
import '../../models/review_tools.dart';
import '../../services/learn_snap_api.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_scaffold_bg.dart';

class ReviewToolsPage extends StatefulWidget {
  const ReviewToolsPage({super.key, this.api});

  final LearnSnapApi? api;

  @override
  State<ReviewToolsPage> createState() => _ReviewToolsPageState();
}

class _ReviewToolsPageState extends State<ReviewToolsPage>
    with SingleTickerProviderStateMixin {
  late final LearnSnapApi _api = widget.api ?? LearnSnapApi();
  late final TabController _tabs;

  ReviewToolsMeta? _meta;
  List<ReviewToolsPendingItem> _pending = [];
  bool _loading = true;
  bool _busy = false;
  String? _error;
  final _titleController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabs.dispose();
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        _api.fetchReviewToolsMeta(),
        _api.fetchReviewToolsPending(),
      ]);
      if (!mounted) return;
      setState(() {
        _meta = results[0] as ReviewToolsMeta;
        _pending = results[1] as List<ReviewToolsPendingItem>;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e is ApiException ? e.message : e.toString();
      });
    }
  }

  Future<void> _assignTemplate(ReviewToolsTemplate tpl) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final result = await _api.assignReviewToolTask(templateId: tpl.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.created ? '已发布「${result.title}」' : '已启用「${result.title}」',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      final msg = e is ApiException ? e.message : e.toString();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _assignCustom() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入任务名称')),
      );
      return;
    }
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final result = await _api.assignReviewToolTask(title: title);
      if (!mounted) return;
      _titleController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.created ? '已发布「${result.title}」' : '已启用「${result.title}」',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      final msg = e is ApiException ? e.message : e.toString();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _approve(ReviewToolsPendingItem item, String rating) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final result = await _api.approveReviewToolCheckin(
        checkinId: item.id,
        rating: rating,
        comment: '审核助手通过',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('已审批，乐豆 +${result.bonusBeans}')),
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      final msg = e is ApiException ? e.message : e.toString();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pad = pagePadding(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('审核助手'),
        bottom: TabBar(
          controller: _tabs,
          labelColor: AppColors.brandDeep,
          unselectedLabelColor: AppColors.inkMuted,
          indicatorColor: AppColors.brand,
          tabs: const [
            Tab(text: '发布任务'),
            Tab(text: '审批打卡'),
          ],
        ),
      ),
      body: AppScaffoldBackground(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : (_error != null
                ? Center(
                    child: Padding(
                      padding: EdgeInsets.all(pad),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _error!,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.nunito(color: AppColors.danger),
                          ),
                          const SizedBox(height: 12),
                          FilledButton(onPressed: _load, child: const Text('重试')),
                        ],
                      ),
                    ),
                  )
                : TabBarView(
                    controller: _tabs,
                    children: [
                      _buildAssignTab(pad),
                      _buildPendingTab(pad),
                    ],
                  )),
      ),
    );
  }

  Widget _buildAssignTab(double pad) {
    final templates = _meta?.templates ?? [];
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: EdgeInsets.all(pad),
        children: [
          Text(
            '仅商店审核演示账号可用。发布后返回首页即可在今日宝箱打卡。',
            style: GoogleFonts.nunito(
              color: AppColors.inkMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _titleController,
            decoration: InputDecoration(
              labelText: '自定义任务名称',
              hintText: '例如：整理书包',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              suffixIcon: IconButton(
                onPressed: _busy ? null : _assignCustom,
                icon: const Icon(Icons.send_rounded),
              ),
            ),
            onSubmitted: (_) => _assignCustom(),
          ),
          const SizedBox(height: 20),
          Text(
            '系统模板',
            style: GoogleFonts.nunito(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 8),
          if (templates.isEmpty)
            Text(
              '暂无可用模板',
              style: GoogleFonts.nunito(color: AppColors.inkMuted),
            )
          else
            ...templates.map(
              (tpl) => Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  title: Text(
                    tpl.title,
                    style: GoogleFonts.nunito(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text('${tpl.durationMin} 分钟'),
                  trailing: FilledButton(
                    onPressed: _busy ? null : () => _assignTemplate(tpl),
                    child: const Text('发布'),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPendingTab(double pad) {
    return RefreshIndicator(
      onRefresh: _load,
      child: _pending.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.all(pad),
              children: [
                const SizedBox(height: 80),
                Text(
                  '暂无待审批打卡',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.nunito(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.inkMuted,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '先在首页完成打卡，再回到这里审批',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.nunito(color: AppColors.inkFaint),
                ),
              ],
            )
          : ListView.builder(
              padding: EdgeInsets.all(pad),
              itemCount: _pending.length,
              itemBuilder: (context, index) {
                final item = _pending[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          style: GoogleFonts.nunito(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.statusLabel,
                          style: GoogleFonts.nunito(color: AppColors.inkMuted),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            FilledButton(
                              onPressed:
                                  _busy ? null : () => _approve(item, 'excellent'),
                              child: const Text('优秀'),
                            ),
                            FilledButton.tonal(
                              onPressed:
                                  _busy ? null : () => _approve(item, 'pass'),
                              child: const Text('通过'),
                            ),
                            OutlinedButton(
                              onPressed: _busy
                                  ? null
                                  : () => _approve(item, 'encourage'),
                              child: const Text('加油'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
