import 'package:flutter/material.dart';
import 'package:palette_generator/palette_generator.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:google_mlkit_selfie_segmentation/google_mlkit_selfie_segmentation.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

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

  // 1. Core Analysis (Colors & Category)
  static Future<Map<String, dynamic>> analyzeImage(String path) async {
    final bytes = await File(path).readAsBytes();
    final imageProvider = MemoryImage(bytes);
    
    // Detect Color
    final palette = await PaletteGenerator.fromImageProvider(imageProvider);
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

    // Detect Hue for Scoring Engine
    final hsv = HSVColor.fromColor(dominant);
    final double hue = hsv.hue;

    // Advanced Metadata / Tags
    final decodedImage = img.decodeImage(bytes);
    List<String> suggestedTags = [];
    if (decodedImage != null) {
      final ratio = decodedImage.height / decodedImage.width;
      if (ratio > 1.8) suggestedTags.add("Slim Fit");
      if (ratio < 1.1) suggestedTags.add("Oversized");
      
      // Pattern detection (Heuristic: Check color variance in palette)
      if (palette.colors.length > 5) {
        suggestedTags.add("Patterned");
      } else {
        suggestedTags.add("Plain");
      }
    }

    return {
      "color": bestMatch,
      "hue": hue,
      "category": "Tops", // Heuristic default
      "tags": suggestedTags,
    };
  }

  // 2. Offline Background Removal
  static Future<String?> removeBackground(String inputPath) async {
    try {
      final inputImage = InputImage.fromFilePath(inputPath);
      final segmenter = SelfieSegmenter(
        mode: SegmenterMode.single,
        enableRawSizeMask: true,
      );

      final mask = await segmenter.processImage(inputImage);
      if (mask == null) return null;

      final bytes = await File(inputPath).readAsBytes();
      final decodedImage = img.decodeImage(bytes);
      if (decodedImage == null) return null;

      final width = mask.width;
      final height = mask.height;
      final confidences = mask.confidences;

      // Resize decoded image to match mask if they differ
      img.Image processed = img.copyResize(decodedImage, width: width, height: height);
      
      // Create a transparent image
      final outImage = img.Image(width: width, height: height, numChannels: 4);

      for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
          final double confidence = confidences![y * width + x];
          final pixel = processed.getPixel(x, y);

          if (confidence > 0.6) { // Foreground
            outImage.setPixel(x, y, pixel);
          } else {
            // Transparent background
            outImage.setPixel(x, y, img.ColorFloat64.rgba(0, 0, 0, 0));
          }
        }
      }

      final directory = await getTemporaryDirectory();
      final outputPath = '${directory.path}/bg_removed_${DateTime.now().millisecondsSinceEpoch}.png';
      await File(outputPath).writeAsBytes(img.encodePng(outImage));
      
      segmenter.close();
      return outputPath;
    } catch (e) {
      debugPrint("Background removal error: $e");
      return null;
    }
  }

  static double _colorDistance(Color c1, Color c2) {
    return (c1.red - c2.red).abs() + 
           (c1.green - c2.green).abs() + 
           (c1.blue - c2.blue).abs().toDouble();
  }
}
