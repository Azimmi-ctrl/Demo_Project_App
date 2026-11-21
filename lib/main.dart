import 'screens/transaction_details_screen.dart';

import 'package:uuid/uuid.dart';

import 'services/api_service.dart';

import 'package:firebase_auth/firebase_auth.dart';

import 'auth_gate.dart';

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';
import 'screens/wallet_test_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  debugPrint('Cashly Campus Firebase initialized successfully!');

  runApp(const CashlyCampusApp());
}

const blue = Color(0xFF2563EB);
const navy = Color(0xFF0F172A);
const bg = Color(0xFFF8FAFC);

String rm(double value) => 'RM ${value.toStringAsFixed(2)}';

class DemoTransaction {
  final String title;
  final String category;
  final double amount;
  final DateTime date;
  final bool isExpense;

  DemoTransaction({
    required this.title,
    required this.category,
    required this.amount,
    required this.date,
    required this.isExpense,
  });
}

class CashlyCampusApp extends StatelessWidget {
  const CashlyCampusApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cashly Campus',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: bg,
        colorScheme: ColorScheme.fromSeed(seedColor: blue),
        appBarTheme: const AppBarTheme(
          backgroundColor: bg,
          foregroundColor: navy,
        ),
      ),
      home: const AuthGate(authenticatedScreen: CampusMainScreen()),
    );
  }
}

class CampusMainScreen extends StatefulWidget {
  const CampusMainScreen({super.key});

  @override
  State<CampusMainScreen> createState() => _CampusMainScreenState();
}

class _CampusMainScreenState extends State<CampusMainScreen> {
  int walletBalanceSen = 0;
  bool walletLoading = true;
  String? walletError;
  bool topUpProcessing = false;
  bool transferProcessing = false;
  List<Map<String, dynamic>> walletTransactions = [];
  bool transactionsLoading = true;
  String? transactionsError;
  int tab = 0;
  double wallet = 500;
  double savings = 100;
  int savingsBalanceSen = 0;
  bool savingsLoading = true;
  String? savingsError;
  bool savingsProcessing = false;
  List<Map<String, dynamic>> savingsTransactions = [];
  bool savingsHistoryLoading = true;
  String? savingsHistoryError;
  double monthlyBudget = 1000;
  int coins = 120;
  bool voucherClaimed = false;
  bool voucherUsed = false;
  bool expenseProcessing = false;
  List<Map<String, dynamic>> monthlyExpenseRecords = [];
  bool expensesLoading = true;
  String? expensesError;
  final transactions = <DemoTransaction>[];

  double get monthlySpending {
    final totalSen = monthlyExpenseRecords.fold<int>(0, (sum, expense) {
      final amountSen = (expense['amount_sen'] as num?)?.toInt() ?? 0;

      return sum + amountSen;
    });

    return totalSen / 100.0;
  }

  Future<void> loadWalletBalance() async {
    if (!mounted) return;

    setState(() {
      walletLoading = true;
      walletError = null;
    });

    try {
      debugPrint('Loading wallet from Flask...');

      await ApiService.syncStudent();
      final result = await ApiService.getWallet();

      debugPrint('Wallet API response: $result');

      final balance = result['balance_sen'];

      if (balance is! num) {
        throw FormatException(
          'Invalid wallet balance: $balance. '
          'API response: $result',
        );
      }

      if (!mounted) return;

      setState(() {
        walletBalanceSen = balance.toInt();
        walletLoading = false;
        walletError = null;
      });

      debugPrint(
        'Wallet loaded: RM '
        '${(walletBalanceSen / 100).toStringAsFixed(2)}',
      );
    } catch (error) {
      debugPrint('Wallet loading error: $error');

      if (!mounted) return;

      setState(() {
        walletLoading = false;
        walletError = error.toString();
      });
    }
  }

  Future<void> loadSavingsBalance() async {
    if (!mounted) return;

    setState(() {
      savingsLoading = true;
      savingsError = null;
    });

    try {
      final result = await ApiService.getSavings();

      debugPrint('Savings API response: $result');

      final balance = result['balance_sen'];

      if (balance is! num) {
        throw const FormatException('Invalid savings balance response.');
      }

      if (!mounted) return;

      setState(() {
        savingsBalanceSen = balance.toInt();
        savingsLoading = false;
        savingsError = null;
      });
    } catch (error) {
      debugPrint('Savings loading error: $error');

      if (!mounted) return;

      setState(() {
        savingsLoading = false;
        savingsError = error.toString();
      });
    }
  }

