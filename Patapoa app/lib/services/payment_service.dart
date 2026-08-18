import 'dart:convert';
import '../config/api_config.dart';
import 'api_service.dart';

class PaymentService {
  final ApiService _apiService = ApiService();

  Future<Map<String, dynamic>> initiatePayment({
    required int orderId,
    required String paymentMethod,
  }) async {
    try {
      final response = await _apiService.post(ApiConfig.paymentsInitiate, {
        'order_id': orderId,
        'payment_method': paymentMethod,
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        final data = jsonDecode(response.body);
        throw Exception(data['message'] ?? 'Failed to initiate payment');
      }
    } catch (e) {
      throw Exception('Error initiating payment: $e');
    }
  }

  Future<Map<String, dynamic>> checkPaymentStatus(int orderId) async {
    try {
      final response = await _apiService.get(ApiConfig.paymentsStatus(orderId));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'] ?? data;
      } else {
        throw Exception('Failed to check payment status');
      }
    } catch (e) {
      throw Exception('Error checking payment status: $e');
    }
  }
}
