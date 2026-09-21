import 'package:flutter/foundation.dart';
import 'pocketbase_services.dart';

class BarcodeService {
  /// Unified lookup: Checks PocketBase master_products library.
  Future<Map<String, dynamic>?> lookupBarcode(String barcode) async {
    try {
      final result = await pb.collection('master_products').getFirstListItem(
        'barcode = "$barcode"',
        expand: 'secondary_category',
      );
      
      return {
        'source': 'library',
        'name': result.data['name'],
        'brand': result.data['brand'],
        'image_url': result.data['primary_image_url'],
        'secondary_category_id': result.data['secondary_category'],
        'secondary_category_name': result.expand['secondary_category']?.first.data['name'],
        'master_product_id': result.id,
      };
    } catch (e) {
      debugPrint('Barcode library lookup failed: $e');
    }

    return null;
  }
}
