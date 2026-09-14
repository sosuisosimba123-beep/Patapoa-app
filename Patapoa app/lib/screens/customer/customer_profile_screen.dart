import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart' as provider;
import '../../providers/auth_provider.dart';
import '../../utils/crashlytics_service.dart';
import 'package:flutter/foundation.dart';

class CustomerProfileScreen extends StatelessWidget {
  const CustomerProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = provider.Provider.of<AuthProvider>(context);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('My Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          _buildAvatar(colorScheme),
          const SizedBox(height: 16),
          Text(auth.user?.name ?? 'User Name', style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
          Text(auth.user?.email ?? 'user@example.com', style: textTheme.bodyMedium),
          const SizedBox(height: 32),
          _buildSection('Account Settings', [
            _ProfileTile(icon: Icons.person_outline, title: 'Personal Information', onTap: () {}),
            _ProfileTile(icon: Icons.location_on_outlined, title: 'Addresses', onTap: () {}),
            _ProfileTile(icon: Icons.payment_outlined, title: 'Payment Methods', onTap: () {}),
          ]),
          const SizedBox(height: 24),
          _buildSection('Support', [
            _ProfileTile(icon: Icons.help_outline, title: 'Help Center', onTap: () {}),
            _ProfileTile(icon: Icons.privacy_tip, title: 'Privacy Policy', onTap: () {}),
          ]),
          if (kDebugMode) ...[
            const SizedBox(height: 24),
            _buildSection('Debug (Internal)', [
              _ProfileTile(
                icon: Icons.my_location,
                title: 'Sync My Location (PB Test)',
                onTap: () async {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Updating location...')),
                  );
                  final success = await auth.updateUserLocation();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(success ? 'Location synced!' : 'Update failed'),
                        backgroundColor: success ? Colors.green : Colors.red,
                      ),
                    );
                  }
                },
              ),
              _ProfileTile(
                icon: Icons.bug_report_outlined,
                title: 'Test Crash',
                onTap: () {
                  CrashlyticsService().triggerTestCrash();
                },
              ),
            ]),
          ],
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Log Out'),
                    content: const Text('Are you sure?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('CANCEL')),
                      TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('LOG OUT')),
                    ],
                  ),
                );

                if (confirm == true) {
                  await auth.logout();
                  if (context.mounted) GoRouter.of(context).go('/role');
                }
              },
              icon: const Icon(Icons.logout), 
              label: const Text('Log Out'),
              style: OutlinedButton.styleFrom(foregroundColor: Colors.red, side: const BorderSide(color: Colors.red)),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildAvatar(ColorScheme colorScheme) {
    return const CircleAvatar(radius: 50, child: Icon(Icons.person, size: 50));
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(padding: const EdgeInsets.only(left: 8, bottom: 8), child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold))),
      Card(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Colors.black12)),
        child: Column(children: children),
      ),
    ]);
  }
}

class _ProfileTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  const _ProfileTile({required this.icon, required this.title, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right, size: 20),
      onTap: onTap,
    );
  }
}
