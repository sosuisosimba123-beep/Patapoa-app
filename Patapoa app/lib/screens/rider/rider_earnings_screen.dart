import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/delivery_partner_service.dart';
import '../../utils/number_utils.dart';

class RiderEarningsScreen extends StatefulWidget {
  const RiderEarningsScreen({super.key});

  @override
  State<RiderEarningsScreen> createState() => _RiderEarningsScreenState();
}

class _RiderEarningsScreenState extends State<RiderEarningsScreen> {
  final DeliveryPartnerService _partnerService = DeliveryPartnerService();
  bool _isLoading = true;
  List<Map<String, dynamic>> _transactions = [];
  Map<String, dynamic>? _profile;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _partnerService.getProfile(),
        _partnerService.getEarnings(),
      ]);
      if (mounted) {
        setState(() {
          _profile = results[0] as Map<String, dynamic>;
          _transactions = results[1] as List<Map<String, dynamic>>;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final balance = NumberUtils.toDouble(_profile?['balance'] ?? 0);
    final pending = NumberUtils.toDouble(_profile?['pending_balance'] ?? 0);

    return Scaffold(
      appBar: AppBar(title: const Text('Partner Wallet')),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  elevation: 2,
                  color: colorScheme.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.account_balance_wallet_outlined, color: Colors.white70, size: 16),
                            const SizedBox(width: 8),
                            Text(
                              'AVAILABLE TO WITHDRAW',
                              style: textTheme.labelSmall?.copyWith(color: Colors.white70, fontWeight: FontWeight.bold, letterSpacing: 1),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'TZS ${NumberUtils.formatCurrency(balance)}',
                          style: textTheme.displaySmall?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                        const Divider(height: 32, color: Colors.white24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _smallStat('Held in Escrow', 'TZS ${NumberUtils.formatCurrency(pending)}'),
                            _smallStat('Total Trips', '${_profile?['total_deliveries'] ?? 0}'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                SizedBox(
                  width: double.infinity,
                  height: 64,
                  child: ElevatedButton.icon(
                    onPressed: balance >= 1000 ? () => context.push('/delivery-partner/withdraw') : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      elevation: 8,
                      shadowColor: colorScheme.primary.withValues(alpha: 0.4),
                    ),
                    icon: const Icon(Icons.account_balance_wallet_rounded, size: 20),
                    label: const Text('REQUEST WITHDRAWAL', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
                  ),
                ),
                
                const SizedBox(height: 40),
                
                Text(
                  'Recent Activity',
                  style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                
                if (_isLoading && _transactions.isEmpty)
                  const Center(child: CircularProgressIndicator())
                else if (_transactions.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(child: Text('No recent trip earnings', style: TextStyle(color: Colors.grey))),
                  )
                else
                  ..._transactions.map((t) => _buildTripEarningTile(t, textTheme, colorScheme)),
                
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _smallStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildTripEarningTile(Map<String, dynamic> t, TextTheme textTheme, ColorScheme colorScheme) {
    final amount = (t['amount'] as num?)?.toDouble() ?? 0.0;
    final dateStr = t['created_at'] as String?;
    final date = dateStr != null ? DateTime.parse(dateStr) : DateTime.now();

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Colors.black12),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: colorScheme.primary.withOpacity(0.1),
          child: Icon(
            Icons.delivery_dining_rounded,
            color: colorScheme.primary,
            size: 20,
          ),
        ),
        title: Text(
          t['description'] ?? 'Trip Earning',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          '${date.day}/${date.month} • ${t['status']?.toString().toUpperCase()}',
          style: const TextStyle(fontSize: 11),
        ),
        trailing: Text(
          'TZS ${NumberUtils.formatCurrency(amount)}',
          style: TextStyle(
            color: colorScheme.primary,
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
      ),
    );
  }
}
