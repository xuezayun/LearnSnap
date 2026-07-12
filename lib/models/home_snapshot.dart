import 'package:flutter/foundation.dart';

class CheckinSubmitResult {
  const CheckinSubmitResult({
    required this.beans,
    required this.revised,
  });

  final int beans;
  final bool revised;
}

class TodayBoxItem {
  TodayBoxItem({
    required this.assignmentId,
    required this.title,
    required this.taskType,
    required this.submitted,
    required this.sortOrder,
    this.checkinId,
    this.checkinStatus,
    this.statusLabel = '',
    this.canRevise = false,
  });

  final int assignmentId;
  final String title;
  final String taskType;
  final bool submitted;
  final int sortOrder;
  final int? checkinId;
  final String? checkinStatus;
  final String statusLabel;
  final bool canRevise;

  bool get isFinalized => submitted && !canRevise;

  String get displaySubtitle {
    if (!submitted) return '照片 + 视频均可提交';
    if (canRevise) {
      if (checkinStatus == 'rejected') return '已驳回 · 点击修订';
      return '${statusLabel.isNotEmpty ? statusLabel : '已提交'} · 点击修订';
    }
    return statusLabel.isNotEmpty ? statusLabel : '已提交';
  }

  factory TodayBoxItem.fromJson(Map<String, dynamic> json) {
    return TodayBoxItem(
      assignmentId: json['assignment_id'] as int,
      title: json['title'] as String? ?? '习惯任务',
      taskType: json['task_type'] as String? ?? 'study',
      submitted: json['submitted'] as bool? ?? json['completed'] as bool? ?? false,
      sortOrder: json['sort_order'] as int? ?? 0,
      checkinId: json['checkin_id'] as int?,
      checkinStatus: json['checkin_status'] as String?,
      statusLabel: json['status_label'] as String? ?? '',
      canRevise: json['can_revise'] as bool? ?? false,
    );
  }
}

class TodayBox {
  TodayBox({
    required this.date,
    required this.total,
    required this.completed,
    required this.streak,
    required this.energyBeans,
    required this.boxes,
  });

  final String date;
  final int total;
  final int completed;
  final int streak;
  final int energyBeans;
  final List<TodayBoxItem> boxes;

  factory TodayBox.fromJson(Map<String, dynamic> json) {
    final rawBoxes = json['boxes'] as List<dynamic>? ?? [];
    return TodayBox(
      date: json['date'] as String? ?? '',
      total: json['total'] as int? ?? 0,
      completed: json['completed'] as int? ?? 0,
      streak: json['streak'] as int? ?? 0,
      energyBeans: json['energy_beans'] as int? ?? 0,
      boxes: rawBoxes
          .whereType<Map<String, dynamic>>()
          .map(TodayBoxItem.fromJson)
          .toList(),
    );
  }
}

class FamilyEntitlements {
  FamilyEntitlements({
    required this.tier,
    required this.label,
    this.expiresAt,
    this.storageMb = 500,
    this.isPlus = false,
  });

  final String tier;
  final String label;
  final String? expiresAt;
  final int storageMb;
  final bool isPlus;

  factory FamilyEntitlements.fromJson(Map<String, dynamic> json) {
    final features = json['features'] as Map<String, dynamic>? ?? {};
    final tier = json['tier'] as String? ?? 'free';
    return FamilyEntitlements(
      tier: tier,
      label: json['label'] as String? ?? (tier == 'plus' ? '会员家庭' : '免费版家庭'),
      expiresAt: json['expires_at'] as String?,
      storageMb: features['storage_mb'] as int? ?? 500,
      isPlus: tier == 'plus',
    );
  }
}

@immutable
class HomeSnapshot {
  const HomeSnapshot({
    required this.todayBox,
    required this.entitlements,
  });

  final TodayBox todayBox;
  final FamilyEntitlements entitlements;
}
