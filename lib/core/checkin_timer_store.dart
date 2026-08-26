import 'package:shared_preferences/shared_preferences.dart';

import 'checkin_timer.dart';

class CheckinTimerStore {
  CheckinTimerStore({SharedPreferences? prefs}) : _prefsOverride = prefs;

  final SharedPreferences? _prefsOverride;

  String _storageKey({
    required int assignmentId,
    required int childId,
    required DateTime now,
  }) {
    return 'checkin_timer_end_${childId}_${assignmentId}_${checkinTimerDayKey(now)}';
  }

  String _submittedKey({
    required int assignmentId,
    required int childId,
    required DateTime now,
  }) {
    return 'checkin_timer_done_${childId}_${assignmentId}_${checkinTimerDayKey(now)}';
  }

  Future<SharedPreferences> _prefs() async {
    return _prefsOverride ?? SharedPreferences.getInstance();
  }

  Future<DateTime?> readEndAt({
    required int assignmentId,
    required int childId,
    DateTime? now,
  }) async {
    final prefs = await _prefs();
    final ms = prefs.getInt(
      _storageKey(
        assignmentId: assignmentId,
        childId: childId,
        now: now ?? DateTime.now(),
      ),
    );
    if (ms == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(ms);
  }

  Future<bool> isSubmitted({
    required int assignmentId,
    required int childId,
    DateTime? now,
  }) async {
    final prefs = await _prefs();
    return prefs.getBool(
          _submittedKey(
            assignmentId: assignmentId,
            childId: childId,
            now: now ?? DateTime.now(),
          ),
        ) ??
        false;
  }

  Future<void> markSubmitted({
    required int assignmentId,
    required int childId,
    DateTime? now,
  }) async {
    final clock = now ?? DateTime.now();
    final prefs = await _prefs();
    await prefs.setBool(
      _submittedKey(assignmentId: assignmentId, childId: childId, now: clock),
      true,
    );
  }

  Future<DateTime> start({
    required int assignmentId,
    required int childId,
    required Duration duration,
    DateTime? now,
  }) async {
    final clock = now ?? DateTime.now();
    if (await isSubmitted(
      assignmentId: assignmentId,
      childId: childId,
      now: clock,
    )) {
      throw StateError('timer locked after first submit');
    }
    final safe = duration.inSeconds <= 0 ? const Duration(minutes: 15) : duration;
    final endAt = clock.add(safe);
    final prefs = await _prefs();
    await prefs.setInt(
      _storageKey(assignmentId: assignmentId, childId: childId, now: clock),
      endAt.millisecondsSinceEpoch,
    );
    return endAt;
  }
}
