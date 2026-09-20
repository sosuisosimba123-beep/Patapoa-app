import 'package:flutter/foundation.dart';
import 'package:pocketbase/pocketbase.dart';
import '../models/order.dart';
import 'pocketbase_services.dart';

class OrderService {
  Future<List<Order>> getCustomerOrders({
    int page = 1,
    int limit = 20,
  }) async {
    final userId = pb.authStore.model?.id;
    if (userId == null) return [];

    try {
      final result = await pb.collection('Orders').getList(
        page: page,
        perPage: limit,
        filter: 'customer = "$userId"',
        expand: 'order_items_via_order,merchant,rider',
        sort: '-created',
      );

      return result.items.map((record) => Order.fromJson({
        'id': record.id,
        ...record.data,
        'expand': record.expand,
      })).toList();
    } catch (e) {
      debugPrint('PocketBase GetOrders Error: $e');
      return [];
    }
  }

  Future<Order> createOrder(Map<String, dynamic> request) async {
    final userId = pb.authStore.model?.id;
    if (userId == null) throw Exception('Auth required');

    // 1. Create the Main Order record
    final orderRecord = await pb.collection('Orders').create(body: {
      'order_number': 'PAT-${DateTime.now().millisecondsSinceEpoch}',
      'customer': userId,
      'merchant': request['merchant_id'],
      'select': 'placed ', // Schema has a space after placed
      'total_amount': request['total_amount'],
      'delivery_fee': request['delivery_fee'] ?? 0.0,
      'Address': request['delivery_address'],
    });

    // 2. Create Order Items linked to this order
    final List<dynamic> items = request['items'];
    for (var item in items) {
      await pb.collection('order_items').create(body: {
        'Orders': orderRecord.id,
        'Products': item['product_id'],
        'quantity': item['quantity'],
        'price_at_purchase': item['price'],
      });
    }

    return Order.fromJson({'id': orderRecord.id, ...orderRecord.data});
  }

  Future<void> updateOrderStatus(String orderId, String status) async {
    await pb.collection('Orders').update(orderId, body: {'select': status});
  }

  Future<Map<String, dynamic>> getOrderTracking(String id) async {
    try {
      final record = await pb.collection('live_orders').getFirstListItem('order_id = "$id"', expand: 'rider');
      return {
        ...record.data,
        'rider': record.expand['rider']?.first.data,
      };
    } catch (e) {
      debugPrint('PocketBase GetOrderTracking Error: $e');
      return {'status': 'placed'};
    }
  }
}
