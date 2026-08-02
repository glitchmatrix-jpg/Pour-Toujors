import 'dart:convert';

import 'package:http/http.dart' as http;

class NationalHoliday {
  const NationalHoliday({
    required this.date,
    required this.name,
    required this.countryCode,
  });

  final DateTime date;
  final String name;
  final String countryCode;
}

class HolidayService {
  static const countryCodes = <String, String>{
    'karachi': 'PK',
    'chiba': 'JP',
    'dublin': 'IE',
    'hattiesburg': 'US',
  };

  Future<List<NationalHoliday>> fetchUpcoming(
    String cityId, {
    int limit = 3,
  }) async {
    try {
      final code = countryCodes[cityId]!;
      final now = DateTime.now();
      final results = <NationalHoliday>[];

      for (final year in [now.year, now.year + 1]) {
        final response = await http
            .get(
              Uri.https(
                'date.nager.at',
                '/api/v3/PublicHolidays/$year/$code',
              ),
            )
            .timeout(const Duration(seconds: 8));
        if (response.statusCode != 200) continue;
        final rows = jsonDecode(response.body) as List<dynamic>;
        for (final raw in rows.cast<Map<String, dynamic>>()) {
          final date = DateTime.parse(raw['date'] as String);
          if (!date.isBefore(DateTime(now.year, now.month, now.day))) {
            results.add(
              NationalHoliday(
                date: date,
                name: (raw['localName'] ?? raw['name']) as String,
                countryCode: code,
              ),
            );
          }
        }
      }

      results.sort((a, b) => a.date.compareTo(b.date));
      return results.take(limit).toList();
    } catch (_) {
      return const <NationalHoliday>[];
    }
  }
}
