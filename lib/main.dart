
import 'package:flutter/material.dart';

void main() {
  runApp(const SmartExpenseApp());
}

const royalBlue = Color(0xFF2563EB);
const navyBlue = Color(0xFF0F172A);
const lightBackground = Color(0xFFF8FAFC);

String money(double value) => 'RM ${value.toStringAsFixed(2)}';

String monthName(int month) {
  const names = [
    'January', 'February', 'March', 'April',
    'May', 'June', 'July', 'August',
    'September', 'October', 'November', 'December'
  ];
  return names[month - 1];
}

class Expense {
  final int id;
  final double amount;
  final String category;
  final String description;
  final DateTime date;

  Expense({
    required this.id,
    required this.amount,
    required this.category,
    required this.description,
    required this.date,
  });
}

class SmartExpenseApp extends StatelessWidget {
  const SmartExpenseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Expense Tracker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: lightBackground,
        colorScheme: ColorScheme.fromSeed(
          seedColor: royalBlue,
          surface: Colors.white,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: lightBackground,
          foregroundColor: navyBlue,
          centerTitle: false,
        ),
      ),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int selectedIndex = 0;
  int nextId = 1;
  double monthlyBudget = 1000;
  final List<Expense> expenses = [];

  double get monthlyTotal {
    final now = DateTime.now();
    return expenses
        .where((e) =>
            e.date.month == now.month &&
            e.date.year == now.year)
        .fold(0.0, (sum, e) => sum + e.amount);
  }

  double get remaining => monthlyBudget - monthlyTotal;

  double get percentage => monthlyBudget > 0
      ? monthlyTotal / monthlyBudget
      : 0;

  void addExpense(
    double amount,
    String category,
    String description,
    DateTime date,
  ) {
    setState(() {
      expenses.add(Expense(
        id: nextId++,
        amount: amount,
        category: category,
        description: description,
        date: date,
      ));
    });
  }

  void deleteExpense(int id) {
    setState(() {
      expenses.removeWhere((e) => e.id == id);
    });
  }

  void updateBudget(double value) {
    setState(() => monthlyBudget = value);
  }

  void openAddExpense() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddExpenseScreen(
          onSave: addExpense,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomePage(
        total: monthlyTotal,
        budget: monthlyBudget,
        expenses: expenses,
        onAdd: openAddExpense,
      ),
      ExpensesPage(
        expenses: expenses,
        onAdd: openAddExpense,
        onDelete: deleteExpense,
      ),
      BudgetPage(
        total: monthlyTotal,
        budget: monthlyBudget,
        onUpdate: updateBudget,
      ),
      ReportsPage(expenses: expenses),
      const PredictionPage(),
    ];

    return Scaffold(
      body: SafeArea(child: pages[selectedIndex]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) {
          setState(() => selectedIndex = index);
        },
        indicatorColor: royalBlue.withValues(alpha: 0.12),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home, color: royalBlue),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long, color: royalBlue),
            label: 'Expenses',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: Icon(
              Icons.account_balance_wallet,
              color: royalBlue,
            ),
            label: 'Budget',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart, color: royalBlue),
            label: 'Reports',
          ),
          NavigationDestination(
            icon: Icon(Icons.auto_graph_outlined),
            selectedIcon: Icon(Icons.auto_graph, color: royalBlue),
            label: 'Predict',
          ),
        ],
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  final String title;

  const SectionTitle(this.title, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 19,
          fontWeight: FontWeight.bold,
          color: navyBlue,
        ),
      ),
    );
  }
}

class InfoCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const InfoCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.color = royalBlue,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 27),
            const SizedBox(height: 12),
            Text(
              label,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 5),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: const TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                  color: navyBlue,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  final double total;
  final double budget;
  final List<Expense> expenses;
  final VoidCallback onAdd;

  const HomePage({
    super.key,
    required this.total,
    required this.budget,
    required this.expenses,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final current = expenses.where((e) =>
        e.date.month == now.month &&
        e.date.year == now.year).toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    final ratio = budget > 0 ? total / budget : 0.0;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          'Hello, Student!',
          style: TextStyle(
            fontSize: 27,
            fontWeight: FontWeight.bold,
            color: navyBlue,
          ),
        ),
        const Text(
          'Manage Today. Predict Tomorrow.',
          style: TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 22),
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: royalBlue,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${monthName(now.month)} ${now.year} Spending',
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 10),
              Text(
                money(total),
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 15),
              LinearProgressIndicator(
                value: ratio.clamp(0.0, 1.0),
                minHeight: 9,
                borderRadius: BorderRadius.circular(10),
                backgroundColor: Colors.white24,
                color: ratio >= 0.9
                    ? Colors.redAccent
                    : ratio >= 0.7
                        ? Colors.orangeAccent
                        : Colors.greenAccent,
              ),
              const SizedBox(height: 10),
              Text(
                '${(ratio * 100).toStringAsFixed(1)}% of budget used',
                style: const TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: InfoCard(
                label: 'Monthly Budget',
                value: money(budget),
                icon: Icons.account_balance_wallet,
              ),
            ),
            Expanded(
              child: InfoCard(
                label: 'Remaining',
                value: money(budget - total),
                icon: Icons.savings,
                color: budget - total < 0
                    ? Colors.red
                    : Colors.green,
              ),
            ),
          ],
        ),
        if (ratio >= 0.7) ...[
          const SizedBox(height: 12),
          Card(
            color: Colors.orange.shade50,
            child: Padding(
              padding: const EdgeInsets.all(15),
              child: Text(
                ratio >= 1
                    ? 'Warning: You have exceeded your monthly budget!'
                    : 'Warning: You are approaching your monthly budget limit.',
                style: const TextStyle(color: navyBlue),
              ),
            ),
          ),
        ],
        const SizedBox(height: 22),
        FilledButton.icon(
          onPressed: onAdd,
          icon: const Icon(Icons.add),
          label: const Text('Add New Expense'),
          style: FilledButton.styleFrom(
            backgroundColor: royalBlue,
            padding: const EdgeInsets.all(15),
          ),
        ),
        const SizedBox(height: 25),
        const SectionTitle('Recent Transactions'),
        if (current.isEmpty)
          const Text(
            'No expenses recorded this month.',
            style: TextStyle(color: Colors.grey),
          ),
        ...current.take(5).map(
          (e) => ExpenseTile(expense: e),
        ),
      ],
    );
  }
}

