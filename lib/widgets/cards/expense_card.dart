import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/expense_model.dart';
import '../../models/category_model.dart';
import '../../providers/category_provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/utils/currency_utils.dart';
import '../../core/utils/date_utils.dart';
import '../../core/constants/app_colors.dart';

/// --- Helpers for converting stored strings into real Flutter objects ---
class ColorUtils {
  static Color fromHex(String? hex) {
    if (hex == null || hex.isEmpty) return AppColors.primary;
    final buffer = StringBuffer();
    if (hex.length == 6 || hex.length == 7) buffer.write('ff');
    buffer.write(hex.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }
}

class IconUtils {
  static IconData fromString(String? name) {
    switch (name) {
      case 'shopping_bag':
        return Icons.shopping_bag;
      case 'food':
        return Icons.fastfood;
      case 'home':
        return Icons.home;
      case 'car':
        return Icons.directions_car;
      case 'health':
        return Icons.health_and_safety;
      default:
        return Icons.category;
    }
  }
}

/// ---------------- Expense Card ----------------
class ExpenseCard extends StatelessWidget {
  final ExpenseModel expense;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool showActions;
  final bool isCompact;

  const ExpenseCard({
    Key? key,
    required this.expense,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.showActions = true,
    this.isCompact = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Consumer2<CategoryProvider, AuthProvider>(
      builder: (context, categoryProvider, authProvider, child) {
        final language = authProvider.language ?? 'en';
        final category = categoryProvider.getCategoryById(expense.categoryId);

        // Convert string values to real objects
        final cardColor = ColorUtils.fromHex(category?.color as String?);
        final cardIcon = IconUtils.fromString(category?.icon as String?);

        return Card(
          margin: EdgeInsets.symmetric(
            horizontal: 16,
            vertical: isCompact ? 4 : 6,
          ),
          elevation: isDark ? 8 : 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: EdgeInsets.all(isCompact ? 12 : 16),
              child: isCompact
                  ? _buildCompactCard(context, category, theme, cardColor, cardIcon, language)
                  : _buildFullCard(context, category, theme, cardColor, cardIcon, language),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCompactCard(BuildContext context, CategoryModel? category, ThemeData theme, Color cardColor, IconData cardIcon, String language) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: cardColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(cardIcon, color: cardColor, size: 20),
        ),
        const SizedBox(width: 12),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                expense.title,
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                category?.name ?? 'Unknown Category',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),

        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              CurrencyUtils.formatAmount(expense.amount),
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: expense.amount >= 0 ? Colors.green : Colors.red,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              AppDateUtils.formatDate(expense.date, language),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFullCard(BuildContext context, CategoryModel? category, ThemeData theme, Color cardColor, IconData cardIcon, String language) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: cardColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(cardIcon, color: cardColor, size: 24),
            ),
            const SizedBox(width: 16),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    expense.title,
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    category?.name ?? 'Unknown Category',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),

            if (showActions)
              PopupMenuButton<String>(
                onSelected: (value) {
                  switch (value) {
                    case 'edit':
                      onEdit?.call();
                      break;
                    case 'delete':
                      onDelete?.call();
                      break;
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit, size: 18),
                        SizedBox(width: 8),
                        Text('Edit'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, size: 18, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Delete', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
                child: const Icon(Icons.more_vert),
              ),
          ],
        ),

        const SizedBox(height: 16),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: expense.amount >= 0 ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: expense.amount >= 0 ? Colors.green.withOpacity(0.3) : Colors.red.withOpacity(0.3),
                ),
              ),
              child: Text(
                CurrencyUtils.formatAmount(expense.amount),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: expense.amount >= 0 ? Colors.green : Colors.red,
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  children: [
                    Icon(Icons.calendar_today, size: 16, color: theme.colorScheme.onSurface.withOpacity(0.6)),
                    const SizedBox(width: 4),
                    Text(
                      AppDateUtils.formatDate(expense.date, language),
                      style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.8)),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(Icons.access_time, size: 16, color: theme.colorScheme.onSurface.withOpacity(0.6)),
                    const SizedBox(width: 4),
                    Text(
                      AppDateUtils.formatTime(expense.date, language),
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.6)),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),

        if (expense.description != null && expense.description!.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: theme.colorScheme.outline.withOpacity(0.2)),
            ),
            child: Text(
              expense.description!,
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.8)),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],

        if (expense.tags != null && expense.tags!.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: expense.tags!.take(3).map((tag) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary.withOpacity(0.3)),
              ),
              child: Text(
                tag,
                style: theme.textTheme.bodySmall?.copyWith(color: AppColors.primary, fontWeight: FontWeight.w500),
              ),
            )).toList(),
          ),
        ],
      ],
    );
  }
}

/// ---------------- Simple Expense Card ----------------
class SimpleExpenseCard extends StatelessWidget {
  final ExpenseModel expense;
  final VoidCallback? onTap;

  const SimpleExpenseCard({Key? key, required this.expense, this.onTap}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Consumer2<CategoryProvider, AuthProvider>(
      builder: (context, categoryProvider, authProvider, child) {
        final language = authProvider.language ?? 'en';
        final category = categoryProvider.getCategoryById(expense.categoryId);

        final cardColor = ColorUtils.fromHex(category?.color as String?);
        final cardIcon = IconUtils.fromString(category?.icon as String?);

        return ListTile(
          onTap: onTap,
          leading: CircleAvatar(
            backgroundColor: cardColor.withOpacity(0.2),
            child: Icon(cardIcon, color: cardColor, size: 20),
          ),
          title: Text(expense.title, maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: Text('${category?.name ?? 'Unknown'} • ${AppDateUtils.formatDate(expense.date, language)}'),
          trailing: Text(
            CurrencyUtils.formatAmount(expense.amount),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: expense.amount >= 0 ? Colors.green : Colors.red,
            ),
          ),
        );
      },
    );
  }
}
