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
        final data = jsonDecode(response.body);
        return data['data'] ?? data;
      } else {
        final data = jsonDecode(response.body);
        throw Exception(data['message'] ?? 'Failed to initiate payment');
      }
    } catch (e) {
      throw Exception('Error initiating payment: $e');
    }
  }

  Future<Map<String, dynamic>> processMpesaStkPush({
    required int orderId,
    required String phoneNumber,
    required double amount,
  }) async {
    try {
      final response = await _apiService.post(ApiConfig.paymentsInitiate, {
        'order_id': orderId,
        'payment_method': 'mpesa',
        'phone_number': phoneNumber,
        'amount': amount,
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data['data'] ?? data;
      } else {
        final data = jsonDecode(response.body);
        throw Exception(data['message'] ?? 'M-Pesa STK push failed');
      }
    } catch (e) {
      throw Exception('Error processing M-Pesa payment: $e');
    }
  }

  Future<Map<String, dynamic>> checkPaymentStatus(String paymentReference) async {
    try {
      final response = await _apiService.get('${ApiConfig.paymentsCallback}/$paymentReference');

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
