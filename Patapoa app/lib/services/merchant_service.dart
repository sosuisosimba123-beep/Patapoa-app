import 'dart:convert';
import '../config/api_config.dart';
import '../models/product.dart';
import '../models/order.dart';
import 'api_service.dart';
import '../utils/api_error_handler.dart';

class MerchantService {
  final ApiService _apiService = ApiService();

  // In-memory cache
  static final Map<String, dynamic> _cache = {};
  static final Map<String, DateTime> _cacheTime = {};
  static const _cacheDuration = Duration(minutes: 5);

  Future<Map<String, dynamic>> getStats({bool forceRefresh = false}) async {
    const cacheKey = 'merchant_stats';
    if (!forceRefresh && _cache.containsKey(cacheKey)) {
      final time = _cacheTime[cacheKey];
      if (time != null && DateTime.now().difference(time) < _cacheDuration) {
        return _cache[cacheKey];
      }
    }

    final response = await _apiService.get(ApiConfig.merchantDashboard);
    final data = jsonDecode(response.body);
    final statsData = data['data'] ?? data;

    _cache[cacheKey] = statsData;
    _cacheTime[cacheKey] = DateTime.now();

    return statsData;
  }

  Future<List<Product>> getProducts({
    int page = 1,
    int limit = 20,
    List<String>? fields,
    List<String>? include,
  }) async {
    return ApiErrorHandler.withRetry(() async {
      String url = ApiConfig.merchantProducts;
      final params = <String>[];
      params.add('page=$page');
      params.add('limit=$limit');

      final queryString = params.isNotEmpty ? '?${params.join('&')}' : '';
      final response = await _apiService.get(url + queryString, fields: fields, include: include);
      
      final dynamic decoded = jsonDecode(response.body);
      final List<dynamic> productsData = decoded is List ? decoded : (decoded['data'] ?? []);
      return productsData.map((json) => Product.fromJson(json)).toList();
    });
  }

  Future<Product> createProduct(ProductCreateRequest request) async {
    final response = await _apiService.post(ApiConfig.merchantProducts, request.toJson());
    final data = jsonDecode(response.body);
    _cache.remove('merchant_stats'); // Invalidate cache to sync home screen
    return Product.fromJson(data['data'] ?? data);
  }

  Future<Product> createManualProduct(Map<String, dynamic> data) async {
    final response = await _apiService.post(ApiConfig.merchantProducts, data);
    final decoded = jsonDecode(response.body);
    _cache.remove('merchant_stats'); // Invalidate cache to sync home screen
    return Product.fromJson(decoded['data'] ?? decoded);
  }

  Future<Product> updateProduct(int id, ProductUpdateRequest request) async {
    final response = await _apiService.put(ApiConfig.merchantProduct(id), request.toJson());
    final data = jsonDecode(response.body);
    _cache.remove('merchant_stats'); // Invalidate cache
    return Product.fromJson(data['data'] ?? data);
  }

  Future<void> deleteProduct(int id) async {
    await _apiService.delete(ApiConfig.merchantProduct(id));
    _cache.remove('merchant_stats'); // Invalidate cache
  }

  Future<List<Order>> getOrders({
    int page = 1,
    int limit = 20,
    List<String>? fields,
    List<String>? include,
  }) async {
    return ApiErrorHandler.withRetry(() async {
      String url = ApiConfig.merchantOrders;
      final params = <String>[];
      params.add('page=$page');
      params.add('limit=$limit');

      final queryString = params.isNotEmpty ? '?${params.join('&')}' : '';
      final response = await _apiService.get(url + queryString, fields: fields, include: include);
      
      final dynamic decoded = jsonDecode(response.body);
      final List<dynamic> ordersData = decoded is List ? decoded : (decoded['data'] ?? []);
      return ordersData.map((json) => Order.fromJson(json)).toList();
    });
  }

  Future<Order> updateOrderStatus(int orderId, String status) async {
    final response = await _apiService.put(
      ApiConfig.merchantUpdateOrderStatus(orderId),
      {'status': status},
    );
    final data = jsonDecode(response.body);
    return Order.fromJson(data['data'] ?? data);
  }

  Future<Map<String, dynamic>> requestPayout(Map<String, dynamic> data) async {
    try {
      final response = await _apiService.post(ApiConfig.merchantPayoutRequest, data);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Failed to request payout');
      }
    } catch (e) {
      throw Exception('Error requesting payout: $e');
    }
  }

  Future<void> updatePayoutDetails(Map<String, dynamic> data) async {
    await _apiService.post('/merchant/payout-setup', data);
    _cache.remove('merchant_stats'); // Invalidate cache
  }

  Future<List<Map<String, dynamic>>> getNearbyMerchants({double? latitude, double? longitude, double radius = 15.0}) async {
    final params = <String>[];
    if (latitude != null) params.add('latitude=$latitude');
    if (longitude != null) params.add('longitude=$longitude');
    params.add('radius=$radius');

    final queryString = params.isNotEmpty ? '?${params.join('&')}' : '';
    final response = await _apiService.get('/merchants/nearby$queryString');
    
    final Map<String, dynamic> data = jsonDecode(response.body);
    final List<dynamic> merchants = data['data'] ?? [];
    return merchants.cast<Map<String, dynamic>>();
  }
}
