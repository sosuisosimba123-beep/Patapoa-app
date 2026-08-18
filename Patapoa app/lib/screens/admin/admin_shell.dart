import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AdminShell extends StatefulWidget {
  const AdminShell({super.key, required this.child});
  final Widget child;

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
          switch (index) {
            case 0: context.go('/admin/overview'); break;
            case 1: context.go('/admin/merchants'); break;
            case 2: context.go('/admin/riders'); break;
            case 3: context.go('/admin/deliveries'); break;
          }
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), label: 'Overview'),
          NavigationDestination(icon: Icon(Icons.storefront_outlined), label: 'Merchants'),
          NavigationDestination(icon: Icon(Icons.local_shipping_outlined), label: 'Riders'),
          NavigationDestination(icon: Icon(Icons.map_outlined), label: 'Deliveries'),
        ],
      ),
    );
  }
}
