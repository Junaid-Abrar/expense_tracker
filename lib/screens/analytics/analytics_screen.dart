import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../providers/auth_provider.dart';
import '../../providers/expense_provider.dart';
import '../../providers/category_provider.dart';
import '../../models/expense_model.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/currency_utils.dart';
import '../../core/utils/date_utils.dart' as app_date_utils;
import '../../core/utils/translation_helper.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({Key? key}) : super(key: key);

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedPeriod = '';

  // Get periods dynamically based on language
  List<String> _getPeriods(String language) => [
    TranslationHelper.getText('this_week', language),
    TranslationHelper.getText('this_month', language),
    TranslationHelper.getText('last_3_months', language),
    TranslationHelper.getText('this_year', language)
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Initialize _selectedPeriod with translated text
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final language = authProvider.getPreference<String>('app_language', 'en');
      _selectedPeriod = _getPeriods(language)[1]; // Default to "This Month"
      _loadAnalyticsData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadAnalyticsData() {
    final expenseProvider = Provider.of<ExpenseProvider>(context, listen: false);
    expenseProvider.loadExpenses();
  }

  DateTime _getStartDate(String language) {
    final now = DateTime.now();
    final periods = _getPeriods(language);

    if (_selectedPeriod == periods[0]) { // This Week
      return now.subtract(Duration(days: now.weekday - 1));
    } else if (_selectedPeriod == periods[1]) { // This Month
      return DateTime(now.year, now.month, 1);
    } else if (_selectedPeriod == periods[2]) { // Last 3 Months
      return DateTime(now.year, now.month - 2, 1);
    } else if (_selectedPeriod == periods[3]) { // This Year
      return DateTime(now.year, 1, 1);
    } else {
      return DateTime(now.year, now.month, 1);
    }
  }

  List<ExpenseModel> _getFilteredExpenses(List<ExpenseModel> expenses, String language) {
    final startDate = _getStartDate(language);
    return expenses.where((expense) => expense.date.isAfter(startDate)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final language = authProvider.getPreference<String>('app_language', 'en');

        return Scaffold(
          appBar: AppBar(
            title: Text(TranslationHelper.getText('analytics', language)),
            elevation: 0,
            actions: [
              PopupMenuButton<String>(
                onSelected: (value) {
                  setState(() {
                    _selectedPeriod = value;
                  });
                },
                itemBuilder: (context) => _getPeriods(language)
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
                        _selectedPeriod.isEmpty ? _getPeriods(language)[1] : _selectedPeriod,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const Icon(Icons.arrow_drop_down),
                    ],
                  ),
                ),
              ),
            ],
            bottom: TabBar(
              controller: _tabController,
              tabs: [
                Tab(text: TranslationHelper.getText('overview', language)),
                Tab(text: TranslationHelper.getText('categories', language)),
                Tab(text: TranslationHelper.getText('trends', language)),
              ],
            ),
          ),
          body: Consumer<ExpenseProvider>(
            builder: (context, expenseProvider, child) {
              if (expenseProvider.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              final filteredExpenses = _getFilteredExpenses(expenseProvider.expenses, language);

              return TabBarView(
                controller: _tabController,
                children: [
                  _buildOverviewTab(filteredExpenses, language),
                  _buildCategoriesTab(filteredExpenses, language),
                  _buildTrendsTab(filteredExpenses, language),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildOverviewTab(List<ExpenseModel> expenses, String language) {
    // Only calculate expenses (not income) for "total spent"
    final totalSpent = expenses
        .where((expense) => expense.isExpense) // Only expenses, not income
        .fold<double>(0, (sum, expense) => sum + expense.amount);
    final avgDailySpend = totalSpent / (_getDateRange(language) ?? 1);
    final totalTransactions = expenses.length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary Cards
          Row(
            children: [
              Expanded(
                child: Consumer<AuthProvider>(
                  builder: (context, authProvider, child) {
                    return _buildSummaryCard(
                      TranslationHelper.getText('total_spent', language),
                      authProvider.userModel?.formatCurrency(totalSpent) ?? '\$${totalSpent.toStringAsFixed(2)}',
                      Icons.account_balance_wallet,
                      AppColors.error,
                    );
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Consumer<AuthProvider>(
                  builder: (context, authProvider, child) {
                    return _buildSummaryCard(
                      TranslationHelper.getText('avg_daily', language),
                      authProvider.userModel?.formatCurrency(avgDailySpend) ?? '\$${avgDailySpend.toStringAsFixed(2)}',
                      Icons.trending_up,
                      AppColors.warning,
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  TranslationHelper.getText('transactions', language),
                  totalTransactions.toString(),
                  Icons.receipt_long,
                  AppColors.primary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildSummaryCard(
                  TranslationHelper.getText('categories', language),
                  _getUniqueCategoriesCount(expenses).toString(),
                  Icons.category,
                  AppColors.secondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Spending Overview Chart
          Text(
            TranslationHelper.getText('spending_overview', language),
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          Container(
            height: 200,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: expenses.isEmpty
                ? Center(child: Text(TranslationHelper.getText('no_data_available', language)))
                : _buildSpendingChart(expenses, language),
          ),
          const SizedBox(height: 24),

          // Recent High Expenses
          Text(
            TranslationHelper.getText('highest_expenses', language),
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          _buildHighExpensesList(expenses, language),
        ],
      ),
    );
  }

  Widget _buildCategoriesTab(List<ExpenseModel> expenses, String language) {
    final categoryTotals = <String, double>{};

    // Only include expenses (not income) in category breakdown
    for (final expense in expenses.where((e) => e.isExpense)) {
      categoryTotals[expense.categoryId] =
          (categoryTotals[expense.categoryId] ?? 0) + expense.amount;
    }

    final sortedCategories = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category Pie Chart
          Container(
            height: 300,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: expenses.isEmpty
                ? Center(child: Text(TranslationHelper.getText('no_data_available', language)))
                : _buildCategoryPieChart(categoryTotals, language),
          ),
          const SizedBox(height: 24),

          // Category List
          Text(
            TranslationHelper.getText('category_breakdown', language),
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          ...sortedCategories.map((entry) => _buildCategoryTile(
            entry.key,
            entry.value,
            categoryTotals.values.fold<double>(0, (sum, amount) => sum + amount), // Use only expense totals
            language,
          )),
        ],
      ),
    );
  }

  Widget _buildTrendsTab(List<ExpenseModel> expenses, String language) {
    final dailyTotals = <DateTime, double>{};

    for (final expense in expenses) {
      final dateKey = DateTime(
        expense.date.year,
        expense.date.month,
        expense.date.day,
      );
      dailyTotals[dateKey] = (dailyTotals[dateKey] ?? 0) + expense.amount;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Trend Chart
          Text(
            TranslationHelper.getText('spending_trend', language),
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          Container(
            height: 250,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: expenses.isEmpty
                ? Center(child: Text(TranslationHelper.getText('no_data_available', language)))
                : _buildTrendChart(dailyTotals, language),
          ),
          const SizedBox(height: 24),

          // Weekly Comparison
          Text(
            TranslationHelper.getText('weekly_comparison', language),
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          _buildWeeklyComparison(expenses, language),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Container(
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
              Icon(icon, color: color, size: 24),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpendingChart(List<ExpenseModel> expenses, String language) {
    final dailyTotals = <DateTime, double>{};

    for (final expense in expenses) {
      final dateKey = DateTime(expense.date.year, expense.date.month, expense.date.day);
      dailyTotals[dateKey] = (dailyTotals[dateKey] ?? 0) + expense.amount;
    }

    if (dailyTotals.isEmpty) {
      return Center(child: Text(TranslationHelper.getText('no_data_available', language)));
    }

    final sortedEntries = dailyTotals.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: sortedEntries.map((e) => e.value).reduce((a, b) => a > b ? a : b) * 1.2,
        barTouchData: BarTouchData(enabled: true),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() < sortedEntries.length) {
                  final date = sortedEntries[value.toInt()].key;
                  return Text('${date.day}', style: const TextStyle(fontSize: 10));
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        barGroups: sortedEntries.asMap().entries.map((entry) {
          return BarChartGroupData(
            x: entry.key,
            barRods: [
              BarChartRodData(
                toY: entry.value.value,
                color: AppColors.primary,
                width: 16,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(4),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCategoryPieChart(Map<String, double> categoryTotals, String language) {
    return Consumer<CategoryProvider>(
      builder: (context, categoryProvider, child) {
        final colors = [
          AppColors.primary,
          AppColors.secondary,
          AppColors.accent,
          AppColors.warning,
          AppColors.error,
          AppColors.success,
        ];

        return Column(
          children: [
            Expanded(
              child: PieChart(
                PieChartData(
                  sections: categoryTotals.entries.map((entry) {
                    final index = categoryTotals.keys.toList().indexOf(entry.key);
                    final category = categoryProvider.getCategoryById(entry.key);

                    return PieChartSectionData(
                      value: entry.value,
                      title: '${((entry.value / categoryTotals.values.fold(0.0, (a, b) => a + b)) * 100).toStringAsFixed(1)}%',
                      color: colors[index % colors.length],
                      radius: 50,
                      titleStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: categoryTotals.entries.map((entry) {
                final index = categoryTotals.keys.toList().indexOf(entry.key);
                final category = categoryProvider.getCategoryById(entry.key);

                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: colors[index % colors.length],
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(category?.name ?? TranslationHelper.getText('unknown', language)),
                  ],
                );
              }).toList(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTrendChart(Map<DateTime, double> dailyTotals, String language) {
    if (dailyTotals.isEmpty) {
      return Center(child: Text(TranslationHelper.getText('no_data_available', language)));
    }

    final sortedEntries = dailyTotals.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    return LineChart(
      LineChartData(
        gridData: FlGridData(show: true),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() < sortedEntries.length) {
                  final date = sortedEntries[value.toInt()].key;
                  return Text('${date.day}/${date.month}', style: const TextStyle(fontSize: 10));
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: true),
        lineBarsData: [
          LineChartBarData(
            spots: sortedEntries.asMap().entries.map((entry) {
              return FlSpot(entry.key.toDouble(), entry.value.value);
            }).toList(),
            isCurved: true,
            color: AppColors.primary,
            barWidth: 3,
            dotData: FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: AppColors.primary.withOpacity(0.3),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTile(String categoryId, double amount, double totalAmount, String language) {
    return Consumer<CategoryProvider>(
      builder: (context, categoryProvider, child) {
        final category = categoryProvider.getCategoryById(categoryId);
        final percentage = (amount / totalAmount * 100);

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
                    category?.icon != null
                        ? IconData(category!.icon as int, fontFamily: 'MaterialIcons')
                        : Icons.category,
                    color: Theme.of(context).primaryColor,
                  ),

                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      category?.getLocalizedName(language) ?? TranslationHelper.getText('unknown', language),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Consumer<AuthProvider>(
                        builder: (context, authProvider, child) {
                          return Text(
                            authProvider.userModel?.formatCurrency(amount) ?? '\$${amount.toStringAsFixed(2)}',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        },
                      ),
                      Text(
                        '${percentage.toStringAsFixed(1)}%',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: percentage / 100,
                backgroundColor: Theme.of(context).dividerColor.withOpacity(0.3),
                valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHighExpensesList(List<ExpenseModel> expenses, String language) {
    final sortedExpenses = List<ExpenseModel>.from(expenses)
      ..sort((a, b) => b.amount.compareTo(a.amount));

    final topExpenses = sortedExpenses.take(5).toList();

    if (topExpenses.isEmpty) {
      return Center(child: Text(TranslationHelper.getText('no_expenses_found', language)));
    }

    return Column(
      children: topExpenses.map((expense) => _buildExpenseTile(expense, language)).toList(),
    );
  }

  Widget _buildExpenseTile(ExpenseModel expense, String language) {
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
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      (expense.description != null && expense.description!.isNotEmpty)
                          ? expense.description!
                          : (category?.getLocalizedName(language) ?? TranslationHelper.getText('unknown', language)),
                      style: Theme.of(context).textTheme.titleSmall,
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
              Consumer<AuthProvider>(
                builder: (context, authProvider, child) {
                  return Text(
                    authProvider.userModel?.formatCurrency(expense.amount) ?? '\$${expense.amount.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.error,
                    ),
                  );
                },
              )
            ],
          ),
        );
      },
    );
  }

  Widget _buildWeeklyComparison(List<ExpenseModel> expenses, String language) {
    // Calculate weekly totals
    final weeklyTotals = <int, double>{};

    for (final expense in expenses) {
      final weekNumber = _getWeekNumber(expense.date);
      weeklyTotals[weekNumber] = (weeklyTotals[weekNumber] ?? 0) + expense.amount;
    }

    if (weeklyTotals.isEmpty) {
      return Center(child: Text(TranslationHelper.getText('no_data_available', language)));
    }

    final sortedWeeks = weeklyTotals.entries.toList()
      ..sort((a, b) => b.key.compareTo(a.key));

    return Column(
      children: sortedWeeks.take(4).map((entry) {
        final isCurrentWeek = entry.key == _getWeekNumber(DateTime.now());

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isCurrentWeek
                ? Theme.of(context).primaryColor.withOpacity(0.1)
                : Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
            border: isCurrentWeek
                ? Border.all(color: Theme.of(context).primaryColor, width: 2)
                : null,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  isCurrentWeek
                      ? TranslationHelper.getText('this_week', language)
                      : '${TranslationHelper.getText('week', language)} ${entry.key}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: isCurrentWeek ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
              Consumer<AuthProvider>(
                builder: (context, authProvider, child) {
                  return Text(
                    authProvider.userModel?.formatCurrency(entry.value) ?? '\$${entry.value.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isCurrentWeek ? Theme.of(context).primaryColor : null,
                    ),
                  );
                },
              )
            ],
          ),
        );
      }).toList(),
    );
  }

  int _getDateRange(String language) {
    final now = DateTime.now();
    final startDate = _getStartDate(language);
    return now.difference(startDate).inDays + 1;
  }

  int _getUniqueCategoriesCount(List<ExpenseModel> expenses) {
    return expenses.map((e) => e.categoryId).toSet().length;
  }

  int _getWeekNumber(DateTime date) {
    final firstDayOfYear = DateTime(date.year, 1, 1);
    final daysSinceFirstDay = date.difference(firstDayOfYear).inDays;
    return (daysSinceFirstDay / 7).ceil();
  }
}