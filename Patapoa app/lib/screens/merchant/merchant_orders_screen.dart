import 'package:flutter/material.dart';
import '../../services/merchant_service.dart';
import '../../models/order.dart';

class MerchantOrdersScreen extends StatefulWidget {
  const MerchantOrdersScreen({super.key});

  @override
  State<MerchantOrdersScreen> createState() => _MerchantOrdersScreenState();
}

class _MerchantOrdersScreenState extends State<MerchantOrdersScreen> {
  String _selectedTab = 'new';
  final _scrollController = ScrollController();
  final MerchantService _merchantService = MerchantService();
  List<Order> _orders = [];
  bool _isLoading = true;
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
    setState(() { _isLoading = true; _currentPage = 1; _hasMore = true; });
    try {
      final orders = await _merchantService.getOrders(page: 1, limit: 20);
      if (mounted) setState(() { _orders = orders; _isLoading = false; _hasMore = orders.length >= 20; });
    } catch (e) {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  Future<void> _loadMoreOrders() async {
    if (_isLoadingMore || !_hasMore) return;
    setState(() => _isLoadingMore = true);
    try {
      final orders = await _merchantService.getOrders(page: _currentPage + 1, limit: 20);
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

  Future<void> _updateStatus(String orderId, String status) async {
    try {
      await _merchantService.updateOrderStatus(orderId, status);
      _loadOrders();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Order updated to $status')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final filtered = _orders.where((o) {
      if (_selectedTab == 'new') return o.status == 'placed' || o.status == 'confirmed';
      if (_selectedTab == 'progress') return o.status == 'preparing' || o.status == 'ready_for_pickup';
      return o.status == 'completed' || o.status == 'delivered';
    }).toList();

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(textTheme, colorScheme),
            _buildTabs(colorScheme),
            const SizedBox(height: 12),
            Expanded(
              child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : filtered.isEmpty
                  ? _buildEmptyState(colorScheme, textTheme)
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: filtered.length + (_isLoadingMore ? 1 : 0),
                      itemBuilder: (context, i) => i < filtered.length ? _buildOrderCard(filtered[i], textTheme, colorScheme) : const Center(child: CircularProgressIndicator()),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(TextTheme textTheme, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Text('Orders', style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: colorScheme.primaryContainer.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(20)),
            child: Text('${_orders.length}', style: textTheme.labelLarge?.copyWith(color: colorScheme.primary, fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }

  Widget _buildTabs(ColorScheme colorScheme) {
    final tabs = ['new', 'progress', 'completed'];
    final labels = ['New', 'In Progress', 'Completed'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: List.generate(tabs.length, (i) {
          final selected = tabs[i] == _selectedTab;
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: i < tabs.length - 1 ? 8 : 0),
              child: FilledButton.tonal(
                onPressed: () => setState(() => _selectedTab = tabs[i]),
                style: FilledButton.styleFrom(
                  backgroundColor: selected ? colorScheme.primaryContainer : colorScheme.surfaceContainerHighest,
                  foregroundColor: selected ? colorScheme.onPrimaryContainer : colorScheme.onSurface,
                ),
                child: Text(labels[i], style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildEmptyState(ColorScheme colorScheme, TextTheme textTheme) {
    return Center(child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.inbox_outlined, size: 64, color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
        const SizedBox(height: 16),
        Text('No orders in this category', style: textTheme.titleMedium?.copyWith(color: colorScheme.onSurfaceVariant)),
      ],
    ));
  }

  Widget _buildOrderCard(Order order, TextTheme textTheme, ColorScheme colorScheme) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(order.displayId, style: textTheme.labelSmall?.copyWith(color: colorScheme.primary, fontWeight: FontWeight.bold)),
                const Spacer(),
                _StatusBadge(status: order.status),
              ],
            ),
            const SizedBox(height: 8),
            Text('TZS ${order.total.toStringAsFixed(0)}', style: textTheme.titleMedium?.copyWith(color: colorScheme.primary, fontWeight: FontWeight.w900)),
            const SizedBox(height: 12),
            _buildActionButtons(order),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(Order order) {
    if (_selectedTab == 'new') {
      return Row(children: [
        Expanded(child: FilledButton.tonal(onPressed: () => _updateStatus(order.id, 'confirmed'), child: const Text('Confirm'))),
        const SizedBox(width: 8),
        Expanded(child: FilledButton.tonal(onPressed: () => _updateStatus(order.id, 'preparing'), child: const Text('Prepare'))),
      ]);
    }
    if (_selectedTab == 'progress') {
      return SizedBox(width: double.infinity, child: FilledButton.tonal(onPressed: () => _updateStatus(order.id, 'ready_for_pickup'), child: const Text('Ready for Pickup')));
    }
    return const SizedBox.shrink();
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: status == 'placed' ? colorScheme.secondaryContainer : colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(status.toUpperCase(), style: Theme.of(context).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w800)),
    );
  }
}
