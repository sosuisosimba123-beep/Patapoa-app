import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/delivery_partner_service.dart';
import '../../utils/number_utils.dart';
import '../../widgets/patapoa_glass_card.dart';

class RiderWithdrawScreen extends StatefulWidget {
  const RiderWithdrawScreen({super.key});

  @override
  State<RiderWithdrawScreen> createState() => _RiderWithdrawScreenState();
}

class _RiderWithdrawScreenState extends State<RiderWithdrawScreen> {
  final _formKey = GlobalKey<FormState>();
  final DeliveryPartnerService _partnerService = DeliveryPartnerService();

  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  String _selectedProvider = 'M-Pesa';
  bool _isLoading = false;
  Map<String, dynamic>? _profile;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await _partnerService.getProfile();
      if (mounted) setState(() => _profile = profile);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
    }
  }

  Future<void> _requestWithdrawal() async {
    if (!_formKey.currentState!.validate()) return;
    
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount < 1000) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Minimum withdrawal is TZS 1,000')));
      return;
    }

    final balance = NumberUtils.toDouble(_profile?['balance'] ?? 0);
    if (amount > balance) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Insufficient balance')));
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _partnerService.requestWithdrawal({
        'amount': amount,
        'phone': _phoneController.text,
        'provider': _selectedProvider.toLowerCase().replaceAll(' ', '_'),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Withdrawal request submitted')));
        context.go('/delivery-partner/withdraw-success');
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text('Cash Out', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, 
            children: [
              _buildBalanceCard(textTheme),
              const SizedBox(height: 32),
              
              _buildSectionTitle('AMOUNT TO WITHDRAW'),
              const SizedBox(height: 12),
              _buildGlassTextField(
                controller: _amountController,
                hint: 'e.g. 20,000',
                prefixText: 'TZS ',
                keyboardType: TextInputType.number,
                validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
              ),
              
              const SizedBox(height: 32),
              _buildSectionTitle('SELECT PROVIDER'),
              const SizedBox(height: 12),
              _buildProviderChips(),
              
              const SizedBox(height: 32),
              _buildSectionTitle('PAYOUT PHONE NUMBER'),
              const SizedBox(height: 12),
              _buildGlassTextField(
                controller: _phoneController,
                hint: '07XX XXX XXX',
                prefixText: '+255 ',
                keyboardType: TextInputType.phone,
                validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
              ),
              
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity, 
                height: 60, 
                child: FilledButton(
                  onPressed: _isLoading ? null : _requestWithdrawal,
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.orangeAccent,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.black) 
                    : const Text('REQUEST WITHDRAWAL', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
                )
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBalanceCard(TextTheme textTheme) {
    return PatapoaGlassCard(
      color: Colors.orange,
      opacity: 0.15,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('CURRENT WITHDRAWABLE BALANCE', style: TextStyle(color: Colors.orangeAccent, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
          const SizedBox(height: 8),
          Text(
            'TZS ${NumberUtils.formatCurrency(_profile?['balance'] ?? 0)}', 
            style: textTheme.headlineMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w900)
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2),
    );
  }

  Widget _buildGlassTextField({
    required TextEditingController controller,
    required String hint,
    required String prefixText,
    required TextInputType keyboardType,
    String? Function(String?)? validator,
  }) {
    return PatapoaGlassCard(
      padding: EdgeInsets.zero,
      borderRadius: 16,
      opacity: 0.05,
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        validator: validator,
        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        decoration: InputDecoration(
          prefixText: prefixText,
          prefixStyle: const TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold),
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.white12),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(20),
        ),
      ),
    );
  }

  Widget _buildProviderChips() {
    final providers = ['M-Pesa', 'Tigo Pesa', 'Airtel Money', 'HaloPesa'];
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: providers.map((p) {
        final isSelected = _selectedProvider == p;
        return InkWell(
          onTap: () => setState(() => _selectedProvider = p),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? Colors.orangeAccent.withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? Colors.orangeAccent : Colors.white10,
                width: 1.5,
              ),
            ),
            child: Text(
              p,
              style: TextStyle(
                color: isSelected ? Colors.orangeAccent : Colors.white60,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
