import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart' as provider;
import '../../providers/auth_provider.dart';
import '../../widgets/liquid_glass_container.dart';
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
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: const Text('My Profile'), backgroundColor: Colors.transparent, elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          _buildAvatar(colorScheme),
          const SizedBox(height: 16),
          Text(auth.user?.name ?? 'User Name', style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
          Text(auth.user?.email ?? 'user@example.com', style: textTheme.bodyMedium),
          const SizedBox(height: 32),
          _buildSection('Account Settings', [
            _ProfileTile(icon: Icons.person_outline, title: 'Personal Information', onTap: () {
               // Navigation to Personal info editing
            }),
            _ProfileTile(icon: Icons.location_on_outlined, title: 'Addresses', onTap: () {
               // Navigation to Address management
            }),
            _ProfileTile(icon: Icons.payment_outlined, title: 'Payment Methods', onTap: () {
               // Navigation to Payment settings
            }),
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
                    const SnackBar(content: Text('Updating location in PocketBase...')),
                  );
                  final success = await auth.updateUserLocation();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(success 
                          ? 'Location synced successfully!' 
                          : 'Update failed: ${auth.errorMessage}'),
                        backgroundColor: success ? Colors.green : Colors.red,
                      ),
                    );
                  }
                },
              ),
              _ProfileTile(
                icon: Icons.bug_report_outlined,
                title: 'Test Crash (Crashlytics)',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Triggering crash in 2 seconds...')),
                  );
                  Future.delayed(const Duration(seconds: 2), () {
                    CrashlyticsService().triggerTestCrash();
                  });
                },
              ),
            ]),
          ],
          const SizedBox(height: 32),
          FilledButton.icon(
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Log Out'),
                  content: const Text('Are you sure you want to sign out?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('CANCEL')),
                    TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('LOG OUT', style: TextStyle(color: Colors.red))),
                  ],
                ),
              );

              if (confirm == true) {
                await auth.logout();
                if (context.mounted) GoRouter.of(context).go('/role');
              }
            },
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52), backgroundColor: colorScheme.errorContainer, foregroundColor: colorScheme.onErrorContainer),
            icon: const Icon(Icons.logout), label: const Text('Log Out'),
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
      LiquidGlassContainer(
        padding: EdgeInsets.zero,
        borderRadius: 20,
        opacity: 0.1,
        blur: 5,
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
