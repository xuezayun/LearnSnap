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
    final badge = _badge;

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
              : _error != null && badge == null
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
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: AppColors.brand.withValues(alpha: 0.3),
                            ),
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
                                '我的荣誉',
                                style: GoogleFonts.nunito(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.brandDeep,
                                ),
                              ),
                              const SizedBox(height: 14),
                              HonorBadgeStrip(badge: badge ?? HonorBadge.empty()),
                              const SizedBox(height: 12),
                              HonorBadgeStatRow(
                                suns: badge?.suns ?? 0,
                                moons: badge?.moons ?? 0,
                                stars: badge?.stars ?? 0,
                                iconSize: 22,
                                style: GoogleFonts.nunito(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.ink,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '累计兑星 ${badge?.starCount ?? 0}',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.nunito(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.inkMuted,
                                ),
                              ),
                              const SizedBox(height: 4),
                              HonorBadgeRuleHint(
                                starsPerMoon: badge?.starsPerMoon ?? 5,
                                moonsPerSun: badge?.moonsPerSun ?? 5,
                                iconSize: 14,
                                style: GoogleFonts.nunito(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.inkMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: AppColors.accentSun.withValues(alpha: 0.35),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                '点亮荣誉之星',
                                style: GoogleFonts.nunito(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.ink,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '当前金豆 ${badge?.balance ?? 0}　·　'
                                '每颗星 ${badge?.starCostBeans ?? 50} 金豆\n'
                                '今天已点亮 ${badge?.redeemedToday ?? 0}/'
                                '${badge?.dailyRedeemLimit ?? 20}',
                                style: GoogleFonts.nunito(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.inkMuted,
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 16),
                              FilledButton(
                                onPressed: _redeeming ? null : _redeem,
                                child: _redeeming
                                    ? const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : Text(
                                        '花 ${badge?.starCostBeans ?? 50} 金豆换一颗星',
                                        style: GoogleFonts.nunito(
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          '坚持拍照赚金豆，攒星星点亮月亮和太阳！',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.nunito(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.inkFaint,
                          ),
                        ),
                      ],
                    ),
        ),
      ),
    );
  }
}
