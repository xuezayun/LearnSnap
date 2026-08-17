class ReviewToolsTemplate {
  const ReviewToolsTemplate({
    required this.id,
    required this.title,
    required this.taskType,
    required this.durationMin,
  });

  final int id;
  final String title;
  final String taskType;
  final int durationMin;

  factory ReviewToolsTemplate.fromJson(Map<String, dynamic> json) {
    return ReviewToolsTemplate(
      id: json['id'] as int,
      title: json['title'] as String? ?? '习惯任务',
      taskType: json['task_type'] as String? ?? 'study',
      durationMin: json['duration_min'] as int? ?? 15,
    );
  }
}

class ReviewToolsMeta {
  const ReviewToolsMeta({
    required this.enabled,
    required this.childId,
    required this.nickname,
    required this.templates,
  });

  final bool enabled;
  final int childId;
  final String nickname;
  final List<ReviewToolsTemplate> templates;

  factory ReviewToolsMeta.fromJson(Map<String, dynamic> json) {
    final raw = json['templates'] as List<dynamic>? ?? [];
    return ReviewToolsMeta(
      enabled: json['enabled'] as bool? ?? false,
      childId: json['child_id'] as int? ?? 0,
      nickname: json['nickname'] as String? ?? '',
      templates: raw
          .whereType<Map>()
          .map((e) => ReviewToolsTemplate.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }
}

class ReviewToolsAssignment {
  const ReviewToolsAssignment({
    required this.created,
    required this.id,
    required this.title,
  });

  final bool created;
  final int id;
  final String title;

  factory ReviewToolsAssignment.fromJson(Map<String, dynamic> json) {
    final raw = json['assignment'];
    final assignment = raw is Map
        ? Map<String, dynamic>.from(raw)
        : <String, dynamic>{};
    return ReviewToolsAssignment(
      created: json['created'] as bool? ?? false,
      id: assignment['id'] as int? ?? 0,
      title: assignment['title'] as String? ?? '',
    );
  }
}

class ReviewToolsPendingItem {
  const ReviewToolsPendingItem({
    required this.id,
    required this.title,
    required this.statusLabel,
    this.submittedAt,
    this.thumbnail = '',
  });

  final int id;
  final String title;
  final String statusLabel;
  final String? submittedAt;
  final String thumbnail;

  factory ReviewToolsPendingItem.fromJson(Map<String, dynamic> json) {
    return ReviewToolsPendingItem(
      id: json['id'] as int,
      title: json['title'] as String? ?? '习惯任务',
      statusLabel: json['status_label'] as String? ?? '待审核',
      submittedAt: json['submitted_at'] as String?,
      thumbnail: json['thumbnail'] as String? ?? '',
    );
  }
}

class ReviewToolsApproveResult {
  const ReviewToolsApproveResult({
    required this.bonusBeans,
    required this.status,
    required this.rating,
    required this.energyBeans,
  });

  final int bonusBeans;
  final String status;
  final String rating;
  final int energyBeans;

  factory ReviewToolsApproveResult.fromJson(Map<String, dynamic> json) {
    return ReviewToolsApproveResult(
      bonusBeans: json['bonus_beans'] as int? ?? 0,
      status: json['status'] as String? ?? '',
      rating: json['rating'] as String? ?? '',
      energyBeans: json['energy_beans'] as int? ?? 0,
    );
  }
}
