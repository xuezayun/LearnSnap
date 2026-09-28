class WrongItem {
  const WrongItem({
    required this.clientUuid,
    required this.subject,
    required this.note,
    required this.status,
    required this.imageKey,
    required this.localPath,
    required this.deleted,
    required this.pendingSync,
    required this.createdAt,
    required this.updatedAt,
  });

  final String clientUuid;
  final String subject;
  final String note;
  final String status;
  final String imageKey;
  final String localPath;
  final bool deleted;
  final bool pendingSync;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get needsReview => !deleted && status != 'mastered';

  WrongItem copyWith({
    String? subject,
    String? note,
    String? status,
    String? imageKey,
    String? localPath,
    bool? deleted,
    bool? pendingSync,
    DateTime? updatedAt,
  }) {
    return WrongItem(
      clientUuid: clientUuid,
      subject: subject ?? this.subject,
      note: note ?? this.note,
      status: status ?? this.status,
      imageKey: imageKey ?? this.imageKey,
      localPath: localPath ?? this.localPath,
      deleted: deleted ?? this.deleted,
      pendingSync: pendingSync ?? this.pendingSync,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toLocalJson() => {
        'client_uuid': clientUuid,
        'subject': subject,
        'note': note,
        'status': status,
        'image_key': imageKey,
        'local_path': localPath,
        'deleted': deleted,
        'pending_sync': pendingSync,
        'created_at': createdAt.toUtc().toIso8601String(),
        'updated_at': updatedAt.toUtc().toIso8601String(),
      };

  Map<String, dynamic> toSyncJson() => {
        'client_uuid': clientUuid,
        'subject': subject,
        'note': note,
        'status': status,
        'image_key': imageKey,
        'deleted': deleted,
        'created_at': createdAt.toUtc().toIso8601String(),
        'updated_at': updatedAt.toUtc().toIso8601String(),
      };

  factory WrongItem.fromLocalJson(Map<String, dynamic> json) {
    return WrongItem(
      clientUuid: json['client_uuid'] as String? ?? '',
      subject: json['subject'] as String? ?? 'other',
      note: json['note'] as String? ?? '',
      status: json['status'] as String? ?? 'open',
      imageKey: json['image_key'] as String? ?? '',
      localPath: json['local_path'] as String? ?? '',
      deleted: json['deleted'] as bool? ?? false,
      pendingSync: json['pending_sync'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
      updatedAt: DateTime.parse(json['updated_at'] as String).toLocal(),
    );
  }

  factory WrongItem.fromServerJson(Map<String, dynamic> json) {
    return WrongItem(
      clientUuid: json['client_uuid'] as String? ?? '',
      subject: json['subject'] as String? ?? 'other',
      note: json['note'] as String? ?? '',
      status: json['status'] as String? ?? 'open',
      imageKey: json['image_key'] as String? ?? '',
      localPath: '',
      deleted: json['deleted'] as bool? ?? false,
      pendingSync: false,
      createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
      updatedAt: DateTime.parse(json['updated_at'] as String).toLocal(),
    );
  }
}

const wrongSubjects = ['chinese', 'math', 'english', 'other'];

String wrongSubjectLabel(String subject) {
  switch (subject) {
    case 'chinese':
      return '语文';
    case 'math':
      return '数学';
    case 'english':
      return '英语';
    default:
      return '其他';
  }
}

String wrongStatusLabel(String status) {
  switch (status) {
    case 'reviewing':
      return '复习中';
    case 'mastered':
      return '已掌握';
    default:
      return '待复习';
  }
}

/// Server copy replaces local unless this device still has a newer unsynced edit.
List<WrongItem> mergeWrongItems({
  required List<WrongItem> local,
  required List<WrongItem> server,
}) {
  final byId = {for (final item in local) item.clientUuid: item};
  for (final remote in server) {
    final current = byId[remote.clientUuid];
    final localNewer = current != null &&
        current.pendingSync &&
        current.updatedAt.isAfter(remote.updatedAt);
    if (localNewer) continue;
    if (remote.deleted) {
      byId.remove(remote.clientUuid);
      continue;
    }
    final sameImage = current != null && current.imageKey == remote.imageKey;
    byId[remote.clientUuid] = remote.copyWith(
      localPath: sameImage ? current.localPath : '',
      pendingSync: false,
    );
  }
  final items = byId.values.where((item) => !item.deleted).toList()
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  return items;
}

DateTime wrongItemDay(DateTime value) => DateTime(value.year, value.month, value.day);

/// Photos in one subject, newest first. [start] and [end] are calendar days, both inclusive.
List<WrongItem> filterWrongItemsBySubject(
  List<WrongItem> items, {
  required String subject,
  DateTime? start,
  DateTime? end,
}) {
  final startDay = start == null ? null : wrongItemDay(start);
  final endDay = end == null ? null : wrongItemDay(end);
  final rows = items.where((item) {
    if (item.deleted || item.subject != subject) return false;
    final day = wrongItemDay(item.createdAt);
    if (startDay != null && day.isBefore(startDay)) return false;
    if (endDay != null && day.isAfter(endDay)) return false;
    return true;
  }).toList()
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  return rows;
}
