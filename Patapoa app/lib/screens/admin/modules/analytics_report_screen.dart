import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../services/api_service.dart';

class AnalyticsReportScreen extends StatefulWidget {
  const AnalyticsReportScreen({super.key});

  @override
  State<AnalyticsReportScreen> createState() => _AnalyticsReportScreenState();
}

class _AnalyticsReportScreenState extends State<AnalyticsReportScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  Map<String, dynamic>? _analytics;

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    setState(() => _isLoading = true);
    try {
      final response = await _apiService.get('/v1/admin/sales-analytics');
      if (mounted) {
        final data = jsonDecode(response.body);
        setState(() {
          _analytics = data['data'];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Analytics & Sales Trends')),
      body: _isLoading
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Top Performing Categories', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                ...?(_analytics?['top_categories'] as List?)?.map((cat) => Card(
                  child: ListTile(
                    title: Text(cat['name']),
                    trailing: Text('TZS ${cat['total_sales']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                )),
                const SizedBox(height: 24),
                Text('Fast Moving Items', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Card(
                  child: Column(
                    children: [
                      ...?(_analytics?['fast_moving_items'] as List?)?.map((item) => ListTile(
                        title: Text(item['product_name']),
                        trailing: Text('${item['total_qty']} sold'),
                      )),
                    ],
                  ),
                ),
              ],
            ),
          ),
    );
  }
}
