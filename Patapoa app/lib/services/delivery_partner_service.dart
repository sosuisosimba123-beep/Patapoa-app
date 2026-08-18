import 'dart:convert';
import '../config/api_config.dart';
import '../services/api_service.dart';
import '../services/request_queue_service.dart';
import '../utils/api_error_handler.dart';

class DeliveryPartnerService {
  final ApiService _apiService = ApiService();
  final RequestQueueService _queueService = RequestQueueService();

  // Simple in-memory cache
  static final Map<String, dynamic> _cache = {};
  static final Map<String, DateTime> _cacheTime = {};
  static const _cacheDuration = Duration(minutes: 5);

  // Throttling for location updates
  DateTime? _lastLocationUpdate;
  static const _locationThrottle = Duration(seconds: 15);

  Future<List<Map<String, dynamic>>> getAvailableOrders({
    int page = 1,
    int limit = 20,
    List<String>? fields,
    List<String>? include,
  }) async {
    return ApiErrorHandler.withRetry(() async {
      String url = ApiConfig.riderAvailableOrders;
      final params = <String>[];
      params.add('page=$page');
      params.add('limit=$limit');

      final queryString = params.isNotEmpty ? '?${params.join('&')}' : '';
      final response = await _apiService.get(url + queryString, fields: fields, include: include);
      
      final data = jsonDecode(response.body);
      final List<dynamic> ordersData = data['data'] ?? data;
      return ordersData.map((item) => item as Map<String, dynamic>).toList();
    });
  }

  Future<Map<String, dynamic>> acceptOrder(int orderId) async {
    final response = await _apiService.post(ApiConfig.riderAcceptOrder(orderId), {});
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> updateOrderStatus(int orderId, String status, {double? latitude, double? longitude}) async {
    final body = <String, dynamic>{'status': status};
    if (latitude != null) body['latitude'] = latitude;
    if (longitude != null) body['longitude'] = longitude;

    final response = await _apiService.put(ApiConfig.riderUpdateOrderStatus(orderId), body);
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> updateLocation(double latitude, double longitude) async {
    final now = DateTime.now();
    if (_lastLocationUpdate != null &&
        now.difference(_lastLocationUpdate!) < _locationThrottle) {
      return {'status': 'throttled', 'message': 'Client-side throttle: Update skipped'};
    }

    _lastLocationUpdate = now;
    final body = {
      'latitude': latitude,
      'longitude': longitude,
    };

    try {
      final response = await _apiService.post(ApiConfig.riderLocation, body);
      return jsonDecode(response.body);
    } catch (e) {
      // If network fails, enqueue for background sync
      if (e is NetworkException || e is RequestTimeoutException) {
        await _queueService.enqueue('POST', ApiConfig.riderLocation, body);
        return {'status': 'queued', 'message': 'Offline: Location queued for sync'};
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> goOnline() async {
    final response = await _apiService.post(ApiConfig.riderOnline, {});
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> goOffline() async {
    final response = await _apiService.post(ApiConfig.riderOffline, {});
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> getProfile({bool forceRefresh = false}) async {
    const cacheKey = 'rider_profile';

    if (!forceRefresh && _cache.containsKey(cacheKey)) {
      final time = _cacheTime[cacheKey];
      if (time != null && DateTime.now().difference(time) < _cacheDuration) {
        return _cache[cacheKey];
      }
    }

    final response = await _apiService.get(ApiConfig.riderProfile);
    final data = jsonDecode(response.body);
    final profileData = data['data'] ?? data;

    // Update cache
    _cache[cacheKey] = profileData;
    _cacheTime[cacheKey] = DateTime.now();

    return profileData;
  }
  
  Future<List<Map<String, dynamic>>> getOrders({
    int page = 1,
    int limit = 20,
    List<String>? fields,
    List<String>? include,
  }) async {
    return ApiErrorHandler.withRetry(() async {
      String url = ApiConfig.riderOrders;
      final params = <String>[];
      params.add('page=$page');
      params.add('limit=$limit');

      final queryString = params.isNotEmpty ? '?${params.join('&')}' : '';
      final response = await _apiService.get(url + queryString, fields: fields, include: include);
      
      final data = jsonDecode(response.body);
      final List<dynamic> ordersData = data['data'] ?? data;
      return ordersData.map((item) => item as Map<String, dynamic>).toList();
    });
  }
  
  Future<List<Map<String, dynamic>>> getEarnings({
    int page = 1,
    int limit = 20,
    List<String>? fields,
  }) async {
    return ApiErrorHandler.withRetry(() async {
      String url = ApiConfig.riderEarnings;
      final params = <String>[];
      params.add('page=$page');
      params.add('limit=$limit');

      final queryString = params.isNotEmpty ? '?${params.join('&')}' : '';
      final response = await _apiService.get(url + queryString, fields: fields);
      
      final data = jsonDecode(response.body);
      final List<dynamic> earningsData = data['data'] ?? data;
      return earningsData.map((item) => item as Map<String, dynamic>).toList();
    });
  }

  Future<Map<String, dynamic>> requestPayout(Map<String, dynamic> data) async {
    final response = await _apiService.post(ApiConfig.riderPayoutRequest, data);
    return jsonDecode(response.body);
  }
  
  Future<Map<String, dynamic>> requestWithdrawal(Map<String, dynamic> data) async {
    return requestPayout(data);
  }
  
  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> data) async {
    final response = await _apiService.put(ApiConfig.riderProfile, data);
    return jsonDecode(response.body);
  }
}
