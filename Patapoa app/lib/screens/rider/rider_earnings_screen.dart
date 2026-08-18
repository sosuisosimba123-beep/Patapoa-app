import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/delivery_partner_service.dart';
import '../../widgets/liquid_glass_container.dart';
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
    final textTheme = Theme.of(context).textTheme;
    final balance = NumberUtils.toDouble(_profile?['balance'] ?? 0);
    final pending = NumberUtils.toDouble(_profile?['pending_balance'] ?? 0);

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Deep Midnight Blue
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          color: Colors.orangeAccent,
          backgroundColor: const Color(0xFF1E293B),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Partner Wallet',
                      style: textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const Icon(Icons.delivery_dining_outlined, color: Colors.orangeAccent, size: 28),
                  ],
                ),
                const SizedBox(height: 24),
                
                LiquidGlassContainer(
                  color: Colors.orange,
                  opacity: 0.15,
                  blur: 20,
                  borderRadius: 32,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.wallet_outlined, color: Colors.orangeAccent, size: 16),
                          const SizedBox(width: 8),
                          Text(
                            'AVAILABLE TO WITHDRAW',
                            style: textTheme.labelSmall?.copyWith(color: Colors.orangeAccent, fontWeight: FontWeight.bold, letterSpacing: 1),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'TZS ${NumberUtils.formatCurrency(balance)}',
                        style: textTheme.displayMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      const Divider(height: 32, color: Colors.white10),
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
                
                const SizedBox(height: 24),
                
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: FilledButton.icon(
                    onPressed: balance >= 1000 ? () => context.push('/delivery-partner/withdraw') : null,
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.orangeAccent,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    icon: const Icon(Icons.account_balance_wallet_outlined),
                    label: const Text('WITHDRAW TO MOBILE MONEY', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                
                const SizedBox(height: 32),
                
                Text(
                  'Recent Activity',
                  style: textTheme.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                
                if (_isLoading && _transactions.isEmpty)
                  const Center(child: CircularProgressIndicator(color: Colors.orangeAccent))
                else if (_transactions.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(child: Text('No recent trip earnings', style: TextStyle(color: Colors.white38))),
                  )
                else
                  ..._transactions.map((t) => _buildTripEarningTile(t, textTheme)),
                
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
        Text(label, style: const TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildTripEarningTile(Map<String, dynamic> t, TextTheme textTheme) {
    final amount = (t['amount'] as num?)?.toDouble() ?? 0.0;
    final dateStr = t['created_at'] as String?;
    final date = dateStr != null ? DateTime.parse(dateStr) : DateTime.now();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: LiquidGlassContainer(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        borderRadius: 16,
        opacity: 0.05,
        blur: 5,
        child: Row(
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: Colors.orangeAccent.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.delivery_dining_rounded,
                color: Colors.orangeAccent,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t['description'] ?? 'Trip Earning',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${date.day}/${date.month} • ${t['status']?.toString().toUpperCase()}',
                    style: const TextStyle(color: Colors.white38, fontSize: 11),
                  ),
                ],
              ),
            ),
            Text(
              'TZS ${NumberUtils.formatCurrency(amount)}',
              style: const TextStyle(
                color: Colors.orangeAccent,
                fontWeight: FontWeight.w900,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
