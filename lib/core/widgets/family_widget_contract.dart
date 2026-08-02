import '../../data/family_seed.dart';

enum FamilyWidgetMomentKind {
  birthday,
  holiday,
  callWindow,
  weatherAlert,
  clockChange,
}

class FamilyWidgetMoment {
  const FamilyWidgetMoment({
    required this.kind,
    required this.title,
    required this.subtitle,
    required this.at,
    this.route,
    this.cityId,
  });

  final FamilyWidgetMomentKind kind;
  final String title;
  final String subtitle;
  final DateTime at;
  final String? route;
  final String? cityId;

  Map<String, Object?> toJson() => {
        'kind': kind.name,
        'title': title,
        'subtitle': subtitle,
        'at': at.toUtc().toIso8601String(),
        'route': route,
        'cityId': cityId,
      };
}

class FamilyWidgetCityStatus {
  const FamilyWidgetCityStatus({
    required this.cityId,
    required this.cityName,
    required this.localTime,
    required this.isDaylight,
    required this.weatherLabel,
    required this.temperatureCelsius,
    required this.memberCount,
    required this.availableCount,
    required this.hasMeaningfulAlert,
  });

  final String cityId;
  final String cityName;
  final DateTime localTime;
  final bool isDaylight;
  final String weatherLabel;
  final double? temperatureCelsius;
  final int memberCount;
  final int availableCount;
  final bool hasMeaningfulAlert;

  Map<String, Object?> toJson() => {
        'cityId': cityId,
        'cityName': cityName,
        'localTime': localTime.toIso8601String(),
        'isDaylight': isDaylight,
        'weatherLabel': weatherLabel,
        'temperatureCelsius': temperatureCelsius,
        'memberCount': memberCount,
        'availableCount': availableCount,
        'hasMeaningfulAlert': hasMeaningfulAlert,
      };
}

class FamilyWidgetOverlapSegment {
  const FamilyWidgetOverlapSegment({
    required this.start,
    required this.end,
    required this.score,
    required this.label,
    required this.includedMemberNames,
  });

  final DateTime start;
  final DateTime end;
  final double score;
  final String label;
  final List<String> includedMemberNames;

  Map<String, Object?> toJson() => {
        'start': start.toUtc().toIso8601String(),
        'end': end.toUtc().toIso8601String(),
        'score': score,
        'label': label,
        'includedMemberNames': includedMemberNames,
      };
}

class SmallFamilyWidgetData {
  const SmallFamilyWidgetData({
    required this.generatedAt,
    required this.viewerName,
    required this.nextMoment,
  });

  final DateTime generatedAt;
  final String viewerName;
  final FamilyWidgetMoment nextMoment;

  Map<String, Object?> toJson() => {
        'schemaVersion': 1,
        'size': 'small',
        'generatedAt': generatedAt.toUtc().toIso8601String(),
        'viewerName': viewerName,
        'nextMoment': nextMoment.toJson(),
      };
}

class MediumFamilyWidgetData {
  const MediumFamilyWidgetData({
    required this.generatedAt,
    required this.viewerName,
    required this.cities,
  }) : assert(cities.length == 4);

  final DateTime generatedAt;
  final String viewerName;
  final List<FamilyWidgetCityStatus> cities;

  Map<String, Object?> toJson() => {
        'schemaVersion': 1,
        'size': 'medium',
        'generatedAt': generatedAt.toUtc().toIso8601String(),
        'viewerName': viewerName,
        'cities': cities.map((city) => city.toJson()).toList(),
      };
}

class LargeFamilyWidgetData {
  const LargeFamilyWidgetData({
    required this.generatedAt,
    required this.viewerName,
    required this.windowStart,
    required this.windowEnd,
    required this.segments,
  });

  final DateTime generatedAt;
  final String viewerName;
  final DateTime windowStart;
  final DateTime windowEnd;
  final List<FamilyWidgetOverlapSegment> segments;

  Map<String, Object?> toJson() => {
        'schemaVersion': 1,
        'size': 'large',
        'generatedAt': generatedAt.toUtc().toIso8601String(),
        'viewerName': viewerName,
        'windowStart': windowStart.toUtc().toIso8601String(),
        'windowEnd': windowEnd.toUtc().toIso8601String(),
        'segments': segments.map((segment) => segment.toJson()).toList(),
      };
}

int familyCountForCity(String cityId) =>
    familyMembers.where((member) => member.cityId == cityId).length;
