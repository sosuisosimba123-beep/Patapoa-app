import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/transaction_service.dart';
import '../../services/merchant_service.dart';
import '../../widgets/patapoa_glass_card.dart';
import '../../utils/number_utils.dart';

class MerchantPayoutScreen extends StatefulWidget {
  const MerchantPayoutScreen({super.key});

  @override
  State<MerchantPayoutScreen> createState() => _MerchantPayoutScreenState();
}

class _MerchantPayoutScreenState extends State<MerchantPayoutScreen> {
  final TransactionService _transactionService = TransactionService();
  final MerchantService _merchantService = MerchantService();
  bool _isLoading = true;
  List<Map<String, dynamic>> _transactions = [];
  Map<String, dynamic>? _stats;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _transactionService.getTransactions(page: 1, limit: 20),
        _merchantService.getStats(),
      ]);
      if (mounted) setState(() {
        _transactions = results[0] as List<Map<String, dynamic>>;
        _stats = results[1] as Map<String, dynamic>;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Dark themed high-contrast Liquid Glass UI
    final textTheme = Theme.of(context).textTheme;
    final balance = NumberUtils.toDouble(_stats?['available_balance'] ?? 0);
    final pending = NumberUtils.toDouble(_stats?['pending_balance'] ?? 0);

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Deep Midnight Blue
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          color: Colors.cyanAccent,
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
                      'Store Wallet',
                      style: textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const Icon(Icons.account_balance_wallet_outlined, color: Colors.cyanAccent, size: 28),
                  ],
                ),
                const SizedBox(height: 24),
                
                PatapoaGlassCard(
                  color: Colors.cyan,
                  opacity: 0.15,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.verified_user_outlined, color: Colors.cyanAccent, size: 16),
                          const SizedBox(width: 8),
                          Text(
                            'AVAILABLE FOR WITHDRAWAL',
                            style: textTheme.labelSmall?.copyWith(color: Colors.cyanAccent, fontWeight: FontWeight.bold, letterSpacing: 1),
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
                          _smallStat('Escrow / Pending', 'TZS ${NumberUtils.formatCurrency(pending)}'),
                          _smallStat('Lifetime Sales', 'TZS ${NumberUtils.formatCurrency(_stats?['total_revenue'])}'),
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
                    onPressed: balance >= 1000 ? () => context.push('/merchant/withdraw') : null,
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.cyanAccent,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    icon: const Icon(Icons.outbond),
                    label: const Text('WITHDRAW TO MOBILE MONEY', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                
                const SizedBox(height: 32),
                
                Text(
                  'Transaction Ledger',
                  style: textTheme.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                
                if (_isLoading && _transactions.isEmpty)
                  const Center(child: CircularProgressIndicator(color: Colors.cyanAccent))
                else if (_transactions.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(child: Text('No entries in ledger', style: TextStyle(color: Colors.white38))),
                  )
                else
                  ..._transactions.map((t) => _buildGlassTransactionTile(t, textTheme)),
                
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

  Widget _buildGlassTransactionTile(Map<String, dynamic> t, TextTheme textTheme) {
    final amount = (t['amount'] as num?)?.toDouble() ?? 0.0;
    final dateStr = t['created_at'] as String?;
    final date = dateStr != null ? DateTime.parse(dateStr) : DateTime.now();
    final isCredit = amount > 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: PatapoaGlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        borderRadius: 16,
        opacity: 0.05,
        child: Row(
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: (isCredit ? Colors.greenAccent : Colors.redAccent).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isCredit ? Icons.add_rounded : Icons.remove_rounded,
                color: isCredit ? Colors.greenAccent : Colors.redAccent,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t['description'] ?? 'Transaction',
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
              '${isCredit ? "+" : ""}${NumberUtils.formatCurrency(amount)}',
              style: TextStyle(
                color: isCredit ? Colors.greenAccent : Colors.redAccent,
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
