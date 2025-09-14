import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/budget_provider.dart';
import '../../providers/expense_provider.dart';
import '../../providers/category_provider.dart';
import '../../models/budget_model.dart';
import '../../models/expense_model.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/currency_utils.dart';
import '../../core/utils/translation_helper.dart';
import 'add_budget_screen.dart';

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({Key? key}) : super(key: key);

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  String _selectedPeriod = 'This Month';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void _loadData() {
    final budgetProvider = Provider.of<BudgetProvider>(context, listen: false);
    final expenseProvider = Provider.of<ExpenseProvider>(context, listen: false);

    budgetProvider.loadBudgets();
    expenseProvider.loadExpenses();
  }

  DateTime get _startDate {
    final now = DateTime.now();
    if (_selectedPeriod == 'This Month') {
      return DateTime(now.year, now.month, 1);
    } else {
      return DateTime(now.year, 1, 1);
    }
  }

  DateTime get _endDate {
    final now = DateTime.now();
    if (_selectedPeriod == 'This Month') {
      return DateTime(now.year, now.month + 1, 0);
    } else {
      return DateTime(now.year, 12, 31);
    }
  }

  Map<String, double> _calculateCategorySpending(List<ExpenseModel> expenses) {
    final categorySpending = <String, double>{};

    final filteredExpenses = expenses.where((expense) {
      // Only include actual expenses (not income) and filter by date range
      return expense.isExpense &&
          expense.date.isAfter(_startDate.subtract(const Duration(days: 1))) &&
          expense.date.isBefore(_endDate.add(const Duration(days: 1)));
    }).toList();

    for (final expense in filteredExpenses) {
      categorySpending[expense.categoryId] =
          (categorySpending[expense.categoryId] ?? 0) + expense.amount;
    }

    return categorySpending;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final language = authProvider.getPreference<String>('app_language', 'en');

        // Helper function for translations
        String getText(String key) => TranslationHelper.getText(key, language);

        // Translated periods
        final periods = [
          {'key': 'this_month', 'value': 'This Month'},
          {'key': 'this_year', 'value': 'This Year'}
        ];

        return Scaffold(
          appBar: AppBar(
            title: Text(getText('budget')),
            elevation: 0,
            actions: [
              PopupMenuButton<String>(
                onSelected: (value) {
                  setState(() {
                    _selectedPeriod = value;
                  });
                },
                itemBuilder: (context) => periods
                    .map((period) => PopupMenuItem(
                  value: period['value']!,
                  child: Text(getText(period['key']!)),
                ))
                    .toList(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _selectedPeriod == 'This Month'
                            ? getText('this_month')
                            : getText('this_year'),
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const Icon(Icons.arrow_drop_down),
                    ],
                  ),
                ),
              ),
            ],
          ),
          body: Consumer3<BudgetProvider, ExpenseProvider, CategoryProvider>(
            builder: (context, budgetProvider, expenseProvider, categoryProvider, child) {
              if (budgetProvider.isLoading || expenseProvider.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              final budgets = budgetProvider.budgets.where((budget) {
                return budget.period == _selectedPeriod.toLowerCase().replaceAll(' ', '_');
              }).toList();

              final categorySpending = _calculateCategorySpending(expenseProvider.expenses);
              final totalBudget = budgets.fold<double>(0, (sum, budget) => sum + budget.amount);
              
              // Only include spending for categories that have budgets
              final totalSpent = budgets.fold<double>(0, (sum, budget) {
                final spent = categorySpending[budget.categoryId] ?? 0;
                return sum + spent;
              });

              return CustomScrollView(
                slivers: [
                  // Overview Section
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildOverviewCard(totalBudget, totalSpent, getText, authProvider),
                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                getText('budget_categories'),
                                style: Theme.of(context).textTheme.headlineSmall,
                              ),
                              TextButton.icon(
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) => const AddBudgetScreen(),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.add),
                                label: Text(getText('add_budget')),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),

                  // Budget List
                  budgets.isEmpty
                      ? SliverFillRemaining(
                    child: _buildEmptyState(getText),
                  )
                      : SliverList(
                    delegate: SliverChildBuilderDelegate(
                          (context, index) {
                        final budget = budgets[index];
                        final spent = categorySpending[budget.categoryId] ?? 0;
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16.0,
                            vertical: 8.0,
                          ),
                          child: _buildBudgetCard(budget, spent, categoryProvider, getText, authProvider),
                        );
                      },
                      childCount: budgets.length,
                    ),
                  ),

                  // Suggestions Section
                  if (budgets.isNotEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              getText('budget_insights'),
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                            const SizedBox(height: 16),
                            _buildInsights(budgets, categorySpending, getText),
                          ],
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const AddBudgetScreen(),
                ),
              );
            },
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }

  Widget _buildOverviewCard(double totalBudget, double totalSpent, String Function(String) getText, AuthProvider authProvider) {
    final remaining = totalBudget - totalSpent;
    final progressPercentage = totalBudget > 0 ? (totalSpent / totalBudget).clamp(0.0, 1.0) : 0.0;
    final isOverBudget = totalSpent > totalBudget;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isOverBudget
              ? [AppColors.error.withOpacity(0.8), AppColors.error]
              : [AppColors.primary.withOpacity(0.8), AppColors.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: (isOverBudget ? AppColors.error : AppColors.primary).withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isOverBudget ? Icons.warning : Icons.account_balance_wallet,
                color: Colors.white,
                size: 28,
              ),
              const SizedBox(width: 12),
              Text(
                '${_selectedPeriod == 'This Month' ? getText('this_month') : getText('this_year')} ${getText('budget_overview')}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      getText('total_budget'),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        authProvider.userModel?.formatCurrency(totalBudget) ?? '\$${totalBudget.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    )
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      getText('spent'),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        authProvider.userModel?.formatCurrency(totalSpent) ?? '\$${totalSpent.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    )
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        isOverBudget ? getText('over_budget') : getText('remaining'),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                      ),
                    ),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        authProvider.userModel?.formatCurrency(remaining.abs()) ?? '\$${remaining.abs().toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    )
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Progress Bar
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    getText('budget_progress'),
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    '${(progressPercentage * 100).toStringAsFixed(1)}%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: progressPercentage,
                backgroundColor: Colors.white.withOpacity(0.3),
                valueColor: AlwaysStoppedAnimation<Color>(
                  isOverBudget ? Colors.white : Colors.white.withOpacity(0.9),
                ),
                minHeight: 6,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetCard(BudgetModel budget, double spent, CategoryProvider categoryProvider, String Function(String) getText, AuthProvider authProvider) {
    final category = categoryProvider.getCategoryById(budget.categoryId);
    final progressPercentage = budget.amount > 0 ? (spent / budget.amount).clamp(0.0, 1.0) : 0.0;
    final remaining = budget.amount - spent;
    final isOverBudget = spent > budget.amount;

    Color progressColor;
    if (isOverBudget) {
      progressColor = AppColors.error;
    } else if (progressPercentage > 0.8) {
      progressColor = AppColors.warning;
    } else {
      progressColor = AppColors.success;
    }

    return Card(
      margin: EdgeInsets.zero,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showBudgetDetails(budget, spent, category?.getLocalizedName(authProvider.getPreference<String>('app_language', 'en')) ?? getText('unknown_category'), getText, authProvider),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: progressColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      category?.iconData ?? Icons.category,
                      color: progressColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          category?.getLocalizedName(authProvider.getPreference<String>('app_language', 'en')) ?? getText('unknown_category'),
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          budget.period == 'this_month' ? getText('monthly') : getText('yearly'),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') {
                        _editBudget(budget);
                      } else if (value == 'delete') {
                        _deleteBudget(budget, getText);
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'edit',
                        child: Text(getText('edit_budget')),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Text(getText('delete_budget')),
                      ),
                    ],
                    child: Icon(
                      Icons.more_vert,
                      color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          getText('spent'),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
                          ),
                        ),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            authProvider.userModel?.formatCurrency(spent) ?? '\$${spent.toStringAsFixed(2)}',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: progressColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          getText('budget'),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
                          ),
                        ),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            authProvider.userModel?.formatCurrency(budget.amount) ?? '\$${budget.amount.toStringAsFixed(2)}',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isOverBudget
                            ? '${getText('over_by')} ${authProvider.userModel?.formatCurrency(remaining.abs()) ?? '\$${remaining.abs().toStringAsFixed(2)}'}'
                            : '${getText('remaining')} ${authProvider.userModel?.formatCurrency(remaining) ?? '\$${remaining.toStringAsFixed(2)}'}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: progressColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${(progressPercentage * 100).toStringAsFixed(1)}%',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: progressColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: progressPercentage,
                    backgroundColor: Theme.of(context).dividerColor.withOpacity(0.3),
                    valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                    minHeight: 4,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(String Function(String) getText) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.account_balance_wallet_outlined,
              size: 80,
              color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.4),
            ),
            const SizedBox(height: 24),
            Text(
              getText('no_budget_set'),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              getText('create_first_budget'),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const AddBudgetScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.add),
              label: Text(getText('create_budget')),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInsights(List<BudgetModel> budgets, Map<String, double> categorySpending, String Function(String) getText) {
    final insights = <Widget>[];

    // Over-budget categories
    final overBudgetCategories = budgets.where((budget) {
      final spent = categorySpending[budget.categoryId] ?? 0;
      return spent > budget.amount;
    }).toList();

    if (overBudgetCategories.isNotEmpty) {
      insights.add(_buildInsightCard(
        getText('over_budget_alert'),
        '${overBudgetCategories.length} ${overBudgetCategories.length == 1 ? getText('category_is') : getText('categories_are')} ${getText('over_budget')}',
        Icons.warning,
        AppColors.error,
      ));
    }

    // Categories close to budget limit
    final nearLimitCategories = budgets.where((budget) {
      final spent = categorySpending[budget.categoryId] ?? 0;
      final percentage = budget.amount > 0 ? spent / budget.amount : 0;
      return percentage >= 0.8 && percentage < 1.0;
    }).toList();

    if (nearLimitCategories.isNotEmpty) {
      insights.add(_buildInsightCard(
        getText('approaching_limit'),
        '${nearLimitCategories.length} ${nearLimitCategories.length == 1 ? getText('category_is') : getText('categories_are')} ${getText('near_budget_limit')}',
        Icons.trending_up,
        AppColors.warning,
      ));
    }

    // Well within budget
    final safeCategories = budgets.where((budget) {
      final spent = categorySpending[budget.categoryId] ?? 0;
      final percentage = budget.amount > 0 ? spent / budget.amount : 0;
      return percentage < 0.5;
    }).toList();

    if (safeCategories.isNotEmpty) {
      insights.add(_buildInsightCard(
        getText('on_track'),
        '${safeCategories.length} ${safeCategories.length == 1 ? getText('category_is') : getText('categories_are')} ${getText('well_within_budget')}',
        Icons.check_circle,
        AppColors.success,
      ));
    }

    if (insights.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(children: insights);
  }

  Widget _buildInsightCard(String title, String description, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showBudgetDetails(BudgetModel budget, double spent, String categoryName, String Function(String) getText, AuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(categoryName),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow(getText('budget_amount'), authProvider.userModel?.formatCurrency(budget.amount) ?? '\$${budget.amount.toStringAsFixed(2)}'),
            _buildDetailRow(getText('amount_spent'), authProvider.userModel?.formatCurrency(spent) ?? '\$${spent.toStringAsFixed(2)}'),
            _buildDetailRow(getText('remaining'), authProvider.userModel?.formatCurrency(budget.amount - spent) ?? '\$${(budget.amount - spent).toStringAsFixed(2)}'),
            _buildDetailRow(getText('budget_period'), budget.period == 'this_month' ? getText('monthly') : getText('yearly')),
            if (budget.notes?.isNotEmpty == true) ...[
              const SizedBox(height: 12),
              Text('${getText('notes')}:', style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(budget.notes!),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(getText('close')),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _editBudget(budget);
            },
            child: Text(getText('edit')),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(value),
        ],
      ),
    );
  }

  void _editBudget(BudgetModel budget) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AddBudgetScreen(budget: budget),
      ),
    );
  }

  void _deleteBudget(BudgetModel budget, String Function(String) getText) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(getText('delete_budget')),
        content: Text(getText('delete_budget_confirmation')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(getText('cancel')),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Provider.of<BudgetProvider>(context, listen: false)
                  .deleteBudget(budget.id);
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: Text(getText('delete')),
          ),
        ],
      ),
    );
  }
}