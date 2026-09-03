import 'package:flutter/foundation.dart';

import 'checkin_media.dart';
import 'child_checkin_detail.dart';
import 'honor_badge.dart';

class CheckinSubmitResult {
  const CheckinSubmitResult({
    required this.beans,
    required this.revised,
    this.checkinId,
  });

  final int beans;
  final bool revised;
  final int? checkinId;
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
    this.quotaBlocked = false,
    this.media = const [],
    this.parentReview,
    this.durationMin = 15,
    this.early = false,
    this.dueDate = '',
    this.dueLabel = '',
    this.repeatLabel = '',
    this.nextDueDate = '',
    this.nextDueLabel = '',
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
  final bool quotaBlocked;
  final List<CheckinMediaItem> media;
  final ParentReviewSummary? parentReview;
  final int durationMin;
  final bool early;
  final String dueDate;
  final String dueLabel;
  final String repeatLabel;
  final String nextDueDate;
  final String nextDueLabel;

  bool get isFinalized => submitted && !canRevise;

  String get displaySubtitle {
    if (quotaBlocked && !submitted) return '今天次数用完啦';
    if (!submitted && early && dueLabel.isNotEmpty) return dueLabel;
    if (!submitted && nextDueLabel.isNotEmpty) return '到$nextDueLabel再拍';
    if (!submitted) return '拍照就能过关';
    if (canRevise) {
      if (checkinStatus == 'rejected') return '再拍一次会更好';
      return '等家长看';
    }
    return statusLabel.isNotEmpty ? statusLabel : '过关啦';
  }

  factory TodayBoxItem.fromJson(Map<String, dynamic> json) {
    final mediaRaw = json['media'];
    final media = <CheckinMediaItem>[];
    if (mediaRaw is List) {
      for (final item in mediaRaw) {
        if (item is Map) {
          media.add(
            CheckinMediaItem.fromSubmittedJson(Map<String, dynamic>.from(item)),
          );
        }
      }
    }
    final parentReview = ParentReviewSummary.tryParse(json['parent_review']);
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
      quotaBlocked: json['quota_blocked'] as bool? ?? false,
      media: media,
      parentReview: parentReview,
      durationMin: _readDurationMin(json['duration_min']),
      early: json['early'] as bool? ?? false,
      dueDate: json['due_date'] as String? ?? '',
      dueLabel: json['due_label'] as String? ?? '',
      repeatLabel: json['repeat_label'] as String? ?? '',
      nextDueDate: json['next_due_date'] as String? ?? '',
      nextDueLabel: json['next_due_label'] as String? ?? '',
    );
  }

  factory TodayBoxItem.fromUpcomingJson(Map<String, dynamic> json) {
    return TodayBoxItem(
      assignmentId: json['assignment_id'] as int,
      title: json['title'] as String? ?? '习惯任务',
      taskType: json['task_type'] as String? ?? 'study',
      submitted: false,
      sortOrder: 0,
      durationMin: _readDurationMin(json['duration_min']),
      repeatLabel: json['repeat_label'] as String? ?? '',
      nextDueDate: json['next_due_date'] as String? ?? '',
      nextDueLabel: json['next_due_label'] as String? ?? '',
    );
  }

  static int _readDurationMin(dynamic value) {
    if (value is int) return value > 0 ? value : 15;
    if (value is num) {
      final n = value.toInt();
      return n > 0 ? n : 15;
    }
    if (value is String) {
      final n = int.tryParse(value);
      if (n != null && n > 0) return n;
    }
    return 15;
  }
}

class TodayBox {
  TodayBox({
    required this.date,
    required this.nickname,
    required this.total,
    required this.completed,
    required this.streak,
    required this.energyBeans,
    required this.boxes,
    this.upcoming = const [],
    this.dailyCheckinTaskLimit = 3,
    this.dailyCheckinUsed = 0,
    this.membershipTier = 'free',
    this.reviewToolsEnabled = false,
    HonorBadge? honorBadge,
  }) : honorBadge = honorBadge ?? HonorBadge.empty();

  final String date;
  final String nickname;
  final int total;
  final int completed;
  final int streak;
  final int energyBeans;
  final List<TodayBoxItem> boxes;
  final List<TodayBoxItem> upcoming;
  final int dailyCheckinTaskLimit;
  final int dailyCheckinUsed;
  final String membershipTier;
  final bool reviewToolsEnabled;
  final HonorBadge honorBadge;

  factory TodayBox.fromJson(Map<String, dynamic> json) {
    final rawBoxes = json['boxes'] as List<dynamic>? ?? [];
    final rawUpcoming = json['upcoming'] as List<dynamic>? ?? [];
    return TodayBox(
      date: json['date'] as String? ?? '',
      nickname: json['nickname'] as String? ?? '同学',
      total: _readInt(json['total']),
      completed: _readInt(json['completed']),
      streak: _readInt(json['streak']),
      energyBeans: _readInt(json['energy_beans']),
      dailyCheckinTaskLimit: _readInt(json['daily_checkin_task_limit'], fallback: 3),
      dailyCheckinUsed: _readInt(json['daily_checkin_used']),
      membershipTier: json['membership_tier'] as String? ?? 'free',
      reviewToolsEnabled: json['review_tools_enabled'] as bool? ?? false,
      boxes: rawBoxes
          .whereType<Map<String, dynamic>>()
          .map(TodayBoxItem.fromJson)
          .toList(),
      upcoming: rawUpcoming
          .whereType<Map<String, dynamic>>()
          .map(TodayBoxItem.fromUpcomingJson)
          .toList(),
      honorBadge: HonorBadge.fromJson(
        json['honor_badge'] is Map
            ? Map<String, dynamic>.from(json['honor_badge'] as Map)
            : null,
      ),
    );
  }

  static int _readInt(dynamic value, {int fallback = 0}) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? fallback;
    return fallback;
  }
}

class FamilyEntitlements {
  FamilyEntitlements({
    required this.tier,
    required this.label,
    this.expiresAt,
    this.storageMb = 500,
    this.isPlus = false,
    this.usable = true,
    this.dailyCheckinTaskLimit = 3,
  });

  final String tier;
  final String label;
  final String? expiresAt;
  final int storageMb;
  final bool isPlus;
  final bool usable;
  final int dailyCheckinTaskLimit;

  factory FamilyEntitlements.fromJson(Map<String, dynamic> json) {
    final features = json['features'] as Map<String, dynamic>? ?? {};
    final tier = json['tier'] as String? ?? 'free';
    final limitRaw = features['daily_checkin_task_limit'];
    final limit = limitRaw is int
        ? limitRaw
        : (limitRaw is num ? limitRaw.toInt() : int.tryParse('$limitRaw') ?? 3);
    return FamilyEntitlements(
      tier: tier,
      label: json['label'] as String? ??
          (tier == 'pro'
              ? 'Pro 会员家庭'
              : (tier == 'plus' ? 'Plus 会员家庭' : '免费版家庭')),
      expiresAt: json['expires_at'] as String?,
      storageMb: features['storage_mb'] as int? ?? 500,
      isPlus: tier == 'plus' || tier == 'pro',
      usable: json['usable'] as bool? ?? true,
      dailyCheckinTaskLimit: limit,
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
