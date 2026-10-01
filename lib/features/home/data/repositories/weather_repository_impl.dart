import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../domain/repositories/weather_repository.dart';

/// Cuaca dari Open-Meteo: gratis dan tanpa API key.
class WeatherRepositoryImpl implements WeatherRepository {
  final http.Client _client;
  final Map<String, WeatherSummary> _cache = {};

  WeatherRepositoryImpl({http.Client? client}) : _client = client ?? http.Client();

  @override
  Future<WeatherSummary?> todayFor(String city) async {
    final key = city.trim().toLowerCase();
    if (key.isEmpty) return null;
    if (_cache.containsKey(key)) return _cache[key];
    try {
      final geo = await _client.get(Uri.parse('https://geocoding-api.open-meteo.com/v1/search?count=1&language=id&name=${Uri.encodeComponent(city)}'));
      final results = (jsonDecode(geo.body)['results'] as List?) ?? const [];
      if (results.isEmpty) return null;
      final lat = results.first['latitude'];
      final lon = results.first['longitude'];
      final res = await _client.get(Uri.parse(
          'https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lon&hourly=temperature_2m,weather_code&forecast_days=1&timezone=auto'));
      final hourly = jsonDecode(res.body)['hourly'] as Map<String, dynamic>;
      final temps = (hourly['temperature_2m'] as List).cast<num>();
      final codes = (hourly['weather_code'] as List).cast<num>();
      final summary = WeatherSummary(
        morning: temps[7].toDouble(),
        noon: temps[13].toDouble(),
        condition: _conditionOf(codes[13].toInt()),
      );
      _cache[key] = summary;
      return summary;
    } catch (_) {
      return null;
    }
  }

  static String _conditionOf(int code) {
    if (code == 0) return 'cerah';
    if (code <= 3) return 'berawan';
    if (code >= 51 && code <= 67) return 'hujan';
    if (code >= 80 && code <= 82) return 'hujan';
    if (code >= 95) return 'badai';
    return 'berawan';
  }
}
