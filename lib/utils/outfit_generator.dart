import 'dart:math';
import 'package:hive_flutter/hive_flutter.dart';
import 'weather_service.dart';

// 🎨 Color Theory Logic
const Map<String, int> colorWheel = {
  "red": 0,
  "orange": 30,
  "yellow": 60,
  "green": 120,
  "teal": 180,
  "blue": 240,
  "purple": 270,
  "pink": 330,
};

bool isNeutral(String color) {
  return color == "black" ||
      color == "white" ||
      color == "beige" ||
      color == "brown";
}

double getHue(String color) {
  return (colorWheel[color.toLowerCase()] ?? -1).toDouble();
}

Map<String, dynamic> getColorScore(String color1, String color2) {
  if (isNeutral(color1) || isNeutral(color2)) {
    return {"score": 5, "type": "Classic Neutral"};
  }
  double hue1 = getHue(color1);
  double hue2 = getHue(color2);
  if (hue1 == -1 || hue2 == -1) return {"score": 1, "type": "Basic Match"};
  double diff = (hue1 - hue2).abs();
  if (diff > 180) diff = 360 - diff;
  if (diff == 0) return {"score": 10, "type": "Monochromatic"};
  if (diff >= 150 && diff <= 210) return {"score": 12, "type": "Complementary (Bold Contrast)"};
  if (diff >= 30 && diff <= 60) return {"score": 8, "type": "Analogous (Subtle & Chic)"};
  return {"score": 2, "type": "Adventurous Mix"};
}

// 📅 Recency Penalty: items worn recently should score lower for variety
int getRecencyPenalty(dynamic item) {
  final lastWorn = item['lastWornDate'];
  if (lastWorn == null) return 0; // Never worn = no penalty
  final daysSinceWorn = DateTime.now().difference(DateTime.parse(lastWorn)).inDays;
  if (daysSinceWorn <= 1) return -8;  // Worn today or yesterday
  if (daysSinceWorn <= 3) return -4;  // Worn this week
  if (daysSinceWorn <= 7) return -2;  // Worn last week
  return 0;
}

