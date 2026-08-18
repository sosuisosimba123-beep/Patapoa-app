import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../services/api_service.dart';

class MerchantManagementScreen extends StatefulWidget {
  const MerchantManagementScreen({super.key});

  @override
  State<MerchantManagementScreen> createState() => _MerchantManagementScreenState();
}

class _MerchantManagementScreenState extends State<MerchantManagementScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  List<dynamic> _merchants = [];

  @override
  void initState() {
    super.initState();
    _loadMerchants();
  }

  Future<void> _loadMerchants() async {
    setState(() => _isLoading = true);
    try {
      final response = await _apiService.get('/v1/admin/merchants');
      if (mounted) {
        final data = jsonDecode(response.body);
        setState(() {
          _merchants = data['data']?['data'] ?? [];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _verifyMerchant(int id) async {
    try {
      await _apiService.post('/v1/admin/merchants/$id/verify', {});
      _loadMerchants();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Supermarket Management')),
      body: _isLoading
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: _loadMerchants,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _merchants.length,
              itemBuilder: (context, i) {
                final m = _merchants[i];
                final isVerified = m['is_verified'] == true;
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isVerified ? Colors.green.shade50 : Colors.orange.shade50,
                      child: Icon(Icons.store, color: isVerified ? Colors.green : Colors.orange),
                    ),
                    title: Text(m['store_name'] ?? 'Unnamed Store'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(m['city'] ?? 'No City'),
                        if (!isVerified)
                          const Text('PENDING VERIFICATION', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 10)),
                      ],
                    ),
                    trailing: !isVerified ? ElevatedButton(
                      onPressed: () => _verifyMerchant(m['id']),
                      child: const Text('Approve'),
                    ) : const Icon(Icons.verified, color: Colors.blue),
                  ),
                );
              },
            ),
          ),
    );
  }
}
