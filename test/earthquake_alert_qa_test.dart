import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:pour_toujours/core/alerts/weather_alert_service.dart';

void main() {
  test('USGS earthquakes enter the existing city warning stream', () async {
    final eventTime = DateTime.utc(2026, 8, 2, 18).millisecondsSinceEpoch;
    final client = MockClient((request) async {
      expect(request.url.host, 'earthquake.usgs.gov');
      expect(
        request.url.path,
        '/earthquakes/feed/v1.0/summary/all_day.geojson',
      );
      return http.Response(
        jsonEncode({
          'type': 'FeatureCollection',
          'features': [
            {
              'type': 'Feature',
              'id': 'near-karachi',
              'properties': {
                'mag': 4.6,
                'place': '45 km west of Karachi, Pakistan',
                'time': eventTime,
              },
              'geometry': {
                'type': 'Point',
                'coordinates': [66.55, 24.86, 12.0],
              },
            },
            {
              'type': 'Feature',
              'id': 'tiny-distant',
              'properties': {
                'mag': 2.1,
                'place': 'Distant ocean',
                'time': eventTime,
              },
              'geometry': {
                'type': 'Point',
                'coordinates': [-150.0, 60.0, 8.0],
              },
            },
          ],
        }),
        200,
        headers: const {'content-type': 'application/geo+json'},
      );
    });

    final alerts = await WeatherAlertService(client: client)
        .fetchOfficialForCity('karachi');

    expect(alerts, hasLength(1));
    final alert = alerts.single;
    expect(alert.isEarthquake, isTrue);
    expect(alert.event, contains('M4.6'));
    expect(alert.headline, contains('Karachi'));
    expect(alert.attribution, 'U.S. Geological Survey');
    expect(alert.instruction, contains('not advance warning'));
    expect(alert.instruction, contains('Drop, Cover, and Hold On'));
    expect(alert.source, WeatherAlertSource.official);
  });
}
