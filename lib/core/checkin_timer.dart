enum CheckinTimerPhase { idle, running, finished }

Duration remainingUntil(DateTime endAt, DateTime now) {
  final delta = endAt.difference(now);
  return delta.isNegative ? Duration.zero : delta;
}

CheckinTimerPhase phaseFor({DateTime? endAt, required DateTime now}) {
  if (endAt == null) return CheckinTimerPhase.idle;
  if (!now.isBefore(endAt)) return CheckinTimerPhase.finished;
  return CheckinTimerPhase.running;
}

String formatCheckinCountdown(Duration remaining) {
  final total = remaining.inSeconds.clamp(0, 24 * 60 * 60);
  final hours = total ~/ 3600;
  final minutes = (total % 3600) ~/ 60;
  final seconds = total % 60;
  if (hours > 0) {
    return '${hours.toString().padLeft(2, '0')}:'
        '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }
  return '${minutes.toString().padLeft(2, '0')}:'
      '${seconds.toString().padLeft(2, '0')}';
}

String checkinTimerDayKey(DateTime now) {
  final y = now.year.toString().padLeft(4, '0');
  final m = now.month.toString().padLeft(2, '0');
  final d = now.day.toString().padLeft(2, '0');
  return '$y$m$d';
}
