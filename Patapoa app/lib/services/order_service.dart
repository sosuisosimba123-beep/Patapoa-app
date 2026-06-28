import 'dart:convert';
import '../config/api_config.dart';
import '../models/order.dart';
import 'api_service.dart';

class OrderService {
  final ApiService _apiService = ApiService();

  Future<List<Order>> getCustomerOrders({int page = 1, int limit = 20}) async {
    try {
      String url = ApiConfig.customerOrders;
      final params = <String>[];
      params.add('page=$page');
      params.add('limit=$limit');
      
      if (params.isNotEmpty) {
        url += '?${params.join('&')}';
      }
      
      final response = await _apiService.get(url);
      
      if (response.statusCode == 200) {
        final dynamic decoded = jsonDecode(response.body);
        final List<dynamic> ordersData = decoded is List ? decoded : (decoded['data'] ?? []);
        return ordersData.map((json) => Order.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load customer orders');
      }
    } catch (e) {
      throw Exception('Error fetching customer orders: $e');
    }
  }

  Future<Order> getOrder(int id, {List<String>? fields}) async {
    try {
      String url = ApiConfig.customerOrder(id);
      if (fields != null && fields.isNotEmpty) {
        url += '?fields=${fields.join(',')}';
      }
      
      final response = await _apiService.get(url);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Order.fromJson(data['data'] ?? data);
      } else {
        throw Exception('Failed to load order');
      }
    } catch (e) {
      throw Exception('Error fetching order: $e');
    }
  }

  Future<Order> createOrder(Map<String, dynamic> request) async {
    try {
      final response = await _apiService.post(ApiConfig.customerOrders, request);
      
      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return Order.fromJson(data['data'] ?? data);
      } else {
        throw Exception('Failed to create order');
      }
    } catch (e) {
      throw Exception('Error creating order: $e');
    }
  }

  Future<Map<String, dynamic>> getOrderTracking(int id) async {
    try {
      final response = await _apiService.get(ApiConfig.orderTracking(id));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'] ?? data;
      } else {
        throw Exception('Failed to load order tracking');
      }
    } catch (e) {
      throw Exception('Error fetching order tracking: $e');
    }
  }

  Future<bool> cancelOrder(int id) async {
    try {
      final response = await _apiService.put(ApiConfig.orderCancel(id), {});
      
      if (response.statusCode == 200) {
        return true;
      } else {
        throw Exception('Failed to cancel order');
      }
    } catch (e) {
      throw Exception('Error canceling order: $e');
    }
  }

  Future<List<Order>> getMerchantOrders({int page = 1, int limit = 20}) async {
    try {
      String url = ApiConfig.merchantOrders;
      final params = <String>[];
      params.add('page=$page');
      params.add('limit=$limit');
      
      if (params.isNotEmpty) {
        url += '?${params.join('&')}';
      }
      
      final response = await _apiService.get(url);
      
      if (response.statusCode == 200) {
        final dynamic decoded = jsonDecode(response.body);
        final List<dynamic> ordersData = decoded is List ? decoded : (decoded['data'] ?? []);
        return ordersData.map((json) => Order.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load merchant orders');
      }
    } catch (e) {
      throw Exception('Error fetching merchant orders: $e');
    }
  }

  Future<Order> updateMerchantOrderStatus(int id, String status) async {
    try {
      final response = await _apiService.put(
        ApiConfig.merchantUpdateOrderStatus(id),
        {'status': status},
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Order.fromJson(data['data'] ?? data);
      } else {
        throw Exception('Failed to update order status');
      }
    } catch (e) {
      throw Exception('Error updating order status: $e');
    }
  }
}
