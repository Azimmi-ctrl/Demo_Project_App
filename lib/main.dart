
import 'package:flutter/material.dart';

void main() => runApp(const CashlyCampusApp());

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
      home: const CampusMainScreen(),
    );
  }
}

class CampusMainScreen extends StatefulWidget {
  const CampusMainScreen({super.key});

  @override
  State<CampusMainScreen> createState() => _CampusMainScreenState();
}

class _CampusMainScreenState extends State<CampusMainScreen> {
  int tab = 0;
  double wallet = 500;
  double savings = 100;
  double monthlyBudget = 1000;
  int coins = 120;
  bool voucherClaimed = false;
  bool voucherUsed = false;
  final transactions = <DemoTransaction>[];

  double get monthlySpending {
    final now = DateTime.now();
    return transactions
        .where((t) =>
            t.isExpense &&
            t.date.year == now.year &&
            t.date.month == now.month)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  void message(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
    );
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
    final controller = TextEditingController();
    final amount = await showDialog<double>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(
            decimal: true,
          ),
          decoration: const InputDecoration(
            prefixText: 'RM ',
            labelText: 'Amount',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final value = double.tryParse(controller.text);
              if (value == null ||
                  !value.isFinite ||
                  value <= 0 ||
                  (value * 100 - (value * 100).round()).abs() >
                      0.000001) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Enter a valid amount with at most 2 decimals.',
                    ),
                  ),
                );
                return;
              }
              Navigator.pop(dialogContext, value);
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (amount != null && mounted) onConfirm(amount);
  }

  void topUp() {
    enterAmount(
      title: 'Add Demo Money',
      onConfirm: (amount) {
        setState(() {
          wallet += amount;
          record('Demo Top-up', 'Top-up', amount);
        });
        message('${rm(amount)} added to demo wallet.');
      },
    );
  }

  void transfer() {
    final recipient = TextEditingController();
    final amountController = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Demo Fund Transfer'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: recipient,
              decoration: const InputDecoration(
                labelText: 'Recipient student ID',
              ),
            ),
            TextField(
              controller: amountController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Amount (RM)',
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Demo only: no real recipient is credited.',
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final value = double.tryParse(amountController.text);
              final student = recipient.text.trim();
              if (student.isEmpty ||
                  value == null ||
                  !value.isFinite ||
                  value <= 0 ||
                  (value * 100 - (value * 100).round()).abs() >
                      0.000001) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  const SnackBar(
                    content: Text('Enter valid recipient and amount.'),
                  ),
                );
                return;
              }
              if (value > wallet) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  const SnackBar(
                    content: Text('Insufficient wallet balance.'),
                  ),
                );
                return;
              }
              setState(() {
                wallet -= value;
                record('Transfer to $student', 'Transfer', value);
              });
              Navigator.pop(dialogContext);
              message('Demo transfer recorded: ${rm(value)}.');
            },
            child: const Text('Send Demo Money'),
          ),
        ],
      ),
    ).then((_) {
      recipient.dispose();
      amountController.dispose();
    });
  }

  void moveSavings(bool deposit) {
    enterAmount(
      title: deposit ? 'Deposit to Savings' : 'Withdraw Savings',
      onConfirm: (amount) {
        if (deposit && amount > wallet) {
          message('Insufficient wallet balance.');
          return;
        }
        if (!deposit && amount > savings) {
          message('Insufficient savings balance.');
          return;
        }
        setState(() {
          if (deposit) {
            wallet -= amount;
            savings += amount;
          } else {
            savings -= amount;
            wallet += amount;
          }
          record(
            deposit ? 'Savings Deposit' : 'Savings Withdrawal',
            'Savings',
            amount,
          );
        });
        message('Savings updated successfully.');
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
        trailing: onTap == null
            ? null
            : const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }

  Widget action(
    IconData icon,
    String label,
    VoidCallback onTap,
  ) {
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
          Text(
            label,
            style: const TextStyle(color: Colors.white70),
          ),
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
            style: TextStyle(
              color: Colors.white70,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget history() {
    if (transactions.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text('No demo transactions yet.'),
      );
    }
    return Column(
      children: transactions.take(8).map((t) {
        return tile(
          t.isExpense
              ? Icons.shopping_bag_outlined
              : Icons.swap_horiz,
          t.title,
          '${t.category} • '
          '${t.date.day}/${t.date.month}/${t.date.year}',
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
        balanceCard('Available Wallet Balance', rm(wallet)),
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
                        rm(savings),
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

  Widget financePage() {
    final ratio = monthlyBudget > 0
        ? monthlySpending / monthlyBudget
        : 0.0;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        heading('Financial Management'),
        balanceCard(
          'Simulated Savings Balance',
          rm(savings),
          icon: Icons.savings,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: FilledButton(
                onPressed: () => moveSavings(true),
                child: const Text('Deposit'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton(
                onPressed: () => moveSavings(false),
                child: const Text('Withdraw'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Card(
          child: ListTile(
            title: const Text('Illustrative Annual Interest'),
            subtitle: const Text(
              '3% simple interest assumption, '
              'based on unchanged balance for 1 year.',
            ),
            trailing: Text(
              rm(savings * 0.03),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        heading('Smart Expense Tracker'),
        tile(
          Icons.receipt_long,
          'This Month Spending',
          rm(monthlySpending),
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
        Text(
          '${(ratio * 100).toStringAsFixed(1)}% of budget used',
        ),
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
        heading('Expense Tools'),
        tile(
          Icons.add,
          'Record Manual Expense',
          'Record an expense paid outside the wallet',
          onTap: () {
            enterAmount(
              title: 'Add Manual Expense',
              onConfirm: (amount) {
                setState(() {
                  record(
                    'Manual Expense',
                    'Others',
                    amount,
                    expense: true,
                  );
                });
                message('Expense recorded.');
              },
            );
          },
        ),
        tile(
          Icons.bar_chart,
          'Spending Report',
          'View your recorded expenses',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ExpenseReportScreen(
                  transactions: List.of(transactions),
                ),
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
        const Text(
          'Sample campus products for demonstration only.',
        ),
        const SizedBox(height: 18),
        Card(
          color: Colors.white,
          child: ListTile(
            leading: const Icon(
              Icons.restaurant,
              color: blue,
              size: 36,
            ),
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
            leading: const Icon(
              Icons.checkroom,
              color: blue,
              size: 36,
            ),
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
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Demonstration voucher; not valid at real shops.',
                ),
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
            child: Icon(
              Icons.person,
              size: 46,
              color: blue,
            ),
          ),
        ),
        const SizedBox(height: 15),
        const Center(
          child: Text(
            'Demo Student',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const Center(child: Text('City University Malaysia')),
        const SizedBox(height: 24),
        tile(
          Icons.badge_outlined,
          'Student Account',
          'Demo account • not verified',
        ),
        tile(
          Icons.lock_outline,
          'Security',
          'Firebase Authentication will be added later',
        ),
        tile(
          Icons.info_outline,
          'About Cashly Campus',
          'Final Year Project prototype',
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

  const ExpenseReportScreen({
    super.key,
    required this.transactions,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final expenses = transactions.where((t) =>
        t.isExpense &&
        t.date.month == now.month &&
        t.date.year == now.year).toList();

    final totals = <String, double>{};
    for (final expense in expenses) {
      totals.update(
        expense.category,
        (value) => value + expense.amount,
        ifAbsent: () => expense.amount,
      );
    }

    final total = expenses.fold(
      0.0,
      (sum, t) => sum + t.amount,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Expense Report')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'This Month: ${rm(total)}',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          if (expenses.isEmpty)
            const Text('No expenses recorded this month.'),
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
