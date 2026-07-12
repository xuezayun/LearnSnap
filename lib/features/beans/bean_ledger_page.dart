import 'package:flutter/material.dart';

import '../../core/device_layout.dart';
import '../../models/bean_ledger.dart';
import '../../services/learn_snap_api.dart';

class BeanLedgerPage extends StatefulWidget {
  const BeanLedgerPage({super.key, this.api, this.initialBalance});

  final LearnSnapApi? api;
  final int? initialBalance;

  @override
  State<BeanLedgerPage> createState() => _BeanLedgerPageState();
}

class _BeanLedgerPageState extends State<BeanLedgerPage> {
  late final LearnSnapApi _api = widget.api ?? LearnSnapApi();
  final List<BeanLedgerEntry> _items = [];
  int _balance = 0;
  String _nickname = '同学';
  int _page = 1;
  bool _hasMore = true;
  bool _loading = true;
  bool _loadingMore = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.initialBalance != null) {
      _balance = widget.initialBalance!;
    }
    _load(reset: true);
  }

  Future<void> _load({bool reset = false}) async {
    if (reset) {
      setState(() {
        _loading = true;
        _error = null;
        _page = 1;
        _hasMore = true;
      });
    } else {
      if (_loadingMore || !_hasMore) return;
      setState(() => _loadingMore = true);
    }

    try {
      final result = await _api.fetchBeanLedger(page: _page);
      if (!mounted) return;
      setState(() {
        if (reset) {
          _items
            ..clear()
            ..addAll(result.items);
        } else {
          _items.addAll(result.items);
        }
        _balance = result.balance;
        _nickname = result.nickname;
        _hasMore = result.hasMore;
        _page = result.page + 1;
        _loading = false;
        _loadingMore = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
        _loadingMore = false;
      });
    }
  }

  String _formatTime(String iso) {
    if (iso.length < 16) return iso;
    return iso.substring(0, 16).replaceFirst('T', ' ');
  }

  @override
  Widget build(BuildContext context) {
    final padding = pagePadding(context);
    final color = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(title: const Text('乐豆流水')),
      body: RefreshIndicator(
        onRefresh: () => _load(reset: true),
        child: _loading
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 200),
                  Center(child: CircularProgressIndicator()),
                ],
              )
            : _error != null
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.all(padding),
                    children: [
                      const SizedBox(height: 120),
                      Text(_error!, textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      Center(
                        child: FilledButton(
                          onPressed: () => _load(reset: true),
                          child: const Text('重试'),
                        ),
                      ),
                    ],
                  )
                : ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(padding, padding, padding, 32),
                    children: [
                      Card(
                        color: color.withValues(alpha: 0.08),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            children: [
                              Text(
                                _nickname,
                                style: const TextStyle(color: Colors.black54),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.bolt, color: color, size: 32),
                                  const SizedBox(width: 8),
                                  Text(
                                    '$_balance',
                                    style: TextStyle(
                                      fontSize: 36,
                                      fontWeight: FontWeight.bold,
                                      color: color,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Text('乐豆', style: TextStyle(fontSize: 16)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (_items.isEmpty)
                        const Card(
                          child: Padding(
                            padding: EdgeInsets.all(24),
                            child: Text(
                              '还没有乐豆流水，完成打卡或获得家长奖励后会显示在这里',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.black54),
                            ),
                          ),
                        )
                      else ...[
                        ..._items.map((entry) => _LedgerTile(
                              entry: entry,
                              timeText: _formatTime(entry.createdAt),
                            )),
                        if (_hasMore)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Center(
                              child: _loadingMore
                                  ? const Padding(
                                      padding: EdgeInsets.all(16),
                                      child: CircularProgressIndicator(),
                                    )
                                  : TextButton(
                                      onPressed: () => _load(),
                                      child: const Text('加载更多'),
                                    ),
                            ),
                          ),
                      ],
                    ],
                  ),
      ),
    );
  }
}

class _LedgerTile extends StatelessWidget {
  const _LedgerTile({required this.entry, required this.timeText});

  final BeanLedgerEntry entry;
  final String timeText;

  @override
  Widget build(BuildContext context) {
    final income = entry.isIncome;
    final amountColor = income ? const Color(0xFF2E7D32) : const Color(0xFFC62828);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(entry.displayTitle),
        subtitle: Text(
          '${entry.entryLabel} · $timeText',
          style: const TextStyle(fontSize: 12),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              entry.amountText,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: amountColor,
                fontSize: 16,
              ),
            ),
            Text(
              '余额 ${entry.balanceAfter}',
              style: const TextStyle(fontSize: 11, color: Colors.black45),
            ),
          ],
        ),
      ),
    );
  }
}
