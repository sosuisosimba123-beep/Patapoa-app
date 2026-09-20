import 'package:flutter/foundation.dart';
import 'package:pocketbase/pocketbase.dart';
import '../models/product.dart';
import '../models/order.dart';
import 'pocketbase_services.dart';

class MerchantService {
  // In-memory cache
  static final Map<String, dynamic> _cache = {};
  static final Map<String, DateTime> _cacheTime = {};
  static const _cacheDuration = Duration(minutes: 5);

  Future<Map<String, dynamic>> getStats({bool forceRefresh = false}) async {
    final userId = pb.authStore.model?.id;
    if (userId == null) return {};

    try {
      // Fetch merchant profile
      final profile = await pb.collection('merchant_profiles').getFirstListItem('user = "$userId"');
      
      // Fetch product count
      final products = await pb.collection('Products').getList(filter: 'merchant = "$userId"', perPage: 1);
      
      // Fetch wallet balance
      final wallet = await pb.collection('Wallets').getFirstListItem('user = "$userId"');

      return {
        ...profile.data,
        'products_count': products.totalItems,
        'available_balance': wallet.data['balance'],
        'pending_balance': wallet.data['pending_balance'],
      };
    } catch (e) {
      debugPrint('PocketBase GetStats Error: $e');
      return {};
    }
  }

  Future<void> createManualProduct(Map<String, dynamic> data) async {
    final userId = pb.authStore.model?.id;
    if (userId == null) throw Exception('User not logged in');

    await pb.collection('Products').create(body: {
      'name': data['name'],
      'brand': data['brand'],
      'Price': data['price'],
      'Description': data['description'],
      'Image_url': data['image_url'],
      'category': data['secondary_category_id'],
      'merchant': userId,
      'is_available': true,
      'barcode': data['barcode'],
    });
  }

  Future<void> updatePayoutDetails(Map<String, dynamic> data) async {
    final userId = pb.authStore.model?.id;
    if (userId == null) return;

    try {
      final record = await pb.collection('merchant_profiles').getFirstListItem('user = "$userId"');
      await pb.collection('merchant_profiles').update(record.id, body: {
        'payout_method': data['payout_method'],
        'payout_account': data['payout_account'],
      });
    } catch (e) {
       // Create if doesn't exist
       await pb.collection('merchant_profiles').create(body: {
         'user': userId,
         'payout_method': data['payout_method'],
         'payout_account': data['payout_account'],
       });
    }
  }

  Future<List<Product>> getProducts({int page = 1, int limit = 20}) async {
    final userId = pb.authStore.model?.id;
    if (userId == null) return [];
    
    final result = await pb.collection('Products').getList(
      page: page,
      perPage: limit,
      filter: 'merchant = "$userId"',
      expand: 'category',
    );

    return result.items.map((r) => Product.fromJson({
      'id': r.id,
      ...r.data,
      'secondary_category': r.expand['category']?.first.data,
    })).toList();
  }

  Future<void> deleteProduct(String id) async {
    await pb.collection('Products').delete(id);
  }

  Future<List<Order>> getOrders({int page = 1, int limit = 20}) async {
    final userId = pb.authStore.model?.id;
    if (userId == null) return [];

    final result = await pb.collection('Orders').getList(
      page: page,
      perPage: limit,
      filter: 'merchant = "$userId"',
      expand: 'order_items_via_order,customer',
      sort: '-created',
    );

    return result.items.map((r) => Order.fromJson({
      'id': r.id,
      ...r.data,
      'expand': r.expand,
    })).toList();
  }

  Future<void> updateOrderStatus(String orderId, String status) async {
    await pb.collection('Orders').update(orderId, body: {'status': status});
  }

  Future<void> requestPayout(Map<String, dynamic> data) async {
     // This would create a transaction in PocketBase
     final userId = pb.authStore.model?.id;
     await pb.collection('transactions').create(body: {
        'user': userId,
        'amount': data['amount'],
        'type': 'debit',
        'description': 'Withdrawal to ${data['phone']}',
     });
  }

  Future<void> updateProduct(String id, ProductUpdateRequest request) async {
    await pb.collection('Products').update(id, body: request.toJson());
    _cache.remove('merchant_stats');
  }

  Future<List<Map<String, dynamic>>> getNearbyMerchants({double? latitude, double? longitude, double radius = 15.0}) async {
    // For now, we return verified merchants from the profiles collection
    final result = await pb.collection('merchant_profiles').getList(
      filter: 'is_verified = true',
      expand: 'user',
    );

    return result.items.map((m) => {
      'id': m.id,
      ...m.data,
      'store_name': m.data['store_name'] ?? 'Local Store',
    }).toList();
  }
}