  Future<void> loadSavingsHistory() async {
    if (!mounted) return;

    setState(() {
      savingsHistoryLoading = true;
      savingsHistoryError = null;
    });

    try {
      final result = await ApiService.getSavingsTransactions();

      debugPrint('Savings history response: $result');

      final raw = result['transactions'];

      if (raw is! List) {
        throw const FormatException('Invalid savings history response.');
      }

      final items = raw.map((item) {
        return Map<String, dynamic>.from(item as Map);
      }).toList();

      if (!mounted) return;

      setState(() {
        savingsTransactions = items;
        savingsHistoryLoading = false;
        savingsHistoryError = null;
      });
    } catch (error) {
      debugPrint('Savings history error: $error');

      if (!mounted) return;

      setState(() {
        savingsHistoryLoading = false;
        savingsHistoryError = error.toString();
      });
    }
  }

  Future<void> loadMonthlyExpenses() async {
    if (!mounted) return;

    setState(() {
      expensesLoading = true;
      expensesError = null;
    });

    try {
      final now = DateTime.now();

      final result = await ApiService.getExpenses(
        year: now.year,
        month: now.month,
      );

      debugPrint('Monthly expenses response: $result');

      final raw = result['expenses'];

      if (raw is! List) {
        throw const FormatException('Invalid expenses response.');
      }

      final items = raw.map((item) {
        return Map<String, dynamic>.from(item as Map);
      }).toList();

      if (!mounted) return;

      setState(() {
        monthlyExpenseRecords = items;
        expensesLoading = false;
        expensesError = null;
      });

      debugPrint('Loaded ${items.length} monthly expenses.');
    } catch (error) {
      debugPrint('Monthly expense loading error: $error');

      if (!mounted) return;

      setState(() {
        expensesLoading = false;
        expensesError = error.toString();
      });
    }
  }

  Future<void> loadWalletTransactions() async {
    if (!mounted) return;

    setState(() {
      transactionsLoading = true;
      transactionsError = null;
    });

    try {
      final result = await ApiService.getTransactions();

      debugPrint('Wallet transactions: $result');

      final raw = result['transactions'];

      if (raw is! List) {
        throw const FormatException('Invalid transaction history response.');
      }

      final items = raw.map((item) {
        return Map<String, dynamic>.from(item as Map);
      }).toList();

      if (!mounted) return;

      setState(() {
        walletTransactions = items;
        transactionsLoading = false;
        transactionsError = null;
      });
    } catch (error) {
      debugPrint('Transaction history error: $error');

      if (!mounted) return;

      setState(() {
        transactionsLoading = false;
        transactionsError = error.toString();
      });
    }
  }

  @override
  void initState() {
    super.initState();
    loadWalletBalance();
    loadWalletTransactions();
    loadSavingsBalance();
    loadSavingsHistory();
    loadMonthlyExpenses();
  }

  void message(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  void record(
    String title,
    String category,
    double amount, {
    bool expense = false,
  }) {
    transactions.insert(
      0,
      DemoTransaction(
        title: title,
        category: category,
        amount: amount,
        date: DateTime.now(),
        isExpense: expense,
      ),
    );
  }

  Future<void> enterAmount({
    required String title,
    required void Function(double) onConfirm,
  }) async {
    final amount = await showDialog<double>(
      context: context,
      builder: (dialogContext) {
        String input = '';

        return AlertDialog(
          title: Text(title),
          content: TextField(
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (value) {
              input = value;
            },
            decoration: const InputDecoration(
              prefixText: 'RM ',
              labelText: 'Amount',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final value = double.tryParse(input);

                if (value == null ||
                    !value.isFinite ||
                    value <= 0 ||
                    (value * 100 - (value * 100).round()).abs() > 0.000001) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Enter a valid amount with at most 2 decimals.',
                      ),
                    ),
                  );
                  return;
                }

                Navigator.of(dialogContext).pop(value);
              },
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );

    if (!mounted || amount == null) return;

    onConfirm(amount);
  }

  void topUp() {
    if (topUpProcessing) return;

    enterAmount(
      title: 'Add Simulated Money',
      onConfirm: (amount) async {
        if (topUpProcessing || !mounted) return;

        final amountSen = (amount * 100).round();

        if (amountSen < 100 || amountSen > 100000) {
          message('Top-up must be between RM1 and RM1000.');
          return;
        }

        setState(() {
          topUpProcessing = true;
        });

        try {
          final key = const Uuid().v4();

          final result = await ApiService.topUpWallet(
            amountSen: amountSen,
            idempotencyKey: key,
          );

          debugPrint('Top-up result: $result');

          await loadWalletBalance();
          await loadWalletTransactions();

          if (!mounted) return;

          if (walletError != null) {
            message(
              'Top-up processed, but balance refresh failed. '
              'Please refresh your wallet.',
            );
            return;
          }

          message('${rm(amount)} added to your database wallet!');
        } catch (error) {
          debugPrint('Top-up error: $error');

          if (!mounted) return;

          message('Top-up failed: $error');
        } finally {
          if (mounted) {
            setState(() {
              topUpProcessing = false;
            });
          }
        }
      },
    );
  }

