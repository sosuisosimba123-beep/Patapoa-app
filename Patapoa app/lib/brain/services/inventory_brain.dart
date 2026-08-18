import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../gemini_client.dart';
import '../brain_rules.dart';

/// InventoryBrain uses AI to clean and standardize merchant product inputs.
class InventoryBrain {
  final GenerativeModel _model;

  InventoryBrain() : _model = GeminiClient.createModel();

  /// Processes raw merchant input and returns a standardized JSON string.
  Future<String?> cleanProductInput(String rawInput) async {
    try {
      final prompt = [
        Content.text(BrainRules.catalogCleanupRule),
        Content.text('INPUT: $rawInput'),
      ];

      final response = await _model.generateContent(prompt);
      
      if (response.text != null) {
        // Basic cleaning to ensure no trailing/leading whitespace or markdown
        return response.text!.trim().replaceAll('```json', '').replaceAll('```', '');
      }
      return null;
    } catch (e) {
      debugPrint('InventoryBrain API Error (Likely Quota): $e');
      // Return a "local" JSON string using our fallback logic
      final fallback = _localStandardizeFallback(rawInput);
      return jsonEncode(fallback);
    }
  }

  /// Optional: Parses the response into a Map for easier UI usage.
  Future<Map<String, dynamic>?> getStandardizedProduct(String rawInput) async {
    if (rawInput.trim().isEmpty) return null;
    
    final cleanJson = await cleanProductInput(rawInput);
    if (cleanJson != null) {
      try {
        return jsonDecode(cleanJson) as Map<String, dynamic>;
      } catch (e) {
        debugPrint('InventoryBrain JSON Parse Error: $e');
      }
    }
    return _localStandardizeFallback(rawInput);
  }

  /// Local logic to handle product metadata when AI is unavailable or over quota.
  Map<String, dynamic> _localStandardizeFallback(String input) {
    String name = input.trim();
    String size = '';

    // 1. Basic Capitalization
    if (name.isNotEmpty) {
      name = name.split(' ').map((word) {
        if (word.isEmpty) return '';
        return word[0].toUpperCase() + word.substring(1).toLowerCase();
      }).join(' ');
    }

    // 2. Simple Regex for Size Extraction (e.g., 1kg, 500ml, 1.5L)
    final lowerInput = input.toLowerCase();
    final sizeRegex = RegExp(r'(\d+(\.\d+)?\s*(kg|g|ml|l|ltr|piece|pack|bunch))', caseSensitive: false);
    final match = sizeRegex.firstMatch(lowerInput);
    if (match != null) {
      size = match.group(0)!.toUpperCase();
    }

    return {
      "product_name": name,
      "size": size,
      "is_valid": name.length > 2
    };
  }
}
