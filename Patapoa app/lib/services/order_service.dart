import 'dart:convert';
import '../config/api_config.dart';
import '../models/order.dart';
import 'api_service.dart';
import '../utils/api_error_handler.dart';

class OrderService {
  final ApiService _apiService = ApiService();

  Future<List<Order>> getCustomerOrders({
    int page = 1,
    int limit = 20,
    List<String>? fields,
    List<String>? include,
  }) async {
    return ApiErrorHandler.withRetry(() async {
      String url = ApiConfig.customerOrders;
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

  Future<Order> getOrder(int id, {List<String>? fields, List<String>? include}) async {
    final response = await _apiService.get(ApiConfig.customerOrder(id), fields: fields, include: include);
    final data = jsonDecode(response.body);
    return Order.fromJson(data['data'] ?? data);
  }

  Future<Order> createOrder(Map<String, dynamic> request) async {
    final response = await _apiService.post(ApiConfig.customerOrders, request);
    final data = jsonDecode(response.body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return Order.fromJson(data['data'] ?? data);
    } else {
      throw Exception(data['message'] ?? 'Failed to create order');
    }
  }

  Future<Map<String, dynamic>> getOrderTracking(int id) async {
    final response = await _apiService.get(ApiConfig.orderTracking(id));
    final data = jsonDecode(response.body);
    return data['data'] ?? data;
  }

  Future<bool> cancelOrder(int id) async {
    await _apiService.put(ApiConfig.orderCancel(id), {});
    return true;
  }

  Future<List<Order>> getMerchantOrders({
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

  Future<Order> updateMerchantOrderStatus(int id, String status) async {
    final response = await _apiService.put(
      ApiConfig.merchantUpdateOrderStatus(id),
      {'status': status},
    );
    final data = jsonDecode(response.body);
    return Order.fromJson(data['data'] ?? data);
  }
}
