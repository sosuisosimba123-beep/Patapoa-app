import 'dart:convert';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:pocketbase/pocketbase.dart';
import '../config/api_config.dart';
import 'api_service.dart';
import 'pocketbase_services.dart';
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

    // 1. Laravel update
    final response = await _apiService.put(ApiConfig.riderUpdateOrderStatus(orderId), body);
    
    // 2. PocketBase Real-time update (Sync with live_orders collection)
    try {
      final records = await pb.collection('live_orders').getList(
        filter: 'order_id = "$orderId"',
        page: 1, perPage: 1
      );

      final pbData = {
        'order_id': orderId.toString(),
        'status': status,
        if (latitude != null) 'rider_lat': latitude,
        if (longitude != null) 'rider_lng': longitude,
      };

      if (records.items.isNotEmpty) {
        await pb.collection('live_orders').update(records.items.first.id, body: pbData);
      } else {
        await pb.collection('live_orders').create(body: pbData);
      }
    } catch (e) {
      debugPrint('PocketBase live_orders sync error: $e');
    }

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

    // 1. Sync with Laravel (MySQL/Persistence)
    try {
      await _apiService.post(ApiConfig.riderLocation, body);
    } catch (e) {
      if (e is NetworkException || e is RequestTimeoutException) {
        await _queueService.enqueue('POST', ApiConfig.riderLocation, body);
      }
    }

    // 2. Real-time broadcast via PocketBase
    try {
      final userId = pb.authStore.model?.id;
      if (userId != null) {
        // Update rider_status
        final statusRecords = await pb.collection('rider_status').getList(
          filter: 'user = "$userId"',
          page: 1, perPage: 1
        );

        final statusData = {
          'user': userId,
          'current_lat': latitude,
          'current_lng': longitude,
          'is_online': true,
        };

        if (statusRecords.items.isNotEmpty) {
          await pb.collection('rider_status').update(statusRecords.items.first.id, body: statusData);
        } else {
          await pb.collection('rider_status').create(body: statusData);
        }
      }
    } catch (e) {
      debugPrint('PocketBase location broadcast error: $e');
    }

    return {'status': 'success'};
  }

  Future<Map<String, dynamic>> goOnline() async {
    // 1. Laravel
    await _apiService.post(ApiConfig.riderOnline, {});

    // 2. PocketBase
    try {
      final userId = pb.authStore.model?.id;
      if (userId != null) {
        final records = await pb.collection('rider_status').getList(
          filter: 'user = "$userId"',
          page: 1, perPage: 1
        );

        if (records.items.isNotEmpty) {
          await pb.collection('rider_status').update(records.items.first.id, body: {'is_online': true});
        } else {
          await pb.collection('rider_status').create(body: {'user': userId, 'is_online': true});
        }
      }
    } catch (_) {}

    return {'status': 'online'};
  }

  Future<Map<String, dynamic>> goOffline() async {
    // 1. Laravel
    await _apiService.post(ApiConfig.riderOffline, {});

    // 2. PocketBase
    try {
      final userId = pb.authStore.model?.id;
      if (userId != null) {
        final records = await pb.collection('rider_status').getList(
          filter: 'user = "$userId"',
          page: 1, perPage: 1
        );
        if (records.items.isNotEmpty) {
          await pb.collection('rider_status').update(records.items.first.id, body: {'is_online': false});
        }
      }
    } catch (_) {}

    return {'status': 'offline'};
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
