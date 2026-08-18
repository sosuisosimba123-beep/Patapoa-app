import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/liquid_glass_container.dart';

class RiderShell extends StatefulWidget {
  const RiderShell({super.key, required this.child});
  final Widget child;

  @override
  State<RiderShell> createState() => _RiderShellState();
}

class _RiderShellState extends State<RiderShell> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      drawer: _buildDrawer(context, auth),
      body: AnimatedLiquidBackground(child: widget.child),
      bottomNavigationBar: LiquidGlassContainer(
        borderRadius: 0,
        padding: EdgeInsets.zero,
        blur: 10,
        opacity: 0.8,
        child: NavigationBar(
          selectedIndex: _currentIndex,
          backgroundColor: Colors.transparent,
          elevation: 0,
          onDestinationSelected: (index) {
            setState(() => _currentIndex = index);
            switch (index) {
              case 0:
                context.go('/delivery-partner/home');
                break;
              case 1:
                context.go('/delivery-partner/orders');
                break;
              case 2:
                context.go('/delivery-partner/earnings');
                break;
              case 3:
                context.go('/delivery-partner/profile');
                break;
            }
          },
          destinations: const [
            NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
            NavigationDestination(icon: Icon(Icons.local_shipping), label: 'Deliveries'),
            NavigationDestination(icon: Icon(Icons.payments), label: 'Earnings'),
            NavigationDestination(icon: Icon(Icons.person), label: 'Profile'),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context, AuthProvider auth) {
    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            accountName: Text(auth.user?.name ?? 'Delivery Partner'),
            accountEmail: Text(auth.user?.email ?? auth.user?.phone ?? ''),
            currentAccountPicture:
                const CircleAvatar(child: Icon(Icons.person, size: 40)),
            decoration:
                BoxDecoration(color: Theme.of(context).colorScheme.primary),
          ),
          ListTile(
            leading: const Icon(Icons.home_outlined),
            title: const Text('Home'),
            onTap: () {
              Navigator.pop(context);
              context.go('/delivery-partner/home');
            },
          ),
          ListTile(
            leading: const Icon(Icons.receipt_long_outlined),
            title: const Text('My Deliveries'),
            onTap: () {
              Navigator.pop(context);
              context.go('/delivery-partner/orders');
            },
          ),
          ListTile(
            leading: const Icon(Icons.payments_outlined),
            title: const Text('Earnings & Payouts'),
            onTap: () {
              Navigator.pop(context);
              context.go('/delivery-partner/earnings');
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.help_outline),
            title: const Text('Support'),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          const Spacer(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Sign Out', style: TextStyle(color: Colors.red)),
            onTap: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Sign Out'),
                  content: const Text(
                      'Are you sure you want to log out of the partner portal?'),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('CANCEL')),
                    TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('LOG OUT',
                            style: TextStyle(color: Colors.red))),
                  ],
                ),
              );

              if (confirm == true) {
                await auth.logout();
                if (context.mounted) context.go('/role');
              }
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
