import 'package:flutter/material.dart';
import 'package:palette_generator/palette_generator.dart';
import 'dart:io';
import 'dart:math';
import 'package:google_mlkit_selfie_segmentation/google_mlkit_selfie_segmentation.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

class AiAnalyzer {
  static final Map<String, Color> _standardColors = {
    "black": Colors.black,
    "white": Colors.white,
    "grey": Colors.grey,
    "navy": const Color(0xFF000080),
    "blue": Colors.blue,
    "brown": Colors.brown,
    "beige": const Color(0xFFF5F5DC),
    "red": Colors.red,
    "maroon": const Color(0xFF800000),
    "green": Colors.green,
    "olive": const Color(0xFF808000),
    "yellow": Colors.yellow,
    "pink": Colors.pink,
    "purple": Colors.purple,
    "orange": Colors.orange,
    "teal": Colors.teal,
  };

  static Future<Map<String, dynamic>> analyzeImage(String path) async {
    final bytes = await File(path).readAsBytes();
    final imageProvider = MemoryImage(bytes);
    
    // Detect Color
    final palette = await PaletteGenerator.fromImageProvider(imageProvider);
    
    // Use a more representative color (prefer vibrant or light/dark over just dominant)
    final representativeColor = palette.vibrantColor?.color ?? 
                               palette.lightVibrantColor?.color ?? 
                               palette.dominantColor?.color ?? 
                               Colors.grey;
    
    String bestMatch = "white";
    double minDistance = double.infinity;

    _standardColors.forEach((name, color) {
      double distance = _weightedColorDistance(representativeColor, color);
      if (distance < minDistance) {
        minDistance = distance;
        bestMatch = name;
      }
    });

    final hsv = HSVColor.fromColor(representativeColor);
    final double hue = hsv.hue;

    final decodedImage = img.decodeImage(bytes);
    List<String> suggestedTags = [];
    if (decodedImage != null) {
      final ratio = decodedImage.height / decodedImage.width;
      if (ratio > 1.8) suggestedTags.add("Slim Fit");
      if (ratio < 1.1) suggestedTags.add("Oversized");
      
      if (palette.colors.length > 8) { // Increased threshold for patterning
        suggestedTags.add("Patterned");
      } else {
        suggestedTags.add("Plain");
      }
    }

    return {
      "color": bestMatch,
      "hue": hue,
      "category": "Tops",
      "tags": suggestedTags,
    };
  }

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

      img.Image processed = img.copyResize(decodedImage, width: width, height: height);
      final outImage = img.Image(width: width, height: height, numChannels: 4);

      for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
          final double confidence = confidences![y * width + x];
          final pixel = processed.getPixel(x, y);

          if (confidence > 0.7) { // Increased confidence for cleaner edges
            outImage.setPixel(x, y, pixel);
          } else {
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

  // Weighted Euclidean Distance for better color perception
  // See: https://en.wikipedia.org/wiki/Color_difference
  static double _weightedColorDistance(Color c1, Color c2) {
    int rmean = ( (c1.red + c2.red) / 2 ).toInt();
    int r = c1.red - c2.red;
    int g = c1.green - c2.green;
    int b = c1.blue - c2.blue;
    return sqrt((((512+rmean)*r*r)>>8) + 4*g*g + (((767-rmean)*b*b)>>8));
  }
}
