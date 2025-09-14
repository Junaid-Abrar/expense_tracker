import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/expense_model.dart';
import '../../models/category_model.dart';
import '../../providers/expense_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/utils/currency_utils.dart';
import '../../core/utils/date_utils.dart';
import '../../core/constants/app_colors.dart';
import '../../widgets/common/loading_widget.dart';
import '../expenses/add_expense_screen.dart';

class ExpenseDetailScreen extends StatefulWidget {
  final String expenseId;

  const ExpenseDetailScreen({
    Key? key,
    required this.expenseId, required String id,
  }) : super(key: key);

  @override
  State<ExpenseDetailScreen> createState() => _ExpenseDetailScreenState();
}

class _ExpenseDetailScreenState extends State<ExpenseDetailScreen> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Consumer3<ExpenseProvider, CategoryProvider, AuthProvider>(
      builder: (context, expenseProvider, categoryProvider, authProvider, child) {
        final language = authProvider.language ?? 'en';
        final expense = expenseProvider.getExpenseById(widget.expenseId);

        if (expense == null) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Expense Details'),
            ),
            body: const Center(
              child: Text('Expense not found'),
            ),
          );
        }

        final category = categoryProvider.getCategoryById(expense.categoryId);
        final attachments = expense.attachments ?? <String>[];
        final tags = expense.tags ?? <String>[];
        final location = expense.location ?? '';

        return Scaffold(
          appBar: AppBar(
            title: const Text('Expense Details'),
            elevation: 0,
            actions: [
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () => _editExpense(context, expense),
              ),
              PopupMenuButton<String>(
                onSelected: (value) async {
                  switch (value) {
                    case 'duplicate':
                      await _duplicateExpense(context, expense);
                      break;
                    case 'delete':
                      await _deleteExpense(context, expense);
                      break;
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'duplicate',
                    child: Row(
                      children: [
                        Icon(Icons.copy, size: 20),
                        SizedBox(width: 12),
                        Text('Duplicate'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, size: 20, color: Colors.red),
                        SizedBox(width: 12),
                        Text('Delete', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          body: _isLoading
              ? const LoadingWidget()
              : SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeaderCard(context, expense, category, theme),
                const SizedBox(height: 16),
                _buildDetailsCard(context, expense, category, location, theme, language),
                const SizedBox(height: 16),
                if (expense.description != null && expense.description!.isNotEmpty)
                  _buildDescriptionCard(context, expense, theme),
                if (tags.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _buildTagsCard(context, tags, theme),
                ],
                if (attachments.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _buildAttachmentsCard(context, attachments, theme),
                ],
                const SizedBox(height: 32),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _editExpense(context, expense),
            icon: const Icon(Icons.edit),
            label: const Text('Edit'),
          ),
        );
      },
    );
  }

  Widget _buildHeaderCard(
      BuildContext context, ExpenseModel expense, CategoryModel? category, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            category != null ? Color(category.color) : AppColors.primary,
            (category != null ? Color(category.color) : AppColors.primary).withOpacity(0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: (category != null ? Color(category.color) : AppColors.primary).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              category != null ? IconData(category.icon, fontFamily: 'MaterialIcons') : Icons.shopping_bag,
              color: Colors.white,
              size: 40,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            expense.title,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            category?.name ?? 'Unknown Category',
            style: theme.textTheme.titleMedium?.copyWith(
              color: Colors.white.withOpacity(0.9),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(25),
            ),
            child: Text(
              CurrencyUtils.formatAmount(expense.amount),
              style: theme.textTheme.headlineMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsCard(
      BuildContext context, ExpenseModel expense, CategoryModel? category, String location, ThemeData theme, String language) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Details', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildDetailRow(
                icon: Icons.calendar_today, label: 'Date', value: AppDateUtils.formatDetailDate(expense.date, language), theme: theme),
            const SizedBox(height: 12),
            _buildDetailRow(
                icon: Icons.access_time, label: 'Time', value: AppDateUtils.formatTime(expense.date, language), theme: theme),
            const SizedBox(height: 12),
            _buildDetailRow(
                icon: category != null ? IconData(category.icon, fontFamily: 'MaterialIcons') : Icons.category,
                label: 'Category',
                value: category?.name ?? 'Unknown Category',
                theme: theme,
                iconColor: category != null ? Color(category.color) : null),
            if (expense.paymentMethod != null) ...[
              const SizedBox(height: 12),
              _buildDetailRow(icon: Icons.payment, label: 'Payment Method', value: expense.paymentMethod!, theme: theme),
            ],
            if (location.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildDetailRow(icon: Icons.location_on, label: 'Location', value: location, theme: theme),
            ],
            const SizedBox(height: 12),
            _buildDetailRow(
                icon: Icons.schedule, label: 'Created', value: AppDateUtils.formatDetailDate(expense.createdAt, language), theme: theme),
            if (expense.updatedAt.isAfter(expense.createdAt.add(const Duration(minutes: 1)))) ...[
              const SizedBox(height: 12),
              _buildDetailRow(icon: Icons.update, label: 'Updated', value: AppDateUtils.formatDetailDate(expense.updatedAt, language), theme: theme),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(
      {required IconData icon, required String label, required String value, required ThemeData theme, Color? iconColor}) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: (iconColor ?? AppColors.primary).withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor ?? AppColors.primary, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.6), fontWeight: FontWeight.w500)),
              const SizedBox(height: 2),
              Text(value, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDescriptionCard(BuildContext context, ExpenseModel expense, ThemeData theme) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.description, color: AppColors.primary, size: 24),
                const SizedBox(width: 8),
                Text('Description', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: theme.colorScheme.outline.withOpacity(0.2)),
              ),
              child: Text(expense.description ?? '', style: theme.textTheme.bodyMedium?.copyWith(height: 1.5)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTagsCard(BuildContext context, List<String> tags, ThemeData theme) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.tag, color: AppColors.primary, size: 24),
                const SizedBox(width: 8),
                Text('Tags', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: tags
                  .map((tag) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                ),
                child: Text(tag,
                    style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.primary, fontWeight: FontWeight.w600)),
              ))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachmentsCard(BuildContext context, List<String> attachments, ThemeData theme) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.attachment, color: AppColors.primary, size: 24),
                const SizedBox(width: 8),
                Text('Attachments', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            Column(
              children: attachments
                  .map(
                    (attachment) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: theme.colorScheme.outline.withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.insert_drive_file, color: AppColors.primary),
                      const SizedBox(width: 12),
                      Expanded(child: Text(attachment, style: theme.textTheme.bodyMedium)),
                      IconButton(
                        icon: const Icon(Icons.open_in_new),
                        onPressed: () {
                          ScaffoldMessenger.of(context)
                              .showSnackBar(const SnackBar(content: Text('Opening attachment...')));
                        },
                      ),
                    ],
                  ),
                ),
              )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  void _editExpense(BuildContext context, ExpenseModel expense) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddExpenseScreen(expense: expense),
      ),
    );
  }

  Future<void> _duplicateExpense(BuildContext context, ExpenseModel expense) async {
    setState(() => _isLoading = true);
    try {
      final expenseProvider = Provider.of<ExpenseProvider>(context, listen: false);

      await expenseProvider.addExpense(
        title: '${expense.title} (Copy)',
        description: expense.description ?? '',
        amount: expense.amount,
        categoryId: expense.categoryId,
        categoryName: expense.categoryName ?? '',
        date: DateTime.now(),
        paymentMethod: expense.paymentMethod ?? '',
        tags: expense.tags ?? [], type: '',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Expense duplicated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to duplicate expense: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteExpense(BuildContext context, ExpenseModel expense) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Expense'),
        content: Text('Are you sure you want to delete "${expense.title}"? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);
    try {
      final expenseProvider = Provider.of<ExpenseProvider>(context, listen: false);
      await expenseProvider.deleteExpense(expense.id);
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Expense deleted successfully'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete expense: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