  void transfer() {
    if (transferProcessing) return;

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        String recipientEmail = '';
        String amountInput = '';

        return AlertDialog(
          title: const Text('Transfer Money'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Send simulated money to another '
                'Cashly Campus student.',
              ),
              const SizedBox(height: 16),

              TextField(
                keyboardType: TextInputType.emailAddress,
                onChanged: (value) {
                  recipientEmail = value.trim();
                },
                decoration: const InputDecoration(
                  labelText: 'Recipient Email',
                  hintText: 'student@example.com',
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 12),

              TextField(
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                onChanged: (value) {
                  amountInput = value;
                },
                decoration: const InputDecoration(
                  labelText: 'Amount',
                  prefixText: 'RM ',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Cancel'),
            ),

            FilledButton(
              onPressed: () async {
                final email = recipientEmail.trim();
                final amount = double.tryParse(amountInput);

                if (email.isEmpty ||
                    !email.contains('@') ||
                    amount == null ||
                    !amount.isFinite ||
                    amount <= 0 ||
                    (amount * 100 - (amount * 100).round()).abs() > 0.000001) {
                  message('Enter a valid email and amount.');
                  return;
                }

                final amountSen = (amount * 100).round();

                if (amountSen < 100 || amountSen > 100000) {
                  message('Transfer must be between RM1 and RM1000.');
                  return;
                }

                if (amountSen > walletBalanceSen) {
                  message('Insufficient wallet balance.');
                  return;
                }

                Navigator.of(dialogContext).pop();

                if (!mounted || transferProcessing) return;

                setState(() {
                  transferProcessing = true;
                });

                try {
                  final key = const Uuid().v4();

                  final result = await ApiService.transferMoney(
                    recipientEmail: email,
                    amountSen: amountSen,
                    idempotencyKey: key,
                  );

                  debugPrint('Transfer result: $result');

                  await loadWalletBalance();
                  await loadWalletTransactions();

                  if (!mounted) return;

                  if (walletError != null) {
                    message(
                      'Transfer processed, but balance '
                      'refresh failed. Please refresh.',
                    );
                    return;
                  }

                  message('${rm(amount)} transferred successfully!');
                } catch (error) {
                  debugPrint('Transfer error: $error');

                  if (!mounted) return;

                  message('Transfer failed: $error');
                } finally {
                  if (mounted) {
                    setState(() {
                      transferProcessing = false;
                    });
                  }
                }
              },
              child: const Text('Transfer'),
            ),
          ],
        );
      },
    );
  }

  void moveSavings(bool deposit) {
    if (savingsProcessing) return;

    enterAmount(
      title: deposit ? 'Deposit to Savings' : 'Withdraw Savings',
      onConfirm: (amount) async {
        if (!mounted || savingsProcessing) return;

        final amountSen = (amount * 100).round();

        if (amountSen < 100 || amountSen > 100000) {
          message('Amount must be between RM1 and RM1000.');
          return;
        }

        if (deposit && amountSen > walletBalanceSen) {
          message('Insufficient wallet balance.');
          return;
        }

        if (!deposit && amountSen > savingsBalanceSen) {
          message('Insufficient savings balance.');
          return;
        }

        setState(() {
          savingsProcessing = true;
        });

        // Generate one key for this transaction.
        final key = const Uuid().v4();

        try {
          final result = deposit
              ? await ApiService.depositSavings(
                  amountSen: amountSen,
                  idempotencyKey: key,
                )
              : await ApiService.withdrawSavings(
                  amountSen: amountSen,
                  idempotencyKey: key,
                );

          debugPrint('Savings transaction result: $result');

          // Refresh balances using PostgreSQL.
          await loadWalletBalance();
          await loadSavingsBalance();
          await loadWalletTransactions();
          await loadSavingsHistory();

          if (!mounted) return;

          if (walletError != null || savingsError != null) {
            message(
              'Transaction processed, but balance refresh failed. '
              'Please refresh your balances.',
            );
            return;
          }

          message(
            deposit
                ? '${rm(amount)} deposited to Savings!'
                : '${rm(amount)} withdrawn from Savings!',
          );
        } catch (error) {
          debugPrint('Savings transaction error: $error');

          if (!mounted) return;

          message(
            'Savings transaction could not be confirmed: $error. '
            'Check your balances before trying again.',
          );
        } finally {
          if (mounted) {
            setState(() {
              savingsProcessing = false;
            });
          }
        }
      },
    );
  }

  void buy(String product, double price) {
    if (wallet < price) {
      message('Insufficient wallet balance.');
      return;
    }

    setState(() {
      wallet -= price;
      final earned = (price / 5).floor();
      coins += earned;
      record(
        product,
        product == 'Campus Meal' ? 'Food & Drinks' : 'Shopping',
        price,
        expense: true,
      );
    });
    message('Demo purchase successful! Campus Coins earned.');
  }

  void redeemCoins() {
    if (coins < 100) {
      message('You need at least 100 coins.');
      return;
    }
    setState(() {
      coins -= 100;
      // Demonstration discount credit, not real money.
      wallet += 1;
      record('Coin Reward Credit', 'Reward', 1);
    });
    message('100 coins redeemed for RM1 demo wallet credit.');
  }

  Widget tile(
    IconData icon,
    String title,
    String subtitle, {
    VoidCallback? onTap,
  }) {
    return Card(
      color: Colors.white,
      elevation: 0,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xFFDBEAFE),
          child: Icon(icon, color: blue),
        ),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: onTap == null ? null : const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }

  Widget action(IconData icon, String label, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: const Color(0xFFDBEAFE),
                child: Icon(icon, color: blue),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget heading(String text) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 14),
    child: Text(
      text,
      style: const TextStyle(
        fontSize: 19,
        fontWeight: FontWeight.bold,
        color: navy,
      ),
    ),
  );

  Widget balanceCard(
    String label,
    String value, {
    IconData icon = Icons.account_balance_wallet,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: blue,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white),
          const SizedBox(height: 12),
          Text(label, style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'SIMULATED FUNDS • NOT REAL MONEY',
            style: TextStyle(color: Colors.white70, fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget history() {
    if (transactionsLoading) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (transactionsError != null) {
      return Column(
        children: [
          const Text('Unable to load transaction history.'),
          TextButton(
            onPressed: loadWalletTransactions,
            child: const Text('Retry'),
          ),
        ],
      );
    }

    if (walletTransactions.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text('No wallet transactions yet.'),
      );
    }

    return Column(
      children: walletTransactions.take(8).map((transaction) {
        final type = transaction['transaction_type']?.toString() ?? '';
        final amountSen = (transaction['amount_sen'] as num?)?.toInt() ?? 0;
        final amount = amountSen / 100.0;
        final isOutgoing = type == 'TRANSFER_OUT' || type == 'SAVINGS_DEPOSIT';

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

        final dateText = transaction['created_at']?.toString() ?? '';

        String formattedDate = 'Unknown date';

        if (dateText.isNotEmpty) {
          final date = DateTime.tryParse(dateText);

          if (date != null) {
            final localDate = date.toLocal();

            formattedDate =
                '${localDate.day}/${localDate.month}/${localDate.year} '
                '${localDate.hour.toString().padLeft(2, '0')}:'
                '${localDate.minute.toString().padLeft(2, '0')}';
          }
        }

        return Card(
          color: Colors.white,
          elevation: 0,
          child: ListTile(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      TransactionDetailsScreen(transaction: transaction),
                ),
              );
            },
            leading: CircleAvatar(
              backgroundColor: isOutgoing
                  ? const Color(0xFFFEE2E2)
                  : const Color(0xFFDCFCE7),
              child: Icon(icon, color: isOutgoing ? Colors.red : Colors.green),
            ),
            title: Text(title),
            subtitle: Text(formattedDate),
            trailing: Text(
              '${isOutgoing ? '-' : '+'} ${rm(amount)}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isOutgoing ? Colors.red : Colors.green,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget homePage() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          'Welcome to Cashly Campus',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: navy,
          ),
        ),
        const Text('City University • Student Demo'),
        const SizedBox(height: 22),
        balanceCard(
          'Available Wallet Balance',
          walletLoading
              ? 'Loading balance...'
              : walletError != null
              ? 'Wallet error - check Debug Console'
              : rm(walletBalanceSen / 100.0),
        ),

        const SizedBox(height: 16),
        Row(
          children: [
            action(Icons.add_circle_outline, 'Top Up', topUp),
            action(Icons.send_outlined, 'Transfer', transfer),
            action(Icons.qr_code_scanner, 'Scan & Pay', () {
              message('QR scanner will be added in Phase 4.');
            }),
            action(Icons.savings_outlined, 'Savings', () {
              setState(() => tab = 1);
            }),
          ],
        ),
        heading('Your Money Overview'),
        Row(
          children: [
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(15),
                  child: Column(
                    children: [
                      const Text('Savings'),
                      Text(
                        savingsLoading
                            ? 'Loading...'
                            : savingsError != null
                            ? 'Unavailable'
                            : rm(savingsBalanceSen / 100.0),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: blue,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(15),
                  child: Column(
                    children: [
                      const Text('Campus Coins'),
                      Text(
                        '$coins',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        heading('Recent Activity'),
        history(),
      ],
    );
  }

  Widget savingsHistory() {
    if (savingsHistoryLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (savingsHistoryError != null) {
      return Column(
        children: [
          const Text('Unable to load savings history.'),
          TextButton(onPressed: loadSavingsHistory, child: const Text('Retry')),
        ],
      );
    }

    if (savingsTransactions.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('No savings transactions yet.'),
        ),
      );
    }

    return Column(
      children: savingsTransactions.map((transaction) {
        final type = transaction['transaction_type']?.toString() ?? '';

        final amountSen = (transaction['amount_sen'] as num?)?.toInt() ?? 0;

        final isDeposit = type == 'DEPOSIT';

        final amount = amountSen / 100.0;

        final title = isDeposit
            ? 'Savings Deposit'
            : type == 'WITHDRAW'
            ? 'Savings Withdrawal'
            : type.replaceAll('_', ' ');

        final createdAt = transaction['created_at']?.toString() ?? '';

        final date = DateTime.tryParse(createdAt)?.toLocal();

        final formattedDate = date == null
            ? 'Unknown date'
            : '${date.day}/${date.month}/${date.year} '
                  '${date.hour.toString().padLeft(2, '0')}:'
                  '${date.minute.toString().padLeft(2, '0')}';

        return Card(
          color: Colors.white,
          elevation: 0,
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: isDeposit
                  ? const Color(0xFFDCFCE7)
                  : const Color(0xFFFEE2E2),
              child: Icon(
                isDeposit ? Icons.arrow_downward : Icons.arrow_upward,
                color: isDeposit ? Colors.green : Colors.red,
              ),
            ),
            title: Text(title),
            subtitle: Text(formattedDate),
            trailing: Text(
              '${isDeposit ? '+' : '-'} ${rm(amount)}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isDeposit ? Colors.green : Colors.red,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget monthlyExpenseHistory() {
    if (expensesLoading) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (expensesError != null) {
      return Column(
        children: [
          const Text('Unable to load expenses.'),
          TextButton(
            onPressed: loadMonthlyExpenses,
            child: const Text('Retry'),
          ),
        ],
      );
    }

    if (monthlyExpenseRecords.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('No expenses recorded this month.'),
        ),
      );
    }

    return Column(
      children: monthlyExpenseRecords.take(8).map((expense) {
        final category = expense['category']?.toString() ?? 'Others';

        final description = expense['description']?.toString() ?? '';

        final amountSen = (expense['amount_sen'] as num?)?.toInt() ?? 0;

        final dateText = expense['expense_date']?.toString() ?? '';

        return Card(
          color: Colors.white,
          elevation: 0,
          child: ListTile(
            leading: const CircleAvatar(
              backgroundColor: Color(0xFFFEE2E2),
              child: Icon(Icons.receipt_long, color: Colors.red),
            ),
            title: Text(description.isEmpty ? category : description),
            subtitle: Text('$category • $dateText'),
            trailing: Text(
              '- ${rm(amountSen / 100.0)}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget financePage() {
    final ratio = monthlyBudget > 0 ? monthlySpending / monthlyBudget : 0.0;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        heading('Financial Management'),
        balanceCard(
          'Simulated Savings Balance',
          savingsLoading
              ? 'Loading savings...'
              : savingsError != null
              ? 'Savings unavailable'
              : rm(savingsBalanceSen / 100.0),
          icon: Icons.savings,
        ),
        const SizedBox(height: 12),

        Row(
          children: [
            Expanded(
              child: FilledButton(
                onPressed:
                    savingsProcessing || savingsLoading || savingsError != null
                    ? null
                    : () => moveSavings(true),
                child: savingsProcessing
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Deposit'),
              ),
            ),

            const SizedBox(width: 10),

            Expanded(
              child: OutlinedButton(
                onPressed:
                    savingsProcessing || savingsLoading || savingsError != null
                    ? null
                    : () => moveSavings(false),
                child: const Text('Withdraw'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        Card(
          color: Colors.white,
          elevation: 0,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Projected Annual Interest',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 8),

                const Text(
                  '6% simple interest per year',
                  style: TextStyle(color: Colors.grey),
                ),

                const SizedBox(height: 16),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Current Savings'),

                    Text(
                      savingsLoading
                          ? 'Loading...'
                          : savingsError != null
                          ? 'Unavailable'
                          : rm(savingsBalanceSen / 100.0),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Estimated Interest'),

                    Text(
                      savingsLoading
                          ? 'Loading...'
                          : savingsError != null
                          ? 'Unavailable'
                          : rm((savingsBalanceSen / 100.0) * 0.06),
                      style: const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),

                const Divider(height: 28),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'After 1 Year',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),

                    Text(
                      savingsLoading
                          ? 'Loading...'
                          : savingsError != null
                          ? 'Unavailable'
                          : rm((savingsBalanceSen / 100.0) * 1.06),
                      style: const TextStyle(
                        color: blue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                const Text(
                  'This is an illustration only. '
                  'It assumes your savings balance stays the '
                  'same for one year. No real interest is earned '
                  'or added to your account.',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ),

        heading('Savings Transaction History'),
        savingsHistory(),
        const SizedBox(height: 16),

        heading('Smart Expense Tracker'),

        tile(
          Icons.receipt_long,
          'This Month Spending',
          expensesLoading
              ? 'Loading expenses...'
              : expensesError != null
              ? 'Expenses unavailable'
              : rm(monthlySpending),
        ),
        const SizedBox(height: 12),
        Text(
          'Monthly Budget: ${rm(monthlyBudget)}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: ratio.clamp(0.0, 1.0),
          minHeight: 12,
          borderRadius: BorderRadius.circular(10),
          color: ratio >= 0.9
              ? Colors.red
              : ratio >= 0.7
              ? Colors.orange
              : Colors.green,
        ),
        const SizedBox(height: 10),
        Text('${(ratio * 100).toStringAsFixed(1)}% of budget used'),
        if (ratio >= 0.7)
          Text(
            ratio >= 1
                ? 'Budget exceeded!'
                : 'Warning: approaching budget limit.',
            style: const TextStyle(color: Colors.deepOrange),
          ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () {
            enterAmount(
              title: 'Set Monthly Budget',
              onConfirm: (amount) {
                setState(() => monthlyBudget = amount);
                message('Monthly budget updated.');
              },
            );
          },
          icon: const Icon(Icons.edit),
          label: const Text('Edit Monthly Budget'),
        ),

        heading('Recent Monthly Expenses'),
        monthlyExpenseHistory(),
        const SizedBox(height: 12),
        heading('Expense Tools'),

        tile(
          Icons.add,
          'Record Manual Expense',
          'Record an expense paid outside the wallet',
          onTap: () {
            if (expenseProcessing) {
              message('An expense is already being saved.');
              return;
            }

            enterAmount(
              title: 'Add Manual Expense',
              onConfirm: (amount) async {
                if (expenseProcessing || !mounted) return;

                final amountSen = (amount * 100).round();

                if (amountSen < 1 || amountSen > 10000000) {
                  message('Expense must be between RM0.01 and RM100,000.');
                  return;
                }

                setState(() {
                  expenseProcessing = true;
                });

                try {
                  final now = DateTime.now();

                  final result = await ApiService.recordExpense(
                    amountSen: amountSen,
                    category: 'Others',
                    description: 'Manual Expense',
                    expenseDate: now,
                  );

                  debugPrint('Expense saved: $result');

                  // Refresh expenses from PostgreSQL
                  await loadMonthlyExpenses();
                  if (!mounted) return;

                  // Check whether the refresh was successful
                  if (expensesError != null) {
                    message(
                      'Expense saved, but refresh failed. '
                      'Tap Retry to reload expenses.',
                    );
                    return;
                  }

                  // Show success message
                  message('${rm(amount)} saved to PostgreSQL successfully!');
                } catch (error) {
                  debugPrint('Expense error: $error');

                  if (!mounted) return;

                  message(
                    'Expense save could not be confirmed: $error. '
                    'Check your records before trying again.',
                  );
                } finally {
                  if (mounted) {
                    setState(() {
                      expenseProcessing = false;
                    });
                  }
                }
              },
            );
          },
        ),

        tile(
          Icons.bar_chart,
          'Spending Report',
          'View your saved monthly expenses',
          onTap: () {
            if (expensesLoading || expensesError != null) {
              message('Please load your expenses first.');
              return;
            }

            final savedTransactions = monthlyExpenseRecords.map((expense) {
              final amountSen = (expense['amount_sen'] as num?)?.toInt() ?? 0;

              final dateText = expense['expense_date']?.toString() ?? '';

              return DemoTransaction(
                title: expense['description']?.toString() ?? 'Manual Expense',
                category: expense['category']?.toString() ?? 'Others',
                amount: amountSen / 100.0,
                date: DateTime.tryParse(dateText) ?? DateTime.now(),
                isExpense: true,
              );
            }).toList();

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    ExpenseReportScreen(transactions: savedTransactions),
              ),
            );
          },
        ),

        tile(
          Icons.auto_graph,
          'AI Spending Prediction',
          'ML backend not connected yet',
          onTap: () {
            message('ML predictions will be added in Phase 8.');
          },
        ),
      ],
    );
  }

  Widget campusPage() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        heading('City University Marketplace'),
        const Text('Sample campus products for demonstration only.'),
        const SizedBox(height: 18),
        Card(
          color: Colors.white,
          child: ListTile(
            leading: const Icon(Icons.restaurant, color: blue, size: 36),
            title: const Text('Campus Meal'),
            subtitle: const Text('Demo cafeteria purchase • RM 12.00'),
            trailing: FilledButton(
              onPressed: () => buy('Campus Meal', 12),
              child: const Text('Buy'),
            ),
          ),
        ),
        Card(
          color: Colors.white,
          child: ListTile(
            leading: const Icon(Icons.checkroom, color: blue, size: 36),
            title: const Text('University T-Shirt'),
            subtitle: const Text('Demo merchandise • RM 35.00'),
            trailing: FilledButton(
              onPressed: () => buy('University T-Shirt', 35),
              child: const Text('Buy'),
            ),
          ),
        ),
        const SizedBox(height: 15),
        const Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Earn 1 Campus Coin for every full RM5 '
              'spent on eligible demo campus purchases.',
            ),
          ),
        ),
      ],
    );
  }

  Widget rewardsPage() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        heading('Campus Rewards'),
        balanceCard(
          'Available Campus Coins',
          '$coins Coins',
          icon: Icons.stars,
        ),
        const SizedBox(height: 20),
        tile(
          Icons.redeem,
          'Redeem 100 Coins',
          'Receive RM1 simulated reward credit',
          onTap: redeemCoins,
        ),
        heading('Available Vouchers'),
        Card(
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'RM5 Campus Meal Voucher',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                ),
                const SizedBox(height: 6),
                const Text('Demonstration voucher; not valid at real shops.'),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: voucherUsed
                      ? null
                      : () {
                          setState(() {
                            if (!voucherClaimed) {
                              voucherClaimed = true;
                            } else {
                              voucherUsed = true;
                            }
                          });
                          message(
                            voucherUsed
                                ? 'Demo voucher marked as redeemed.'
                                : 'Demo voucher claimed.',
                          );
                        },
                  child: Text(
                    voucherUsed
                        ? 'Redeemed'
                        : voucherClaimed
                        ? 'Redeem Demo Voucher'
                        : 'Claim Voucher',
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget profilePage() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        heading('Student Profile'),

        const Center(
          child: CircleAvatar(
            radius: 42,
            backgroundColor: Color(0xFFDBEAFE),
            child: Icon(Icons.person, size: 46, color: blue),
          ),
        ),

        const SizedBox(height: 15),

        const Center(child: Text('City University Malaysia')),

        const SizedBox(height: 24),

        tile(
          Icons.badge_outlined,
          'Student Account',
          'Registered with Firebase Authentication',
        ),

        tile(Icons.lock_outline, 'Security', 'Firebase Authentication enabled'),

        tile(
          Icons.info_outline,
          'About Cashly Campus',
          'Final Year Project prototype',
        ),

        const SizedBox(height: 24),

        // TEST BACKEND CONNECTION
        Card(
          child: ListTile(
            leading: const Icon(Icons.cloud_done_outlined, color: Colors.blue),
            title: const Text('Test Backend Connection'),
            subtitle: const Text('Connect Firebase, Flask and PostgreSQL'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () async {
              final messenger = ScaffoldMessenger.of(context);

              try {
                final health = await ApiService.healthCheck();
                debugPrint('Backend: $health');

                final result = await ApiService.syncStudent();
                debugPrint('Student sync: $result');

                if (!mounted) return;

                final student = result['student'] as Map<String, dynamic>;
                final walletData = result['wallet'] as Map<String, dynamic>;

                final email = student['email'] ?? 'Unknown student';
                final balance = walletData['balance_sen'] ?? 0;

                messenger.showSnackBar(
                  SnackBar(
                    content: Text('Connected! $email | Wallet: $balance sen'),
                    backgroundColor: Colors.green,
                  ),
                );

                await loadWalletBalance();
              } catch (error) {
                debugPrint('Backend connection error: $error');

                if (!mounted) return;

                messenger.showSnackBar(
                  SnackBar(
                    content: Text('Connection failed: $error'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
          ),
        ),

        // TEST DATABASE WALLET
        Card(
          child: ListTile(
            leading: const Icon(Icons.account_balance_wallet_outlined),
            title: const Text('Test Database Wallet'),
            subtitle: const Text('Balance, top-up and transaction history'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const WalletTestScreen()),
              );

              if (!mounted) return;

              await loadWalletBalance();
            },
          ),
        ),

        // TEST SAVINGS CONNECTION
        Card(
          child: ListTile(
            leading: const Icon(Icons.savings_outlined, color: Colors.green),
            title: const Text('Test Savings Connection'),
            subtitle: const Text('Check PostgreSQL savings balance'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () async {
              // Capture messenger before await
              final messenger = ScaffoldMessenger.of(context);

              try {
                final result = await ApiService.getSavings();

                debugPrint('SAVINGS API RESPONSE: $result');

                if (!mounted) return;

                final balanceSen = (result['balance_sen'] as num).toInt();

                messenger.showSnackBar(
                  SnackBar(
                    content: Text(
                      'Savings connected! Balance: '
                      'RM ${(balanceSen / 100).toStringAsFixed(2)}',
                    ),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (error) {
                debugPrint('SAVINGS ERROR: $error');

                if (!mounted) return;

                messenger.showSnackBar(
                  SnackBar(
                    content: Text('Savings connection failed: $error'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
          ),
        ),

        // LOGOUT BUTTON
        Card(
          child: ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text(
              'Logout',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
            subtitle: const Text('Sign out of your Cashly Campus account'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () async {
              await FirebaseAuth.instance.signOut();
            },
          ),
        ),

        const SizedBox(height: 24),

        const Text(
          'All money, interest, vouchers and rewards '
          'are simulated. No real financial services '
          'are provided by this application.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget currentPage;

    switch (tab) {
      case 0:
        currentPage = homePage();
        break;
      case 1:
        currentPage = financePage();
        break;
      case 2:
        currentPage = campusPage();
        break;
      case 3:
        currentPage = rewardsPage();
        break;
      case 4:
        currentPage = profilePage();
        break;
      default:
        currentPage = homePage();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Cashly Campus',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 12),
            child: Center(
              child: Text(
                'DEMO',
                style: TextStyle(
                  color: Colors.deepOrange,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(child: currentPage),
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab,
        onDestinationSelected: (index) {
          setState(() => tab = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: Icon(Icons.account_balance_wallet),
            label: 'Finance',
          ),
          NavigationDestination(
            icon: Icon(Icons.storefront_outlined),
            selectedIcon: Icon(Icons.storefront),
            label: 'Campus',
          ),
          NavigationDestination(
            icon: Icon(Icons.card_giftcard_outlined),
            selectedIcon: Icon(Icons.card_giftcard),
            label: 'Rewards',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class ExpenseReportScreen extends StatelessWidget {
  final List<DemoTransaction> transactions;

  const ExpenseReportScreen({super.key, required this.transactions});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final expenses = transactions
        .where(
          (t) =>
              t.isExpense &&
              t.date.month == now.month &&
              t.date.year == now.year,
        )
        .toList();

    final totals = <String, double>{};
    for (final expense in expenses) {
      totals.update(
        expense.category,
        (value) => value + expense.amount,
        ifAbsent: () => expense.amount,
      );
    }

    final total = expenses.fold(0.0, (sum, t) => sum + t.amount);

    return Scaffold(
      appBar: AppBar(title: const Text('Expense Report')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'This Month: ${rm(total)}',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          if (expenses.isEmpty) const Text('No expenses recorded this month.'),
          ...totals.entries.map(
            (entry) => Card(
              child: ListTile(
                title: Text(entry.key),
                trailing: Text(rm(entry.value)),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'This is a basic Phase 1 report. '
            'Full charts, date filters and ML '
            'predictions will be added later.',
          ),
        ],
      ),
    );
  }
}
