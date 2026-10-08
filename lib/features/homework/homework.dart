class HomeworkItem {
  const HomeworkItem({
    required this.id,
    required this.subject,
    required this.subjectLabel,
    required this.title,
    required this.done,
  });

  final int id;
  final String subject;
  final String subjectLabel;
  final String title;
  final bool done;

  HomeworkItem copyWith({bool? done}) {
    return HomeworkItem(
      id: id,
      subject: subject,
      subjectLabel: subjectLabel,
      title: title,
      done: done ?? this.done,
    );
  }

  factory HomeworkItem.fromJson(Map<String, dynamic> json) {
    return HomeworkItem(
      id: json['id'] is int ? json['id'] as int : int.tryParse('${json['id']}') ?? 0,
      subject: json['subject']?.toString() ?? 'other',
      subjectLabel: json['subject_label']?.toString() ?? '其他',
      title: json['title']?.toString() ?? '',
      done: json['done'] == true,
    );
  }
}

class HomeworkSheet {
  const HomeworkSheet({
    required this.id,
    required this.startDate,
    required this.endDate,
    required this.items,
  });

  final int id;
  final String startDate;
  final String endDate;
  final List<HomeworkItem> items;

  factory HomeworkSheet.fromJson(Map<String, dynamic> json) {
    final raw = json['items'];
    return HomeworkSheet(
      id: json['id'] is int ? json['id'] as int : int.tryParse('${json['id']}') ?? 0,
      startDate: json['start_date']?.toString() ?? '',
      endDate: json['end_date']?.toString() ?? '',
      items: [
        if (raw is List)
          for (final item in raw)
            if (item is Map) HomeworkItem.fromJson(Map<String, dynamic>.from(item)),
      ],
    );
  }
}
