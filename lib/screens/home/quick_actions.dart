import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/utils/translation_helper.dart';
import '../../providers/expense_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/category_model.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/currency_utils.dart';
import '../expenses/add_expense_screen.dart';
import '../budget/budget_screen.dart';
import '../analytics/analytics_screen.dart';
import '../categories/category_screen.dart';

class QuickActions extends StatelessWidget {
  const QuickActions({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Quick Actions Title
        Consumer<AuthProvider>(
          builder: (context, authProvider, child) {
            final language = authProvider.getPreference<String>('app_language', 'en');
            return Text(
              TranslationHelper.getText('quick_actions', language),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            );
          },
        ),
        const SizedBox(height: 16),

        // Primary Actions Row
        Row(
          children: [
            Expanded(
              child: Consumer<AuthProvider>(
                builder: (context, authProvider, child) {
                  final language = authProvider.getPreference<String>('app_language', 'en');
                  return _buildPrimaryActionCard(
                    context,
                    TranslationHelper.getText('add_expense', language),
                    TranslationHelper.getText('track_spending', language),
                    Icons.add_circle,
                    AppColors.primary,
                        () => _navigateToAddExpense(context),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Consumer<AuthProvider>(
                builder: (context, authProvider, child) {
                  final language = authProvider.getPreference<String>('app_language', 'en');
                  return _buildPrimaryActionCard(
                    context,
                    TranslationHelper.getText('view_budget', language),
                    TranslationHelper.getText('check_progress', language),
                    Icons.account_balance_wallet,
                    AppColors.secondary,
                        () => _navigateToBudget(context),
                  );
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Secondary Actions Row
        Row(
          children: [
            Expanded(
              child: Consumer<AuthProvider>(
                builder: (context, authProvider, child) {
                  final language = authProvider.getPreference<String>('app_language', 'en');
                  return _buildSecondaryActionCard(
                    context,
                    TranslationHelper.getText('analytics', language),
                    Icons.analytics,
                    AppColors.accent,
                        () => _navigateToAnalytics(context),
                  );
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Consumer<AuthProvider>(
                builder: (context, authProvider, child) {
                  final language = authProvider.getPreference<String>('app_language', 'en');
                  return _buildSecondaryActionCard(
                    context,
                    TranslationHelper.getText('categories', language),
                    Icons.category,
                    AppColors.warning,
                        () => _navigateToCategories(context),
                  );
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Consumer<AuthProvider>(
                builder: (context, authProvider, child) {
                  final language = authProvider.getPreference<String>('app_language', 'en');
                  return _buildSecondaryActionCard(
                    context,
                    TranslationHelper.getText('quick_add', language),
                    Icons.flash_on,
                    AppColors.success,
                        () => _showQuickAddDialog(context),
                  );
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Quick Add Categories
        _buildQuickAddCategories(context),
      ],
    );
  }

  Widget _buildPrimaryActionCard(
      BuildContext context,
      String title,
      String subtitle,
      IconData icon,
      Color color,
      VoidCallback onTap,
      ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withOpacity(0.8), color],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Colors.white, size: 32),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecondaryActionCard(
      BuildContext context,
      String title,
      IconData icon,
      Color color,
      VoidCallback onTap,
      ) {
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
            Icon(icon, color: color, size: 28),
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

  Widget _buildQuickAddCategories(BuildContext context) {
    return Consumer<CategoryProvider>(
      builder: (context, categoryProvider, child) {
        final categories = categoryProvider.categories.take(5).toList();

        if (categories.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Consumer<AuthProvider>(
              builder: (context, authProvider, child) {
                final language = authProvider.getPreference<String>('app_language', 'en');
                return Text(
                  TranslationHelper.getText('quick_add_by_category', language),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 80,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final category = categories[index];
                  return Container(
                    margin: EdgeInsets.only(
                      right: index < categories.length - 1 ? 12 : 0,
                    ),
                    child: _buildQuickCategoryCard(context, category),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildQuickCategoryCard(BuildContext context, CategoryModel category) {
    return InkWell(
      onTap: () => _showQuickExpenseDialog(context, category),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 70,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).dividerColor.withOpacity(0.5),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              IconData(category.icon, fontFamily: 'MaterialIcons'),
              color: Color(category.color),
              size: 24,
            ),
            const SizedBox(height: 8),
            Consumer<AuthProvider>(
              builder: (context, authProvider, child) {
                final language = authProvider.getPreference<String>('app_language', 'en');
                return Text(
                  category.getLocalizedName(language),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToAddExpense(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const AddExpenseScreen()),
    );
  }

  void _navigateToBudget(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const BudgetScreen()),
    );
  }

  void _navigateToAnalytics(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const AnalyticsScreen()),
    );
  }

  void _navigateToCategories(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const CategoryScreen()),
    );
  }

  void _showQuickAddDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => QuickAddBottomSheet(),
    );
  }

  void _showQuickExpenseDialog(BuildContext context, CategoryModel category) {
    final amountController = TextEditingController();
    final descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              IconData(category.icon, fontFamily: 'MaterialIcons'),
              color: Color(category.color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Consumer<AuthProvider>(
                builder: (context, authProvider, child) {
                  final language = authProvider.getPreference<String>('app_language', 'en');
                  return Text('${TranslationHelper.getText('add_transaction', language)} - ${category.getLocalizedName(language)}');
                },
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Amount',
                prefixText: '\$ ',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              decoration: InputDecoration(
                labelText: 'Description (Optional)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (amountController.text.isNotEmpty) {
                final amt = double.tryParse(amountController.text) ?? 0;
                _addQuickExpense(context, category, amt, descriptionController.text.trim());
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _addQuickExpense(
      BuildContext context,
      CategoryModel category,
      double amount,
      String description,
      ) async {
    if (amount <= 0) return;

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final language = authProvider.getPreference<String>('app_language', 'en');
      final expenseProvider = Provider.of<ExpenseProvider>(context, listen: false);

      final success = await expenseProvider.addExpense(
        title: description.isEmpty ? category.getLocalizedName(language) : description,
        description: description.isEmpty ? 'Quick expense for ${category.getLocalizedName(language)}' : description,
        amount: amount,
        categoryId: category.id,
        categoryName: category.getLocalizedName(language),
        date: DateTime.now(),
        type: 'expense',
      );

      Navigator.of(context).pop();

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${CurrencyUtils.formatCurrency(amount)} added to ${category.getLocalizedName(language)}',
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: const [
                Icon(Icons.error, color: Colors.white),
                SizedBox(width: 8),
                Expanded(child: Text('Failed to add expense')),
              ],
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: Text('Failed to add expense: ${e.toString()}')),
            ],
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

// -------------------- QuickAddBottomSheet Class --------------------
class QuickAddBottomSheet extends StatefulWidget {
  const QuickAddBottomSheet({Key? key}) : super(key: key);

  @override
  State<QuickAddBottomSheet> createState() => _QuickAddBottomSheetState();
}

class _QuickAddBottomSheetState extends State<QuickAddBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();

  CategoryModel? _selectedCategory;
  bool _isLoading = false;

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          Consumer<AuthProvider>(
            builder: (context, authProvider, child) {
              final language = authProvider.getPreference<String>('app_language', 'en');
              return Text(
                TranslationHelper.getText('quick_add_expense', language),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              );
            },
          ),
          const SizedBox(height: 24),

          Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Amount',
                    prefixText: '\$ ',
                    prefixIcon: const Icon(Icons.attach_money),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Please enter amount';
                    final amount = double.tryParse(value);
                    if (amount == null || amount <= 0) return 'Please enter a valid amount';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                Consumer<CategoryProvider>(
                  builder: (context, categoryProvider, child) {
                    return DropdownButtonFormField<CategoryModel>(
                      value: _selectedCategory,
                      decoration: InputDecoration(
                        labelText: 'Category',
                        prefixIcon: const Icon(Icons.category),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      items: categoryProvider.categories.map((category) {
                        return DropdownMenuItem<CategoryModel>(
                          value: category,
                          child: Row(
                            children: [
                              Icon(
                                IconData(category.icon, fontFamily: 'MaterialIcons'),
                                color: Color(category.color),
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Consumer<AuthProvider>(
                                builder: (context, authProvider, child) {
                                  final language = authProvider.getPreference<String>('app_language', 'en');
                                  return Text(category.getLocalizedName(language));
                                },
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (category) {
                        setState(() {
                          _selectedCategory = category;
                        });
                      },
                      validator: (value) {
                        if (value == null) return 'Please select a category';
                        return null;
                      },
                    );
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  decoration: InputDecoration(
                    labelText: 'Description (Optional)',
                    prefixIcon: const Icon(Icons.description),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isLoading ? null : _addExpense,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Add Expense', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _addExpense() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('Please select a category'), backgroundColor: AppColors.error),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final amount = double.parse(_amountController.text);
      final description = _descriptionController.text.trim();
      
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final language = authProvider.getPreference<String>('app_language', 'en');
      final expenseProvider = Provider.of<ExpenseProvider>(context, listen: false);

      final success = await expenseProvider.addExpense(
        title: description.isEmpty ? _selectedCategory!.getLocalizedName(language) : description,
        description: description.isEmpty ? 'Quick expense for ${_selectedCategory!.getLocalizedName(language)}' : description,
        amount: amount,
        categoryId: _selectedCategory!.id,
        categoryName: _selectedCategory!.getLocalizedName(language),
        date: DateTime.now(),
        type: 'expense',
      );

      if (success) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text('${CurrencyUtils.formatCurrency(amount)} added to ${_selectedCategory!.getLocalizedName(language)}')),
              ],
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('Failed to add expense'), backgroundColor: AppColors.error));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add expense: ${e.toString()}'), backgroundColor: AppColors.error),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}
