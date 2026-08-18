import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../services/api_service.dart';

class OrderManagementScreen extends StatefulWidget {
  const OrderManagementScreen({super.key});

  @override
  State<OrderManagementScreen> createState() => _OrderManagementScreenState();
}

class _OrderManagementScreenState extends State<OrderManagementScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  List<dynamic> _orders = [];

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() => _isLoading = true);
    try {
      final response = await _apiService.get('/v1/admin/orders');
      if (mounted) {
        final data = jsonDecode(response.body);
        setState(() {
          _orders = data['data']?['data'] ?? [];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Order & Transaction Ledger')),
      body: _isLoading
        ? const Center(child: CircularProgressIndicator())
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _orders.length,
            itemBuilder: (context, i) {
              final o = _orders[i];
              return Card(
                child: ListTile(
                  title: Text('Order ${o['display_id']}'),
                  subtitle: Text('Total: TZS ${o['total']} • ${o['status'].toString().toUpperCase()}'),
                  trailing: const Icon(Icons.chevron_right),
                ),
              );
            },
          ),
    );
  }
}
