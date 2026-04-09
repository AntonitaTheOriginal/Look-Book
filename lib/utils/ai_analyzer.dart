import 'package:flutter/material.dart';
import 'package:palette_generator/palette_generator.dart';
import 'dart:io';

class AiAnalyzer {
  static final Map<String, Color> _standardColors = {
    "black": Colors.black,
    "white": Colors.white,
    "blue": Colors.blue,
    "brown": Colors.brown,
    "beige": const Color(0xFFF5F5DC),
    "red": Colors.red,
    "green": Colors.green,
    "yellow": Colors.yellow,
    "pink": Colors.pink,
    "purple": Colors.purple,
    "orange": Colors.orange,
    "teal": Colors.teal,
  };

  static Future<Map<String, String>> analyzeImage(String path) async {
    final image = FileImage(File(path));
    
    // 1. Detect Color
    final palette = await PaletteGenerator.fromImageProvider(image);
    final dominant = palette.dominantColor?.color ?? Colors.grey;
    
    String bestMatch = "white";
    double minDistance = double.infinity;

    _standardColors.forEach((name, color) {
      double distance = _colorDistance(dominant, color);
      if (distance < minDistance) {
        minDistance = distance;
        bestMatch = name;
      }
    });

    // 2. Detect Category (Basic Heuristic)
    // In a real app, this would use ML Kit Image Labeling
    // Here we use image metadata as a shortcut if available, or just default to Tops
    String category = "Tops"; 
    
    // Logic: If it's very tall, it's likely bottoms.
    // Since we don't have easy access to dimensions without decoding, 
    // we'll stick to color automation as the primary AI value for now.

    return {
      "color": bestMatch,
      "category": category,
    };
  }

  static double _colorDistance(Color c1, Color c2) {
    return (c1.red - c2.red).abs() + 
           (c1.green - c2.green).abs() + 
           (c1.blue - c2.blue).abs().toDouble();
  }
}