class ExpenseTile extends StatelessWidget {
  final Expense expense;
  final VoidCallback? onDelete;

  const ExpenseTile({
    super.key,
    required this.expense,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      elevation: 0,
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: Color(0xFFDBEAFE),
          child: Icon(Icons.receipt, color: royalBlue),
        ),
        title: Text(expense.category),
        subtitle: Text(
          '${expense.description.isEmpty ? "No description" : expense.description} • '
          '${expense.date.day}/${expense.date.month}/${expense.date.year}',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              money(expense.amount),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: navyBlue,
              ),
            ),
            if (onDelete != null)
              IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: onDelete,
              ),
          ],
        ),
      ),
    );
  }
}

class ExpensesPage extends StatelessWidget {
  final List<Expense> expenses;
  final VoidCallback onAdd;
  final ValueChanged<int> onDelete;

  const ExpensesPage({
    super.key,
    required this.expenses,
    required this.onAdd,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final sorted = [...expenses]
      ..sort((a, b) => b.date.compareTo(a.date));

    return Scaffold(
      backgroundColor: lightBackground,
      appBar: AppBar(title: const Text('My Expenses')),
      body: sorted.isEmpty
          ? const Center(
              child: Text('No expenses yet. Add your first expense!'),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: sorted.length,
              itemBuilder: (context, index) {
                final expense = sorted[index];
                return ExpenseTile(
                  expense: expense,
                  onDelete: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (dialogContext) => AlertDialog(
                        title: const Text('Delete expense?'),
                        content: const Text(
                          'This action cannot be undone.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () =>
                                Navigator.pop(dialogContext, false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () =>
                                Navigator.pop(dialogContext, true),
                            child: const Text('Delete'),
                          ),
                        ],
                      ),
                    );
                    if (confirmed == true) {
                      onDelete(expense.id);
                    }
                  },
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: onAdd,
        icon: const Icon(Icons.add),
        label: const Text('Add Expense'),
      ),
    );
  }
}

class AddExpenseScreen extends StatefulWidget {
  final void Function(
    double amount,
    String category,
    String description,
    DateTime date,
  ) onSave;

  const AddExpenseScreen({
    super.key,
    required this.onSave,
  });

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final formKey = GlobalKey<FormState>();
  final amountController = TextEditingController();
  final descriptionController = TextEditingController();

  final categories = [
    'Food & Drinks',
    'Transportation',
    'Education',
    'Shopping',
    'Entertainment',
    'Accommodation',
    'Health',
    'Bills',
    'Others',
  ];

  String category = 'Food & Drinks';
  DateTime selectedDate = DateTime.now();

  @override
  void dispose() {
    amountController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Expense')),
      body: Form(
        key: formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextFormField(
              controller: amountController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Amount (RM)',
                prefixIcon: Icon(Icons.payments),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                final amount = double.tryParse(value ?? '');
                if (amount == null ||
                    !amount.isFinite ||
                    amount <= 0) {
                  return 'Enter a valid amount greater than zero';
                }
                return null;
              },
            ),
            const SizedBox(height: 18),
            DropdownButtonFormField<String>(
              initialValue: category,
              decoration: const InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
              ),
              items: categories
                  .map((c) => DropdownMenuItem(
                        value: c,
                        child: Text(c),
                      ))
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => category = value);
                }
              },
            ),
            const SizedBox(height: 18),
            TextFormField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (Optional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 18),
            ListTile(
              title: const Text('Expense Date'),
              subtitle: Text(
                '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
              ),
              trailing: const Icon(Icons.calendar_month),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: selectedDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (picked != null) {
                  setState(() => selectedDate = picked);
                }
              },
            ),
            const SizedBox(height: 25),
            FilledButton(
              onPressed: () {
                if (!formKey.currentState!.validate()) return;

                widget.onSave(
                  double.parse(amountController.text),
                  category,
                  descriptionController.text.trim(),
                  selectedDate,
                );

                Navigator.pop(context);
              },
              child: const Text('Save Expense'),
            ),
          ],
        ),
      ),
    );
  }
}

