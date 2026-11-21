import 'package:flutter/material.dart';

class TransactionDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> transaction;

  const TransactionDetailsScreen({super.key, required this.transaction});

  @override
  Widget build(BuildContext context) {
    final type = transaction['transaction_type']?.toString() ?? 'UNKNOWN';

    final amountSen = (transaction['amount_sen'] as num?)?.toInt() ?? 0;

    final balanceSen = (transaction['balance_after_sen'] as num?)?.toInt() ?? 0;

    final id = transaction['id']?.toString() ?? '-';

    final isOutgoing = type == 'TRANSFER_OUT' || type == 'SAVINGS_DEPOSIT';

    final amount = amountSen / 100.0;
    final balance = balanceSen / 100.0;

    String title;
    IconData icon;

    switch (type) {
      case 'TOPUP':
        title = 'Wallet Top Up';
        icon = Icons.add_circle_outline;
        break;

      case 'TRANSFER_OUT':
        title = 'Money Sent';
        icon = Icons.arrow_upward;
        break;

      case 'TRANSFER_IN':
        title = 'Money Received';
        icon = Icons.arrow_downward;
        break;

      case 'SAVINGS_DEPOSIT':
        title = 'Transfer to Savings';
        icon = Icons.savings_outlined;
        break;

      case 'SAVINGS_WITHDRAW':
        title = 'Transfer from Savings';
        icon = Icons.account_balance_wallet_outlined;
        break;

      default:
        title = type.replaceAll('_', ' ');
        icon = Icons.receipt_long;
    }

    final date = DateTime.tryParse(transaction['created_at']?.toString() ?? '');

    String formattedDate = 'Unknown date';

    if (date != null) {
      final local = date.toLocal();

      formattedDate =
          '${local.day.toString().padLeft(2, '0')}/'
          '${local.month.toString().padLeft(2, '0')}/'
          '${local.year} '
          '${local.hour.toString().padLeft(2, '0')}:'
          '${local.minute.toString().padLeft(2, '0')}';
    }

    final amountColor = isOutgoing ? Colors.red : Colors.green;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Transaction Details'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 20),

            CircleAvatar(
              radius: 38,
              backgroundColor: amountColor.withValues(alpha: 0.12),
              child: Icon(icon, color: amountColor, size: 38),
            ),

            const SizedBox(height: 20),

            Text(
              '${isOutgoing ? '-' : '+'} '
              'RM ${amount.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
                color: amountColor,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              title,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
            ),

            const SizedBox(height: 30),

            Card(
              color: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    detailRow('Transaction ID', '#$id'),
                    const Divider(height: 28),

                    detailRow('Transaction Type', type),
                    const Divider(height: 28),

                    detailRow('Date & Time', formattedDate),
                    const Divider(height: 28),

                    detailRow('Status', 'Completed'),
                    const Divider(height: 28),

                    detailRow(
                      'Balance After',
                      'RM ${balance.toStringAsFixed(2)}',
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            const Text(
              'Cashly Campus uses simulated money only.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget detailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: Colors.grey, fontSize: 14),
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
        ),
      ],
    );
  }
}
