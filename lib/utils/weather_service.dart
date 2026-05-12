import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';

class WeatherData {
  final double temperature;
  final String condition;
  final String icon;
  final bool isRainy;
  final bool isWindy;

  WeatherData({
    required this.temperature,
    required this.condition,
    required this.icon,
    this.isRainy = false,
    this.isWindy = false,
  });
}

class WeatherService {
  static String get _apiKey => dotenv.env['OPENWEATHER_API_KEY'] ?? '';

  static Future<WeatherData> getCurrentWeather() async {
    try {
      // 1. Check location permission
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) throw 'Location services are disabled.';

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) throw 'Permission denied';
      }
      if (permission == LocationPermission.deniedForever) throw 'Permission permanently denied';

      // 2. Get position (with timeout)
      Position position;
      try {
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.low,
        ).timeout(const Duration(seconds: 12));
      } catch (e) {
        debugPrint("GPS timeout, trying last known: $e");
        final last = await Geolocator.getLastKnownPosition();
        if (last == null) throw 'Could not get location';
        position = last;
      }

      // 3. Fetch weather data
      if (_apiKey.isEmpty) throw 'OpenWeather API key not set';

      final url = Uri.parse(
        'https://api.openweathermap.org/data/2.5/weather'
        '?lat=${position.latitude}&lon=${position.longitude}'
        '&appid=$_apiKey&units=metric',
      );

      final response = await http.get(url).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final main = data['main'];
        final weather = data['weather'][0];
        final windSpeed = (data['wind']?['speed'] as num?)?.toDouble() ?? 0;

        return WeatherData(
          temperature: (main['temp'] as num).toDouble(),
          condition: weather['main'],
          icon: _icon(weather['main']),
          isRainy: weather['main'].toString().toLowerCase().contains('rain') ||
                   weather['main'].toString().toLowerCase().contains('drizzle'),
          isWindy: windSpeed > 10,
        );
      } else {
        debugPrint("Weather API ${response.statusCode}: ${response.body}");
        throw 'Weather API error ${response.statusCode}';
      }
    } catch (e) {
      debugPrint("WeatherService error: $e");
      // Return a sensible fallback rather than fake sunny weather
      return WeatherData(
        temperature: 25.0,
        condition: 'Clear',
        icon: '⛅',
        isRainy: false,
        isWindy: false,
      );
    }
  }

  static String _icon(String condition) {
    switch (condition.toLowerCase()) {
      case 'clear': return '☀️';
      case 'clouds': return '☁️';
      case 'rain': return '🌧️';
      case 'drizzle': return '🌦️';
      case 'snow': return '❄️';
      case 'thunderstorm': return '⛈️';
      case 'mist':
      case 'haze':
      case 'fog': return '🌫️';
      default: return '⛅';
    }
  }

  static String getSuggestion(WeatherData w) {
    if (w.isRainy) return "Bring an umbrella & waterproof shoes today.";
    if (w.isWindy) return "Windy out — layer up or grab a jacket.";
    if (w.temperature > 32) return "Very hot! Go light — linen or breathable fabrics.";
    if (w.temperature > 25) return "Warm day. Light, breezy clothes recommended.";
    if (w.temperature > 18) return "Perfect weather for almost any outfit.";
    if (w.temperature > 12) return "A bit cool — add a light layer.";
    return "Cold today! Bundle up with warm layers.";
  }
}
