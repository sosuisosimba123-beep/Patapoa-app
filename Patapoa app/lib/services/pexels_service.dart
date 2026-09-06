import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../models/pexels_image.dart';

class PexelsService {
  static final String _apiKey = dotenv.env['PEXELS_API_KEY'] ?? '';
  static const String _baseUrl = 'https://api.pexels.com/v1';

  Future<List<PexelsImage>> searchImages(String query, {int perPage = 20}) async {
    if (_apiKey.isEmpty) {
      throw Exception('Pexels API Key not found in .env. Please ensure PEXELS_API_KEY is defined.');
    }

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/search?query=${Uri.encodeComponent(query)}&per_page=$perPage'),
        headers: {
          'Authorization': _apiKey,
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> photos = data['photos'];
        return photos.map((json) => PexelsImage.fromJson(json)).toList();
      } else {
        throw Exception('Pexels API Error (${response.statusCode}): ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to connect to Pexels: $e');
    }
  }

  Future<List<PexelsImage>> getCuratedImages({int perPage = 20}) async {
    if (_apiKey.isEmpty) {
      throw Exception('Pexels API Key not found in .env');
    }

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/curated?per_page=$perPage'),
        headers: {
          'Authorization': _apiKey,
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> photos = data['photos'];
        return photos.map((json) => PexelsImage.fromJson(json)).toList();
      } else {
        throw Exception('Pexels API Error: ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to fetch curated images: $e');
    }
  }
}
