import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../../services/api_service.dart';
import '../gemini_client.dart';
import '../brain_rules.dart';

/// ImageResolutionService finds and verifies product images for manual listings.
class ImageResolutionService {
  final GenerativeModel _model;
  final ApiService _apiService = ApiService();

  ImageResolutionService() : _model = GeminiClient.createModel();

  /// Attempts to find a verified product image URL for a manual text input.
  Future<String?> resolveProductImage({
    required String productName,
    int? masterProductId,
  }) async {
    try {
      final prompt = [
        Content.text(BrainRules.imageResolutionRule),
        Content.text('PRODUCT: $productName'),
      ];

      final response = await _model.generateContent(prompt);
      final text = response.text?.trim().replaceAll('```json', '').replaceAll('```', '');

      if (text != null && text.isNotEmpty) {
        final Map<String, dynamic> data = jsonDecode(text);
        
        if (data['resolved'] == true && data['image_url'] != null) {
          final String verifiedUrl = data['image_url'];
          
          // Task 2.1: Save to master catalog if ID is provided
          if (masterProductId != null) {
             _updateMasterImageAsync(masterProductId, verifiedUrl);
          }
          
          return verifiedUrl;
        }
      }
      
      return null; // Triggers UI fallback to 3D icon
    } catch (e) {
      debugPrint('ImageResolutionService Error (API/Quota): $e');
      return null; // Fallback to assets
    }
  }

  /// Fire-and-forget update to the master catalog to minimize latency for the merchant.
  Future<void> _updateMasterImageAsync(int masterProductId, String imageUrl) async {
    try {
      // Assuming a backend endpoint exists to update master product metadata
      await _apiService.put('/master-products/$masterProductId', {
        'primary_image_url': imageUrl,
      });
      debugPrint('Master Product $masterProductId updated with new image.');
    } catch (e) {
      debugPrint('Failed to update master catalog: $e');
    }
  }
}
