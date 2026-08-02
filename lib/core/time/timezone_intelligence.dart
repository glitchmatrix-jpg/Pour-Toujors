import 'package:timezone/timezone.dart' as tz;

class OffsetChange {
  const OffsetChange({
    required this.zoneId,
    required this.at,
    required this.oldOffset,
    required this.newOffset,
  });

  final String zoneId;
  final DateTime at;
  final Duration oldOffset;
  final Duration newOffset;

  bool get movesForward => newOffset > oldOffset;
}

class TimezoneSnapshot {
  const TimezoneSnapshot({
    required this.zoneId,
    required this.localTime,
    required this.utcOffset,
    required this.viewerDifference,
    required this.observesDst,
    required this.nextChange,
  });

  final String zoneId;
  final DateTime localTime;
  final Duration utcOffset;
  final Duration viewerDifference;
  final bool observesDst;
  final OffsetChange? nextChange;
}

class TimezoneIntelligenceService {
  static const cityZones = <String, String>{
    'karachi': 'Asia/Karachi',
    'chiba': 'Asia/Tokyo',
    'dublin': 'Europe/Dublin',
    'hattiesburg': 'America/Chicago',
  };

  TimezoneSnapshot snapshot({
    required String cityId,
    required String viewerCityId,
    DateTime? now,
  }) {
    final instant = now ?? DateTime.now().toUtc();
    final zoneId = cityZones[cityId]!;
    final viewerZoneId = cityZones[viewerCityId]!;
    final zone = tz.getLocation(zoneId);
    final viewerZone = tz.getLocation(viewerZoneId);
    final local = tz.TZDateTime.from(instant, zone);
    final viewerLocal = tz.TZDateTime.from(instant, viewerZone);
    final next = nextOffsetChange(zoneId, from: instant);
    final observes = _observesOffsetChanges(zoneId, instant.year);
    return TimezoneSnapshot(
      zoneId: zoneId,
      localTime: local,
      utcOffset: local.timeZoneOffset,
      viewerDifference: local.timeZoneOffset - viewerLocal.timeZoneOffset,
      observesDst: observes,
      nextChange: next,
    );
  }

  OffsetChange? nextOffsetChange(
    String zoneId, {
    DateTime? from,
    Duration horizon = const Duration(days: 550),
  }) {
    final zone = tz.getLocation(zoneId);
    final start = (from ?? DateTime.now().toUtc()).toUtc();
    var cursor = start;
    var previous = tz.TZDateTime.from(cursor, zone).timeZoneOffset;
    final end = start.add(horizon);

    while (cursor.isBefore(end)) {
      cursor = cursor.add(const Duration(hours: 6));
      final current = tz.TZDateTime.from(cursor, zone).timeZoneOffset;
      if (current != previous) {
        var low = cursor.subtract(const Duration(hours: 6));
        var high = cursor;
        while (high.difference(low) > const Duration(minutes: 1)) {
          final mid = low.add(Duration(milliseconds: high.difference(low).inMilliseconds ~/ 2));
          final midOffset = tz.TZDateTime.from(mid, zone).timeZoneOffset;
          if (midOffset == previous) {
            low = mid;
          } else {
            high = mid;
          }
        }
        return OffsetChange(
          zoneId: zoneId,
          at: high.toUtc(),
          oldOffset: previous,
          newOffset: current,
        );
      }
      previous = current;
    }
    return null;
  }

  bool _observesOffsetChanges(String zoneId, int year) {
    final zone = tz.getLocation(zoneId);
    final january = tz.TZDateTime(zone, year, 1, 15).timeZoneOffset;
    final july = tz.TZDateTime(zone, year, 7, 15).timeZoneOffset;
    return january != july;
  }

  bool isAmbiguousLocalTime(String zoneId, DateTime localWallTime) {
    final zone = tz.getLocation(zoneId);
    final earlier = tz.TZDateTime(
      zone,
      localWallTime.year,
      localWallTime.month,
      localWallTime.day,
      localWallTime.hour,
      localWallTime.minute,
    );
    final later = earlier.add(const Duration(hours: 1));
    return earlier.year == later.year &&
        earlier.month == later.month &&
        earlier.day == later.day &&
        earlier.hour == later.hour &&
        earlier.timeZoneOffset != later.timeZoneOffset;
  }

  bool isSkippedLocalTime(String zoneId, DateTime localWallTime) {
    final zone = tz.getLocation(zoneId);
    final resolved = tz.TZDateTime(
      zone,
      localWallTime.year,
      localWallTime.month,
      localWallTime.day,
      localWallTime.hour,
      localWallTime.minute,
    );
    return resolved.year != localWallTime.year ||
        resolved.month != localWallTime.month ||
        resolved.day != localWallTime.day ||
        resolved.hour != localWallTime.hour ||
        resolved.minute != localWallTime.minute;
  }

  DateTime convert({
    required DateTime instant,
    required String destinationZoneId,
  }) => tz.TZDateTime.from(instant.toUtc(), tz.getLocation(destinationZoneId));

  String describeChange(OffsetChange change, String cityName) {
    final direction = change.movesForward ? 'moves one hour forward' : 'moves one hour back';
    return '$cityName $direction on ${change.at.toLocal().day}/${change.at.toLocal().month}.';
  }
}
