class WeatherData {
  final double temperature;
  final String condition;
  final String icon;

  WeatherData({
    required this.temperature,
    required this.condition,
    required this.icon,
  });
}

class WeatherService {
  static WeatherData getCurrentWeather() {
    // This is a mock implementation. 
    // In a real app, this would fetch from an API like OpenWeatherMap.
    return WeatherData(
      temperature: 22.0,
      condition: "Sunny",
      icon: "☀️",
    );
  }

  static String getSuggestion(double temp) {
    if (temp > 25) return "Stay cool! It's hot outside.";
    if (temp < 15) return "It's a bit chilly. Grab a jacket!";
    return "Perfect weather for a light outfit!";
  }
}
