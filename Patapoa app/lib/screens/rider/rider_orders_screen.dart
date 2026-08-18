import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/delivery_partner_service.dart';
import '../../features/delivery_partner/delivery_partner_models.dart';

class RiderOrdersScreen extends StatefulWidget {
  const RiderOrdersScreen({super.key});

  @override
  State<RiderOrdersScreen> createState() => _RiderOrdersScreenState();
}

class _RiderOrdersScreenState extends State<RiderOrdersScreen> {
  final DeliveryPartnerService _riderService = DeliveryPartnerService();
  final _scrollController = ScrollController();

  bool _isLoading = false;
  List<Map<String, dynamic>> _orders = [];
  String? _errorMessage;
  int _currentPage = 1;
  bool _hasMore = true;
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _loadOrders();
    _scrollController.addListener(_onScroll);
  }

  Future<void> _loadOrders() async {
    setState(() { _isLoading = true; _errorMessage = null; _currentPage = 1; _hasMore = true; });
    try {
      final orders = await _riderService.getOrders(page: 1, limit: 20);
      if (mounted) setState(() { _orders = orders; _isLoading = false; _hasMore = orders.length >= 20; });
    } catch (e) {
      if (mounted) setState(() { _errorMessage = e.toString(); _isLoading = false; });
    }
  }

  Future<void> _loadMoreOrders() async {
    if (_isLoadingMore || !_hasMore) return;
    setState(() => _isLoadingMore = true);
    try {
      final orders = await _riderService.getOrders(page: _currentPage + 1, limit: 20);
      if (mounted) {
        setState(() { _orders.addAll(orders); _currentPage++; _hasMore = orders.length >= 20; _isLoadingMore = false; });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingMore = false);
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) _loadMoreOrders();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final topInset = math.max(12.0, MediaQuery.paddingOf(context).top);

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(16, topInset + 8, 16, 12),
            child: Row(
              children: [
                Builder(
                  builder: (context) => IconButton(
                    onPressed: () => Scaffold.of(context).openDrawer(), 
                    icon: const Icon(Icons.menu)
                  ),
                ),
                const SizedBox(width: 8),
                Text('Deliveries', style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                const Spacer(),
                IconButton(onPressed: _loadOrders, icon: const Icon(Icons.refresh)),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? _buildErrorState(colorScheme, textTheme)
                    : _orders.isEmpty
                        ? _buildEmptyState(colorScheme, textTheme)
                        : ListView.separated(
                            controller: _scrollController,
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                            itemCount: _orders.length + (_isLoadingMore ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (index < _orders.length) return _buildOrderTile(_orders[index], context);
                              return const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()));
                            },
                            separatorBuilder: (_, __) => const SizedBox(height: 12),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(ColorScheme colorScheme, TextTheme textTheme) {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(Icons.error_outline, size: 64, color: colorScheme.error),
      const SizedBox(height: 16),
      Text(_errorMessage!, style: textTheme.bodyMedium?.copyWith(color: colorScheme.error), textAlign: TextAlign.center),
      const SizedBox(height: 16),
      FilledButton(onPressed: _loadOrders, child: const Text('Retry')),
    ]));
  }

  Widget _buildEmptyState(ColorScheme colorScheme, TextTheme textTheme) {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(Icons.inbox_outlined, size: 64, color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
      const SizedBox(height: 16),
      Text('No orders found', style: textTheme.titleMedium?.copyWith(color: colorScheme.onSurfaceVariant)),
    ]));
  }

  Widget _buildOrderTile(Map<String, dynamic> order, BuildContext context) {
    return _OrderCard(
      order: DeliveryOrder(
        id: order['id']?.toString() ?? '',
        customerName: order['customer_name'] ?? 'Customer',
        customerRating: (order['customer_rating'] as num?)?.toDouble() ?? 0.0,
        customerPhone: order['customer_phone'] ?? '',
        pickupLocation: order['pickup_location'] ?? '',
        dropoffLocation: order['delivery_location'] ?? '',
        pickupDistance: (order['pickup_distance'] as num?)?.toDouble() ?? 0.0,
        items: [],
        totalAmount: (order['total_amount'] as num?)?.toDouble() ?? 0.0,
        deliveryFee: (order['delivery_fee'] as num?)?.toDouble() ?? 0.0,
        earnings: (order['earnings'] as num?)?.toDouble() ?? 0.0,
        status: order['status'] ?? 'pending',
        orderDate: DateTime.now(),
        isCashOnDelivery: order['is_cash_on_delivery'] as bool? ?? false,
      ),
      onTap: () => context.go('/delivery-partner/route-assign', extra: order),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final DeliveryOrder order;
  final VoidCallback onTap;
  const _OrderCard({required this.order, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outline.withValues(alpha: 0.1)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('Order #${order.id}', style: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold)),
              _StatusBadge(status: order.status),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              const Icon(Icons.location_on_outlined, size: 16),
              const SizedBox(width: 8),
              Expanded(child: Text(order.dropoffLocation, style: textTheme.bodyMedium, maxLines: 1, overflow: TextOverflow.ellipsis)),
            ]),
            const SizedBox(height: 8),
            Row(children: [
              const Icon(Icons.person_outline, size: 16),
              const SizedBox(width: 8),
              Text(order.customerName, style: textTheme.bodyMedium),
            ]),
            const Divider(height: 24),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('Earnings', style: textTheme.bodySmall),
              Text('TZS ${order.earnings.toStringAsFixed(0)}', style: textTheme.titleMedium?.copyWith(color: colorScheme.primary, fontWeight: FontWeight.bold)),
            ]),
          ]),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: colorScheme.primaryContainer.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(8)),
      child: Text(status.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: colorScheme.onPrimaryContainer)),
    );
  }
}
