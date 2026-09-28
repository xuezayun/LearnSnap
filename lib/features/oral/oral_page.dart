import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/app_colors.dart';
import '../../widgets/app_scaffold_bg.dart';
import '../dictation/dictation_settings.dart';
import 'oral_math.dart';
import 'oral_play_page.dart';
import 'oral_settings.dart';

class OralPage extends StatefulWidget {
  const OralPage({super.key});

  @override
  State<OralPage> createState() => _OralPageState();
}

class _OralPageState extends State<OralPage> {
  final _store = OralSettingsStore();
  OralSettings _settings = const OralSettings();

  @override
  void initState() {
    super.initState();
    _store.load().then((settings) {
      if (!mounted) return;
      setState(() => _settings = settings);
    });
  }

  Future<void> _update(OralSettings next) async {
    setState(() => _settings = next);
    await _store.save(next);
  }

  void _toggleOp(OralOp op) {
    final next = {..._settings.ops};
    if (next.contains(op)) {
      if (next.length == 1) return;
      next.remove(op);
    } else {
      next.add(op);
    }
    _update(_settings.copyWith(ops: next));
  }

  void _start() {
    final problems = buildOralProblems(
      ops: _settings.ops,
      within: _settings.within,
      count: _settings.count,
    );
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => OralPlayPage(
          problems: problems,
          repeats: _settings.repeats,
          gapSeconds: _settings.gapSeconds,
          pace: _settings.pace,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final arithmetic = _settings.ops.contains(OralOp.add) || _settings.ops.contains(OralOp.sub);
    return Scaffold(
      appBar: AppBar(title: const Text('听算')),
      body: AppScaffoldBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            children: [
              Text(
                '听一题，在纸上写答案。不报得数，也不批改。',
                style: GoogleFonts.nunito(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 18),
              const _Label('运算'),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final op in OralOp.values)
                    FilterChip(
                      label: Text(_opLabel(op)),
                      selected: _settings.ops.contains(op),
                      onSelected: (_) => _toggleOp(op),
                      selectedColor: const Color(0xFFF3EEFF),
                      checkmarkColor: AppColors.subjectMath,
                      labelStyle: GoogleFonts.nunito(
                        fontWeight: FontWeight.w800,
                        color: AppColors.subjectMath,
                      ),
                    ),
                ],
              ),
              if (arithmetic) ...[
                const SizedBox(height: 18),
                const _Label('加减范围'),
                _ChoiceRow(
                  labels: const ['10以内', '20以内', '100以内'],
                  values: const [10, 20, 100],
                  selected: _settings.within,
                  onSelected: (value) => _update(_settings.copyWith(within: value)),
                ),
              ],
              if (_settings.ops.contains(OralOp.mul) || _settings.ops.contains(OralOp.div)) ...[
                const SizedBox(height: 8),
                Text(
                  '乘除用九九乘法口诀。',
                  style: GoogleFonts.nunito(
                    fontWeight: FontWeight.w700,
                    color: AppColors.inkMuted,
                  ),
                ),
              ],
              const SizedBox(height: 18),
              const _Label('题数'),
              _ChoiceRow(
                labels: const ['10题', '20题', '30题'],
                values: const [10, 20, 30],
                selected: _settings.count,
                onSelected: (value) => _update(_settings.copyWith(count: value)),
              ),
              const SizedBox(height: 18),
              const _Label('每题间隔'),
              _ChoiceRow(
                labels: const ['5秒', '8秒', '10秒', '15秒'],
                values: const [5, 8, 10, 15],
                selected: _settings.gapSeconds,
                onSelected: (value) => _update(_settings.copyWith(gapSeconds: value)),
              ),
              const SizedBox(height: 18),
              const _Label('每题几遍'),
              _ChoiceRow(
                labels: const ['1遍', '2遍'],
                values: const [1, 2],
                selected: _settings.repeats,
                onSelected: (value) => _update(_settings.copyWith(repeats: value)),
              ),
              const SizedBox(height: 18),
              const _Label('语速'),
              _ChoiceRow(
                labels: [for (final pace in DictationPace.values) pace.label],
                values: [for (final pace in DictationPace.values) pace.index],
                selected: _settings.pace.index,
                onSelected: (index) => _update(
                  _settings.copyWith(pace: DictationPace.values[index]),
                ),
              ),
              const SizedBox(height: 28),
              FilledButton(
                onPressed: _start,
                child: const Text('开始听算'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _opLabel(OralOp op) => switch (op) {
      OralOp.add => '加法',
      OralOp.sub => '减法',
      OralOp.mul => '乘法',
      OralOp.div => '除法',
    };

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: GoogleFonts.nunito(
          fontWeight: FontWeight.w800,
          color: AppColors.brandDeep,
        ),
      ),
    );
  }
}

class _ChoiceRow extends StatelessWidget {
  const _ChoiceRow({
    required this.labels,
    required this.values,
    required this.selected,
    required this.onSelected,
  });

  final List<String> labels;
  final List<int> values;
  final int selected;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (var i = 0; i < labels.length; i++)
          ChoiceChip(
            label: Text(labels[i]),
            selected: selected == values[i],
            onSelected: (_) => onSelected(values[i]),
            selectedColor: AppColors.brandSoft,
            labelStyle: GoogleFonts.nunito(
              fontWeight: FontWeight.w800,
              color: AppColors.brandDeep,
            ),
          ),
      ],
    );
  }
}
