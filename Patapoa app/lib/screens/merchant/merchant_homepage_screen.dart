import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/merchant_service.dart';
import '../../utils/number_utils.dart';
import '../../widgets/liquid_glass_container.dart';

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
  }

  Future<void> _loadStats() async {
    setState(() => _isLoading = true);
    try {
      final stats = await _merchantService.getStats();
      if (mounted) setState(() { _stats = stats; _isLoading = false; });
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
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadStats,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(textTheme, colorScheme),
                const SizedBox(height: 24),
                _buildOnboardingChecklist(colorScheme, textTheme, stats),
                if ((stats['low_stock_count'] ?? 0) > 0) ...[
                  const SizedBox(height: 16),
                  _buildLowStockAlert(colorScheme, textTheme, stats['low_stock_count']),
                ],
                const SizedBox(height: 24),
                _buildEarningsCard(colorScheme, textTheme, totalRevenue, stats),
                const SizedBox(height: 24),
                _buildOrderRequestsHeader(textTheme, colorScheme),
                const SizedBox(height: 12),
                if (_isLoading)
                  const Center(child: CircularProgressIndicator())
                else if (pendingOrdersList.isEmpty)
                  _buildEmptyState(textTheme, colorScheme, stats['pending_orders'] ?? 0)
                else
                  ...pendingOrdersList.take(2).map((raw) => _buildOrderCard(raw, textTheme, colorScheme)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(TextTheme textTheme, ColorScheme colorScheme) {
    return Row(
      children: [
        Image.asset(
          'assets/images/patapoa official logo.png',
          height: 32,
          fit: BoxFit.contain,
        ),
        const SizedBox(width: 8),
        Text('Merchant', style: textTheme.titleLarge?.copyWith(color: colorScheme.primary, fontWeight: FontWeight.w900)),
        const Spacer(),
        CircleAvatar(
          radius: 18,
          backgroundColor: colorScheme.primaryContainer.withValues(alpha: 0.2),
          child: Icon(Icons.person, color: colorScheme.primary, size: 18),
        ),
      ],
    );
  }

  Widget _buildLowStockAlert(ColorScheme colorScheme, TextTheme textTheme, int count) {
    return LiquidGlassContainer(
      padding: const EdgeInsets.all(16),
      borderRadius: 16,
      opacity: 0.2,
      blur: 10,
      color: Colors.red,
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: colorScheme.error),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              '$count items are running low on stock. Update them now.',
              style: textTheme.bodyMedium?.copyWith(color: colorScheme.error, fontWeight: FontWeight.w600),
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

    return LiquidGlassContainer(
      padding: const EdgeInsets.all(20),
      borderRadius: 24,
      opacity: 0.15,
      blur: 15,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '🏪 Welcome, ${stats['store_name'] ?? 'Shopkeeper'}!',
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text('Complete these steps to start receiving orders:'),
          const SizedBox(height: 16),
          _checklistTile(
            context,
            'Store Location Set (${stats['city'] ?? 'Tanzania'})',
            locationSet,
            '/merchant/location-setup',
          ),
          _checklistTile(
            context,
            'Add First 5 Stock Items ($productsCount/5)',
            productsCount >= 5,
            '/merchant/add-product',
          ),
          _checklistTile(
            context,
            'Setup Mobile Money for Payouts',
            payoutSet,
            '/merchant/profile', // Assuming payout setup is in profile for now
          ),
        ],
      ),
    );
  }

  Widget _checklistTile(BuildContext context, String title, bool isDone, String route) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: isDone ? null : () => context.push(route),
        child: Row(
          children: [
            Icon(
              isDone ? Icons.check_circle : Icons.radio_button_unchecked,
              color: isDone ? Colors.green : colorScheme.primary,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  decoration: isDone ? TextDecoration.lineThrough : null,
                  color: isDone ? Colors.grey : null,
                  fontWeight: isDone ? null : FontWeight.w500,
                ),
              ),
            ),
            if (!isDone)
              Icon(Icons.chevron_right, size: 16, color: colorScheme.primary),
          ],
        ),
      ),
    );
  }

  Widget _buildEarningsCard(ColorScheme colorScheme, TextTheme textTheme, dynamic totalRevenue, Map stats) {
    return LiquidGlassContainer(
      padding: const EdgeInsets.all(24),
      borderRadius: 32,
      opacity: 0.8,
      blur: 20,
      color: colorScheme.primary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Total Earnings', style: textTheme.bodyMedium?.copyWith(color: Colors.white70)),
          const SizedBox(height: 8),
          Text(
            'TZS ${totalRevenue.toString().replaceAllMapped(RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"), (m) => "${m[1]},")}',
            style: textTheme.headlineMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              _QuickStatCard(icon: Icons.receipt, value: '${stats['total_orders'] ?? 0}', label: 'Orders'),
              const SizedBox(width: 12),
              _QuickStatCard(icon: Icons.pending_actions, value: '${stats['pending_orders'] ?? 0}', label: 'Pending'),
              const SizedBox(width: 12),
              _QuickStatCard(icon: Icons.star, value: NumberUtils.formatRating(stats['rating']), label: 'Rating'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOrderRequestsHeader(TextTheme textTheme, ColorScheme colorScheme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('New Order Requests', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
        TextButton(onPressed: () => context.go('/merchant/orders'), child: Text('View All', style: textTheme.labelSmall?.copyWith(color: colorScheme.primary))),
      ],
    );
  }

  Widget _buildEmptyState(TextTheme textTheme, ColorScheme colorScheme, int pendingCount) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Text(
          pendingCount > 0 ? '$pendingCount orders pending — open Orders tab' : 'No new orders right now',
          style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
        ),
      ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> map, TextTheme textTheme, ColorScheme colorScheme) {
    final id = (map['id'] as num).toInt();
    final displayId = map['display_id'] as String? ?? '#$id';
    final customerName = map['customer']?['name'] as String? ?? 'Customer';
    final items = (map['items_list'] as List? ?? []);

    return LiquidGlassContainer(
      padding: const EdgeInsets.all(20),
      borderRadius: 24,
      opacity: 0.1,
      blur: 5,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(displayId, style: textTheme.titleMedium?.copyWith(color: colorScheme.primary, fontWeight: FontWeight.bold)),
              Text(customerName, style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
            ],
          ),
          const Divider(height: 24, color: Colors.white24),
          Text('ITEMS:', style: textTheme.labelSmall?.copyWith(letterSpacing: 1, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...items.map((item) {
            final String name = item['product_name'] ?? '';
            final String brand = item['brand'] ?? '';
            final String unit = item['unit'] ?? '';
            String fullDisplayName = name;
            if (brand.isNotEmpty && unit.isNotEmpty) {
              fullDisplayName = '$brand $name ($unit)';
            } else if (brand.isNotEmpty) {
              fullDisplayName = '$brand $name';
            } else if (unit.isNotEmpty) {
              fullDisplayName = '$name ($unit)';
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Text('${item['quantity']}x ', style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.bold)),
                  Expanded(child: Text(fullDisplayName, maxLines: 1, overflow: TextOverflow.ellipsis)),
                  Text('TZS ${NumberUtils.formatCurrency(NumberUtils.toDouble(item['unit_price']) * NumberUtils.toDouble(item['quantity']))}'),
                ],
              ),
            );
          }),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(child: OutlinedButton(
                onPressed: () => _handleOrder(id, 'cancelled'), 
                style: OutlinedButton.styleFrom(
                  foregroundColor: colorScheme.error,
                  side: BorderSide(color: colorScheme.error.withValues(alpha: 0.5)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ), 
                child: const Text('Decline')
              )),
              const SizedBox(width: 12),
              Expanded(child: FilledButton(
                onPressed: () => _handleOrder(id, 'confirmed'), 
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Accept Order')
              )),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _handleOrder(int id, String status) async {
    try {
      await _merchantService.updateOrderStatus(id, status);
      _loadStats();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Order updated successfully')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }
}

class _QuickStatCard extends StatelessWidget {
  const _QuickStatCard({required this.icon, required this.value, required this.label});
  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(12)),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(height: 4),
            Text(value, style: textTheme.titleMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w900)),
            Text(label, style: textTheme.labelSmall?.copyWith(color: Colors.white70)),
          ],
        ),
      ),
    );
  }
}
