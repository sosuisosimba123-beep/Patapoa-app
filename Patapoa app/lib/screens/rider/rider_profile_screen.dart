import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../services/delivery_partner_service.dart';
import '../../providers/auth_provider.dart';
import '../../utils/number_utils.dart';

class RiderProfileScreen extends StatefulWidget {
  const RiderProfileScreen({super.key});

  @override
  State<RiderProfileScreen> createState() => _RiderProfileScreenState();
}

class _RiderProfileScreenState extends State<RiderProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final DeliveryPartnerService _riderService = DeliveryPartnerService();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _vehicleController = TextEditingController();

  bool _isEditing = false;
  Map<String, dynamic>? _profile;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await _riderService.getProfile();
      if (mounted) {
        setState(() {
          _profile = profile;
          _nameController.text = profile['name'] ?? profile['user']?['name'] ?? '';
          _phoneController.text = profile['phone'] ?? profile['user']?['phone'] ?? '';
          _emailController.text = profile['email'] ?? profile['user']?['email'] ?? '';
          _vehicleController.text = profile['vehicle_type'] ?? '';
        });
      }
    } catch (e) {
      debugPrint('Error loading rider profile: $e');
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    try {
      await _riderService.updateProfile({
        'name': _nameController.text, 'phone': _phoneController.text,
        'email': _emailController.text, 'vehicle_type': _vehicleController.text,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated!')));
        setState(() => _isEditing = false);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final topInset = math.max(12.0, MediaQuery.paddingOf(context).top);

    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(16, topInset, 16, 120),
        child: Form(
          key: _formKey,
          child: Column(children: [
            _buildHeader(colorScheme, textTheme),
            const SizedBox(height: 24),
            _buildAvatar(colorScheme),
            const SizedBox(height: 16),
            _buildEditableName(textTheme),
            _buildRatingRow(colorScheme, textTheme),
            const SizedBox(height: 32),
            _buildFormFields(colorScheme),
            const SizedBox(height: 32),
            _buildLogoutButton(colorScheme),
          ]),
        ),
      ),
    );
  }

  Widget _buildHeader(ColorScheme colorScheme, TextTheme textTheme) {
    return Row(children: [
      Builder(
        builder: (context) => IconButton(
          onPressed: () => Scaffold.of(context).openDrawer(), 
          icon: const Icon(Icons.menu)
        ),
      ),
      const SizedBox(width: 8),
      Text('Partner Profile', style: textTheme.headlineSmall?.copyWith(color: colorScheme.primary, fontWeight: FontWeight.bold)),
      const Spacer(),
      IconButton(onPressed: _isEditing ? _saveProfile : () => setState(() => _isEditing = true), icon: Icon(_isEditing ? Icons.save : Icons.edit)),
    ]);
  }

  Widget _buildAvatar(ColorScheme colorScheme) {
    return Stack(children: [
      const CircleAvatar(radius: 48, child: Icon(Icons.person, size: 48)),
      Positioned(bottom: 0, right: 0, child: Container(padding: const EdgeInsets.all(4), decoration: BoxDecoration(color: colorScheme.primary, shape: BoxShape.circle), child: const Icon(Icons.verified, size: 16, color: Colors.white))),
    ]);
  }

  Widget _buildEditableName(TextTheme textTheme) {
    return TextFormField(
      controller: _nameController, enabled: _isEditing, textAlign: TextAlign.center,
      style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
      decoration: const InputDecoration(border: InputBorder.none),
    );
  }

  Widget _buildRatingRow(ColorScheme colorScheme, TextTheme textTheme) {
    return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(Icons.star, size: 18, color: colorScheme.tertiary),
      Text(NumberUtils.formatRating(_profile?['rating']), style: textTheme.titleMedium),
      const SizedBox(width: 8),
      Text('• ${_profile?['total_deliveries'] ?? 0} deliveries', style: textTheme.bodySmall),
    ]);
  }

  Widget _buildFormFields(ColorScheme colorScheme) {
    return Column(children: [
      _buildField('Phone', _phoneController, Icons.phone, enabled: _isEditing),
      const SizedBox(height: 16),
      _buildField('Email', _emailController, Icons.email, enabled: _isEditing),
      const SizedBox(height: 16),
      _buildField('Vehicle', _vehicleController, Icons.directions_car, enabled: _isEditing),
    ]);
  }

  Widget _buildField(String label, TextEditingController controller, IconData icon, {bool enabled = true}) {
    return TextFormField(
      controller: controller, enabled: enabled,
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon), filled: true, fillColor: Colors.grey.shade100, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
    );
  }

  Widget _buildLogoutButton(ColorScheme colorScheme) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    return FilledButton.icon(
      onPressed: () async {
        final confirmed = await showDialog<bool>(
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

        if (confirmed == true) {
          await auth.logout();
          if (mounted) context.go('/role');
        }
      },
      style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52), backgroundColor: colorScheme.errorContainer, foregroundColor: colorScheme.onErrorContainer),
      icon: const Icon(Icons.logout), label: const Text('Log Out'),
    );
  }
}
