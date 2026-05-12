import 'dart:math';
import '../models/clothes_item.dart';
import 'weather_service.dart';

class ScoringEngine {
  // Weights (can be updated by feedback loop)
  static Map<String, double> weights = {
    'occasion': 5.0,
    'color': 4.0,
    'weather': 6.0,
    'recency': 3.0,
    'preference': 2.0,
  };

  static Map<String, dynamic> calculateScore(
    ClothesItem item, {
    String? targetOccasion,
    WeatherData? weather,
    String? topColor,
    Map<String, double>? userPreferences,
  }) {
    double totalScore = 0;
    Map<String, String> insights = {};

    // 1. Occasion Match
    double occasionScore = 0;
    if (targetOccasion != null && item.occasion == targetOccasion) {
      occasionScore = 1.0;
      insights['Occasion'] = "✔ Perfect match for $targetOccasion";
    } else {
      insights['Occasion'] = "✘ Different occasion style";
    }
    totalScore += occasionScore * weights['occasion']!;

    // 2. Color Harmony (if matching against a top)
    double colorScore = 0;
    if (topColor != null) {
      final harmony = getColorHarmony(topColor, item.color, item.colorHue);
      colorScore = harmony['score'] as double;
      insights['Color'] = "✔ ${harmony['type']}";
    } else {
      colorScore = 0.5; // Neutral start
      insights['Color'] = "✔ Neutral starting point";
    }
    totalScore += colorScore * weights['color']!;

    // 3. Weather Suitability
    double weatherScore = 0.5;
    if (weather != null) {
      weatherScore = getWeatherMatch(item, weather);
      if (weatherScore > 0.8) {
        insights['Weather'] = "✔ Great for ${weather.temperature}°C";
      } else if (weatherScore < 0.4) {
        insights['Weather'] = "⚠ Might be too hot/cold";
      } else {
        insights['Weather'] = "✔ Suitable for current weather";
      }
    }
    totalScore += weatherScore * weights['weather']!;

    // 4. Recency (Penalty for recently worn)
    double recencyScore = 1.0;
    if (item.lastWornDate != null) {
      final daysSince = DateTime.now().difference(item.lastWornDate!).inDays;
      if (daysSince < 1) recencyScore = 0.1;
      else if (daysSince < 3) recencyScore = 0.4;
      else if (daysSince < 7) recencyScore = 0.7;
      
      if (recencyScore < 0.5) insights['Freshness'] = "⚠ Worn recently";
      else insights['Freshness'] = "✔ Fresh pick!";
    } else {
      insights['Freshness'] = "✔ New discovery!";
    }
    totalScore += recencyScore * weights['recency']!;

    return {
      'total': totalScore,
      'insights': insights,
    };
  }

  static double getWeatherMatch(ClothesItem item, WeatherData weather) {
    double score = 0.8; // Baseline
    final temp = weather.temperature;
    final isRainy = weather.isRainy;
    final isWindy = weather.condition.toLowerCase().contains('wind') || weather.condition.toLowerCase().contains('storm');

    // 1. Rain & Protection Logic
    if (isRainy) {
      if (item.weatherSuitability.contains('Rainy') || item.tags.contains('Waterproof')) {
        score = 1.0;
      } else if (item.tags.contains('Quick-dry')) {
        score = 0.7;
      } else {
        score = 0.2; // Avoid heavy non-waterproof items
      }
    }

    if (isWindy && item.tags.contains('Windproof')) {
      score = min(1.0, score + 0.2);
    }

    // 2. Temperature & Fabric Logic
    if (temp > 30) {
      // Very Hot: Favor Breathable/Linen
      if (item.tags.contains('Linen') || item.tags.contains('Breathable') || item.tags.contains('Thin')) {
        score = min(1.0, score + 0.2);
      }
      if (item.weatherSuitability.contains('Cold') || item.tags.contains('Wool')) {
        score = max(0.0, score - 0.7);
      }
    } else if (temp > 22) {
      // Warm: Favor Cotton/Thin
      if (item.tags.contains('Cotton') || item.tags.contains('Thin')) {
        score = min(1.0, score + 0.1);
      }
    } else if (temp < 10) {
      // Cold: Favor Wool/Thermal/Thick
      if (item.tags.contains('Wool') || item.tags.contains('Thermal') || item.tags.contains('Thick') || item.tags.contains('Heavy Wool')) {
        score = min(1.0, score + 0.3);
      }
      if (item.weatherSuitability.contains('Hot') || item.tags.contains('Linen')) {
        score = max(0.0, score - 0.5);
      }
    } else if (temp < 0) {
      // Freezing: Mandatory Insulation
      if (item.tags.contains('Thermal') || item.tags.contains('Heavy')) {
        score = 1.0;
      } else {
        score = max(0.0, score - 0.4);
      }
    }

    return score.clamp(0.0, 1.0);
  }

  static Map<String, dynamic> getColorHarmony(String color1, String color2, double hue2) {
    // Basic neutral check
    if (isNeutral(color1) || isNeutral(color2)) {
      return {'score': 0.8, 'type': 'Classic Neutral Match'};
    }
    
    // This would ideally use hue values
    return {'score': 0.7, 'type': 'Harmonious Match'};
  }

  static bool isNeutral(String color) {
    return ['black', 'white', 'beige', 'brown', 'grey'].contains(color.toLowerCase());
  }
}

