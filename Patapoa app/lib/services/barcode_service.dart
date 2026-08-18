import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'api_service.dart';

class BarcodeService {
  final ApiService _apiService = ApiService();

  /// Unified lookup: Checks backend scan endpoint (Cache ➔ Gemini ➔ Fallback).
  Future<Map<String, dynamic>?> lookupBarcode(String barcode) async {
    try {
      final response = await _apiService.post('/products/scan', {'barcode': barcode});
      
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final data = decoded['data'] ?? decoded;
        
        return {
          'source': data['is_cached'] == true ? 'cache' : 'ai',
          'name': data['name'],
          'brand': data['brand'],
          'image_url': data['image_url'],
          'secondary_category_id': data['secondary_category_id'],
          'secondary_category_name': data['secondary_category_name'],
          'master_product_id': data['master_product_id'],
        };
      }
    } catch (e) {
      debugPrint('Barcode lookup failed: $e');
    }

    return null;
  }
}
