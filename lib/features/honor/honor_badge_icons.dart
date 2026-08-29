import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/app_colors.dart';

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

class HonorMedalLook {
  const HonorMedalLook({
    required this.label,
    required this.wash,
    required this.plate,
    required this.ink,
  });

  final String label;
  final Color wash;
  final Color plate;
  final Color ink;

  static HonorMedalLook of(String type) {
    return switch (type) {
      'sun' => const HonorMedalLook(
        label: '太阳',
        wash: Color(0xFFFFF1DE),
        plate: Color(0xFFFFE0A8),
        ink: Color(0xFFB45309),
      ),
      'moon' => const HonorMedalLook(
        label: '月亮',
        wash: Color(0xFFEEF1FF),
        plate: Color(0xFFD9E0FF),
        ink: Color(0xFF4C5BD4),
      ),
      _ => const HonorMedalLook(
        label: '星星',
        wash: Color(0xFFFFF6D6),
        plate: Color(0xFFFFE58A),
        ink: Color(0xFFB45309),
      ),
    };
  }
}

/// Three large sun / moon / star medals for the trophy page.
class HonorBadgeMedalBoard extends StatelessWidget {
  const HonorBadgeMedalBoard({
    super.key,
    required this.suns,
    required this.moons,
    required this.stars,
    this.tablet = false,
  });

  final int suns;
  final int moons;
  final int stars;
  final bool tablet;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _MedalCard(type: 'star', count: stars, tablet: tablet)),
        SizedBox(width: tablet ? 14 : 10),
        Expanded(child: _MedalCard(type: 'moon', count: moons, tablet: tablet)),
        SizedBox(width: tablet ? 14 : 10),
        Expanded(child: _MedalCard(type: 'sun', count: suns, tablet: tablet)),
      ],
    );
  }
}

class _MedalCard extends StatelessWidget {
  const _MedalCard({
    required this.type,
    required this.count,
    required this.tablet,
  });

  final String type;
  final int count;
  final bool tablet;

  @override
  Widget build(BuildContext context) {
    final look = HonorMedalLook.of(type);
    return LayoutBuilder(
      builder: (context, constraints) {
        final plate = (constraints.maxWidth - 12).clamp(52.0, tablet ? 120.0 : 96.0);
        final glyph = plate * 0.78;
        return Container(
          padding: EdgeInsets.fromLTRB(6, tablet ? 16 : 12, 6, tablet ? 14 : 12),
          decoration: BoxDecoration(
            color: look.wash,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: look.plate, width: 1.5),
          ),
          child: Column(
            children: [
              Container(
                width: plate,
                height: plate,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: look.ink.withValues(alpha: 0.16),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Opacity(
                  opacity: count > 0 ? 1 : 0.42,
                  child: HonorBadgeGlyph(type: type, size: glyph),
                ),
              ),
              SizedBox(height: tablet ? 10 : 8),
              Text(
                look.label,
                style: GoogleFonts.nunito(
                  fontSize: tablet ? 16 : 14,
                  fontWeight: FontWeight.w800,
                  color: look.ink,
                ),
              ),
              Text(
                '$count',
                style: GoogleFonts.nunito(
                  fontSize: tablet ? 28 : 24,
                  fontWeight: FontWeight.w900,
                  color: AppColors.ink,
                  height: 1.1,
                ),
              ),
            ],
          ),
        );
      },
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
      final from = HonorMedalLook.of(a);
      final to = HonorMedalLook.of(b);
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: from.plate),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$n',
              style: style ??
                  GoogleFonts.nunito(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: AppColors.ink,
                  ),
            ),
            const SizedBox(width: 4),
            HonorBadgeGlyph(type: a, size: iconSize),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Text(
                '=',
                style: GoogleFonts.nunito(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: AppColors.inkMuted,
                ),
              ),
            ),
            Text(
              '1',
              style: style ??
                  GoogleFonts.nunito(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: AppColors.ink,
                  ),
            ),
            const SizedBox(width: 4),
            HonorBadgeGlyph(type: b, size: iconSize),
            const SizedBox(width: 6),
            Text(
              to.label,
              style: GoogleFonts.nunito(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: to.ink,
              ),
            ),
          ],
        ),
      );
    }

    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: [
        pair('star', 'moon', starsPerMoon),
        pair('moon', 'sun', moonsPerSun),
      ],
    );
  }
}
