import 'package:timezone/timezone.dart' as tz;

import '../../data/family_seed.dart';

class AvailabilitySnapshot {
  const AvailabilitySnapshot({
    required this.kind,
    required this.confidence,
    required this.reason,
    required this.localTime,
  });

  final AvailabilityKind kind;
  final ConfidenceLevel confidence;
  final String reason;
  final tz.TZDateTime localTime;

  String get label => switch (kind) {
        AvailabilityKind.asleep => 'Probably asleep',
        AvailabilityKind.working => 'Likely working',
        AvailabilityKind.likelyFree => 'Usually free',
        AvailabilityKind.maybeFree => 'May be free',
        AvailabilityKind.unknown => 'Schedule unclear',
      };

  String get confidenceLabel => switch (confidence) {
        ConfidenceLevel.high => 'High-confidence routine',
        ConfidenceLevel.medium => 'Routine estimate',
        ConfidenceLevel.low => 'Low-confidence estimate',
      };
}

AvailabilitySnapshot evaluateAvailability({
  required FamilyMember member,
  required FamilyCity city,
  DateTime? now,
}) {
  final instant = now ?? DateTime.now();
  final local = tz.TZDateTime.from(instant, tz.getLocation(city.timezone));
  final minute = local.hour * 60 + local.minute;

  for (final band in member.routine.bands) {
    if (band.applies(local.weekday, minute)) {
      return AvailabilitySnapshot(
        kind: band.kind,
        confidence: band.confidence,
        reason: band.reason,
        localTime: local,
      );
    }
  }

  return AvailabilitySnapshot(
    kind: AvailabilityKind.unknown,
    confidence: ConfidenceLevel.low,
    reason: 'No reliable routine information covers this time.',
    localTime: local,
  );
}
