import 'package:shared_preferences/shared_preferences.dart';

import '../dictation/dictation_settings.dart';
import 'oral_math.dart';

class OralSettings {
  const OralSettings({
    this.ops = const {OralOp.add, OralOp.sub},
    this.within = 20,
    this.count = 10,
    this.gapSeconds = 8,
    this.repeats = 1,
    this.pace = DictationPace.normal,
  });

  final Set<OralOp> ops;
  final int within;
  final int count;
  final int gapSeconds;
  final int repeats;
  final DictationPace pace;

  OralSettings copyWith({
    Set<OralOp>? ops,
    int? within,
    int? count,
    int? gapSeconds,
    int? repeats,
    DictationPace? pace,
  }) {
    return OralSettings(
      ops: ops ?? this.ops,
      within: within ?? this.within,
      count: count ?? this.count,
      gapSeconds: gapSeconds ?? this.gapSeconds,
      repeats: repeats ?? this.repeats,
      pace: pace ?? this.pace,
    );
  }
}

class OralSettingsStore {
  static const _opsKey = 'oral_ops';
  static const _withinKey = 'oral_within';
  static const _countKey = 'oral_count';
  static const _gapKey = 'oral_gap_seconds';
  static const _repeatsKey = 'oral_repeats';
  static const _paceKey = 'oral_pace';

  Future<OralSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    final rawOps = prefs.getStringList(_opsKey);
    final ops = <OralOp>{
      for (final name in rawOps ?? const ['add', 'sub'])
        if (OralOp.values.any((op) => op.name == name))
          OralOp.values.firstWhere((op) => op.name == name),
    };
    final paceName = prefs.getString(_paceKey);
    return OralSettings(
      ops: ops.isEmpty ? const {OralOp.add, OralOp.sub} : ops,
      within: (prefs.getInt(_withinKey) ?? 20).clamp(10, 100).toInt(),
      count: (prefs.getInt(_countKey) ?? 10).clamp(5, 30).toInt(),
      gapSeconds: (prefs.getInt(_gapKey) ?? 8).clamp(3, 15).toInt(),
      repeats: (prefs.getInt(_repeatsKey) ?? 1).clamp(1, 2).toInt(),
      pace: DictationPace.values.firstWhere(
        (pace) => pace.name == paceName,
        orElse: () => DictationPace.normal,
      ),
    );
  }

  Future<void> save(OralSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_opsKey, [for (final op in settings.ops) op.name]);
    await prefs.setInt(_withinKey, settings.within);
    await prefs.setInt(_countKey, settings.count);
    await prefs.setInt(_gapKey, settings.gapSeconds);
    await prefs.setInt(_repeatsKey, settings.repeats);
    await prefs.setString(_paceKey, settings.pace.name);
  }
}
