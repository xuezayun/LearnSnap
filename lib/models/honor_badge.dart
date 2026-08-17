class HonorBadgeIcon {
  HonorBadgeIcon({required this.type, required this.count});

  final String type; // sun | moon | star
  final int count;

  factory HonorBadgeIcon.fromJson(Map<String, dynamic> json) {
    return HonorBadgeIcon(
      type: json['type'] as String? ?? 'star',
      count: _readInt(json['count'], fallback: 1),
    );
  }

  static int _readInt(dynamic value, {int fallback = 0}) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? fallback;
    return fallback;
  }
}

class HonorBadge {
  HonorBadge({
    required this.starCount,
    required this.suns,
    required this.moons,
    required this.stars,
    required this.display,
    required this.starCostBeans,
    required this.starsPerMoon,
    required this.moonsPerSun,
    required this.balance,
    required this.dailyRedeemLimit,
    required this.redeemedToday,
    required this.canRedeemCount,
  });

  final int starCount;
  final int suns;
  final int moons;
  final int stars;
  final List<HonorBadgeIcon> display;
  final int starCostBeans;
  final int starsPerMoon;
  final int moonsPerSun;
  final int balance;
  final int dailyRedeemLimit;
  final int redeemedToday;
  final int canRedeemCount;

  bool get hasAny => starCount > 0;

  factory HonorBadge.empty() {
    return HonorBadge(
      starCount: 0,
      suns: 0,
      moons: 0,
      stars: 0,
      display: const [],
      starCostBeans: 50,
      starsPerMoon: 5,
      moonsPerSun: 5,
      balance: 0,
      dailyRedeemLimit: 20,
      redeemedToday: 0,
      canRedeemCount: 20,
    );
  }

  factory HonorBadge.fromJson(Map<String, dynamic>? json) {
    if (json == null) return HonorBadge.empty();
    final rawDisplay = json['display'];
    final display = <HonorBadgeIcon>[];
    if (rawDisplay is List) {
      for (final item in rawDisplay) {
        if (item is Map) {
          display.add(HonorBadgeIcon.fromJson(Map<String, dynamic>.from(item)));
        }
      }
    }
    return HonorBadge(
      starCount: HonorBadgeIcon._readInt(json['star_count']),
      suns: HonorBadgeIcon._readInt(json['suns']),
      moons: HonorBadgeIcon._readInt(json['moons']),
      stars: HonorBadgeIcon._readInt(json['stars']),
      display: display,
      starCostBeans: HonorBadgeIcon._readInt(json['star_cost_beans'], fallback: 50),
      starsPerMoon: HonorBadgeIcon._readInt(json['stars_per_moon'], fallback: 5),
      moonsPerSun: HonorBadgeIcon._readInt(json['moons_per_sun'], fallback: 5),
      balance: HonorBadgeIcon._readInt(json['balance']),
      dailyRedeemLimit:
          HonorBadgeIcon._readInt(json['daily_redeem_limit'], fallback: 20),
      redeemedToday: HonorBadgeIcon._readInt(json['redeemed_today']),
      canRedeemCount: HonorBadgeIcon._readInt(json['can_redeem_count']),
    );
  }
}
