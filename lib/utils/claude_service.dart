import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/clothes_item.dart';
import 'weather_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ClaudeService {
  static String get _apiKey => dotenv.env['CLAUDE_API_KEY'] ?? "";
  static const String _apiUrl = "https://api.anthropic.com/v1/messages";

  static Future<String> getStylistAdvice({
    required ClothesItem? top,
    required ClothesItem? bottom,
    required ClothesItem? shoes,
    required WeatherData? weather,
    required String occasion,
  }) async {
    if (_apiKey == "YOUR_CLAUDE_API_KEY") return "Please set your Claude API key to get personalized stylist advice! ✨";

    final prompt = """
    You are an expert fashion stylist. I have selected the following outfit for a $occasion occasion.
    
    Current Weather: ${weather?.temperature}°C, ${weather?.condition}
    
    Outfit:
    - Top: ${top?.color} ${top?.category} (${top?.tags.join(', ')})
    - Bottom: ${bottom?.color} ${bottom?.category} (${bottom?.tags.join(', ')})
    - Shoes: ${shoes?.color} ${shoes?.category} (${shoes?.tags.join(', ')})
    
    Please provide a concise (2-3 sentences), sophisticated stylist advice on why this outfit works for this occasion and weather. Mention color harmony or fabric suitability if relevant.
    """;

    try {
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': _apiKey,
          'anthropic-version': '2023-06-01',
        },
        body: json.encode({
          'model': 'claude-3-haiku-20240307',
          'max_tokens': 150,
          'messages': [
            {'role': 'user', 'content': prompt}
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['content'][0]['text'];
      } else {
        print("Claude Error: ${response.body}");
        return "Your AI Stylist is currently unavailable. But you look great anyway!";
      }
    } catch (e) {
      print("Claude Request Exception: $e");
      return "Unable to reach your AI Stylist. Check your internet connection.";
    }
  }
}
