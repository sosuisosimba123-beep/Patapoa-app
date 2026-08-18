import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../services/api_service.dart';
import '../../../screens/admin/modules/merchant_management_screen.dart';
import '../../../screens/admin/modules/order_management_screen.dart';
import '../../../screens/admin/modules/analytics_report_screen.dart';
import '../../../screens/admin/modules/system_settings_screen.dart';
import '../../../screens/admin/modules/delivery_logistics_screen.dart';

class AdminOverviewScreen extends StatefulWidget {
  const AdminOverviewScreen({super.key});

  @override
  State<AdminOverviewScreen> createState() => _AdminOverviewScreenState();
}

class _AdminOverviewScreenState extends State<AdminOverviewScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  Map<String, dynamic>? _stats;
  Map<String, dynamic>? _expansionMetrics;
  bool _isLoadingExpansion = false;

  @override
  void initState() {
    super.initState();
    _loadStats();
    _loadExpansionMetrics();
  }

  Future<void> _loadStats() async {
    setState(() => _isLoading = true);
    try {
      final response = await _apiService.get('/v1/admin/dashboard');
      if (mounted) {
        final data = jsonDecode(response.body);
        setState(() {
          _stats = data['data'] ?? data;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading admin stats: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadExpansionMetrics() async {
    setState(() => _isLoadingExpansion = true);
    try {
      final response = await _apiService.get('/v1/admin/expansion-metrics');
      if (mounted) {
        final data = jsonDecode(response.body);
        setState(() {
          _expansionMetrics = data['data'] ?? data;
          _isLoadingExpansion = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading expansion metrics: $e');
      if (mounted) setState(() => _isLoadingExpansion = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Patapoa', style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900, color: colorScheme.primary)),
            Text('PLATFORM CONTROLLER', style: textTheme.labelSmall?.copyWith(letterSpacing: 1.5, fontWeight: FontWeight.bold, color: colorScheme.onSurfaceVariant)),
          ],
        ),
        actions: [
          IconButton(onPressed: () { _loadStats(); _loadExpansionMetrics(); }, icon: const Icon(Icons.refresh)),
          const CircleAvatar(radius: 18, child: Icon(Icons.person, size: 20)),
          const SizedBox(width: 16),
        ],
      ),
      body: _isLoading
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: () async { await _loadStats(); await _loadExpansionMetrics(); },
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildKPIGrid(),
                  const SizedBox(height: 24),
                  _buildSectionTitle('Operational Modules', textTheme),
                  const SizedBox(height: 12),
                  _buildModuleGrid(colorScheme),
                  const SizedBox(height: 24),
                  _buildSectionTitle('Strategic Expansion Data', textTheme),
                  const SizedBox(height: 12),
                  _buildExpansionData(colorScheme, textTheme),
                  const SizedBox(height: 24),
                  _buildSectionTitle('Deliverer Status', textTheme),
                  const SizedBox(height: 12),
                  _buildDelivererStatusCard(colorScheme, textTheme),
                  const SizedBox(height: 24),
                  _buildSectionTitle('Verification Requests', textTheme),
                  const SizedBox(height: 12),
                  _buildVerificationSection(colorScheme, textTheme),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildModuleGrid(ColorScheme colorScheme) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 2.5,
      children: [
        _ModuleTile(
          title: 'Merchants',
          icon: Icons.store_mall_directory,
          color: Colors.blue,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MerchantManagementScreen())),
        ),
        _ModuleTile(
          title: 'Orders',
          icon: Icons.receipt_long,
          color: Colors.green,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OrderManagementScreen())),
        ),
        _ModuleTile(
          title: 'Analytics',
          icon: Icons.analytics,
          color: Colors.purple,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AnalyticsReportScreen())),
        ),
        _ModuleTile(
          title: 'Logistics',
          icon: Icons.local_shipping,
          color: Colors.red,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DeliveryLogisticsScreen())),
        ),
        _ModuleTile(
          title: 'Settings',
          icon: Icons.settings,
          color: Colors.blueGrey,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SystemSettingsScreen())),
        ),
      ],
    );
  }

  Widget _buildExpansionData(ColorScheme colorScheme, TextTheme textTheme) {
    if (_isLoadingExpansion) return const Center(child: LinearProgressIndicator());
    if (_expansionMetrics == null) return const Text('No expansion data available');

    final unmet = _expansionMetrics!['unmet_demand'] as List? ?? [];

    return Column(
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Total Waitlist', style: textTheme.labelLarge),
                    Text('${_expansionMetrics!['total_waitlist']}', style: textTheme.titleLarge?.copyWith(color: colorScheme.primary, fontWeight: FontWeight.bold)),
                  ],
                ),
                const Divider(height: 24),
                Text('Most Demanded (Unmet)', style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                if (unmet.isEmpty) const Text('No data yet', style: TextStyle(fontSize: 12, color: Colors.grey)),
                ...unmet.take(3).map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${item['query']}', style: const TextStyle(fontSize: 13)),
                      Text('${item['search_count']} searches', style: textTheme.labelSmall),
                    ],
                  ),
                )),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildKPIGrid() {
    final executive = _stats?['executive'] ?? {};
    final revenue = executive['total_revenue'] ?? 0.0;
    final gmv = executive['daily_gmv'] ?? 0.0;
    final riders = executive['active_riders'] ?? 0;
    final payouts = _stats?['pending_actions']?['payouts'] ?? 0.0;

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 1.4,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      children: [
        _KPICard(
          title: 'TOTAL REVENUE',
          value: 'TZS ${_formatAmount(revenue)}',
          icon: Icons.payments,
          color: Colors.green,
        ),
        _KPICard(
          title: 'DAILY GMV',
          value: 'TZS ${_formatAmount(gmv)}',
          icon: Icons.trending_up,
          color: Colors.purple,
        ),
        _KPICard(
          title: 'LIVE RIDERS',
          value: '$riders',
          icon: Icons.local_shipping,
          color: Colors.blue
        ),
        _KPICard(
          title: 'PENDING PAYOUTS',
          value: 'TZS ${_formatAmount(payouts)}',
          icon: Icons.account_balance_wallet,
          color: Colors.red
        ),
      ],
    );
  }

  String _formatAmount(dynamic amount) {
    if (amount == null) return '0';
    if (amount is String) amount = double.tryParse(amount) ?? 0;
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1)}K';
    }
    return amount.toStringAsFixed(0);
  }

  Widget _buildDelivererStatusCard(ColorScheme colorScheme, TextTheme textTheme) {
    final active = _stats?['active_riders'] ?? 0;
    final total = _stats?['total_riders'] ?? 1;
    final progress = total > 0 ? active / total : 0.0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          _StatusRow(label: 'Active Riders', value: '$active', color: colorScheme.primary),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: colorScheme.surfaceContainerHighest,
            color: colorScheme.primary,
            minHeight: 8
          ),
          const SizedBox(height: 16),
          _StatusRow(label: 'Total Riders', value: '$total', color: colorScheme.onSurfaceVariant),
        ]),
      ),
    );
  }

  Widget _buildVerificationSection(ColorScheme colorScheme, TextTheme textTheme) {
    final merchants = _stats?['pending_merchant_verifications'] ?? 0;
    final riders = _stats?['pending_rider_verifications'] ?? 0;

    return Column(children: [
      _ActivityTile(
        icon: Icons.storefront,
        title: 'Pending Merchants',
        subtitle: 'Requires verification',
        status: '$merchants',
        color: merchants > 0 ? Colors.orange : Colors.grey
      ),
      _ActivityTile(
        icon: Icons.motorcycle,
        title: 'Pending Riders',
        subtitle: 'Requires verification',
        status: '$riders',
        color: riders > 0 ? Colors.orange : Colors.grey
      ),
    ]);
  }


  Widget _buildSectionTitle(String title, TextTheme textTheme) {
    return Text(title, style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold));
  }
}

class _ModuleTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ModuleTile({required this.title, required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}

class _KPICard extends StatelessWidget {
  final String title, value;
  final IconData icon;
  final Color color;
  final String? trend;
  const _KPICard({required this.title, required this.value, required this.icon, required this.color, this.trend});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey.shade200)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Icon(icon, color: color, size: 20),
            if (trend != null) Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)), child: Text(trend!, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold))),
          ]),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          Text(title, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black54)),
        ]),
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  final String label, value;
  final Color color;
  const _StatusRow({required this.label, required this.value, required this.color});
  @override
  Widget build(BuildContext context) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Row(children: [Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)), const SizedBox(width: 8), Text(label)]),
      Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
    ]);
  }
}

class _ActivityTile extends StatelessWidget {
  final IconData icon;
  final String title, subtitle, status;
  final Color color;
  const _ActivityTile({required this.icon, required this.title, required this.subtitle, required this.status, required this.color});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      trailing: Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)), child: Text(status, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold))),
    );
  }
}
