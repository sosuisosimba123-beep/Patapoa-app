import 'dart:convert';
import '../config/api_config.dart';
import 'api_service.dart';

class AddressService {
  final ApiService _apiService = ApiService();

  Future<List<Map<String, dynamic>>> getAddresses() async {
    try {
      final response = await _apiService.get(ApiConfig.addresses);
      if (response.statusCode == 200) {
        final dynamic decoded = jsonDecode(response.body);
        final List<dynamic> data = decoded is List ? decoded : (decoded['data'] ?? []);
        return data.map((item) => item as Map<String, dynamic>).toList();
      } else {
        throw Exception('Failed to load addresses');
      }
    } catch (e) {
      throw Exception('Error fetching addresses: $e');
    }
  }

  Future<Map<String, dynamic>> createAddress({
    required String label,
    required String recipientName,
    required String phone,
    required String addressLine1,
    String? addressLine2,
    required String city,
    required String region,
    double? latitude,
    double? longitude,
  }) async {
    try {
      final body = <String, dynamic>{
        'label': label,
        'recipient_name': recipientName,
        'phone': phone,
        'address_line_1': addressLine1,
        'city': city,
        'region': region,
      };
      if (addressLine2 != null) body['address_line_2'] = addressLine2;
      if (latitude != null) body['latitude'] = latitude;
      if (longitude != null) body['longitude'] = longitude;

      final response = await _apiService.post(ApiConfig.addresses, body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data['data'] ?? data;
      } else {
        throw Exception('Failed to create address');
      }
    } catch (e) {
      throw Exception('Error creating address: $e');
    }
  }

  Future<Map<String, dynamic>> setDefaultAddress(int id) async {
    try {
      final response = await _apiService.put(ApiConfig.addressSetDefault(id), {});
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'] ?? data;
      } else {
        throw Exception('Failed to set default address');
      }
    } catch (e) {
      throw Exception('Error setting default address: $e');
    }
  }

  Future<void> deleteAddress(int id) async {
    try {
      final response = await _apiService.delete(ApiConfig.address(id));
      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Failed to delete address');
      }
    } catch (e) {
      throw Exception('Error deleting address: $e');
    }
  }
}
