import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/api_client.dart';
import '../../core/device_layout.dart';
import '../../models/honor_badge.dart';
import '../../services/learn_snap_api.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_scaffold_bg.dart';
import 'honor_badge_icons.dart';
import 'honor_badge_strip.dart';

class HonorBadgePage extends StatefulWidget {
  const HonorBadgePage({super.key, this.api, this.initial});

  final LearnSnapApi? api;
  final HonorBadge? initial;

  @override
  State<HonorBadgePage> createState() => _HonorBadgePageState();
}

class _HonorBadgePageState extends State<HonorBadgePage> {
  late final LearnSnapApi _api = widget.api ?? LearnSnapApi();
  HonorBadge? _badge;
  bool _loading = true;
  bool _redeeming = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _badge = widget.initial;
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = _badge == null;
      _error = null;
    });
    try {
      final badge = await _api.fetchHonorBadge();
      if (!mounted) return;
      setState(() {
        _badge = badge;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _redeem() async {
    final badge = _badge;
    if (badge == null || _redeeming) return;
    if (badge.canRedeemCount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('今天换够啦，明天再来点亮星星')),
      );
      return;
    }
    if (badge.balance < badge.starCostBeans) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '金豆不够哦，还差 ${badge.starCostBeans - badge.balance} 豆，去拍照就能赚到',
          ),
        ),
      );
      return;
    }
    setState(() => _redeeming = true);
    try {
      final next = await _api.redeemHonorStars(count: 1);
      if (!mounted) return;
      setState(() {
        _badge = next;
        _redeeming = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('又亮一颗星啦！')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _redeeming = false);
      final msg = e is ApiException ? e.message : e.toString();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final padding = pagePadding(context);
    final tablet = isTablet(context);
    final badge = _badge ?? HonorBadge.empty();

    return Scaffold(
      appBar: AppBar(title: const Text('我的奖杯')),
      body: AppScaffoldBackground(
        child: RefreshIndicator(
          onRefresh: _load,
          child: _loading
              ? ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: const [
                    SizedBox(height: 200),
                    Center(child: CircularProgressIndicator()),
                  ],
                )
              : _error != null && _badge == null
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: EdgeInsets.all(padding),
                      children: [
                        const SizedBox(height: 120),
                        Text(_error!, textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        Center(
                          child: FilledButton(
                            onPressed: _load,
                            child: const Text('重试'),
                          ),
                        ),
                      ],
                    )
                  : ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: EdgeInsets.all(padding),
                      children: [
                        const SizedBox(height: 4),
                        _HonorHeroCard(badge: badge, tablet: tablet),
                        SizedBox(height: tablet ? 20 : 16),
                        _RedeemStarCard(
                          badge: badge,
                          tablet: tablet,
                          redeeming: _redeeming,
                          onRedeem: _redeem,
                        ),
                        const SizedBox(height: 20),
                        Text(
                          '坚持拍照赚金豆，攒星星就能点亮月亮和太阳！',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.nunito(
                            fontSize: tablet ? 15 : 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.inkFaint,
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
        ),
      ),
    );
  }
}

class _HonorHeroCard extends StatelessWidget {
  const _HonorHeroCard({required this.badge, required this.tablet});

  final HonorBadge badge;
  final bool tablet;

  @override
  Widget build(BuildContext context) {
    final hasTrophy = badge.display.isNotEmpty;
    return Container(
      padding: EdgeInsets.fromLTRB(
        tablet ? 22 : 16,
        tablet ? 22 : 18,
        tablet ? 22 : 16,
        tablet ? 20 : 16,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.brand.withValues(alpha: 0.28)),
        boxShadow: [
          BoxShadow(
            color: AppColors.brand.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            '我的奖杯',
            style: GoogleFonts.nunito(
              fontSize: tablet ? 24 : 20,
              fontWeight: FontWeight.w800,
              color: AppColors.brandDeep,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            badge.starCount > 0 ? '累计点亮 ${badge.starCount} 颗星' : '还没有奖杯，去点亮第一颗星吧',
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              fontSize: tablet ? 15 : 13,
              fontWeight: FontWeight.w700,
              color: AppColors.inkMuted,
            ),
          ),
          SizedBox(height: tablet ? 18 : 14),
          HonorBadgeMedalBoard(
            suns: badge.suns,
            moons: badge.moons,
            stars: badge.stars,
            tablet: tablet,
          ),
          SizedBox(height: tablet ? 18 : 16),
          Text(
            '怎么升级？',
            style: GoogleFonts.nunito(
              fontSize: tablet ? 16 : 14,
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 10),
          HonorBadgeRuleHint(
            starsPerMoon: badge.starsPerMoon,
            moonsPerSun: badge.moonsPerSun,
            iconSize: tablet ? 32 : 26,
          ),
          if (hasTrophy) ...[
            SizedBox(height: tablet ? 18 : 16),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '奖杯墙',
                style: GoogleFonts.nunito(
                  fontSize: tablet ? 16 : 14,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
              ),
            ),
            const SizedBox(height: 10),
            HonorBadgeStrip(
              badge: badge,
              glyphSize: tablet ? 48 : 40,
            ),
          ],
        ],
      ),
    );
  }
}

class _RedeemStarCard extends StatelessWidget {
  const _RedeemStarCard({
    required this.badge,
    required this.tablet,
    required this.redeeming,
    required this.onRedeem,
  });

  final HonorBadge badge;
  final bool tablet;
  final bool redeeming;
  final VoidCallback onRedeem;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(tablet ? 22 : 18),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8EC),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.accentSun.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const HonorBadgeGlyph(type: 'star', size: 40),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '点亮一颗星',
                  style: GoogleFonts.nunito(
                    fontSize: tablet ? 22 : 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _MiniStat(
                  label: '我的金豆',
                  value: '${badge.balance}',
                  wash: AppColors.beanGoldSoft,
                  ink: AppColors.beanGoldDeep,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MiniStat(
                  label: '一颗星',
                  value: '${badge.starCostBeans}',
                  wash: const Color(0xFFFFF6D6),
                  ink: const Color(0xFFB45309),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MiniStat(
                  label: '今天已点亮',
                  value: '${badge.redeemedToday}/${badge.dailyRedeemLimit}',
                  wash: const Color(0xFFEEF1FF),
                  ink: const Color(0xFF4C5BD4),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: tablet ? 56 : 52,
            child: FilledButton(
              onPressed: redeeming ? null : onRedeem,
              child: redeeming
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const HonorBadgeGlyph(type: 'star', size: 22),
                        const SizedBox(width: 8),
                        Text(
                          '花 ${badge.starCostBeans} 金豆换一颗星',
                          style: GoogleFonts.nunito(
                            fontSize: tablet ? 17 : 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.label,
    required this.value,
    required this.wash,
    required this.ink,
  });

  final String label;
  final String value;
  final Color wash;
  final Color ink;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: wash,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              maxLines: 1,
              style: GoogleFonts.nunito(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: ink,
                height: 1.1,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.nunito(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.inkMuted,
            ),
          ),
        ],
      ),
    );
  }
}
