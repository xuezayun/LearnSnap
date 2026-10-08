import 'package:shared_preferences/shared_preferences.dart';

import '../dictation/dictation_settings.dart';
import 'oral_math.dart';

class OralSettings {
  const OralSettings({
    this.ops = const {OralOp.add, OralOp.sub},
    this.grade = OralGrade.one,
    this.count = 10,
    this.gapSeconds = 8,
    this.repeats = 1,
    this.pace = DictationPace.normal,
  });

  final Set<OralOp> ops;
  final OralGrade grade;
  final int count;
  final int gapSeconds;
  final int repeats;
  final DictationPace pace;

  OralSettings copyWith({
    Set<OralOp>? ops,
    OralGrade? grade,
    int? count,
    int? gapSeconds,
    int? repeats,
    DictationPace? pace,
  }) {
    return OralSettings(
      ops: ops ?? this.ops,
      grade: grade ?? this.grade,
      count: count ?? this.count,
      gapSeconds: gapSeconds ?? this.gapSeconds,
      repeats: repeats ?? this.repeats,
      pace: pace ?? this.pace,
    );
  }
}

class OralSettingsStore {
  static const _opsKey = 'oral_ops';
  static const _gradeKey = 'oral_grade';
  static const _withinKey = 'oral_within';
  static const _countKey = 'oral_count';
  static const _gapKey = 'oral_gap_seconds';
  static const _repeatsKey = 'oral_repeats';
  static const _paceKey = 'oral_pace';

  Future<OralSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    final grade = _readGrade(prefs);
    final rawOps = prefs.getStringList(_opsKey);
    final ops = <OralOp>{
      for (final name in rawOps ?? const ['add', 'sub'])
        if (OralOp.values.any((op) => op.name == name))
          OralOp.values.firstWhere((op) => op.name == name),
    };
    final usable = ops.where(grade.allowedOps.contains).toSet();
    final paceName = prefs.getString(_paceKey);
    return OralSettings(
      ops: usable.isEmpty ? grade.allowedOps : usable,
      grade: grade,
      count: (prefs.getInt(_countKey) ?? 10).clamp(5, 30).toInt(),
      gapSeconds: _gapSeconds(prefs.getInt(_gapKey)),
      repeats: (prefs.getInt(_repeatsKey) ?? 1).clamp(1, 2).toInt(),
      pace: DictationPace.values.firstWhere(
        (pace) => pace.name == paceName,
        orElse: () => DictationPace.normal,
      ),
    );
  }

  OralGrade _readGrade(SharedPreferences prefs) {
    final saved = prefs.getInt(_gradeKey);
    if (saved != null) return OralGrade.fromNumber(saved);
    final within = prefs.getInt(_withinKey);
    if (within != null && within > 20) return OralGrade.two;
    return OralGrade.one;
  }

  int _gapSeconds(int? raw) {
    final value = (raw ?? 8).clamp(5, 10).toInt();
    if (value <= 5) return 5;
    if (value <= 8) return 8;
    return 10;
  }

  Future<void> save(OralSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    final ops = settings.ops.where(settings.grade.allowedOps.contains).toSet();
    await prefs.setStringList(
      _opsKey,
      [for (final op in (ops.isEmpty ? settings.grade.allowedOps : ops)) op.name],
    );
    await prefs.setInt(_gradeKey, settings.grade.number);
    await prefs.setInt(_countKey, settings.count);
    await prefs.setInt(_gapKey, _gapSeconds(settings.gapSeconds));
    await prefs.setInt(_repeatsKey, settings.repeats);
    await prefs.setString(_paceKey, settings.pace.name);
  }
}
