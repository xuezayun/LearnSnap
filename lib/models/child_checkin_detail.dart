import 'checkin_media.dart';

class ParentReviewSummary {
  const ParentReviewSummary({
    required this.rating,
    required this.ratingLabel,
    required this.comment,
    required this.bonusBeans,
    this.reviewedAt,
  });

  final String rating;
  final String ratingLabel;
  final String comment;
  final int bonusBeans;
  final String? reviewedAt;

  factory ParentReviewSummary.fromJson(Map<String, dynamic> json) {
    final beansRaw = json['bonus_beans'];
    final beans = beansRaw is int
        ? beansRaw
        : (beansRaw is num ? beansRaw.toInt() : int.tryParse('$beansRaw') ?? 0);
    return ParentReviewSummary(
      rating: '${json['rating'] ?? ''}'.trim(),
      ratingLabel: '${json['rating_label'] ?? ''}'.trim(),
      // 小程序「写一句鼓励」→ ParentReview.comment
      comment: '${json['comment'] ?? ''}'.trim(),
      bonusBeans: beans,
      reviewedAt: json['reviewed_at']?.toString(),
    );
  }

  static ParentReviewSummary? tryParse(dynamic raw) {
    if (raw is! Map) return null;
    return ParentReviewSummary.fromJson(
      raw.map((key, value) => MapEntry('$key', value)),
    );
  }

  /// Human label for rating: 优秀 / 通过 / 加油 (never reuse status text).
  String get displayRatingLabel {
    if (ratingLabel.isNotEmpty &&
        ratingLabel != '家长已通过' &&
        ratingLabel != '家长已鼓励') {
      return ratingLabel;
    }
    switch (rating) {
      case 'excellent':
        return '优秀';
      case 'pass':
        return '通过';
      case 'encourage':
        return '加油';
      case 'rejected':
        return '已驳回';
      default:
        return ratingLabel.isNotEmpty ? ratingLabel : '已评价';
    }
  }
}

class ChildCheckinDetail {
  const ChildCheckinDetail({
    required this.id,
    required this.title,
    required this.taskType,
    required this.status,
    required this.statusLabel,
    required this.note,
    required this.canRevise,
    required this.media,
    this.assignmentId,
    this.submittedAt,
    this.parentReview,
  });

  final int id;
  final int? assignmentId;
  final String title;
  final String taskType;
  final String status;
  final String statusLabel;
  final String note;
  final bool canRevise;
  final String? submittedAt;
  final List<CheckinMediaItem> media;
  final ParentReviewSummary? parentReview;

  factory ChildCheckinDetail.fromJson(Map<String, dynamic> json) {
    final mediaRaw = json['media'];
    final media = <CheckinMediaItem>[];
    if (mediaRaw is List) {
      for (final item in mediaRaw) {
        if (item is Map) {
          final parsed = CheckinMediaItem.fromSubmittedJson(
            Map<String, dynamic>.from(item),
          );
          if (parsed.hasRemotePreview || parsed.isExistingRemote) {
            media.add(parsed);
          }
        }
      }
    }
    final review = ParentReviewSummary.tryParse(json['parent_review']);
    final idRaw = json['id'];
    final id = idRaw is int ? idRaw : int.tryParse('$idRaw') ?? 0;
    return ChildCheckinDetail(
      id: id,
      assignmentId: json['assignment_id'] as int?,
      title: (json['title'] as String? ?? '').trim(),
      taskType: json['task_type'] as String? ?? '',
      status: json['status'] as String? ?? '',
      statusLabel: json['status_label'] as String? ?? '',
      note: json['note'] as String? ?? '',
      canRevise: json['can_revise'] as bool? ?? false,
      submittedAt: json['submitted_at'] as String?,
      media: media,
      parentReview: review,
    );
  }
}
