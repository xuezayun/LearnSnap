import 'package:shared_preferences/shared_preferences.dart';

class DictationSettings {
  const DictationSettings({
    this.repeats = 2,
    this.gapSeconds = 3,
    this.pace = DictationPace.normal,
    this.lang = DictationLangPref.chinese,
  });

  final int repeats;
  final int gapSeconds;
  final DictationPace pace;
  final DictationLangPref lang;

  DictationSettings copyWith({
    int? repeats,
    int? gapSeconds,
    DictationPace? pace,
    DictationLangPref? lang,
  }) {
    return DictationSettings(
      repeats: repeats ?? this.repeats,
      gapSeconds: gapSeconds ?? this.gapSeconds,
      pace: pace ?? this.pace,
      lang: lang ?? this.lang,
    );
  }
}

enum DictationPace {
  slow(0.55, '慢'),
  normal(0.72, '正常'),
  fast(0.9, '稍快');

  const DictationPace(this.relative, this.label);

  final double relative;
  final String label;
}

enum DictationLangPref { chinese, english }

class DictationSettingsStore {
  static const _repeatsKey = 'dictation_repeats';
  static const _gapKey = 'dictation_gap_seconds';
  static const _paceKey = 'dictation_pace';
  static const _langKey = 'dictation_lang';

  Future<DictationSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    final paceName = prefs.getString(_paceKey);
    final langName = prefs.getString(_langKey);
    return DictationSettings(
      repeats: (prefs.getInt(_repeatsKey) ?? 2).clamp(1, 3).toInt(),
      gapSeconds: (prefs.getInt(_gapKey) ?? 3).clamp(1, 5).toInt(),
      pace: DictationPace.values.firstWhere(
        (pace) => pace.name == paceName,
        orElse: () => DictationPace.normal,
      ),
      lang: DictationLangPref.values.firstWhere(
        (lang) => lang.name == langName,
        orElse: () => DictationLangPref.chinese,
      ),
    );
  }

  Future<void> save(DictationSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_repeatsKey, settings.repeats.clamp(1, 3).toInt());
    await prefs.setInt(_gapKey, settings.gapSeconds.clamp(1, 5).toInt());
    await prefs.setString(_paceKey, settings.pace.name);
    await prefs.setString(_langKey, settings.lang.name);
  }
}
