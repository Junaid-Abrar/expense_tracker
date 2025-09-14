import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../providers/expense_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/expense_model.dart';
import '../../models/user_model.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/translation_helper.dart';

class ExpenseListScreen extends StatefulWidget {
  const ExpenseListScreen({super.key});

  @override
  State<ExpenseListScreen> createState() => _ExpenseListScreenState();
}

class _ExpenseListScreenState extends State<ExpenseListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedFilter = '';

  // Get filter options dynamically based on language
  List<String> _getFilterOptions(String language) => [
    TranslationHelper.getText('all', language),
    TranslationHelper.getText('this_week', language),
    TranslationHelper.getText('this_month', language),
    TranslationHelper.getText('this_year', language)
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Initialize filter with translated text
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final language = authProvider.getPreference<String>('app_language', 'en');
      _selectedFilter = _getFilterOptions(language)[0]; // Default to "All"

      context.read<ExpenseProvider>().loadExpenses();
      context.read<CategoryProvider>().initializeCategories();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<ExpenseModel> _getFilteredExpenses(List<ExpenseModel> expenses, String language) {
    final now = DateTime.now();
    final filterOptions = _getFilterOptions(language);

    if (_selectedFilter == filterOptions[1]) { // This Week
      final weekStart = now.subtract(Duration(days: now.weekday - 1));
      return expenses.where((e) => e.date.isAfter(weekStart)).toList();
    } else if (_selectedFilter == filterOptions[2]) { // This Month
      final monthStart = DateTime(now.year, now.month, 1);
      return expenses.where((e) => e.date.isAfter(monthStart)).toList();
    } else if (_selectedFilter == filterOptions[3]) { // This Year
      final yearStart = DateTime(now.year, 1, 1);
      return expenses.where((e) => e.date.isAfter(yearStart)).toList();
    } else {
      return expenses;
    }
  }

  void _deleteExpense(ExpenseModel expense, String language) async {
    final confirmed = await _showDeleteDialog(language);
    if (confirmed && mounted) {
      final expenseProvider = context.read<ExpenseProvider>();

      try {
        // Actually call the delete method
        final success = await expenseProvider.deleteExpense(expense.id);

        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(TranslationHelper.getText('expense_deleted_successfully', language))),
          );
          // The UI will automatically update because ExpenseProvider will notify listeners
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(TranslationHelper.getText('failed_to_delete_expense', language)),
              backgroundColor: AppColors.error,
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${TranslationHelper.getText('failed_to_delete_expense', language)}: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<bool> _showDeleteDialog(String language) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(TranslationHelper.getText('delete_expense', language)),
        content: Text(TranslationHelper.getText('delete_expense_confirmation', language)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(TranslationHelper.getText('cancel', language)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: Text(TranslationHelper.getText('delete', language)),
          ),
        ],
      ),
    ) ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        final UserModel? user = authProvider.userModel;
        final language = authProvider.getPreference<String>('app_language', 'en');

        if (user == null) {
          return const Center(child: CircularProgressIndicator());
        }

        // Update filter if language changed
        if (_selectedFilter.isEmpty) {
          _selectedFilter = _getFilterOptions(language)[0];
        }

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: AppBar(
            title: Text(TranslationHelper.getText('transactions', language)),
            backgroundColor: Colors.transparent,
            elevation: 0,
            actions: [
              PopupMenuButton<String>(
                initialValue: _selectedFilter,
                onSelected: (value) => setState(() => _selectedFilter = value),
                itemBuilder: (context) => _getFilterOptions(language)
                    .map((filter) => PopupMenuItem(value: filter, child: Text(filter)))
                    .toList(),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  margin: const EdgeInsets.only(right: 16),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_selectedFilter, style: TextStyle(color: AppColors.primary)),
                      const SizedBox(width: 4),
                      Icon(Icons.arrow_drop_down, color: AppColors.primary),
                    ],
                  ),
                ),
              ),
            ],
            bottom: TabBar(
              controller: _tabController,
              tabs: [
                Tab(text: TranslationHelper.getText('all', language)),
                Tab(text: TranslationHelper.getText('expenses', language)),
                Tab(text: TranslationHelper.getText('income', language)),
              ],
            ),
          ),
          body: Consumer<ExpenseProvider>(
            builder: (context, expenseProvider, child) {
              if (expenseProvider.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              return TabBarView(
                controller: _tabController,
                children: [
                  _buildExpenseList(_getFilteredExpenses(expenseProvider.expenses, language), user, language),
                  _buildExpenseList(
                    _getFilteredExpenses(
                      expenseProvider.expenses.where((e) => e.type == 'expense').toList(),
                      language,
                    ),
                    user,
                    language,
                  ),
                  _buildExpenseList(
                    _getFilteredExpenses(
                      expenseProvider.expenses.where((e) => e.type == 'income').toList(),
                      language,
                    ),
                    user,
                    language,
                  ),
                ],
              );
            },
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => context.push('/expenses/add'),
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }

  Widget _buildExpenseList(List<ExpenseModel> expenses, UserModel user, String language) {
    if (expenses.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              TranslationHelper.getText('no_transactions_found', language),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              TranslationHelper.getText('add_first_transaction', language),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[500],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => context.push('/expenses/add'),
              icon: const Icon(Icons.add),
              label: Text(TranslationHelper.getText('add_transaction', language)),
            ),
          ],
        ),
      );
    }

    // Group expenses by date
    final groupedExpenses = <String, List<ExpenseModel>>{};
    for (final expense in expenses) {
      final dateKey = '${expense.date.day}/${expense.date.month}/${expense.date.year}';
      groupedExpenses[dateKey] ??= [];
      groupedExpenses[dateKey]!.add(expense);
    }

    // Sort by date (newest first)
    final sortedDates = groupedExpenses.keys.toList()
      ..sort((a, b) {
        final dateA = groupedExpenses[a]!.first.date;
        final dateB = groupedExpenses[b]!.first.date;
        return dateB.compareTo(dateA);
      });

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sortedDates.length,
      itemBuilder: (context, index) {
        final dateKey = sortedDates[index];
        final dayExpenses = groupedExpenses[dateKey]!;
        final totalAmount = dayExpenses.fold<double>(
          0.0,
              (sum, expense) => sum + (expense.type == 'expense' ? -expense.amount : expense.amount),
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date header
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Text(
                    dateKey,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${totalAmount >= 0 ? '+' : ''}${context.read<AuthProvider>().formatCurrency(totalAmount.abs())}',
                    style: TextStyle(
                      color: totalAmount >= 0 ? AppColors.success : AppColors.error,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            // Expenses for this date
            ...dayExpenses.map((expense) => _buildExpenseItem(expense, user, language)),

            const SizedBox(height: 16),
          ],
        );
      },
    );
  }

  Widget _buildExpenseItem(ExpenseModel expense, UserModel user, String language) {
    return Consumer<CategoryProvider>(
      builder: (context, categoryProvider, child) {
        final category = categoryProvider.getCategoryById(expense.categoryId);

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
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
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: category?.color != null ? Color(category!.color).withOpacity(0.1) : AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                category?.icon != null ? IconData(category!.icon, fontFamily: 'MaterialIcons') : Icons.receipt,
                color: category?.color != null ? Color(category!.color) : AppColors.primary,
              ),
            ),
            title: Text(
              category?.getLocalizedName(language) ?? TranslationHelper.getText('unknown_category', language),
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: expense.description?.isNotEmpty == true
                ? Text(expense.description!)
                : null,
            trailing: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${expense.type == 'expense' ? '-' : '+'}${context.read<AuthProvider>().userModel?.formatCurrency(expense.amount) ?? '\$${expense.amount.toStringAsFixed(2)}'}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: expense.type == 'expense' ? AppColors.error : AppColors.success,
                  ),
                ),
              ],
            ),
            onTap: () => _showExpenseDetails(expense, user, language),
          ),
        );
      },
    );
  }

  void _showExpenseDetails(ExpenseModel expense, UserModel user, String language) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 50,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              TranslationHelper.getText('transaction_details', language),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            _buildDetailRow(
              TranslationHelper.getText('amount', language),
              context.read<AuthProvider>().formatCurrency(expense.amount),
            ),
            _buildDetailRow(
              TranslationHelper.getText('type', language),
              expense.type == 'expense'
                  ? TranslationHelper.getText('expense', language).toUpperCase()
                  : TranslationHelper.getText('income', language).toUpperCase(),
            ),
            _buildDetailRow(
              TranslationHelper.getText('category', language),
              expense.categoryId,
            ),
            _buildDetailRow(
              TranslationHelper.getText('date', language),
              '${expense.date.day}/${expense.date.month}/${expense.date.year}',
            ),
            if (expense.description?.isNotEmpty == true)
              _buildDetailRow(
                TranslationHelper.getText('description', language),
                expense.description!,
              ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      // Navigate to edit screen
                    },
                    child: Text(TranslationHelper.getText('edit', language)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _deleteExpense(expense, language);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.error,
                    ),
                    child: Text(TranslationHelper.getText('delete', language)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}