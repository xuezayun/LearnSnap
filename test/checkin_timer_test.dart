import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:app/core/checkin_timer.dart';
import 'package:app/core/checkin_timer_store.dart';

void main() {
  test('formatCheckinCountdown pads minutes and seconds', () {
    expect(formatCheckinCountdown(const Duration(minutes: 12, seconds: 5)), '12:05');
    expect(formatCheckinCountdown(Duration.zero), '00:00');
    expect(
      formatCheckinCountdown(const Duration(hours: 1, minutes: 2, seconds: 3)),
      '01:02:03',
    );
  });

  test('phaseFor uses end timestamp', () {
    final now = DateTime(2026, 8, 23, 21, 0, 0);
    expect(phaseFor(endAt: null, now: now), CheckinTimerPhase.idle);
    expect(
      phaseFor(endAt: now.add(const Duration(seconds: 1)), now: now),
      CheckinTimerPhase.running,
    );
    expect(
      phaseFor(endAt: now, now: now),
      CheckinTimerPhase.finished,
    );
  });

  test('store keeps end time so leaving the page can resume', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final store = CheckinTimerStore(prefs: prefs);
    final now = DateTime(2026, 8, 23, 21, 0, 0);
    final end = await store.start(
      assignmentId: 9,
      childId: 3,
      duration: const Duration(minutes: 15),
      now: now,
    );
    expect(end, now.add(const Duration(minutes: 15)));

    final restored = await store.readEndAt(assignmentId: 9, childId: 3, now: now);
    expect(restored, end);
    expect(
      phaseFor(endAt: restored, now: now.add(const Duration(minutes: 3))),
      CheckinTimerPhase.running,
    );
    expect(
      remainingUntil(restored!, now.add(const Duration(minutes: 3))),
      const Duration(minutes: 12),
    );
  });

  test('first submit locks timer so start cannot run again', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final store = CheckinTimerStore(prefs: prefs);
    final now = DateTime(2026, 8, 23, 21, 0, 0);

    await store.start(
      assignmentId: 9,
      childId: 3,
      duration: const Duration(minutes: 15),
      now: now,
    );
    await store.markSubmitted(assignmentId: 9, childId: 3, now: now);

    expect(
      await store.isSubmitted(assignmentId: 9, childId: 3, now: now),
      isTrue,
    );
    expect(
      () => store.start(
        assignmentId: 9,
        childId: 3,
        duration: const Duration(minutes: 15),
        now: now.add(const Duration(minutes: 1)),
      ),
      throwsStateError,
    );
  });
}
