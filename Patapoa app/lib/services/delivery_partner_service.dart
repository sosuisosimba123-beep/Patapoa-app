import 'package:flutter/foundation.dart' show debugPrint;
import 'pocketbase_services.dart';

class DeliveryPartnerService {
  // Simple in-memory cache
  static final Map<String, dynamic> _cache = {};
  static final Map<String, DateTime> _cacheTime = {};
  static const _cacheDuration = Duration(minutes: 5);

  Future<List<Map<String, dynamic>>> getAvailableOrders({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final result = await pb.collection('Orders').getList(
        page: page,
        perPage: limit,
        filter: 'status = "ready" && rider = null',
        expand: 'merchant,customer',
      );
      
      return result.items.map((r) => {'id': r.id, ...r.data, 'expand': r.expand}).toList();
    } catch (e) {
      debugPrint('PocketBase GetAvailableOrders Error: $e');
      return [];
    }
  }

  Future<void> acceptOrder(String orderId) async {
    final userId = pb.authStore.model?.id;
    if (userId == null) return;

    await pb.collection('Orders').update(orderId, body: {
      'rider': userId,
      'status': 'confirmed',
    });
  }

  Future<void> updateOrderStatus(String orderId, String status, {double? latitude, double? longitude}) async {
    // 1. Update main order
    await pb.collection('Orders').update(orderId, body: {'status': status});
    
    // 2. Update real-time tracker
    try {
      final records = await pb.collection('live_orders').getList(
        filter: 'order_id = "$orderId"',
        page: 1, perPage: 1
      );

      final pbData = {
        'order_id': orderId,
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
  }

  Future<void> updateLocation(double latitude, double longitude) async {
    final userId = pb.authStore.model?.id;
    if (userId == null) return;

    try {
      final records = await pb.collection('rider_status').getList(
        filter: 'user = "$userId"',
        page: 1, perPage: 1
      );

      final data = {
        'user': userId,
        'current_lat': latitude,
        'current_lng': longitude,
        'is_online': true,
      };

      if (records.items.isNotEmpty) {
        await pb.collection('rider_status').update(records.items.first.id, body: data);
      } else {
        await pb.collection('rider_status').create(body: data);
      }
    } catch (e) {
      debugPrint('PocketBase location update error: $e');
    }
  }

  Future<void> goOnline() async {
    final userId = pb.authStore.model?.id;
    if (userId == null) return;

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

  Future<void> goOffline() async {
    final userId = pb.authStore.model?.id;
    if (userId == null) return;

    final records = await pb.collection('rider_status').getList(
      filter: 'user = "$userId"',
      page: 1, perPage: 1
    );
    if (records.items.isNotEmpty) {
      await pb.collection('rider_status').update(records.items.first.id, body: {'is_online': false});
    }
  }

  Future<Map<String, dynamic>> getProfile({bool forceRefresh = false}) async {
    final userId = pb.authStore.model?.id;
    if (userId == null) return {};

    try {
      final record = await pb.collection('rider_profiles').getFirstListItem('user = "$userId"');
      return {'id': record.id, ...record.data};
    } catch (e) {
      debugPrint('PocketBase GetRiderProfile Error: $e');
      return {};
    }
  }
  
  Future<List<Map<String, dynamic>>> getOrders({
    int page = 1,
    int limit = 20,
  }) async {
    final userId = pb.authStore.model?.id;
    if (userId == null) return [];

    try {
      final result = await pb.collection('Orders').getList(
        page: page,
        perPage: limit,
        filter: 'rider = "$userId"',
        expand: 'merchant,customer',
        sort: '-created',
      );
      return result.items.map((r) => {'id': r.id, ...r.data, 'expand': r.expand}).toList();
    } catch (e) {
      debugPrint('PocketBase GetRiderOrders Error: $e');
      return [];
    }
  }
  
  Future<List<Map<String, dynamic>>> getEarnings() async {
    final userId = pb.authStore.model?.id;
    if (userId == null) return [];

    try {
      final result = await pb.collection('transactions').getList(
        filter: 'user = "$userId"',
        sort: '-created',
      );
      return result.items.map((r) => {'id': r.id, ...r.data}).toList();
    } catch (e) {
      debugPrint('PocketBase GetEarnings Error: $e');
      return [];
    }
  }

  Future<void> requestPayout(Map<String, dynamic> data) async {
    final userId = pb.authStore.model?.id;
    await pb.collection('transactions').create(body: {
      'user': userId,
      'amount': -(data['amount'] as num).abs(),
      'type': 'debit',
      'description': 'Withdrawal to ${data['phone']}',
      'status': 'pending',
    });
  }

  Future<void> requestWithdrawal(Map<String, dynamic> data) async {
    return requestPayout(data);
  }

  Future<void> updateProfile(Map<String, dynamic> data) async {
    final userId = pb.authStore.model?.id;
    if (userId == null) return;
    final record = await pb.collection('rider_profiles').getFirstListItem('user = "$userId"');
    await pb.collection('rider_profiles').update(record.id, body: data);
  }
}
