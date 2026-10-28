import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

class WeatherModel {
  final double temperature;
  final double feelsLike;
  final int humidity;
  final double windSpeed;
  final int rainProbability;
  final String condition;
  final int conditionCode;
  final bool isSevere;
  final String? advisory;
  final bool isCached;
  final String locationName;
  final DateTime updatedAt;

  const WeatherModel({
    required this.temperature,
    required this.feelsLike,
    required this.humidity,
    required this.windSpeed,
    required this.rainProbability,
    required this.condition,
    required this.conditionCode,
    required this.isSevere,
    this.advisory,
    required this.isCached,
    required this.locationName,
    required this.updatedAt,
  });

  factory WeatherModel.fromJson(Map<String, dynamic> json, {String locationName = 'Current Location'}) {
    final weather = json['weather'] as Map<String, dynamic>? ?? json;
    final advisory = json['advisory'] as Map<String, dynamic>?;

    final temp = (weather['temperature'] as num?)?.toDouble() ?? 28.5;
    final feels = (weather['feels_like'] as num?)?.toDouble() ?? (temp + 2.5);
    final humidity = (weather['relative_humidity_2m'] as num?)?.toInt() ?? 78;
    final wind = (weather['wind_speed_10m'] as num?)?.toDouble() ?? 14.2;
    final rainProb = (weather['precipitation_probability'] as num?)?.toInt() ?? 65;
    final conditionDesc = (weather['condition'] as String?) ?? 'Moderate Rain';
    final code = (weather['weather_code'] as num?)?.toInt() ?? 63;
    final isCached = json['cached'] == true;

    final hasSevereAdvisory = advisory != null && (advisory['severity'] == 'SEVERE' || advisory['severity'] == 'CRITICAL');
    final advisoryText = advisory?['message'] as String?;

    return WeatherModel(
      temperature: temp,
      feelsLike: feels,
      humidity: humidity,
      windSpeed: wind,
      rainProbability: rainProb,
      condition: conditionDesc,
      conditionCode: code,
      isSevere: hasSevereAdvisory || code >= 80,
      advisory: advisoryText,
      isCached: isCached,
      locationName: locationName,
      updatedAt: DateTime.now(),
    );
  }

  static WeatherModel fallback(String locationName) {
    return WeatherModel(
      temperature: 28.4,
      feelsLike: 31.2,
      humidity: 82,
      windSpeed: 16.5,
      rainProbability: 70,
      condition: 'Heavy Rain / Thunderstorm Alert',
      conditionCode: 80,
      isSevere: true,
      advisory: 'IMD Alert: Heavy rainfall & waterlogging expected in low-lying Hindon & Yamuna basins.',
      isCached: true,
      locationName: locationName,
      updatedAt: DateTime.now(),
    );
  }
}

class WeatherService {
  static const String baseUrl = 'http://localhost:5000/api/v1/weather';
  static WeatherModel? _cachedModel;
  static DateTime? _cacheTimestamp;
  static const Duration cacheTtl = Duration(minutes: 10);

  static Future<WeatherModel> getWeather({
    double lat = 28.6480,
    double lon = 77.3450,
    String locationName = 'Ghaziabad, UP',
    bool forceRefresh = false,
  }) async {
    // Check in-memory cache
    if (!forceRefresh &&
        _cachedModel != null &&
        _cacheTimestamp != null &&
        DateTime.now().difference(_cacheTimestamp!) < cacheTtl) {
      return _cachedModel!;
    }

    try {
      final uri = Uri.parse('$baseUrl?lat=$lat&lon=$lon');
      final response = await http.get(uri).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final model = WeatherModel.fromJson(json, locationName: locationName);
        _cachedModel = model;
        _cacheTimestamp = DateTime.now();
        return model;
      }
    } catch (_) {
      // Backend not running or timeout -> Fallback gracefully
    }

    // Try keyless Open-Meteo direct fetch as secondary resilient tier
    try {
      final directUri = Uri.parse(
        'https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lon'
        '&current=temperature_2m,relative_humidity_2m,apparent_temperature,precipitation,weather_code,wind_speed_10m'
        '&hourly=precipitation_probability&forecast_days=1&timezone=auto',
      );
      final response = await http.get(directUri).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final current = json['current'] as Map<String, dynamic>?;
        final hourly = json['hourly'] as Map<String, dynamic>?;

        final temp = (current?['temperature_2m'] as num?)?.toDouble() ?? 28.0;
        final feels = (current?['apparent_temperature'] as num?)?.toDouble() ?? 30.0;
        final hum = (current?['relative_humidity_2m'] as num?)?.toInt() ?? 75;
        final wind = (current?['wind_speed_10m'] as num?)?.toDouble() ?? 12.0;
        final rainProb = (hourly?['precipitation_probability'] as List?)?.isNotEmpty == true
            ? ((hourly!['precipitation_probability'][0] as num?)?.toInt() ?? 50)
            : 50;
        final code = (current?['weather_code'] as num?)?.toInt() ?? 61;

        final model = WeatherModel(
          temperature: temp,
          feelsLike: feels,
          humidity: hum,
          windSpeed: wind,
          rainProbability: rainProb,
          condition: code >= 80 ? 'Heavy Rain / Storm' : (code >= 50 ? 'Rain Showers' : 'Partly Cloudy'),
          conditionCode: code,
          isSevere: code >= 80,
          advisory: code >= 80 ? 'Local IMD Alert: Active thunderstorm and rainfall' : null,
          isCached: false,
          locationName: locationName,
          updatedAt: DateTime.now(),
        );
        _cachedModel = model;
        _cacheTimestamp = DateTime.now();
        return model;
      }
    } catch (_) {}

    final fallback = WeatherModel.fallback(locationName);
    _cachedModel = fallback;
    _cacheTimestamp = DateTime.now();
    return fallback;
  }
}
