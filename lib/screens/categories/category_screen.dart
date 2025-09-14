import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/expense_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/category_model.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/currency_utils.dart';
import '../../core/utils/translation_helper.dart';
import 'add_category_screen.dart';

class CategoryScreen extends StatefulWidget {
  const CategoryScreen({Key? key}) : super(key: key);

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadData() {
    final categoryProvider = Provider.of<CategoryProvider>(context, listen: false);
    final expenseProvider = Provider.of<ExpenseProvider>(context, listen: false);

    categoryProvider.loadCategories();
    expenseProvider.loadExpenses();
  }

  List<CategoryModel> _getFilteredCategories(List<CategoryModel> categories, String language) {
    if (_searchQuery.isEmpty) {
      return categories;
    }

    return categories.where((category) =>
        category.getLocalizedName(language).toLowerCase().contains(_searchQuery.toLowerCase())).toList();
  }

  Map<String, double> _getCategorySpending(List<dynamic> expenses) {
    final categorySpending = <String, double>{};
    final now = DateTime.now();
    final thisMonthStart = DateTime(now.year, now.month, 1);

    for (final expense in expenses) {
      if (expense.date.isAfter(thisMonthStart.subtract(const Duration(days: 1)))) {
        categorySpending[expense.categoryId] =
            (categorySpending[expense.categoryId] ?? 0) + expense.amount;
      }
    }

    return categorySpending;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Categories'),
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const AddCategoryScreen(),
                ),
              );
            },
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: Consumer3<CategoryProvider, ExpenseProvider, AuthProvider>(
        builder: (context, categoryProvider, expenseProvider, authProvider, child) {
          if (categoryProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final language = authProvider.language;
          final categories = _getFilteredCategories(categoryProvider.categories, language);
          final categorySpending = _getCategorySpending(expenseProvider.expenses);
          final totalSpending = categorySpending.values.fold<double>(0, (sum, amount) => sum + amount);

          return Column(
            children: [
              // Search Bar
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search categories...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _searchQuery = '';
                        });
                      },
                      icon: const Icon(Icons.clear),
                    )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Theme.of(context).dividerColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2),
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
              ),

              // Category Statistics
              if (totalSpending > 0 && categories.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: _buildCategoryStats(categories.length, totalSpending, categorySpending),
                ),
                const SizedBox(height: 16),
              ],

              // Categories List
              Expanded(
                child: categories.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                  onRefresh: () async {
                    _loadData();
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      final category = categories[index];
                      final spent = categorySpending[category.id] ?? 0;
                      final percentage = totalSpending > 0 ? (spent / totalSpending * 100) : 0.0;

                      return _buildCategoryCard(category, spent, percentage);
                    },
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
              builder: (context) => const AddCategoryScreen(),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildCategoryStats(int categoryCount, double totalSpending, Map<String, double> categorySpending) {
    final topSpendingCategory = categorySpending.entries.isNotEmpty
        ? categorySpending.entries.reduce((a, b) => a.value > b.value ? a : b)
        : null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary.withOpacity(0.8), AppColors.primary],
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
                      'Total Categories',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    Text(
                      categoryCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
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
                      'This Month',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    Text(
                      CurrencyUtils.formatCurrency(totalSpending),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
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
                      'Active Categories',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    Text(
                      categorySpending.length.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (topSpendingCategory != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.trending_up, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Consumer2<CategoryProvider, AuthProvider>(
                      builder: (context, categoryProvider, authProvider, child) {
                        final category = categoryProvider.getCategoryById(topSpendingCategory.key);
                        final language = authProvider.language;
                        return Text(
                          'Top spending: ${category?.getLocalizedName(language) ?? 'Unknown'} - ${CurrencyUtils.formatCurrency(topSpendingCategory.value)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCategoryCard(CategoryModel category, double spent, double percentage) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _showCategoryDetails(category, spent),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        category.icon != null
                            ? IconData(category.icon!, fontFamily: 'MaterialIcons')
                            : Icons.category,
                        color: Theme.of(context).primaryColor,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Consumer<AuthProvider>(
                            builder: (context, authProvider, child) {
                              final language = authProvider.language;
                              return Text(
                                category.getLocalizedName(language),
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              );
                            },
                          ),
                          if (category.description?.isNotEmpty == true) ...[
                            const SizedBox(height: 4),
                            Text(
                              category.description!,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'edit') {
                          _editCategory(category);
                        } else if (value == 'delete') {
                          _deleteCategory(category);
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Text('Edit Category'),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Text('Delete Category'),
                        ),
                      ],
                      child: Icon(
                        Icons.more_vert,
                        color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
                if (spent > 0) ...[
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'This month spending',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            CurrencyUtils.formatCurrency(spent),
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                          Text(
                            '${percentage.toStringAsFixed(1)}% of total',
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
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                    minHeight: 4,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.category_outlined,
              size: 80,
              color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.4),
            ),
            const SizedBox(height: 24),
            Text(
              _searchQuery.isNotEmpty ? 'No categories found' : 'No Categories Yet',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _searchQuery.isNotEmpty
                  ? 'Try searching with different keywords'
                  : 'Create your first category to start organizing your expenses.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6),
              ),
            ),
            if (_searchQuery.isEmpty) ...[
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const AddCategoryScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.add),
                label: const Text('Create Category'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showCategoryDetails(CategoryModel category, double spent) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              category.icon != null
                  ? IconData(category.icon!, fontFamily: 'MaterialIcons')
                  : Icons.category,
              color: Theme.of(context).primaryColor,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Consumer<AuthProvider>(
                builder: (context, authProvider, child) {
                  final language = authProvider.language;
                  return Text(category.getLocalizedName(language));
                },
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (category.description?.isNotEmpty == true) ...[
              const Text('Description:', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(category.description!),
              const SizedBox(height: 16),
            ],
            const Text('This Month Spending:', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(
              CurrencyUtils.formatCurrency(spent),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 16),
            const Text('Created:', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(
              '${category.createdAt.day}/${category.createdAt.month}/${category.createdAt.year}',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _editCategory(category);
            },
            child: const Text('Edit'),
          ),
        ],
      ),
    );
  }

  void _editCategory(CategoryModel category) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AddCategoryScreen(category: category),
      ),
    );
  }

  void _deleteCategory(CategoryModel category) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Category'),
        content: Consumer<AuthProvider>(
          builder: (context, authProvider, child) {
            final language = authProvider.language;
            return Text('Are you sure you want to delete "${category.getLocalizedName(language)}"? This action cannot be undone.');
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Provider.of<CategoryProvider>(context, listen: false)
                  .deleteCategory(category.id);

              final language = Provider.of<AuthProvider>(context, listen: false).language;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Category "${category.getLocalizedName(language)}" deleted'),
                  backgroundColor: AppColors.success,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}