
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../services/api_service.dart';

class WalletTestScreen extends StatefulWidget {
  const WalletTestScreen({super.key});

  @override
  State<WalletTestScreen> createState() =>
      _WalletTestScreenState();
}

class _WalletTestScreenState
    extends State<WalletTestScreen> {
  int balanceSen = 0;
  bool loading = true;
  bool processing = false;

  List<dynamic> transactions = [];

  @override
  void initState() {
    super.initState();
    loadWallet();
  }

  Future<void> loadWallet() async {
    setState(() => loading = true);

    try {
      final wallet = await ApiService.getWallet();
      final history = await ApiService.getTransactions();

      if (!mounted) return;

      setState(() {
        balanceSen = wallet['balance_sen'] as int;
        transactions = history['transactions'] as List;
      });
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  Future<void> topUp(int amountSen) async {
    if (processing) return;

    setState(() => processing = true);

    try {
      final key = const Uuid().v4();

      await ApiService.topUpWallet(
        amountSen: amountSen,
        idempotencyKey: key,
      );

      await loadWallet();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Simulated top-up successful!'),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Top-up failed: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => processing = false);
      }
    }
  }

  String money(int sen) {
    return 'RM ${(sen / 100).toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cashly Wallet Test'),
      ),
      body: loading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : RefreshIndicator(
              onRefresh: loadWallet,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  const Text('Available Balance'),
                  const SizedBox(height: 8),

                  Text(
                    money(balanceSen),
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 24),
                  const Text('Simulated Top-Up'),

                  const SizedBox(height: 12),

                  Wrap(
                    spacing: 12,
                    children: [
                      for (final amount in [1000, 2000, 5000])
                        ElevatedButton(
                          onPressed: processing
                              ? null
                              : () => topUp(amount),
                          child: Text('+ ${money(amount)}'),
                        ),
                    ],
                  ),

                  const SizedBox(height: 30),

                  const Text(
                    'Transaction History',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 12),

                  if (transactions.isEmpty)
                    const Text('No transactions yet.'),

                  for (final item in transactions)
                    Card(
                      child: ListTile(
                        leading: const Icon(
                          Icons.account_balance_wallet,
                        ),
                        title: Text(
                          item['transaction_type'],
                        ),
                        subtitle: Text(
                          item['created_at'].toString(),
                        ),
                        trailing: Text(
                          '+ ${money(item['amount_sen'] as int)}',
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}