Map<String, dynamic> generateOutfit({
  WeatherData? weather,
  String? targetOccasion,
  String? targetPlace,
  bool hurryMode = false,
  bool boldMode = true,
  bool luckyDip = false,  // 🎲 Ignores all filters for random discovery
}) {
  final box = Hive.box('clothesBox');
  final Map<dynamic, dynamic> allEntries = box.toMap();
  final random = Random();

  // 🎲 Lucky Dip: fully random, ignores dirty/ironing filters
  if (luckyDip) {
    final all = allEntries.entries.toList();
    final tops = all.where((e) => e.value['category'] == 'Tops').toList();
    final bottoms = all.where((e) => e.value['category'] == 'Bottoms').toList();
    final footwear = all.where((e) => e.value['category'] == 'Footwear').toList();
    final dresses = all.where((e) => e.value['category'] == 'Dresses').toList();

    // Prefer dress outfit if available
    if (dresses.isNotEmpty && footwear.isNotEmpty && random.nextBool()) {
      final dress = dresses[random.nextInt(dresses.length)];
      final shoe = footwear[random.nextInt(footwear.length)];
      return {
        "top": null, "topKey": null,
        "bottom": dress.value, "bottomKey": dress.key,
        "shoes": shoe.value, "shoesKey": shoe.key,
        "isDressOutfit": true,
        "harmony": "Lucky Dip",
        "suggestion": "🎲 Lucky Dip! Surprise yourself!",
      };
    }

    if (tops.isEmpty || bottoms.isEmpty || footwear.isEmpty) {
      return {"top": null, "bottom": null, "shoes": null};
    }
    return {
      "top": tops[random.nextInt(tops.length)].value,
      "topKey": tops[random.nextInt(tops.length)].key,
      "bottom": bottoms[random.nextInt(bottoms.length)].value,
      "bottomKey": bottoms[random.nextInt(bottoms.length)].key,
      "shoes": footwear[random.nextInt(footwear.length)].value,
      "shoesKey": footwear[random.nextInt(footwear.length)].key,
      "isDressOutfit": false,
      "harmony": "Lucky Dip",
      "suggestion": "🎲 Lucky Dip! You might discover a hidden gem!",
    };
  }

  // Standard outfit generation flow
  final items = allEntries.entries.where((e) {
    final item = e.value;
    final isDirty = item['isDirty'] ?? false;
    // BUG FIX: Default needsIroning to FALSE (not true) for legacy items
    if (hurryMode && (item['needsIroning'] ?? false)) return false;
    // Footwear is never "dirty" in the laundry sense — always available
    if (item['category'] == 'Footwear') return true;
    return !isDirty;
  }).toList();

  final tops = items.where((e) => e.value['category'] == 'Tops').toList();
  final bottoms = items.where((e) => e.value['category'] == 'Bottoms').toList();
  final footwear = items.where((e) => e.value['category'] == 'Footwear').toList();
  final dresses = items.where((e) => e.value['category'] == 'Dresses').toList();

  // 👗 Dress Path: if dresses available, 40% chance to suggest dress outfit
  final canUseDress = dresses.isNotEmpty && footwear.isNotEmpty;
  final useDress = canUseDress && random.nextInt(10) < 4;

  if (useDress) {
    dynamic pickBestFromPool(List<MapEntry<dynamic, dynamic>> pool, {String? matchColor}) {
      final scored = pool.map((e) {
        int score = getRecencyPenalty(e.value);
        if (e.value['occasion'] == targetOccasion) score += 5;
        if (e.value['place'] == targetPlace) score += 3;
        if (matchColor != null) score += getColorScore(matchColor, e.value['color'] ?? '')['score'] as int;
        return MapEntry(e, score);
      }).toList();
      scored.sort((a, b) => b.value.compareTo(a.value));
      final topPool = scored.take(3).toList();
      return topPool[random.nextInt(min(3, topPool.length))].key;
    }
    final dress = pickBestFromPool(dresses);
    final shoe = pickBestFromPool(footwear, matchColor: dress.value['color']);
    return {
      "top": null, "topKey": null,
      "bottom": dress.value, "bottomKey": dress.key,
      "shoes": shoe.value, "shoesKey": shoe.key,
      "isDressOutfit": true,
      "harmony": getColorScore(dress.value['color'] ?? '', shoe.value['color'] ?? '')['type'],
      "suggestion": "A dress outfit! Effortless and chic. ✨",
    };
  }

  if (tops.isEmpty || bottoms.isEmpty || footwear.isEmpty) {
    return {"top": null, "bottom": null, "shoes": null};
  }

  // 1. Pick Top with occasion/place scoring + recency penalty
  final topsWithScores = tops.map((e) {
    int score = getRecencyPenalty(e.value);
    if (e.value['occasion'] == targetOccasion) score += 5;
    if (e.value['place'] == targetPlace) score += 3;
    return MapEntry(e, score);
  }).toList();
  topsWithScores.sort((a, b) => b.value.compareTo(a.value));
  final selectedTopEntry = topsWithScores.take(3).toList()[random.nextInt(min(3, topsWithScores.length))].key;

  // 2. Match Bottoms & Footwear via Color Theory + recency penalty
  dynamic pickMatching(List<MapEntry<dynamic, dynamic>> pool, String topColor) {
    final scoredItems = pool.map((e) {
      final colorResult = getColorScore(topColor, e.value['color'] ?? "");
      int score = (colorResult['score'] as int) + getRecencyPenalty(e.value);
      if (e.value['occasion'] == targetOccasion) score += 4;
      return {"entry": e, "score": score, "type": colorResult['type']};
    }).toList();
    scoredItems.sort((a, b) => (b['score'] as int).compareTo(a['score'] as int));
    return scoredItems.first;
  }

  final bottomResult = pickMatching(bottoms, selectedTopEntry.value['color'] ?? '');
  final shoeResult = pickMatching(footwear, selectedTopEntry.value['color'] ?? '');

  return {
    "top": selectedTopEntry.value,
    "topKey": selectedTopEntry.key,
    "bottom": bottomResult['entry'].value,
    "bottomKey": bottomResult['entry'].key,
    "shoes": shoeResult['entry'].value,
    "shoesKey": shoeResult['entry'].key,
    "isDressOutfit": false,
    "harmony": bottomResult['type'],
    "suggestion": hurryMode
        ? "Quick pick! No ironing required. ⚡"
        : "Matched using ${bottomResult['type']} theory. Looks sharp!",
  };
}