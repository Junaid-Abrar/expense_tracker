import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/expense_provider.dart';
import '../../providers/budget_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/expense_model.dart';
import '../../models/budget_model.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/currency_utils.dart';
import '../../core/utils/date_utils.dart' as app_date_utils;
import '../expenses/add_expense_screen.dart';
import '../budget/budget_screen.dart';
import '../analytics/analytics_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDashboardData();
    });
  }

  void _loadDashboardData() {
    final expenseProvider = Provider.of<ExpenseProvider>(context, listen: false);
    final budgetProvider = Provider.of<BudgetProvider>(context, listen: false);
    final categoryProvider = Provider.of<CategoryProvider>(context, listen: false);

    expenseProvider.loadExpenses();
    budgetProvider.loadBudgets();
    categoryProvider.loadCategories();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          _loadDashboardData();
        },
        child: CustomScrollView(
          slivers: [
            // App Bar
            SliverAppBar(
              expandedHeight: 120,
              floating: false,
              pinned: true,
              elevation: 0,
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              flexibleSpace: FlexibleSpaceBar(
                title: Text(
                  'Dashboard',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                centerTitle: false,
                titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
              ),
            ),

            // Dashboard Content
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Quick Stats
                    _buildQuickStats(),
                    const SizedBox(height: 24),

                    // Quick Actions
                    _buildQuickActions(),
                    const SizedBox(height: 24),

                    // Budget Overview
                    _buildBudgetOverview(),
                    const SizedBox(height: 24),

                    // Recent Expenses
                    _buildRecentExpenses(),
                    const SizedBox(height: 24),

                    // Spending Insights
                    _buildSpendingInsights(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStats() {
    return Consumer<ExpenseProvider>(
      builder: (context, expenseProvider, child) {
        if (expenseProvider.isLoading) {
          return _buildStatsPlaceholder();
        }

        final now = DateTime.now();
        final thisMonthStart = DateTime(now.year, now.month, 1);
        final thisMonthExpenses = expenseProvider.expenses.where((expense) =>
            expense.date.isAfter(thisMonthStart.subtract(const Duration(days: 1)))).toList();

        final todayExpenses = expenseProvider.expenses.where((expense) =>
        expense.date.day == now.day &&
            expense.date.month == now.month &&
            expense.date.year == now.year).toList();

        final thisMonthTotal = thisMonthExpenses.fold<double>(0, (sum, expense) => sum + expense.amount);
        final todayTotal = todayExpenses.fold<double>(0, (sum, expense) => sum + expense.amount);
        final avgDaily = thisMonthTotal / now.day;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This Month',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Total Spent',
                    CurrencyUtils.formatCurrency(thisMonthTotal),
                    Icons.account_balance_wallet,
                    AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Today',
                    CurrencyUtils.formatCurrency(todayTotal),
                    Icons.today,
                    AppColors.secondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Daily Average',
                    CurrencyUtils.formatCurrency(avgDaily),
                    Icons.trending_up,
                    AppColors.accent,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Transactions',
                    thisMonthExpenses.length.toString(),
                    Icons.receipt_long,
                    AppColors.warning,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsPlaceholder() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'This Month',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildPlaceholderCard()),
            const SizedBox(width: 12),
            Expanded(child: _buildPlaceholderCard()),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildPlaceholderCard()),
            const SizedBox(width: 12),
            Expanded(child: _buildPlaceholderCard()),
          ],
        ),
      ],
    );
  }

  Widget _buildPlaceholderCard() {
    return Container(
      height: 100,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                'Add Expense',
                Icons.add_circle,
                AppColors.primary,
                    () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const AddExpenseScreen(),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                'View Budget',
                Icons.account_balance_wallet,
                AppColors.secondary,
                    () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const BudgetScreen(),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                'Analytics',
                Icons.analytics,
                AppColors.accent,
                    () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const AnalyticsScreen(),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBudgetOverview() {
    return Consumer2<BudgetProvider, ExpenseProvider>(
      builder: (context, budgetProvider, expenseProvider, child) {
        if (budgetProvider.isLoading || expenseProvider.isLoading) {
          return _buildBudgetPlaceholder();
        }

        final now = DateTime.now();
        final thisMonthStart = DateTime(now.year, now.month, 1);
        final thisMonthExpenses = expenseProvider.expenses.where((expense) =>
            expense.date.isAfter(thisMonthStart.subtract(const Duration(days: 1)))).toList();

        final monthlyBudgets = budgetProvider.budgets.where((budget) =>
        budget.period == 'this_month').toList();

        if (monthlyBudgets.isEmpty) {
          return _buildNoBudgetCard();
        }

        final totalBudget = monthlyBudgets.fold<double>(0, (sum, budget) => sum + budget.amount);
        final categorySpending = <String, double>{};

        for (final expense in thisMonthExpenses) {
          categorySpending[expense.categoryId] =
              (categorySpending[expense.categoryId] ?? 0) + expense.amount;
        }

        final totalSpent = categorySpending.values.fold<double>(0, (sum, amount) => sum + amount);
        final remaining = totalBudget - totalSpent;
        final progressPercentage = totalBudget > 0 ? (totalSpent / totalBudget).clamp(0.0, 1.0) : 0.0;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Budget Overview',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const BudgetScreen(),
                      ),
                    );
                  },
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: totalSpent > totalBudget
                      ? [AppColors.error.withOpacity(0.8), AppColors.error]
                      : [AppColors.primary.withOpacity(0.8), AppColors.primary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Total Budget',
                              style: TextStyle(color: Colors.white70, fontSize: 14),
                            ),
                            Text(
                              CurrencyUtils.formatCurrency(totalBudget),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Spent',
                              style: TextStyle(color: Colors.white70, fontSize: 14),
                            ),
                            Text(
                              CurrencyUtils.formatCurrency(totalSpent),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              remaining < 0 ? 'Over Budget' : 'Remaining',
                              style: const TextStyle(color: Colors.white70, fontSize: 14),
                            ),
                            Text(
                              CurrencyUtils.formatCurrency(remaining.abs()),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  LinearProgressIndicator(
                    value: progressPercentage,
                    backgroundColor: Colors.white.withOpacity(0.3),
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                    minHeight: 4,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Progress',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                      Text(
                        '${(progressPercentage * 100).toStringAsFixed(1)}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBudgetPlaceholder() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Budget Overview',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          height: 120,
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Center(child: CircularProgressIndicator()),
        ),
      ],
    );
  }

  Widget _buildNoBudgetCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Budget Overview',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Theme.of(context).dividerColor.withOpacity(0.5),
              style: BorderStyle.solid,
            ),
          ),
          child: Column(
            children: [
              Icon(
                Icons.account_balance_wallet_outlined,
                size: 48,
                color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.4),
              ),
              const SizedBox(height: 12),
              Text(
                'No Budget Set',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Set up your monthly budget to track spending',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const BudgetScreen(),
                    ),
                  );
                },
                child: const Text('Create Budget'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRecentExpenses() {
    return Consumer<ExpenseProvider>(
      builder: (context, expenseProvider, child) {
        if (expenseProvider.isLoading) {
          return _buildRecentExpensesPlaceholder();
        }

        final recentExpenses = expenseProvider.expenses.take(5).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Expenses',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    // Navigate to expense list
                  },
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (recentExpenses.isEmpty)
              _buildNoExpensesCard()
            else
              ...recentExpenses.map((expense) => _buildExpenseItem(expense)),
          ],
        );
      },
    );
  }

  Widget _buildRecentExpensesPlaceholder() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Expenses',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ...List.generate(3, (index) =>
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              height: 72,
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ),
      ],
    );
  }

  Widget _buildNoExpensesCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 48,
            color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.4),
          ),
          const SizedBox(height: 12),
          Text(
            'No Expenses Yet',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Start tracking by adding your first expense',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpenseItem(ExpenseModel expense) {
    return Consumer2<CategoryProvider, AuthProvider>(
      builder: (context, categoryProvider, authProvider, child) {
        final language = authProvider.language ?? 'en';
        final category = categoryProvider.getCategoryById(expense.categoryId);

        final descriptionOrCategory = (expense.description?.isNotEmpty ?? false)
            ? expense.description!
            : (category?.name ?? 'Unknown');

        final iconData = category?.icon != null
            ? IconData(category!.icon!, fontFamily: 'MaterialIcons')
            : Icons.receipt;

        final color = category?.color != null
            ? Color(category!.color!)
            : Theme.of(context).primaryColor;

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  iconData,
                  color: color,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      descriptionOrCategory,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      app_date_utils.AppDateUtils.formatDate(expense.date, language),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.color
                            ?.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                CurrencyUtils.formatCurrency(expense.amount),
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: expense.amount < 0 ? AppColors.error : AppColors.success,
                ),
              ),
            ],
          ),
        );
      },
    );
  }


  Widget _buildSpendingInsights() {
    return Consumer<ExpenseProvider>(
      builder: (context, expenseProvider, child) {
        if (expenseProvider.isLoading || expenseProvider.expenses.isEmpty) {
          return const SizedBox.shrink();
        }

        final now = DateTime.now();
        final thisMonthStart = DateTime(now.year, now.month, 1);
        final lastMonthStart = DateTime(now.year, now.month - 1, 1);
        final lastMonthEnd = DateTime(now.year, now.month, 0);

        final thisMonthExpenses = expenseProvider.expenses.where((expense) =>
            expense.date.isAfter(thisMonthStart.subtract(const Duration(days: 1)))).toList();

        final lastMonthExpenses = expenseProvider.expenses.where((expense) =>
        expense.date.isAfter(lastMonthStart.subtract(const Duration(days: 1))) &&
            expense.date.isBefore(lastMonthEnd.add(const Duration(days: 1)))).toList();

        final thisMonthTotal = thisMonthExpenses.fold<double>(0, (sum, expense) => sum + expense.amount);
        final lastMonthTotal = lastMonthExpenses.fold<double>(0, (sum, expense) => sum + expense.amount);

        final difference = thisMonthTotal - lastMonthTotal;
        final percentageChange = lastMonthTotal > 0 ? (difference / lastMonthTotal * 100) : 0.0;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Spending Insights',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        difference > 0 ? Icons.trending_up : Icons.trending_down,
                        color: difference > 0 ? AppColors.error : AppColors.success,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'vs Last Month',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    difference > 0
                        ? 'You spent ${CurrencyUtils.formatCurrency(difference.abs())} more'
                        : 'You saved ${CurrencyUtils.formatCurrency(difference.abs())}',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${percentageChange.toStringAsFixed(1)}% ${difference > 0 ? 'increase' : 'decrease'} from last month',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: difference > 0 ? AppColors.error : AppColors.success,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}