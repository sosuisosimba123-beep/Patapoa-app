import 'dart:convert';
import '../config/api_config.dart';
import '../models/product.dart';
import '../models/order.dart';
import 'api_service.dart';

class MerchantService {
  final ApiService _apiService = ApiService();

  Future<Map<String, dynamic>> getStats() async {
    try {
      final response = await _apiService.get(ApiConfig.merchantDashboard);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'] ?? data;
      } else {
        throw Exception('Failed to load merchant stats');
      }
    } catch (e) {
      throw Exception('Error fetching merchant stats: $e');
    }
  }

  Future<List<Product>> getProducts({int page = 1, int limit = 20}) async {
    try {
      String url = ApiConfig.merchantProducts;
      final params = <String>[];
      params.add('page=$page');
      params.add('limit=$limit');
      
      if (params.isNotEmpty) {
        url += '?${params.join('&')}';
      }
      
      final response = await _apiService.get(url);
      
      if (response.statusCode == 200) {
        final dynamic decoded = jsonDecode(response.body);
        final List<dynamic> productsData = decoded is List ? decoded : (decoded['data'] ?? []);
        return productsData.map((json) => Product.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load merchant products');
      }
    } catch (e) {
      throw Exception('Error fetching merchant products: $e');
    }
  }

  Future<Product> createProduct(ProductCreateRequest request) async {
    try {
      final response = await _apiService.post(ApiConfig.merchantProducts, request.toJson());
      
      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return Product.fromJson(data['data'] ?? data);
      } else {
        throw Exception('Failed to create product');
      }
    } catch (e) {
      throw Exception('Error creating product: $e');
    }
  }

  Future<Product> updateProduct(int id, ProductUpdateRequest request) async {
    try {
      final response = await _apiService.put(ApiConfig.merchantProduct(id), request.toJson());
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Product.fromJson(data['data'] ?? data);
      } else {
        throw Exception('Failed to update product');
      }
    } catch (e) {
      throw Exception('Error updating product: $e');
    }
  }

  Future<void> deleteProduct(int id) async {
    try {
      final response = await _apiService.delete(ApiConfig.merchantProduct(id));
      
      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Failed to delete product');
      }
    } catch (e) {
      throw Exception('Error deleting product: $e');
    }
  }

  Future<List<Order>> getOrders({int page = 1, int limit = 20}) async {
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

  Future<Order> updateOrderStatus(int orderId, String status) async {
    try {
      final response = await _apiService.put(
        ApiConfig.merchantUpdateOrderStatus(orderId),
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
