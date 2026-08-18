import 'dart:convert';
import '../config/api_config.dart';
import 'api_service.dart';

class TransactionService {
  final ApiService _apiService = ApiService();

  Future<List<Map<String, dynamic>>> getTransactions({int page = 1, int limit = 20}) async {
    try {
      String url = ApiConfig.transactions;
      final params = <String>[];
      params.add('page=$page');
      params.add('limit=$limit');
      
      if (params.isNotEmpty) {
        url += '?${params.join('&')}';
      }
      
      final response = await _apiService.get(url);
      
      if (response.statusCode == 200) {
        final dynamic decoded = jsonDecode(response.body);
        final List<dynamic> transactionsData = decoded is List ? decoded : (decoded['data'] ?? []);
        return transactionsData.map((item) => item as Map<String, dynamic>).toList();
      } else {
        throw Exception('Failed to load transactions');
      }
    } catch (e) {
      throw Exception('Error fetching transactions: $e');
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
}
