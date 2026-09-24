import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/app_colors.dart';
import '../../widgets/app_scaffold_bg.dart';
import 'dictation_settings.dart';

class DictationSettingsPage extends StatefulWidget {
  const DictationSettingsPage({super.key, required this.initial});

  final DictationSettings initial;

  @override
  State<DictationSettingsPage> createState() => _DictationSettingsPageState();
}

class _DictationSettingsPageState extends State<DictationSettingsPage> {
  final _store = DictationSettingsStore();
  late DictationSettings _settings = widget.initial;

  Future<void> _update(DictationSettings next) async {
    setState(() => _settings = next);
    await _store.save(next);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('朗读设置')),
      body: AppScaffoldBackground(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: [
            _StepCard(
              title: '每个词读几遍',
              value: '${_settings.repeats} 遍',
              onMinus: _settings.repeats <= 1
                  ? null
                  : () => _update(_settings.copyWith(repeats: _settings.repeats - 1)),
              onPlus: _settings.repeats >= 3
                  ? null
                  : () => _update(_settings.copyWith(repeats: _settings.repeats + 1)),
            ),
            const SizedBox(height: 12),
            _StepCard(
              title: '词与词的间隔',
              value: '${_settings.gapSeconds} 秒',
              onMinus: _settings.gapSeconds <= 1
                  ? null
                  : () => _update(
                        _settings.copyWith(gapSeconds: _settings.gapSeconds - 1),
                      ),
              onPlus: _settings.gapSeconds >= 5
                  ? null
                  : () => _update(
                        _settings.copyWith(gapSeconds: _settings.gapSeconds + 1),
                      ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '语速',
                    style: GoogleFonts.nunito(
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: [
                      for (final pace in DictationPace.values)
                        ChoiceChip(
                          label: Text(pace.label),
                          selected: _settings.pace == pace,
                          onSelected: (_) => _update(_settings.copyWith(pace: pace)),
                          selectedColor: AppColors.brandSoft,
                          labelStyle: GoogleFonts.nunito(
                            fontWeight: FontWeight.w800,
                            color: AppColors.brandDeep,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepCard extends StatelessWidget {
  const _StepCard({
    required this.title,
    required this.value,
    required this.onMinus,
    required this.onPlus,
  });

  final String title;
  final String value;
  final VoidCallback? onMinus;
  final VoidCallback? onPlus;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.nunito(
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
              ),
            ),
          ),
          IconButton(onPressed: onMinus, icon: const Icon(Icons.remove_circle_outline)),
          Text(
            value,
            style: GoogleFonts.nunito(fontWeight: FontWeight.w800),
          ),
          IconButton(onPressed: onPlus, icon: const Icon(Icons.add_circle_outline)),
        ],
      ),
    );
  }
}
