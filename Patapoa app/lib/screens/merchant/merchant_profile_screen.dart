import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../services/merchant_service.dart';
import '../../services/auth_service.dart';
import '../../providers/auth_provider.dart';

class MerchantProfileScreen extends StatefulWidget {
  const MerchantProfileScreen({super.key});

  @override
  State<MerchantProfileScreen> createState() => _MerchantProfileScreenState();
}

class _MerchantProfileScreenState extends State<MerchantProfileScreen> {
  final MerchantService _merchantService = MerchantService();
  final AuthService _authService = AuthService();
  bool _isEditing = false;
  bool _isLoading = false;
  final _formKey = GlobalKey<FormState>();

  final _storeNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _locationController = TextEditingController();
  final _phoneController = TextEditingController();
  final _payoutAccountController = TextEditingController();
  String _selectedPayoutMethod = 'mpesa';

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    try {
      final profile = await _merchantService.getStats();
      if (mounted) {
        setState(() {
          _isLoading = false;
          if (_storeNameController.text.isEmpty) {
            _storeNameController.text = profile['store_name'] ?? '';
            _emailController.text = profile['email'] ?? '';
            _locationController.text = profile['city'] ?? '';
            _phoneController.text = profile['phone'] ?? '';
            _payoutAccountController.text = profile['payout_account'] ?? '';
            _selectedPayoutMethod = profile['payout_method'] ?? 'mpesa';
          }
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _storeNameController.dispose();
    _emailController.dispose();
    _locationController.dispose();
    _phoneController.dispose();
    _payoutAccountController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      // Update core profile
      await _authService.updateProfile({
        'name': _storeNameController.text,
        'email': _emailController.text,
        'phone': _phoneController.text,
      });

      // Update payout details
      await _merchantService.updatePayoutDetails({
        'payout_method': _selectedPayoutMethod,
        'payout_account': _payoutAccountController.text,
      });

      if (mounted) {
        setState(() { _isLoading = false; _isEditing = false; });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile & Payout updated')));
        _loadProfile();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(textTheme),
              const SizedBox(height: 24),
              _buildForm(),
              const SizedBox(height: 24),
              _buildLogoutButton(colorScheme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(TextTheme textTheme) {
    return Row(
      children: [
        Text('Profile', style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
        const Spacer(),
        if (!_isEditing)
          IconButton(onPressed: () => setState(() => _isEditing = true), icon: const Icon(Icons.edit))
        else
          TextButton.icon(
            onPressed: _isLoading ? null : _saveProfile,
            icon: _isLoading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.save),
            label: Text(_isLoading ? 'Saving...' : 'Save'),
          ),
      ],
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Store Information', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade700)),
          const SizedBox(height: 12),
          _buildField('Store Name', _storeNameController, enabled: _isEditing, validator: (v) => v?.isEmpty ?? true ? 'Required' : null),
          _buildField('Email', _emailController, enabled: _isEditing, keyboardType: TextInputType.emailAddress),
          _buildField('Location', _locationController, enabled: _isEditing),
          _buildField('Phone', _phoneController, enabled: _isEditing, keyboardType: TextInputType.phone),
          
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),
          
          Text('Payout Settings (ClickPesa)', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade700)),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _selectedPayoutMethod,
            decoration: const InputDecoration(labelText: 'Payout Method', border: OutlineInputBorder()),
            items: const [
              DropdownMenuItem(value: 'mpesa', child: Text('M-Pesa')),
              DropdownMenuItem(value: 'tigo_pesa', child: Text('Tigo Pesa')),
              DropdownMenuItem(value: 'airtel_money', child: Text('Airtel Money')),
              DropdownMenuItem(value: 'bank', child: Text('Bank Account')),
            ],
            onChanged: _isEditing ? (v) => setState(() => _selectedPayoutMethod = v!) : null,
          ),
          const SizedBox(height: 16),
          _buildField('Payout Number/Account', _payoutAccountController, enabled: _isEditing, keyboardType: TextInputType.text, validator: (v) => v?.isEmpty ?? true ? 'Required for payments' : null),
        ],
      ),
    );
  }

  Widget _buildField(String label, TextEditingController controller, {bool enabled = true, TextInputType? keyboardType, String? Function(String?)? validator}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        enabled: enabled,
        keyboardType: keyboardType,
        validator: validator,
        decoration: InputDecoration(labelText: label, filled: true, fillColor: enabled ? null : Colors.grey.shade100, border: const OutlineInputBorder()),
      ),
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
          if (mounted) GoRouter.of(context).go('/role');
        }
      },
      style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52), backgroundColor: colorScheme.errorContainer, foregroundColor: colorScheme.onErrorContainer),
      icon: const Icon(Icons.logout),
      label: const Text('Log Out'),
    );
  }
}
