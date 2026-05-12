import 'package:flutter/material.dart';
import 'package:palette_generator/palette_generator.dart';
import 'dart:io';
import 'dart:math';
import 'package:google_mlkit_selfie_segmentation/google_mlkit_selfie_segmentation.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

class AiAnalyzer {
  // Extended color palette with more nuanced shades
  static final List<_ColorEntry> _colorTable = [
    _ColorEntry("black",   const Color(0xFF111111)),
    _ColorEntry("white",   const Color(0xFFF8F8F8)),
    _ColorEntry("grey",    const Color(0xFF888888)),
    _ColorEntry("navy",    const Color(0xFF001F5B)),
    _ColorEntry("blue",    const Color(0xFF1565C0)),
    _ColorEntry("sky blue",const Color(0xFF0288D1)),
    _ColorEntry("teal",    const Color(0xFF00695C)),
    _ColorEntry("green",   const Color(0xFF2E7D32)),
    _ColorEntry("olive",   const Color(0xFF827717)),
    _ColorEntry("yellow",  const Color(0xFFF9A825)),
    _ColorEntry("orange",  const Color(0xFFE65100)),
    _ColorEntry("red",     const Color(0xFFC62828)),
    _ColorEntry("maroon",  const Color(0xFF880E4F)),
    _ColorEntry("pink",    const Color(0xFFE91E63)),
    _ColorEntry("purple",  const Color(0xFF6A1B9A)),
    _ColorEntry("lavender",const Color(0xFF9575CD)),
    _ColorEntry("brown",   const Color(0xFF5D4037)),
    _ColorEntry("beige",   const Color(0xFFF5F5DC)),
    _ColorEntry("cream",   const Color(0xFFFFFDD0)),
    _ColorEntry("khaki",   const Color(0xFFBDB76B)),
  ];

  /// Analyze image: returns color name, hue, and tags.
  static Future<Map<String, dynamic>> analyzeImage(String path) async {
    final bytes = await File(path).readAsBytes();
    final palette = await PaletteGenerator.fromImageProvider(MemoryImage(bytes), maximumColorCount: 32);

    // Prefer vibrant colors over the dominant (which is often the background)
    // We try each in order and pick the most saturated one that makes sense
    final candidates = [
      palette.vibrantColor?.color,
      palette.lightVibrantColor?.color,
      palette.darkVibrantColor?.color,
      palette.mutedColor?.color,
      palette.lightMutedColor?.color,
      palette.darkMutedColor?.color,
      palette.dominantColor?.color,
    ].whereType<Color>().toList();

    // Pick the candidate with highest saturation (most colorful)
    Color representative = candidates.isEmpty ? Colors.grey : candidates.reduce((a, b) {
      final sa = HSVColor.fromColor(a).saturation;
      final sb = HSVColor.fromColor(b).saturation;
      return sa >= sb ? a : b;
    });

    // If saturation is very low, it's likely a neutral – use dominant
    if (HSVColor.fromColor(representative).saturation < 0.08) {
      representative = palette.dominantColor?.color ?? Colors.grey;
    }

    final bestMatch = _closestColorName(representative);
    final hue = HSVColor.fromColor(representative).hue;

    // Simple structural tags from image metadata
    final decodedImage = img.decodeImage(bytes);
    final List<String> tags = [];
    if (decodedImage != null) {
      final ratio = decodedImage.height / decodedImage.width;
      if (ratio > 1.9) tags.add("Slim Fit");
      else if (ratio < 1.05) tags.add("Oversized");

      // Pattern detection: more palette candidates = more colors = likely patterned
      if (palette.colors.length > 10) tags.add("Patterned");
      else tags.add("Plain");
    }

    return {
      "color": bestMatch,
      "hue": hue,
      "category": "Tops",
      "tags": tags,
    };
  }

  /// Weighted Euclidean color distance (perceptual)
  /// https://www.compuphase.com/cmetric.htm
  static double _colorDist(Color c1, Color c2) {
    final rmean = (c1.red + c2.red) ~/ 2;
    final dr = c1.red - c2.red;
    final dg = c1.green - c2.green;
    final db = c1.blue - c2.blue;
    return sqrt(((2 + rmean / 256.0) * dr * dr) +
                4 * dg * dg +
                ((2 + (255 - rmean) / 256.0) * db * db));
  }

  static String _closestColorName(Color color) {
    String best = _colorTable[0].name;
    double minDist = double.infinity;
    for (final entry in _colorTable) {
      final d = _colorDist(color, entry.color);
      if (d < minDist) {
        minDist = d;
        best = entry.name;
      }
    }
    return best;
  }

  /// Background removal using ML Kit Selfie Segmentation.
  /// Note: this model is trained on people. For clothing-only photos it may
  /// not segment perfectly — we apply a less aggressive threshold to keep
  /// more of the garment visible.
  static Future<String?> removeBackground(String inputPath) async {
    try {
      final segmenter = SelfieSegmenter(
        mode: SegmenterMode.single,
        enableRawSizeMask: true,
      );

      final inputImage = InputImage.fromFilePath(inputPath);
      final mask = await segmenter.processImage(inputImage);
      segmenter.close();

      if (mask == null) return null;

      final bytes = await File(inputPath).readAsBytes();
      final src = img.decodeImage(bytes);
      if (src == null) return null;

      final mw = mask.width;
      final mh = mask.height;
      final resized = img.copyResize(src, width: mw, height: mh);
      final out = img.Image(width: mw, height: mh, numChannels: 4);
      final confs = mask.confidences!;

      for (int y = 0; y < mh; y++) {
        for (int x = 0; x < mw; x++) {
          final conf = confs[y * mw + x];
          // Lower threshold (0.5) keeps more of the garment intact
          if (conf > 0.5) {
            out.setPixel(x, y, resized.getPixel(x, y));
          } else {
            out.setPixel(x, y, img.ColorFloat64.rgba(0, 0, 0, 0));
          }
        }
      }

      final dir = await getTemporaryDirectory();
      final outPath = '${dir.path}/item_${DateTime.now().millisecondsSinceEpoch}.png';
      await File(outPath).writeAsBytes(img.encodePng(out));
      return outPath;
    } catch (e) {
      debugPrint("removeBackground error: $e");
      return null;
    }
  }
}

class _ColorEntry {
  final String name;
  final Color color;
  const _ColorEntry(this.name, this.color);
}
