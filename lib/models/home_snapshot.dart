import 'package:flutter/foundation.dart';

import 'checkin_media.dart';
import 'child_checkin_detail.dart';
import 'honor_badge.dart';

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
    this.quotaBlocked = false,
    this.media = const [],
    this.parentReview,
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

  bool get isFinalized => submitted && !canRevise;

  String get displaySubtitle {
    if (quotaBlocked && !submitted) return '今日打卡次数已达上限';
    if (!submitted) return '最多 3 张图 + 1 段视频';
    if (canRevise) {
      if (checkinStatus == 'rejected') return '已驳回 · 点击修订';
      return '${statusLabel.isNotEmpty ? statusLabel : '已提交'} · 点击修订';
    }
    return statusLabel.isNotEmpty ? statusLabel : '已提交';
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
    );
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
  final int dailyCheckinTaskLimit;
  final int dailyCheckinUsed;
  final String membershipTier;
  final bool reviewToolsEnabled;
  final HonorBadge honorBadge;

  factory TodayBox.fromJson(Map<String, dynamic> json) {
    final rawBoxes = json['boxes'] as List<dynamic>? ?? [];
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