class BudgetPage extends StatefulWidget {
  final double total;
  final double budget;
  final ValueChanged<double> onUpdate;

  const BudgetPage({
    super.key,
    required this.total,
    required this.budget,
    required this.onUpdate,
  });

  @override
  State<BudgetPage> createState() => _BudgetPageState();
}

class _BudgetPageState extends State<BudgetPage> {
  final controller = TextEditingController();

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ratio = widget.budget > 0
        ? widget.total / widget.budget
        : 0.0;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const SectionTitle('Monthly Budget'),
        InfoCard(
          label: 'Your Monthly Budget',
          value: money(widget.budget),
          icon: Icons.account_balance_wallet,
        ),
        InfoCard(
          label: 'Total Spent',
          value: money(widget.total),
          icon: Icons.trending_down,
          color: Colors.orange,
        ),
        InfoCard(
          label: 'Remaining Balance',
          value: money(widget.budget - widget.total),
          icon: Icons.savings,
          color: Colors.green,
        ),
        const SizedBox(height: 20),
        Text(
          '${(ratio * 100).toStringAsFixed(1)}% used',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 10),
        LinearProgressIndicator(
          value: ratio.clamp(0.0, 1.0),
          minHeight: 14,
          borderRadius: BorderRadius.circular(10),
          color: ratio >= 0.9
              ? Colors.red
              : ratio >= 0.7
                  ? Colors.orange
                  : Colors.green,
        ),
        const SizedBox(height: 25),
        const SectionTitle('Update Your Budget'),
        TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(
            decimal: true,
          ),
          decoration: const InputDecoration(
            labelText: 'New Budget (RM)',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 15),
        FilledButton(
          onPressed: () {
            final value = double.tryParse(controller.text);
            if (value == null || !value.isFinite || value <= 0) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Please enter a valid budget'),
                ),
              );
              return;
            }
            widget.onUpdate(value);
            controller.clear();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Budget updated!')),
            );
          },
          child: const Text('Save Budget'),
        ),
      ],
    );
  }
}

class ReportsPage extends StatelessWidget {
  final List<Expense> expenses;

  const ReportsPage({
    super.key,
    required this.expenses,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final current = expenses.where((e) =>
        e.date.month == now.month &&
        e.date.year == now.year).toList();

    final totals = <String, double>{};
    for (final expense in current) {
      totals.update(
        expense.category,
        (value) => value + expense.amount,
        ifAbsent: () => expense.amount,
      );
    }

    final total = current.fold(
      0.0,
      (double sum, Expense e) => sum + e.amount,
    );

    final sorted = totals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const SectionTitle('Spending Reports'),
        Text(
          '${monthName(now.month)} ${now.year}',
          style: const TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 15),
        InfoCard(
          label: 'Total Monthly Expenses',
          value: money(total),
          icon: Icons.analytics,
        ),
        InfoCard(
          label: 'Transactions',
          value: '${current.length}',
          icon: Icons.receipt_long,
        ),
        const SizedBox(height: 25),
        const SectionTitle('Spending by Category'),
        if (sorted.isEmpty)
          const Text(
            'No data available. Add expenses to see your report.',
            style: TextStyle(color: Colors.grey),
          ),
        ...sorted.map((entry) {
          final share = total > 0 ? entry.value / total : 0.0;
          return Card(
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text(entry.key)),
                      Text(
                        money(entry.value),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  LinearProgressIndicator(
                    value: share,
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(8),
                    color: royalBlue,
                    backgroundColor: Colors.blue.shade50,
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '${(share * 100).toStringAsFixed(1)}%',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}

class PredictionPage extends StatelessWidget {
  const PredictionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const SectionTitle('AI Spending Prediction'),
        const SizedBox(height: 15),
        Card(
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(25),
            child: Column(
              children: [
                const Icon(
                  Icons.auto_graph,
                  size: 75,
                  color: royalBlue,
                ),
                const SizedBox(height: 20),
                const Text(
                  'Next Month Prediction',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 15),
                const Text(
                  'Prediction not available yet',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(height: 15),
                const Text(
                  'The machine learning backend is not '
                  'connected yet. Continue recording your '
                  'expenses. Predictions will be available '
                  'after the model is implemented and '
                  'sufficient historical data is collected.',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 25),
        const SectionTitle('Planned Prediction Models'),
        const ListTile(
          leading: Icon(Icons.show_chart, color: royalBlue),
          title: Text('Moving Average'),
          subtitle: Text('Baseline forecasting method'),
        ),
        const ListTile(
          leading: Icon(Icons.timeline, color: royalBlue),
          title: Text('Linear Regression'),
          subtitle: Text('Machine learning model'),
        ),
        const ListTile(
          leading: Icon(Icons.account_tree, color: royalBlue),
          title: Text('Random Forest Regression'),
          subtitle: Text('Machine learning model'),
        ),
      ],
    );
  }
}
