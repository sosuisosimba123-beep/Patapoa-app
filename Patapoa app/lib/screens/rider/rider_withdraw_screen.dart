import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/delivery_partner_service.dart';
import '../../utils/number_utils.dart';

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
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Withdrawal request submitted!')));
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
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Partner Cash Out')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, 
            children: [
              _buildBalanceCard(colorScheme, textTheme),
              const SizedBox(height: 32),
              
              _buildLabel('AMOUNT TO WITHDRAW'),
              const SizedBox(height: 12),
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                decoration: const InputDecoration(
                  prefixText: 'TZS ',
                  hintText: '0.00',
                ),
                validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
              ),
              
              const SizedBox(height: 32),
              _buildLabel('SELECT PROVIDER'),
              const SizedBox(height: 12),
              _buildProviderGrid(),
              
              const SizedBox(height: 32),
              _buildLabel('PAYOUT PHONE NUMBER'),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  prefixText: '+255 ',
                  hintText: '07XX XXX XXX',
                ),
                validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
              ),
              
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity, 
                height: 60, 
                child: FilledButton(
                  onPressed: _isLoading ? null : _requestWithdrawal,
                  child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white) 
                    : const Text('CONFIRM CASH OUT', style: TextStyle(fontWeight: FontWeight.bold)),
                )
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBalanceCard(ColorScheme colorScheme, TextTheme textTheme) {
    return Card(
      color: colorScheme.primaryContainer.withOpacity(0.1),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: colorScheme.primary.withOpacity(0.2))),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('WITHDRAWABLE BALANCE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1, color: Colors.grey)),
                const SizedBox(height: 8),
                Text(
                  'TZS ${NumberUtils.formatCurrency(_profile?['balance'] ?? 0)}', 
                  style: textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900, color: colorScheme.primary)
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(text, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1));
  }

  Widget _buildProviderGrid() {
    final providers = ['M-Pesa', 'Tigo Pesa', 'Airtel Money', 'HaloPesa'];
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 3, crossAxisSpacing: 12, mainAxisSpacing: 12),
      itemCount: providers.length,
      itemBuilder: (context, i) {
        final p = providers[i];
        final isSelected = _selectedProvider == p;
        return InkWell(
          onTap: () => setState(() => _selectedProvider = p),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              color: isSelected ? Theme.of(context).colorScheme.primary : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isSelected ? Colors.transparent : Colors.black12),
            ),
            alignment: Alignment.center,
            child: Text(p, style: TextStyle(color: isSelected ? Colors.white : Colors.black87, fontWeight: FontWeight.bold)),
          ),
        );
      },
    );
  }
}
