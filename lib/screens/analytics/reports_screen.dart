import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/expense_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/budget_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/expense_model.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/currency_utils.dart';
import '../../core/utils/date_utils.dart' as app_date_utils;
import '../../core/utils/translation_helper.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({Key? key}) : super(key: key);

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedPeriodKey = 'this_month';
  DateTime? _customStartDate;
  DateTime? _customEndDate;

  List<String> _getLocalizedPeriods(String language) => [
    TranslationHelper.getText('this_week', language),
    TranslationHelper.getText('this_month', language),
    TranslationHelper.getText('last_month', language),
    TranslationHelper.getText('this_quarter', language),
    TranslationHelper.getText('this_year', language),
    TranslationHelper.getText('last_year', language),
    TranslationHelper.getText('custom_range', language)
  ];

  final List<String> _periodKeys = [
    'this_week',
    'this_month',
    'last_month',
    'this_quarter',
    'this_year',
    'last_year',
    'custom_range'
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadReportData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadReportData() {
    final expenseProvider = Provider.of<ExpenseProvider>(context, listen: false);
    final budgetProvider = Provider.of<BudgetProvider>(context, listen: false);
    final categoryProvider = Provider.of<CategoryProvider>(context, listen: false);

    expenseProvider.loadExpenses();
    budgetProvider.loadBudgets();
    categoryProvider.loadCategories();
  }

  DateTimeRange _getDateRange() {
    final now = DateTime.now();

    switch (_selectedPeriodKey) {
      case 'this_week':
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        return DateTimeRange(
          start: DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day),
          end: now,
        );
      case 'this_month':
        return DateTimeRange(
          start: DateTime(now.year, now.month, 1),
          end: now,
        );
      case 'last_month':
        final lastMonth = DateTime(now.year, now.month - 1, 1);
        final lastDayOfLastMonth = DateTime(now.year, now.month, 0);
        return DateTimeRange(
          start: lastMonth,
          end: lastDayOfLastMonth,
        );
      case 'this_quarter':
        final quarter = ((now.month - 1) ~/ 3) + 1;
        final quarterStart = DateTime(now.year, (quarter - 1) * 3 + 1, 1);
        return DateTimeRange(
          start: quarterStart,
          end: now,
        );
      case 'this_year':
        return DateTimeRange(
          start: DateTime(now.year, 1, 1),
          end: now,
        );
      case 'last_year':
        return DateTimeRange(
          start: DateTime(now.year - 1, 1, 1),
          end: DateTime(now.year - 1, 12, 31),
        );
      case 'custom_range':
        if (_customStartDate != null && _customEndDate != null) {
          return DateTimeRange(start: _customStartDate!, end: _customEndDate!);
        }
        return DateTimeRange(
          start: DateTime(now.year, now.month, 1),
          end: now,
        );
      default:
        return DateTimeRange(
          start: DateTime(now.year, now.month, 1),
          end: now,
        );
    }
  }

  List<ExpenseModel> _getFilteredExpenses(List<ExpenseModel> expenses) {
    final dateRange = _getDateRange();
    return expenses.where((expense) {
      return expense.date.isAfter(dateRange.start.subtract(const Duration(days: 1))) &&
          expense.date.isBefore(dateRange.end.add(const Duration(days: 1)));
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final language = authProvider.language;
        final localizedPeriods = _getLocalizedPeriods(language);
        
        return Scaffold(
          appBar: AppBar(
            title: Text(TranslationHelper.getText('reports', language)),
            elevation: 0,
            actions: [
              PopupMenuButton<String>(
                onSelected: (value) async {
                  final index = localizedPeriods.indexOf(value);
                  final periodKey = index >= 0 ? _periodKeys[index] : 'this_month';
                  if (periodKey == 'custom_range') {
                    await _showDateRangePicker();
                  }
                  setState(() {
                    _selectedPeriodKey = periodKey;
                  });
                },
                itemBuilder: (context) => localizedPeriods
                    .map((period) => PopupMenuItem(
                  value: period,
                  child: Text(period),
                ))
                    .toList(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _selectedPeriodKey == 'custom_range' && _customStartDate != null
                            ? TranslationHelper.getText('custom', language)
                            : TranslationHelper.getText(_selectedPeriodKey, language),
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const Icon(Icons.arrow_drop_down),
                    ],
                  ),
                ),
              ),
              IconButton(
                onPressed: () => _exportReport(language),
                icon: const Icon(Icons.share),
              ),
            ],
            bottom: TabBar(
              controller: _tabController,
              tabs: [
                Tab(text: TranslationHelper.getText('summary', language)),
                Tab(text: TranslationHelper.getText('categories', language)),
                Tab(text: TranslationHelper.getText('trends', language)),
                Tab(text: TranslationHelper.getText('budget', language)),
              ],
            ),
          ),
          body: Consumer3<ExpenseProvider, CategoryProvider, BudgetProvider>(
            builder: (context, expenseProvider, categoryProvider, budgetProvider, child) {
              if (expenseProvider.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              final filteredExpenses = _getFilteredExpenses(expenseProvider.expenses);

              return TabBarView(
                controller: _tabController,
                children: [
                  _buildSummaryTab(filteredExpenses, language),
                  _buildCategoriesTab(filteredExpenses, categoryProvider, language),
                  _buildTrendsTab(filteredExpenses, language),
                  _buildBudgetTab(budgetProvider, filteredExpenses, categoryProvider, language),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildSummaryTab(List<ExpenseModel> expenses, String language) {
    // Only calculate expenses (not income) for "total spent"
    final totalSpent = expenses
        .where((expense) => expense.isExpense) // Only expenses, not income
        .fold<double>(0, (sum, expense) => sum + expense.amount);
    final totalTransactions = expenses.length;
    final averageTransaction = totalTransactions > 0 ? totalSpent / totalTransactions : 0.0;
    final dateRange = _getDateRange();
    final daysDifference = dateRange.end.difference(dateRange.start).inDays + 1;
    final dailyAverage = daysDifference > 0 ? totalSpent / daysDifference : 0.0;

    // Group by payment method
    final paymentMethods = <String, double>{};
    for (final expense in expenses) {
      final method = TranslationHelper.getText('general', language);
      paymentMethods[method] = (paymentMethods[method] ?? 0) + expense.amount;
    }

    // Get highest expenses
    final sortedExpensesList = List<ExpenseModel>.from(expenses)
      ..sort((a, b) => b.amount.compareTo(a.amount));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Period Info Card
          _buildPeriodInfoCard(language),
          const SizedBox(height: 24),

          // Key Metrics
          Text(
            TranslationHelper.getText('key_metrics', language),
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  TranslationHelper.getText('total_spent', language),
                  CurrencyUtils.formatCurrency(totalSpent),
                  Icons.account_balance_wallet,
                  AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  TranslationHelper.getText('transactions', language),
                  totalTransactions.toString(),
                  Icons.receipt_long,
                  AppColors.secondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  TranslationHelper.getText('avg_daily', language),
                  CurrencyUtils.formatCurrency(dailyAverage),
                  Icons.trending_up,
                  AppColors.accent,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  TranslationHelper.getText('avg_transaction', language),
                  CurrencyUtils.formatCurrency(averageTransaction),
                  Icons.calculate,
                  AppColors.warning,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Payment Methods
          if (paymentMethods.isNotEmpty) ...[
            Text(
              TranslationHelper.getText('payment_methods', language),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...paymentMethods.entries.map((entry) => _buildPaymentMethodItem(
              entry.key,
              entry.value,
              totalSpent,
              language,
            )),
            const SizedBox(height: 24),
          ],

          // Top Expenses
          if (sortedExpensesList.isNotEmpty) ...[
            Text(
              TranslationHelper.getText('highest_expenses', language),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...sortedExpensesList.take(5).map((expense) => _buildExpenseItem(expense, language)),
          ],
        ],
      ),
    );
  }

  Widget _buildCategoriesTab(List<ExpenseModel> expenses, CategoryProvider categoryProvider, String language) {
    final categoryTotals = <String, double>{};
    final categoryTransactions = <String, int>{};

    for (final expense in expenses) {
      categoryTotals[expense.categoryId] =
          (categoryTotals[expense.categoryId] ?? 0) + expense.amount;
      categoryTransactions[expense.categoryId] =
          (categoryTransactions[expense.categoryId] ?? 0) + 1;
    }

    final sortedCategories = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final totalSpent = categoryTotals.values.fold<double>(0, (sum, amount) => sum + amount);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Categories Overview
          _buildCategoriesOverviewCard(sortedCategories.length, totalSpent, language),
          const SizedBox(height: 24),

          // Category Breakdown
          Text(
            TranslationHelper.getText('category_breakdown', language),
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          if (sortedCategories.isEmpty)
            _buildEmptyStateCard(TranslationHelper.getText('no_expenses_found', language))
          else
            ...sortedCategories.map((entry) {
              final category = categoryProvider.getCategoryById(entry.key);
              final percentage = totalSpent > 0 ? (entry.value / totalSpent * 100) : 0.0;
              final transactionCount = categoryTransactions[entry.key] ?? 0;

              return _buildCategoryReportCard(
                category?.getLocalizedName(language) ?? TranslationHelper.getText('unknown', language),
                category?.icon as IconData?,
                entry.value,
                percentage,
                transactionCount,
                language,
              );
            }),
        ],
      ),
    );
  }

  Widget _buildTrendsTab(List<ExpenseModel> expenses, String language) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            TranslationHelper.getText('spending_trend', language),
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          if (expenses.isEmpty)
            _buildEmptyStateCard(TranslationHelper.getText('no_data_available', language))
          else
            Container(
              height: 200,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  '${TranslationHelper.getText('trend_chart', language)}\n(${TranslationHelper.getText('chart_implementation_needed', language)})',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBudgetTab(BudgetProvider budgetProvider, List<ExpenseModel> expenses, CategoryProvider categoryProvider, String language) {
    final budgets = budgetProvider.budgets;
    final categorySpending = <String, double>{};

    for (final expense in expenses) {
      categorySpending[expense.categoryId] =
          (categorySpending[expense.categoryId] ?? 0) + expense.amount;
    }

    final totalBudget = budgets.fold<double>(0, (sum, budget) => sum + budget.amount);
    final totalSpent = categorySpending.values.fold<double>(0, (sum, amount) => sum + amount);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Budget Overview
          _buildBudgetOverviewCard(totalBudget, totalSpent, language),
          const SizedBox(height: 24),

          // Budget Performance
          Text(
            TranslationHelper.getText('budget_progress', language),
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          if (budgets.isEmpty)
            _buildEmptyStateCard(TranslationHelper.getText('no_budgets_set', language))
          else
            ...budgets.map((budget) {
              final category = categoryProvider.getCategoryById(budget.categoryId);
              final spent = categorySpending[budget.categoryId] ?? 0;
              final remaining = budget.amount - spent;
              final percentage = budget.amount > 0 ? (spent / budget.amount * 100).clamp(0, 100) : 0.0;

              return _buildBudgetReportCard(
                category?.getLocalizedName(language) ?? TranslationHelper.getText('unknown', language),
                category?.icon as IconData?,
                budget.amount.toDouble(),
                spent.toDouble(),
                remaining.toDouble(),
                percentage.toDouble(),
                language,
              );
            }),
        ],
      ),
    );
  }

  Widget _buildPeriodInfoCard(String language) {
    final dateRange = _getDateRange();
    final daysDifference = dateRange.end.difference(dateRange.start).inDays + 1;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary.withOpacity(0.8), AppColors.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            TranslationHelper.getText('report_period', language),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      TranslationHelper.getText('from', language),
                      style: const TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    Text(
                      app_date_utils.AppDateUtils.formatDate(dateRange.start, language),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
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
                      TranslationHelper.getText('to', language),
                      style: const TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    Text(
                      app_date_utils.AppDateUtils.formatDate(dateRange.end, language),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
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
                      TranslationHelper.getText('duration', language),
                      style: const TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    Text(
                      '$daysDifference ${daysDifference == 1 ? TranslationHelper.getText('day', language) : TranslationHelper.getText('days', language)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
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

  Widget _buildPaymentMethodItem(String method, double amount, double total, String language) {
    final percentage = total > 0 ? (amount / total * 100) : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            Icons.payment,
            color: AppColors.primary,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  method,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${percentage.toStringAsFixed(1)}% ${TranslationHelper.getText('of_total', language)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          Text(
            CurrencyUtils.formatCurrency(amount),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpenseItem(ExpenseModel expense, String language) {
    return Consumer<CategoryProvider>(
      builder: (context, categoryProvider, child) {
        final category = categoryProvider.getCategoryById(expense.categoryId);

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                category?.icon != null
                    ? IconData(category!.icon as int, fontFamily: 'MaterialIcons')
                    : Icons.receipt,
                color: AppColors.primary,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      (expense.description != null && expense.description!.isNotEmpty)
                          ? expense.description!
                          : category?.getLocalizedName(language) ?? TranslationHelper.getText('unknown', language),
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    Text(
                      app_date_utils.AppDateUtils.formatDate(expense.date, language),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                CurrencyUtils.formatCurrency(expense.amount),
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.error,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCategoriesOverviewCard(int categoryCount, double totalSpent, String language) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.secondary.withOpacity(0.8), AppColors.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  TranslationHelper.getText('categories_used', language),
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
                Text(
                  categoryCount.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
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
                  TranslationHelper.getText('total_spent', language),
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
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
        ],
      ),
    );
  }

  Widget _buildCategoryReportCard(String name, IconData? icon, double amount, double percentage, int transactions, String language) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                icon ?? Icons.category,
                color: AppColors.primary,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '$transactions ${transactions == 1 ? TranslationHelper.getText('transaction', language) : TranslationHelper.getText('transactions', language)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    CurrencyUtils.formatCurrency(amount),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${percentage.toStringAsFixed(1)}%',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: percentage / 100,
            backgroundColor: Theme.of(context).dividerColor.withOpacity(0.3),
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            minHeight: 4,
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetOverviewCard(double totalBudget, double totalSpent, String language) {
    final remaining = totalBudget - totalSpent;
    final percentage = totalBudget > 0 ? (totalSpent / totalBudget * 100).clamp(0, 100) : 0.0;
    final isOverBudget = totalSpent > totalBudget;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isOverBudget
              ? [AppColors.error.withOpacity(0.8), AppColors.error]
              : [AppColors.success.withOpacity(0.8), AppColors.success],
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
                    Text(
                      TranslationHelper.getText('total_budget', language),
                      style: const TextStyle(color: Colors.white70, fontSize: 14),
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
                    Text(
                      TranslationHelper.getText('spent', language),
                      style: const TextStyle(color: Colors.white70, fontSize: 14),
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
                      isOverBudget ? TranslationHelper.getText('over_budget', language) : TranslationHelper.getText('remaining', language),
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
            value: percentage / 100,
            backgroundColor: Colors.white.withOpacity(0.3),
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            minHeight: 4,
          ),
          const SizedBox(height: 8),
          Text(
            '${percentage.toStringAsFixed(1)}% ${TranslationHelper.getText('of_budget_used', language)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetReportCard(String name, IconData? icon, double budget, double spent, double remaining, double percentage, String language) {
    final isOverBudget = spent > budget;
    final color = isOverBudget ? AppColors.error :
    percentage > 80 ? AppColors.warning : AppColors.success;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                icon ?? Icons.category,
                color: color,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                '${percentage.toStringAsFixed(0)}%',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: color,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    TranslationHelper.getText('budget', language),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
                    ),
                  ),
                  Text(
                    CurrencyUtils.formatCurrency(budget),
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    TranslationHelper.getText('spent', language),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
                    ),
                  ),
                  Text(
                    CurrencyUtils.formatCurrency(spent),
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    isOverBudget ? TranslationHelper.getText('over', language) : TranslationHelper.getText('remaining', language),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
                    ),
                  ),
                  Text(
                    CurrencyUtils.formatCurrency(remaining.abs()),
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isOverBudget ? AppColors.error : AppColors.success,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: (percentage / 100).clamp(0.0, 1.0),
            backgroundColor: Theme.of(context).dividerColor.withOpacity(0.3),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 4,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyStateCard(String message) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.info_outline,
              size: 48,
              color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.4),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showDateRangePicker() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _customStartDate != null && _customEndDate != null
          ? DateTimeRange(start: _customStartDate!, end: _customEndDate!)
          : null,
    );

    if (picked != null) {
      setState(() {
        _customStartDate = picked.start;
        _customEndDate = picked.end;
      });
    }
  }

  void _exportReport(String language) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(TranslationHelper.getText('export_functionality_will_be_implemented', language)),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}