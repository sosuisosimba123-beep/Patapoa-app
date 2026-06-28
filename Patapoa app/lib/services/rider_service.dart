import 'dart:convert';
import '../config/api_config.dart';
import '../services/api_service.dart';

class RiderService {
  final ApiService _apiService = ApiService();

  Future<List<Map<String, dynamic>>> getAvailableOrders({int page = 1, int limit = 20}) async {
    try {
      String url = ApiConfig.riderAvailableOrders;
      final params = <String>[];
      params.add('page=$page');
      params.add('limit=$limit');
      
      if (params.isNotEmpty) {
        url += '?${params.join('&')}';
      }
      
      final response = await _apiService.get(url);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> ordersData = data['data'] ?? data;
        return ordersData.map((item) => item as Map<String, dynamic>).toList();
      } else {
        throw Exception('Failed to load available orders');
      }
    } catch (e) {
      throw Exception('Error loading available orders: $e');
    }
  }

  Future<Map<String, dynamic>> acceptOrder(int orderId) async {
    try {
      final response = await _apiService.post(ApiConfig.riderAcceptOrder(orderId), {});
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to accept order');
      }
    } catch (e) {
      throw Exception('Error accepting order: $e');
    }
  }

  Future<Map<String, dynamic>> updateOrderStatus(int orderId, String status, {double? latitude, double? longitude}) async {
    try {
      final body = <String, dynamic>{'status': status};
      if (latitude != null) body['latitude'] = latitude;
      if (longitude != null) body['longitude'] = longitude;
      
      final response = await _apiService.put(ApiConfig.riderUpdateOrderStatus(orderId), body);
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to update order status');
      }
    } catch (e) {
      throw Exception('Error updating order status: $e');
    }
  }

  Future<Map<String, dynamic>> updateLocation(double latitude, double longitude) async {
    try {
      final response = await _apiService.post(ApiConfig.riderLocation, {
        'latitude': latitude,
        'longitude': longitude,
      });
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to update location');
      }
    } catch (e) {
      throw Exception('Error updating location: $e');
    }
  }

  Future<Map<String, dynamic>> goOnline() async {
    try {
      final response = await _apiService.post(ApiConfig.riderOnline, {});
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to go online');
      }
    } catch (e) {
      throw Exception('Error going online: $e');
    }
  }

  Future<Map<String, dynamic>> goOffline() async {
    try {
      final response = await _apiService.post(ApiConfig.riderOffline, {});
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to go offline');
      }
    } catch (e) {
      throw Exception('Error going offline: $e');
    }
  }

  Future<Map<String, dynamic>> getProfile() async {
    try {
      final response = await _apiService.get(ApiConfig.riderProfile);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'] ?? data;
      } else {
        throw Exception('Failed to load rider profile');
      }
    } catch (e) {
      throw Exception('Error loading rider profile: $e');
    }
  }
  
  Future<List<Map<String, dynamic>>> getOrders({int page = 1, int limit = 20}) async {
    try {
      String url = ApiConfig.riderOrders;
      final params = <String>[];
      params.add('page=$page');
      params.add('limit=$limit');
      
      if (params.isNotEmpty) {
        url += '?${params.join('&')}';
      }
      
      final response = await _apiService.get(url);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> ordersData = data['data'] ?? data;
        return ordersData.map((item) => item as Map<String, dynamic>).toList();
      } else {
        throw Exception('Failed to load rider orders');
      }
    } catch (e) {
      throw Exception('Error loading rider orders: $e');
    }
  }
  
  Future<List<Map<String, dynamic>>> getEarnings({int page = 1, int limit = 20}) async {
    try {
      String url = ApiConfig.riderEarnings;
      final params = <String>[];
      params.add('page=$page');
      params.add('limit=$limit');
      
      if (params.isNotEmpty) {
        url += '?${params.join('&')}';
      }
      
      final response = await _apiService.get(url);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> earningsData = data['data'] ?? data;
        return earningsData.map((item) => item as Map<String, dynamic>).toList();
      } else {
        throw Exception('Failed to load earnings');
      }
    } catch (e) {
      throw Exception('Error loading earnings: $e');
    }
  }

  Future<Map<String, dynamic>> requestPayout(Map<String, dynamic> data) async {
    try {
      final response = await _apiService.post(ApiConfig.riderPayoutRequest, data);
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to request payout');
      }
    } catch (e) {
      throw Exception('Error requesting payout: $e');
    }
  }
  
  Future<Map<String, dynamic>> requestWithdrawal(Map<String, dynamic> data) async {
    return requestPayout(data);
  }
  
  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> data) async {
    try {
      final response = await _apiService.put(ApiConfig.riderProfile, data);
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to update profile');
      }
    } catch (e) {
      throw Exception('Error updating profile: $e');
    }
  }
}
