import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../config/api_config.dart';
import '../models/product.dart';
import 'api_service.dart';
import '../utils/api_error_handler.dart';

class ProductService {
  final ApiService _apiService = ApiService();

  // In-memory cache for categories
  static final Map<String, dynamic> _cache = {};
  static final Map<String, DateTime> _cacheTime = {};
  static const _cacheDuration = Duration(minutes: 30);

  Future<ProductResponse> getProducts({
    int? primaryCategoryId,
    int? secondaryCategoryId,
    int? merchantId,
    String? search,
    double? latitude,
    double? longitude,
    int page = 1,
    int limit = 20,
    List<String>? fields,
    List<String>? include,
  }) async {
    return ApiErrorHandler.withRetry(() async {
      String url = ApiConfig.products;
      final params = <String>[];
      
      if (merchantId != null) params.add('merchant_id=$merchantId');
      if (primaryCategoryId != null) params.add('primary_category_id=$primaryCategoryId');
      if (secondaryCategoryId != null) params.add('secondary_category_id=$secondaryCategoryId');
      if (search != null) params.add('q=${Uri.encodeComponent(search)}');
      if (latitude != null) params.add('latitude=$latitude');
      if (longitude != null) params.add('longitude=$longitude');
      params.add('page=$page');
      params.add('limit=$limit');

      final queryString = params.isNotEmpty ? '?${params.join('&')}' : '';
      final response = await _apiService.get(url + queryString, fields: fields, include: include);
      
      final dynamic decoded = jsonDecode(response.body);
      final Map<String, dynamic> responseData = (decoded is Map && decoded.containsKey('data'))
          ? (decoded['data'] is Map ? decoded['data'] : {'data': decoded['data']})
          : {};

      // Unified extraction logic
      List<dynamic> productsJson = [];
      if (responseData.containsKey('products')) {
        final productsData = responseData['products'];
        productsJson = productsData is List ? productsData : (productsData is Map ? (productsData['data'] ?? []) : []);
      } else {
        productsJson = responseData['data'] is List ? responseData['data'] : [];
      }

      debugPrint('Products Loaded: ${productsJson.length} items');
      if (responseData['hero_product'] != null) {
        debugPrint('Hero Product: ${responseData['hero_product']['name']}');
      }

      return ProductResponse(
        products: productsJson.map((json) => Product.fromJson(json)).toList(),
        heroProduct: responseData['hero_product'] != null ? MasterProduct.fromJson(responseData['hero_product']) : null,
        merchantsNearby: responseData['merchants_nearby'] ?? true,
      );
    });
  }

  Future<List<MasterProduct>> getMasterProducts({String? search, int? secondaryCategoryId}) async {
    final params = <String>[];
    if (search != null) params.add('q=${Uri.encodeComponent(search)}');
    if (secondaryCategoryId != null) params.add('secondary_category_id=$secondaryCategoryId');

    final queryString = params.isNotEmpty ? '?${params.join('&')}' : '';
    final response = await _apiService.get(ApiConfig.masterProducts + queryString);
    final dynamic decoded = jsonDecode(response.body);
    final List<dynamic> data = decoded is List ? decoded : (decoded['data'] ?? []);

    return data.map((json) => MasterProduct.fromJson(json)).toList();
  }

  Future<Product> getProduct(int id, {List<String>? fields, List<String>? include}) async {
    final response = await _apiService.get(ApiConfig.product(id), fields: fields, include: include);
    final data = jsonDecode(response.body);
    return Product.fromJson(data['data'] ?? data);
  }

  Future<List<Product>> getMerchantProducts({int page = 1, int limit = 20}) async {
    return ApiErrorHandler.withRetry(() async {
      String url = ApiConfig.merchantProducts;
      final params = <String>[];
      params.add('page=$page');
      params.add('limit=$limit');

      final queryString = params.isNotEmpty ? '?${params.join('&')}' : '';
      final response = await _apiService.get(url + queryString);
      
      final dynamic decoded = jsonDecode(response.body);
      final List<dynamic> productsData = decoded is List ? decoded : (decoded['data'] ?? []);
      return productsData.map((json) => Product.fromJson(json)).toList();
    });
  }

  Future<ProductResponse> searchProducts(String query, {double? latitude, double? longitude}) async {
    return getProducts(search: query, latitude: latitude, longitude: longitude);
  }

  Future<List<PrimaryCategory>> getCategories({bool forceRefresh = false}) async {
    const cacheKey = 'primary_categories';
    if (!forceRefresh && _cache.containsKey(cacheKey)) {
      final time = _cacheTime[cacheKey];
      if (time != null && DateTime.now().difference(time) < _cacheDuration) {
        return (_cache[cacheKey] as List).map((json) => PrimaryCategory.fromJson(json)).toList();
      }
    }

    final response = await _apiService.get('/primary-categories');
    final dynamic decoded = jsonDecode(response.body);
    final List<dynamic> categoriesData = decoded is List ? decoded : (decoded['data'] ?? []);

    _cache[cacheKey] = categoriesData;
    _cacheTime[cacheKey] = DateTime.now();

    return categoriesData.map((json) => PrimaryCategory.fromJson(json)).toList();
  }

  Future<Product> createProduct(ProductCreateRequest request) async {
    final response = await _apiService.post(ApiConfig.merchantProducts, request.toJson());
    final data = jsonDecode(response.body);
    return Product.fromJson(data['data'] ?? data);
  }

  Future<Product> updateProduct(int id, ProductUpdateRequest request) async {
    final response = await _apiService.put(ApiConfig.merchantProduct(id), request.toJson());
    final data = jsonDecode(response.body);
    return Product.fromJson(data['data'] ?? data);
  }

  Future<void> deleteProduct(int id) async {
    await _apiService.delete(ApiConfig.merchantProduct(id));
  }
}
