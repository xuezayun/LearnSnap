class CheckinHistoryItem {
  const CheckinHistoryItem({
    required this.id,
    required this.title,
    required this.taskType,
    required this.status,
    required this.statusLabel,
    required this.canRevise,
    this.assignmentId,
    this.submittedAt,
    this.coverMediaId,
    this.coverMediaType = '',
  });

  final int id;
  final int? assignmentId;
  final String title;
  final String taskType;
  final String status;
  final String statusLabel;
  final bool canRevise;
  final String? submittedAt;
  final int? coverMediaId;
  final String coverMediaType;

  bool get hasImageCover =>
      coverMediaId != null && coverMediaId! > 0 && coverMediaType != 'video';

  factory CheckinHistoryItem.fromJson(Map<String, dynamic> json) {
    return CheckinHistoryItem(
      id: _readInt(json['id']),
      assignmentId: _readNullableInt(json['assignment_id']),
      title: (json['title'] as String? ?? '').trim(),
      taskType: json['task_type'] as String? ?? '',
      status: json['status'] as String? ?? '',
      statusLabel: json['status_label'] as String? ?? '',
      canRevise: json['can_revise'] as bool? ?? false,
      submittedAt: json['submitted_at']?.toString(),
      coverMediaId: _readNullableInt(json['cover_media_id']),
      coverMediaType: json['cover_media_type'] as String? ?? '',
    );
  }

  static int _readInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse('$value') ?? 0;
  }

  static int? _readNullableInt(dynamic value) {
    if (value == null) return null;
    final parsed = _readInt(value);
    return parsed > 0 ? parsed : null;
  }
}

class CheckinHistoryPageData {
  const CheckinHistoryPageData({
    required this.nickname,
    required this.items,
    required this.total,
    required this.page,
    required this.pageSize,
    required this.hasMore,
  });

  final String nickname;
  final List<CheckinHistoryItem> items;
  final int total;
  final int page;
  final int pageSize;
  final bool hasMore;

  factory CheckinHistoryPageData.fromJson(Map<String, dynamic> json) {
    final items = json['items'] as List<dynamic>? ?? [];
    return CheckinHistoryPageData(
      nickname: json['nickname'] as String? ?? '同学',
      items: items
          .whereType<Map>()
          .map((e) => CheckinHistoryItem.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      total: CheckinHistoryItem._readInt(json['total']),
      page: CheckinHistoryItem._readInt(json['page']),
      pageSize: CheckinHistoryItem._readInt(json['page_size']),
      hasMore: json['has_more'] as bool? ?? false,
    );
  }
}
