class CheckinReportStats {
  CheckinReportStats({
    required this.periodStart,
    required this.periodEnd,
    required this.totalCheckins,
    required this.beansEarned,
    required this.activeDays,
    required this.completionRate,
    required this.dailyCheckins,
    required this.topTasks,
    required this.ratingBreakdown,
  });

  final String periodStart;
  final String periodEnd;
  final int totalCheckins;
  final int beansEarned;
  final int activeDays;
  final double completionRate;
  final List<DailyCheckin> dailyCheckins;
  final List<TopTaskStat> topTasks;
  final Map<String, int> ratingBreakdown;

  String get completionRateText => '${(completionRate * 100).round()}%';

  factory CheckinReportStats.fromJson(Map<String, dynamic> json) {
    final daily = json['daily_checkins'] as List<dynamic>? ?? [];
    final tasks = json['top_tasks'] as List<dynamic>? ?? [];
    final ratings = json['rating_breakdown'] as Map<String, dynamic>? ?? {};
    return CheckinReportStats(
      periodStart: json['period_start'] as String? ?? '',
      periodEnd: json['period_end'] as String? ?? '',
      totalCheckins: _readInt(json['total_checkins']),
      beansEarned: _readInt(json['beans_earned']),
      activeDays: _readInt(json['active_days']),
      completionRate: _readDouble(json['completion_rate']),
      dailyCheckins: daily
          .whereType<Map<String, dynamic>>()
          .map(DailyCheckin.fromJson)
          .toList(),
      topTasks: tasks
          .whereType<Map<String, dynamic>>()
          .map(TopTaskStat.fromJson)
          .toList(),
      ratingBreakdown: ratings.map(
        (key, value) => MapEntry(key, _readInt(value)),
      ),
    );
  }

  static int _readInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return 0;
  }

  static double _readDouble(dynamic value) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return 0;
  }
}

class DailyCheckin {
  DailyCheckin({required this.date, required this.count});

  final String date;
  final int count;

  String get shortLabel {
    if (date.length < 10) return date;
    return date.substring(5);
  }

  factory DailyCheckin.fromJson(Map<String, dynamic> json) {
    return DailyCheckin(
      date: json['date'] as String? ?? '',
      count: CheckinReportStats._readInt(json['checkins']),
    );
  }
}

class TopTaskStat {
  TopTaskStat({required this.title, required this.count});

  final String title;
  final int count;

  factory TopTaskStat.fromJson(Map<String, dynamic> json) {
    return TopTaskStat(
      title: json['title'] as String? ?? '习惯任务',
      count: CheckinReportStats._readInt(json['count']),
    );
  }
}

class CheckinReport {
  CheckinReport({
    required this.nickname,
    required this.streak,
    required this.energyBeans,
    required this.stats,
    required this.tier,
    required this.historyDays,
  });

  final String nickname;
  final int streak;
  final int energyBeans;
  final CheckinReportStats stats;
  final String tier;
  final int? historyDays;

  bool get isPlus => tier == 'plus';

  factory CheckinReport.fromJson(Map<String, dynamic> json) {
    final statsJson = json['stats'] as Map<String, dynamic>? ?? {};
    return CheckinReport(
      nickname: json['nickname'] as String? ?? '同学',
      streak: CheckinReportStats._readInt(json['streak']),
      energyBeans: CheckinReportStats._readInt(json['energy_beans']),
      stats: CheckinReportStats.fromJson(statsJson),
      tier: json['tier'] as String? ?? 'free',
      historyDays: json['history_days'] as int?,
    );
  }
}
