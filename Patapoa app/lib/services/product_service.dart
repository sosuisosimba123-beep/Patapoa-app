import 'package:flutter/foundation.dart';
import 'package:pocketbase/pocketbase.dart';
import '../models/product.dart';
import 'pocketbase_services.dart';

class ProductService {
  // In-memory cache for categories
  static final Map<String, dynamic> _cache = {};
  static final Map<String, DateTime> _cacheTime = {};
  static const _cacheDuration = Duration(minutes: 30);

  Future<ProductResponse> getProducts({
    String? primaryCategoryId,
    String? secondaryCategoryId,
    String? merchantId,
    String? search,
    double? latitude,
    double? longitude,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final filterParts = <String>[];
      
      if (merchantId != null) filterParts.add('merchant = "$merchantId"');
      if (secondaryCategoryId != null) filterParts.add('category = "$secondaryCategoryId"');
      if (search != null && search.isNotEmpty) {
        filterParts.add('name ~ "${search.replaceAll('"', '\\"')}"');
      }

      final filter = filterParts.isNotEmpty ? filterParts.join(' && ') : '';

      final result = await pb.collection('Products').getList(
        page: page,
        perPage: limit,
        filter: filter,
        expand: 'category,merchant',
        sort: '-created',
      );

      final products = result.items.map((record) {
        return Product.fromJson({
          'id': record.id,
          ...record.data,
          'merchant': record.expand['merchant']?.first.data,
          'secondary_category': record.expand['category']?.first.data,
        });
      }).toList();

      return ProductResponse(
        products: products,
        heroProduct: products.isNotEmpty ? MasterProduct.fromJson(result.items.first.data) : null,
        merchantsNearby: true,
      );
    } catch (e) {
      debugPrint('PocketBase GetProducts Error: $e');
      return ProductResponse(products: [], merchantsNearby: false);
    }
  }

  Future<List<Product>> getMerchantProducts({int page = 1, int limit = 20}) async {
    final userId = pb.authStore.model?.id;
    if (userId == null) return [];

    final result = await pb.collection('Products').getList(
      page: page,
      perPage: limit,
      filter: 'merchant = "$userId"',
      expand: 'category',
    );

    return result.items.map((record) {
      return Product.fromJson({
        'id': record.id,
        ...record.data,
        'secondary_category': record.expand['category']?.first.data,
      });
    }).toList();
  }

  Future<List<PrimaryCategory>> getCategories({bool forceRefresh = false}) async {
    try {
      final result = await pb.collection('primary_category').getList(
        expand: 'secondary_categories_via_primary_category',
      );

      return result.items.map((record) {
        return PrimaryCategory.fromJson({
          'id': record.id,
          ...record.data,
          'secondary_categories': record.expand['secondary_categories_via_primary_category']?.map((s) => s.data).toList(),
        });
      }).toList();
    } catch (e) {
      debugPrint('PocketBase GetCategories Error: $e');
      return [];
    }
  }

  Future<List<MasterProduct>> getMasterProducts({String? search, String? secondaryCategoryId}) async {
    try {
      final filterParts = <String>[];
      if (search != null && search.isNotEmpty) {
        filterParts.add('name ~ "${search.replaceAll('"', '\\"')}"');
      }
      if (secondaryCategoryId != null) {
        filterParts.add('secondary_category = "$secondaryCategoryId"');
      }

      final result = await pb.collection('master_products').getList(
        filter: filterParts.join(' && '),
        expand: 'secondary_category',
      );

      return result.items.map((record) => MasterProduct.fromJson({
        'id': record.id,
        ...record.data,
        'secondary_category': record.expand['secondary_category']?.first.data,
      })).toList();
    } catch (e) {
      debugPrint('PocketBase GetMasterProducts Error: $e');
      return [];
    }
  }

  Future<ProductResponse> searchProducts(String query, {double? latitude, double? longitude}) async {
    return getProducts(search: query, latitude: latitude, longitude: longitude);
  }

  Future<void> updateProduct(String id, Map<String, dynamic> data) async {
    await pb.collection('Products').update(id, body: data);
  }
}
