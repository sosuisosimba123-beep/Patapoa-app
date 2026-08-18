import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../services/api_service.dart';
import '../../../utils/number_utils.dart';

class SystemSettingsScreen extends StatefulWidget {
  const SystemSettingsScreen({super.key});

  @override
  State<SystemSettingsScreen> createState() => _SystemSettingsScreenState();
}

class _SystemSettingsScreenState extends State<SystemSettingsScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  Map<String, dynamic>? _settings;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    try {
      final response = await _apiService.get('/v1/admin/settings');
      if (mounted) {
        final data = jsonDecode(response.body);
        setState(() {
          _settings = data['data'];
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
      appBar: AppBar(title: const Text('System Configuration')),
      body: _isLoading
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildSettingTile('Commission Rate', '${(NumberUtils.toDouble(_settings?['platform_commission_rate']) * 100).toStringAsFixed(0)}%'),
              _buildSettingTile('Base Delivery Fee', 'TZS ${NumberUtils.formatCurrency(_settings?['delivery_base_fee'])}'),
              _buildSettingTile('Per KM Fee', 'TZS ${NumberUtils.formatCurrency(_settings?['delivery_per_km_fee'])}'),
              const Divider(height: 32),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text('Operational Zones', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              ...(_settings?['active_operational_zones'] as List).map((zone) => ListTile(
                title: Text(zone['city']),
                subtitle: Text('Radius: ${zone['radius']} km'),
                leading: const Icon(Icons.location_city),
              )),
              const Divider(height: 32),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text('Delivery Pricing Rules', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              ...(_settings?['pricing_rules'] as List? ?? []).map((rule) => Card(
                child: ListTile(
                  title: Text(rule['zone_name']),
                  subtitle: Text('Base: TZS ${rule['base_fee']} • KM: TZS ${rule['per_km_fee']}'),
                  trailing: Text('x${rule['surge_multiplier']}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
                ),
              )),
            ],
          ),
    );
  }

  Widget _buildSettingTile(String label, String value) {
    return ListTile(
      title: Text(label),
      trailing: Text(value, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
      onTap: () {
        // Implement edit logic
      },
    );
  }
}
