import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart' as provider;
import '../../providers/cart_provider.dart';
import '../../widgets/liquid_glass_container.dart';

class CustomerShell extends StatelessWidget {
  const CustomerShell({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final path = GoRouterState.of(context).uri.path;
    final selectedIndex = _getSelectedIndex(path);

    return Scaffold(
      body: AnimatedLiquidBackground(child: child),
      bottomNavigationBar: LiquidGlassContainer(
        borderRadius: 0,
        padding: EdgeInsets.zero,
        blur: 10,
        opacity: 0.8,
        child: NavigationBar(
          selectedIndex: selectedIndex,
          onDestinationSelected: (i) => _onItemTapped(i, context),
          backgroundColor: Colors.transparent,
          elevation: 0,
          destinations: const [
            NavigationDestination(icon: Icon(Icons.explore_outlined), label: 'Explore'),
            NavigationDestination(icon: Icon(Icons.local_shipping_outlined), label: 'Orders'),
            NavigationDestination(icon: Icon(Icons.person_outline), label: 'Profile'),
          ],
        ),
      ),
      floatingActionButton: path.startsWith('/customer/explore') ? _buildCartFab(context) : null,
    );
  }

  int _getSelectedIndex(String path) {
    if (path.startsWith('/customer/explore')) return 0;
    if (path.startsWith('/customer/orders')) return 1;
    if (path.startsWith('/customer/profile')) return 2;
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0: context.go('/customer/explore'); break;
      case 1: context.go('/customer/orders'); break;
      case 2: context.go('/customer/profile'); break;
    }
  }

  Widget _buildCartFab(BuildContext context) {
    return provider.Consumer<CartProvider>(builder: (context, cart, _) {
      return FloatingActionButton(
        heroTag: 'cart_fab',
        onPressed: () => context.go('/customer/cart'),
        child: cart.itemCount > 0
          ? Badge(label: Text('${cart.itemCount}'), child: const Icon(Icons.shopping_cart))
          : const Icon(Icons.shopping_cart),
      );
    });
  }
}
