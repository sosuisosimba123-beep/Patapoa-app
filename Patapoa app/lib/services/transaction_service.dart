import 'package:flutter/foundation.dart';
import 'pocketbase_services.dart';

class TransactionService {
  Future<List<Map<String, dynamic>>> getTransactions({int page = 1, int limit = 20}) async {
    final userId = pb.authStore.model?.id;
    if (userId == null) return [];

    try {
      final result = await pb.collection('transactions').getList(
        page: page,
        perPage: limit,
        filter: 'user = "$userId"',
        sort: '-created',
      );

      return result.items.map((record) => {
        'id': record.id,
        ...record.data,
        'created_at': record.created,
      }).toList();
    } catch (e) {
      debugPrint('PocketBase GetTransactions Error: $e');
      return [];
    }
  }

  Future<void> requestPayout(Map<String, dynamic> data) async {
    final userId = pb.authStore.model?.id;
    if (userId == null) throw Exception('Auth required');

    try {
      // Create a pending debit transaction
      await pb.collection('transactions').create(body: {
        'user': userId,
        'amount': -(data['amount'] as num).abs(),
        'type': 'debit',
        'description': 'Withdrawal request to ${data['phone']} (${data['provider']})',
        'status': 'pending',
      });
    } catch (e) {
      throw Exception('Failed to submit payout request: $e');
    }
  }
}
