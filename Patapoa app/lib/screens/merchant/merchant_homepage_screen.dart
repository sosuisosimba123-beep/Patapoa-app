import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/merchant_service.dart';
import '../../services/pocketbase_services.dart';
import '../../utils/number_utils.dart';

class MerchantHomeScreen extends StatefulWidget {
  const MerchantHomeScreen({super.key});

  @override
  State<MerchantHomeScreen> createState() => _MerchantHomeScreenState();
}

class _MerchantHomeScreenState extends State<MerchantHomeScreen> {
  final MerchantService _merchantService = MerchantService();
  Map<String, dynamic>? _stats;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
    _broadcastActivity();
  }

  Future<void> _broadcastActivity() async {
    try {
      final userId = pb.authStore.model?.id;
      if (userId == null) return;

      final records = await pb.collection('merchant_activity').getList(
        filter: 'user = "$userId"',
        page: 1, perPage: 1
      );

      final data = {
        'user': userId,
        'is_accepting_orders': true,
        'last_seen': DateTime.now().toIso8601String(),
      };

      if (records.items.isNotEmpty) {
        await pb.collection('merchant_activity').update(records.items.first.id, body: data);
      } else {
        await pb.collection('merchant_activity').create(body: data);
      }
    } catch (e) {
      debugPrint('Merchant activity broadcast error: $e');
    }
  }

  Future<void> _loadStats() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final stats = await _merchantService.getStats();
      if (mounted) {
        setState(() {
          _stats = stats;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final stats = _stats ?? {};
    final totalRevenue = stats['total_revenue'] ?? 0;
    final pendingOrdersList = (_stats?['recent_orders'] as List<dynamic>? ?? []);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Merchant Dashboard'),
        actions: [
          IconButton(
            onPressed: _loadStats,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadStats,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildEarningsCard(colorScheme, textTheme, totalRevenue, stats),
              const SizedBox(height: 24),
              _buildOnboardingChecklist(colorScheme, textTheme, stats),
              if ((stats['low_stock_count'] ?? 0) > 0) ...[
                const SizedBox(height: 16),
                _buildLowStockAlert(colorScheme, textTheme, stats['low_stock_count']),
              ],
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('New Order Requests', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  TextButton(
                    onPressed: () => context.go('/merchant/orders'),
                    child: const Text('View All'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (_isLoading)
                const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()))
              else if (pendingOrdersList.isEmpty)
                const Center(child: Padding(padding: EdgeInsets.all(32), child: Text('No new orders right now')))
              else
                ...pendingOrdersList.take(3).map((raw) => _buildOrderCard(raw, textTheme, colorScheme)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEarningsCard(ColorScheme colorScheme, TextTheme textTheme, dynamic totalRevenue, Map stats) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Total Earnings', style: textTheme.labelLarge),
            const SizedBox(height: 8),
            Text(
              'TZS ${NumberUtils.formatCurrency(totalRevenue)}',
              style: textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold, color: colorScheme.primary),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _statItem(Icons.shopping_bag, '${stats['total_orders'] ?? 0}', 'Orders'),
                _statItem(Icons.pending, '${stats['pending_orders'] ?? 0}', 'Pending'),
                _statItem(Icons.star, NumberUtils.formatRating(stats['rating']), 'Rating'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _statItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, size: 20, color: Colors.grey),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }

  Widget _buildLowStockAlert(ColorScheme colorScheme, TextTheme textTheme, int count) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.errorContainer),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: colorScheme.error),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              '$count items are running low on stock.',
              style: TextStyle(color: colorScheme.error, fontWeight: FontWeight.w600),
            ),
          ),
          TextButton(
            onPressed: () => context.go('/merchant/inventory'),
            child: const Text('View'),
          ),
        ],
      ),
    );
  }

  Widget _buildOnboardingChecklist(ColorScheme colorScheme, TextTheme textTheme, Map stats) {
    final bool locationSet = stats['latitude'] != null;
    final int productsCount = stats['products_count'] ?? 0;
    final bool payoutSet = stats['payout_setup'] ?? false;

    if (locationSet && productsCount >= 5 && payoutSet) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('🏪 Store Setup', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _checklistTile('Store Location Set', locationSet, '/merchant/location-setup'),
            _checklistTile('Add First 5 Items', productsCount >= 5, '/merchant/add-product'),
            _checklistTile('Setup Payouts', payoutSet, '/merchant/profile'),
          ],
        ),
      ),
    );
  }

  Widget _checklistTile(String title, bool isDone, String route) {
    return ListTile(
      leading: Icon(isDone ? Icons.check_circle : Icons.radio_button_unchecked, color: isDone ? Colors.green : null),
      title: Text(title, style: TextStyle(decoration: isDone ? TextDecoration.lineThrough : null)),
      trailing: isDone ? null : const Icon(Icons.chevron_right, size: 16),
      onTap: isDone ? null : () => context.push(route),
      dense: true,
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> map, TextTheme textTheme, ColorScheme colorScheme) {
    final String id = map['id'].toString();
    final displayId = map['display_id'] as String? ?? '#$id';
    final customerName = map['customer']?['name'] as String? ?? 'Customer';
    final items = (map['items_list'] as List? ?? []);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(displayId, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(customerName),
              ],
            ),
            const Divider(),
            ...items.map((item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Text('${item['quantity']}x ${item['product_name']}'),
            )),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: OutlinedButton(onPressed: () => _handleOrder(id, 'cancelled'), child: const Text('Decline'))),
                const SizedBox(width: 12),
                Expanded(child: FilledButton(onPressed: () => _handleOrder(id, 'confirmed'), child: const Text('Accept'))),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleOrder(String id, String status) async {
    try {
      await _merchantService.updateOrderStatus(id, status);
      _loadStats();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Order updated')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }
}
