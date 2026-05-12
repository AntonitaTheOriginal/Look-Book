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

  WeatherData({
    required this.temperature,
    required this.condition,
    required this.icon,
    this.isRainy = false,
  });
}

class WeatherService {
  static String get _apiKey => dotenv.env['OPENWEATHER_API_KEY'] ?? "";

  static Future<WeatherData> getCurrentWeather() async {
    try {
      // 1. Get Location
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled().timeout(const Duration(seconds: 5));
      if (!serviceEnabled) throw 'Location services are disabled.';

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) throw 'Location permissions are denied';
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low, // Faster lock
      ).timeout(const Duration(seconds: 10));

      // 2. Fetch Weather
      final url = Uri.parse(
          'https://api.openweathermap.org/data/2.5/weather?lat=${position.latitude}&lon=${position.longitude}&appid=$_apiKey&units=metric');
      
      final response = await http.get(url).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final main = data['main'];
        final weather = data['weather'][0];
        
        return WeatherData(
          temperature: (main['temp'] as num).toDouble(),
          condition: weather['main'],
          icon: _getWeatherIcon(weather['main']),
          isRainy: weather['main'].toString().toLowerCase().contains('rain'),
        );
      } else {
        debugPrint("Weather API Error: ${response.statusCode} - ${response.body}");
        throw 'Failed to load weather: ${response.statusCode}';
      }
    } catch (e) {
      debugPrint("Weather Integration Error: $e");
      // Fallback
      return WeatherData(
        temperature: 20.0,
        condition: "Unknown",
        icon: "⛅",
        isRainy: false,
      );
    }
  }

  static String _getWeatherIcon(String condition) {
    switch (condition.toLowerCase()) {
      case 'clear': return "☀️";
      case 'clouds': return "☁️";
      case 'rain': return "🌧️";
      case 'snow': return "❄️";
      case 'thunderstorm': return "⛈️";
      default: return "⛅";
    }
  }

  static String getSuggestion(WeatherData weather) {
    if (weather.isRainy) return "It's raining! Wear waterproof shoes and a jacket.";
    if (weather.temperature > 28) return "Stay cool! High sun intensity today.";
    if (weather.temperature < 15) return "It's a bit chilly. Grab a sweater!";
    return "Beautiful day! Perfect for a light outfit.";
  }
}

