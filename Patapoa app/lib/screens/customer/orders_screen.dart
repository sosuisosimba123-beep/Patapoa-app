import 'package:flutter/material.dart';
import '../../services/order_service.dart';
import '../../models/order.dart';
import '../../widgets/liquid_glass_container.dart';

class CustomerOrdersScreen extends StatefulWidget {
  const CustomerOrdersScreen({super.key});

  @override
  State<CustomerOrdersScreen> createState() => _CustomerOrdersScreenState();
}

class _CustomerOrdersScreenState extends State<CustomerOrdersScreen> {
  final OrderService _orderService = OrderService();
  String _selectedFilter = 'All';
  List<Order> _orders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() => _isLoading = true);
    try {
      final orders = await _orderService.getCustomerOrders();
      if (mounted) setState(() { _orders = orders; _isLoading = false; });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final filteredOrders = _orders.where((order) {
      if (_selectedFilter == 'All') return true;
      if (_selectedFilter == 'Pending') {
        return ['placed', 'confirmed', 'preparing', 'ready_for_pickup', 'rider_assigned', 'rider_heading_to_pickup', 'at_pickup', 'picked_up', 'heading_to_customer', 'at_dropoff'].contains(order.status);
      }
      if (_selectedFilter == 'Delivered') return order.status == 'completed' || order.status == 'delivered';
      if (_selectedFilter == 'Cancelled') return order.status == 'cancelled';
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: const Text('My Orders'), backgroundColor: Colors.transparent, elevation: 0),
      body: Column(children: [
        _buildFilters(colorScheme),
        Expanded(
          child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : filteredOrders.isEmpty
              ? const Center(child: Text('No orders found'))
              : RefreshIndicator(onRefresh: _loadOrders, child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredOrders.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, i) => _OrderCard(order: filteredOrders[i]),
                )),
        ),
      ]),
    );
  }

  Widget _buildFilters(ColorScheme colorScheme) {
    final filters = ['All', 'Pending', 'Delivered', 'Cancelled'];
    return SizedBox(height: 60, child: ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      scrollDirection: Axis.horizontal,
      itemCount: filters.length,
      separatorBuilder: (context, index) => const SizedBox(width: 8),
      itemBuilder: (context, i) => FilterChip(
        label: Text(filters[i]),
        selected: _selectedFilter == filters[i],
        onSelected: (s) => setState(() => _selectedFilter = filters[i]),
      ),
    ));
  }
}

class _OrderCard extends StatelessWidget {
  final Order order;
  const _OrderCard({required this.order});
  @override
  Widget build(BuildContext context) {
    return LiquidGlassContainer(
      padding: EdgeInsets.zero,
      borderRadius: 16,
      opacity: 0.1,
      blur: 5,
      child: ListTile(
        title: Text('Order ${order.displayId}', style: const TextStyle(fontWeight: FontWeight.w900)),
        subtitle: Text('Status: ${order.status.toUpperCase()}', style: const TextStyle(fontSize: 10, letterSpacing: 1.1, fontWeight: FontWeight.bold)),
        trailing: Text('TZS ${order.total.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }
}
