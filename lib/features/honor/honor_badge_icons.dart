import 'package:flutter/material.dart';

/// Asset paths and widgets for honor badge icons (star / moon / sun).
abstract final class HonorBadgeAssets {
  static const star = 'assets/honor/star.png';
  static const moon = 'assets/honor/moon.png';
  static const sun = 'assets/honor/sun.png';

  static String pathFor(String type) {
    return switch (type) {
      'sun' => sun,
      'moon' => moon,
      _ => star,
    };
  }
}

class HonorBadgeGlyph extends StatelessWidget {
  const HonorBadgeGlyph({
    super.key,
    required this.type,
    this.size = 22,
  });

  /// `sun` | `moon` | `star`
  final String type;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      HonorBadgeAssets.pathFor(type),
      width: size,
      height: size,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
      errorBuilder: (_, _, _) => Text(
        switch (type) {
          'sun' => '☀️',
          'moon' => '🌙',
          _ => '⭐',
        },
        style: TextStyle(fontSize: size * 0.85),
      ),
    );
  }
}

class HonorBadgeStatRow extends StatelessWidget {
  const HonorBadgeStatRow({
    super.key,
    required this.suns,
    required this.moons,
    required this.stars,
    this.iconSize = 20,
    this.style,
  });

  final int suns;
  final int moons;
  final int stars;
  final double iconSize;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    Widget cell(String type, int count) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          HonorBadgeGlyph(type: type, size: iconSize),
          const SizedBox(width: 4),
          Text('$count', style: style),
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        cell('sun', suns),
        const SizedBox(width: 16),
        cell('moon', moons),
        const SizedBox(width: 16),
        cell('star', stars),
      ],
    );
  }
}

class HonorBadgeRuleHint extends StatelessWidget {
  const HonorBadgeRuleHint({
    super.key,
    required this.starsPerMoon,
    required this.moonsPerSun,
    this.iconSize = 14,
    this.style,
  });

  final int starsPerMoon;
  final int moonsPerSun;
  final double iconSize;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    Widget pair(String a, String b, int n) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$n', style: style),
          HonorBadgeGlyph(type: a, size: iconSize),
          Text('=1', style: style),
          HonorBadgeGlyph(type: b, size: iconSize),
        ],
      );
    }

    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 8,
      children: [
        pair('star', 'moon', starsPerMoon),
        Text('·', style: style),
        pair('moon', 'sun', moonsPerSun),
      ],
    );
  }
}
