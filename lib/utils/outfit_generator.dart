import 'dart:math';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/clothes_item.dart';
import 'weather_service.dart';
import 'scoring_engine.dart';

Map<String, dynamic> generateOutfit({
  WeatherData? weather,
  String? targetOccasion,
  String? targetPlace,
  bool hurryMode = false,
  bool boldMode = true,
  bool luckyDip = false,
}) {
  final box = Hive.box<ClothesItem>('clothesBox_v2');
  final List<ClothesItem> allItems = box.values.toList();
  final random = Random();

  if (luckyDip) {
    if (allItems.isEmpty) return {"top": null, "bottom": null, "shoes": null};
    
    final tops = allItems.where((i) => i.category == 'Tops').toList();
    final bottoms = allItems.where((i) => i.category == 'Bottoms').toList();
    final footwear = allItems.where((i) => i.category == 'Footwear').toList();
    
    if (tops.isEmpty || bottoms.isEmpty || footwear.isEmpty) {
      return {"top": null, "bottom": null, "shoes": null};
    }

    final t = tops[random.nextInt(tops.length)];
    final b = bottoms[random.nextInt(bottoms.length)];
    final s = footwear[random.nextInt(footwear.length)];

    return {
      "top": t,
      "topKey": t.key,
      "bottom": b,
      "bottomKey": b.key,
      "shoes": s,
      "shoesKey": s.key,
      "isDressOutfit": false,
      "harmony": "Lucky Dip",
      "suggestion": "🎲 Surprise! A random mix for discovery.",
      "aiInsights": {"Discovery": "Lucky dip ignores all rules!"}
    };
  }

  // 1. Filter available items
  final availableItems = allItems.where((item) {
    if (item.isDirty) return false;
    if (hurryMode && item.needsIroning) return false;
    return true;
  }).toList();

  final tops = availableItems.where((i) => i.category == 'Tops').toList();
  final bottoms = availableItems.where((i) => i.category == 'Bottoms').toList();
  final footwear = availableItems.where((i) => i.category == 'Footwear').toList();
  final dresses = availableItems.where((i) => i.category == 'Dresses').toList();

  // 2. Select Top (or Dress)
  // For simplicity, we'll pick Top first, then match.
  if (tops.isEmpty || bottoms.isEmpty || footwear.isEmpty) {
    return {"top": null, "bottom": null, "shoes": null};
  }

  // Score all tops
  final scoredTops = tops.map((t) {
    final res = ScoringEngine.calculateScore(
      t,
      targetOccasion: targetOccasion,
      weather: weather,
    );
    return {'item': t, 'score': res['total'] as double, 'insights': res['insights']};
  }).toList();

  scoredTops.sort((a, b) => (b['score'] as double).compareTo(a['score'] as double));
  final selectedTopResult = scoredTops.take(3).toList()[random.nextInt(min(3, scoredTops.length))];
  final selectedTop = selectedTopResult['item'] as ClothesItem;

  // 3. Match Bottoms
  final scoredBottoms = bottoms.map((b) {
    final res = ScoringEngine.calculateScore(
      b,
      targetOccasion: targetOccasion,
      weather: weather,
      topColor: selectedTop.color,
    );
    return {'item': b, 'score': res['total'] as double, 'insights': res['insights']};
  }).toList();

  scoredBottoms.sort((a, b) => (b['score'] as double).compareTo(a['score'] as double));
  final selectedBottomResult = scoredBottoms.first;
  final selectedBottom = selectedBottomResult['item'] as ClothesItem;

  // 4. Match Shoes
  final scoredShoes = footwear.map((s) {
    final res = ScoringEngine.calculateScore(
      s,
      targetOccasion: targetOccasion,
      weather: weather,
      topColor: selectedTop.color,
    );
    return {'item': s, 'score': res['total'] as double, 'insights': res['insights']};
  }).toList();

  scoredShoes.sort((a, b) => (b['score'] as double).compareTo(a['score'] as double));
  final selectedShoeResult = scoredShoes.first;
  final selectedShoe = selectedShoeResult['item'] as ClothesItem;

  // Merge Insights
  Map<String, dynamic> finalInsights = {};
  (selectedTopResult['insights'] as Map<String, String>).forEach((k, v) => finalInsights['Top $k'] = v);
  (selectedBottomResult['insights'] as Map<String, String>).forEach((k, v) => finalInsights['Bottom $k'] = v);
  (selectedShoeResult['insights'] as Map<String, String>).forEach((k, v) => finalInsights['Shoe $k'] = v);

  return {
    "top": selectedTop,
    "topKey": selectedTop.key,
    "bottom": selectedBottom,
    "bottomKey": selectedBottom.key,
    "shoes": selectedShoe,
    "shoesKey": selectedShoe.key,
    "isDressOutfit": false,
    "harmony": "AI Optimized",
    "suggestion": "Suggested by Hybrid Intelligence Engine",
    "aiInsights": finalInsights,
  };
}