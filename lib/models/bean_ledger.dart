class BeanLedgerEntry {
  BeanLedgerEntry({
    required this.id,
    required this.entryType,
    required this.entryLabel,
    required this.amount,
    required this.balanceAfter,
    required this.note,
    required this.taskTitle,
    required this.createdAt,
  });

  final int id;
  final String entryType;
  final String entryLabel;
  final int amount;
  final int balanceAfter;
  final String note;
  final String taskTitle;
  final String createdAt;

  bool get isIncome => amount > 0;

  String get amountText {
    if (amount > 0) return '+$amount';
    return '$amount';
  }

  String get displayTitle =>
      taskTitle.isNotEmpty ? taskTitle : (note.isNotEmpty ? note : entryLabel);

  factory BeanLedgerEntry.fromJson(Map<String, dynamic> json) {
    return BeanLedgerEntry(
      id: _readInt(json['id']),
      entryType: json['entry_type'] as String? ?? '',
      entryLabel: json['entry_label'] as String? ?? '',
      amount: _readInt(json['amount']),
      balanceAfter: _readInt(json['balance_after']),
      note: json['note'] as String? ?? '',
      taskTitle: json['task_title'] as String? ?? '',
      createdAt: json['created_at'] as String? ?? '',
    );
  }

  static int _readInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return 0;
  }
}

class BeanLedgerPage {
  BeanLedgerPage({
    required this.nickname,
    required this.balance,
    required this.items,
    required this.total,
    required this.page,
    required this.pageSize,
    required this.hasMore,
  });

  final String nickname;
  final int balance;
  final List<BeanLedgerEntry> items;
  final int total;
  final int page;
  final int pageSize;
  final bool hasMore;

  factory BeanLedgerPage.fromJson(Map<String, dynamic> json) {
    final items = json['items'] as List<dynamic>? ?? [];
    return BeanLedgerPage(
      nickname: json['nickname'] as String? ?? '同学',
      balance: BeanLedgerEntry._readInt(json['balance']),
      items: items
          .whereType<Map<String, dynamic>>()
          .map(BeanLedgerEntry.fromJson)
          .toList(),
      total: BeanLedgerEntry._readInt(json['total']),
      page: BeanLedgerEntry._readInt(json['page']),
      pageSize: BeanLedgerEntry._readInt(json['page_size']),
      hasMore: json['has_more'] as bool? ?? false,
    );
  }
}
