import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../services/api_service.dart';
import '../../../utils/number_utils.dart';

import './add_rider_screen.dart';

class DeliveryLogisticsScreen extends StatefulWidget {
  const DeliveryLogisticsScreen({super.key});

  @override
  State<DeliveryLogisticsScreen> createState() => _DeliveryLogisticsScreenState();
}

class _DeliveryLogisticsScreenState extends State<DeliveryLogisticsScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  Map<String, dynamic>? _logisticsData;

  @override
  void initState() {
    super.initState();
    _loadLogistics();
  }

  Future<void> _loadLogistics() async {
    setState(() => _isLoading = true);
    try {
      final response = await _apiService.get('/v1/admin/delivery-logistics');
      if (mounted) {
        final data = jsonDecode(response.body);
        setState(() {
          _logisticsData = data['data'];
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
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Delivery & Logistics')),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'add_rider_fab',
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddRiderScreen())).then((_) => _loadLogistics()),
        icon: const Icon(Icons.add),
        label: const Text('Add Rider'),
      ),
      body: _isLoading
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: _loadLogistics,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildRiderStats(colorScheme, textTheme),
                const SizedBox(height: 24),
                Text('Active Deliveries', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                _buildActiveDeliveries(colorScheme, textTheme),
                const SizedBox(height: 24),
                Text('Top Performing Riders', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                _buildTopRiders(colorScheme, textTheme),
              ],
            ),
          ),
    );
  }

  Widget _buildRiderStats(ColorScheme colorScheme, TextTheme textTheme) {
    final stats = _logisticsData?['stats'] as List? ?? [];
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            label: 'Online',
            value: stats.firstWhere((s) => s['is_online'] == 1, orElse: () => {'count': 0})['count'].toString(),
            color: Colors.green
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            label: 'Offline',
            value: stats.firstWhere((s) => s['is_online'] == 0, orElse: () => {'count': 0})['count'].toString(),
            color: Colors.grey
          ),
        ),
      ],
    );
  }

  Widget _buildActiveDeliveries(ColorScheme colorScheme, TextTheme textTheme) {
    final active = _logisticsData?['active_deliveries'] as List? ?? [];
    if (active.isEmpty) return const Card(child: Padding(padding: EdgeInsets.all(16), child: Text('No active deliveries')));

    return Column(
      children: active.map((d) => Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: ListTile(
          leading: const Icon(Icons.delivery_dining),
          title: Text('Order ${d['display_id']}'),
          subtitle: Text('Rider: ${d['rider']?['user']?['name'] ?? 'Assigning...'}'),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: colorScheme.primaryContainer, borderRadius: BorderRadius.circular(6)),
            child: Text(d['status'].toString().toUpperCase(), style: TextStyle(color: colorScheme.primary, fontSize: 10, fontWeight: FontWeight.bold)),
          ),
        ),
      )).toList(),
    );
  }

  Widget _buildTopRiders(ColorScheme colorScheme, TextTheme textTheme) {
    final riders = _logisticsData?['top_performers'] as List? ?? [];
    return Column(
      children: riders.map((r) => Card(
        child: ListTile(
          leading: const CircleAvatar(child: Icon(Icons.person)),
          title: Text(r['name']),
          subtitle: Text('${r['total_deliveries']} deliveries • ${NumberUtils.formatRating(r['rating'])}★'),
          trailing: Text('${NumberUtils.toDouble(r['avg_time']).toStringAsFixed(1)} min avg', style: textTheme.labelSmall),
        ),
      )).toList(),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label, value;
  final Color color;
  const _StatCard({required this.label, required this.value, required this.color});
  @override
  Widget build(BuildContext context) {
    return Card(
      color: color.withValues(alpha: 0.1),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color.withValues(alpha: 0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
          Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w500)),
        ]),
      ),
    );
  }
}
