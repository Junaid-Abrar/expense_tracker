import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/expense_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/category_provider.dart';
import '../../core/constants/app_colors.dart';
import '../../models/expense_model.dart';
import '../../core/utils/translation_helper.dart';

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({Key? key}) : super(key: key);

  @override
  State<TransactionHistoryScreen> createState() => _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  DateTimeRange? _selectedDateRange;
  String _selectedType = 'all'; // 'all', 'expense', 'income'

  String _getTranslation(String key, String language) {
    return TranslationHelper.getText(key, language);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ExpenseProvider>().loadExpenses();
    });
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _selectedDateRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: AppColors.primary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDateRange) {
      setState(() {
        _selectedDateRange = picked;
      });
    }
  }

  void _clearFilters() {
    setState(() {
      _selectedDateRange = null;
      _selectedType = 'all';
    });
  }

  List<ExpenseModel> _getFilteredTransactions() {
    final expenseProvider = context.read<ExpenseProvider>();
    var transactions = expenseProvider.allExpenses;

    // Filter by type
    if (_selectedType != 'all') {
      transactions = transactions.where((t) => t.type == _selectedType).toList();
    }

    // Filter by date range
    if (_selectedDateRange != null) {
      transactions = transactions.where((t) {
        return t.date.isAfter(_selectedDateRange!.start.subtract(const Duration(days: 1))) &&
            t.date.isBefore(_selectedDateRange!.end.add(const Duration(days: 1)));
      }).toList();
    }

    // Sort by date (newest first)
    transactions.sort((a, b) => b.date.compareTo(a.date));

    return transactions;
  }

  String _buildFilterSummary(String language) {
    List<String> filters = [];

    if (_selectedType != 'all') {
      filters.add(_selectedType == 'expense' ? _getTranslation('expenses_only', language) : _getTranslation('income_only', language));
    }

    if (_selectedDateRange != null) {
      filters.add('${_selectedDateRange!.start.day}/${_selectedDateRange!.start.month} - ${_selectedDateRange!.end.day}/${_selectedDateRange!.end.month}');
    }

    return filters.join(' • ');
  }

  void _showFilterBottomSheet(String language) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.6,
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 8, bottom: 16),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Text(
                      _getTranslation('filter_transactions', language),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _selectedDateRange = null;
                          _selectedType = 'all';
                        });
                        setModalState(() {
                          _selectedDateRange = null;
                          _selectedType = 'all';
                        });
                      },
                      child: Text(_getTranslation('clear_all', language)),
                    ),
                  ],
                ),
              ),

              const Divider(),

              // Filter options
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    // Transaction Type
                    Text(
                      _getTranslation('transaction_type', language),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...['all', 'expense', 'income'].map((type) {
                      final isSelected = _selectedType == type;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _selectedType = type;
                            });
                            setModalState(() {
                              _selectedType = type;
                            });
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isSelected ? AppColors.primary.withOpacity(0.1) : null,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSelected ? AppColors.primary : Colors.grey.withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  type == 'all' ? Icons.all_inclusive :
                                  type == 'expense' ? Icons.trending_down : Icons.trending_up,
                                  color: isSelected ? AppColors.primary : Colors.grey[600],
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  type == 'all' ? _getTranslation('all_transactions', language) :
                                  type == 'expense' ? _getTranslation('expenses_only', language) : _getTranslation('income_only', language),
                                  style: TextStyle(
                                    color: isSelected ? AppColors.primary : null,
                                    fontWeight: isSelected ? FontWeight.w600 : null,
                                  ),
                                ),
                                const Spacer(),
                                if (isSelected)
                                  Icon(Icons.check, color: AppColors.primary),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),

                    const SizedBox(height: 24),

                    // Date Range
                    Text(
                      _getTranslation('date_range', language),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    InkWell(
                      onTap: () async {
                        final picked = await showDateRangePicker(
                          context: context,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                          initialDateRange: _selectedDateRange,
                        );
                        if (picked != null) {
                          setState(() {
                            _selectedDateRange = picked;
                          });
                          setModalState(() {
                            _selectedDateRange = picked;
                          });
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.withOpacity(0.3)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.date_range, color: Colors.grey[600]),
                            const SizedBox(width: 12),
                            Text(
                              _selectedDateRange == null
                                  ? _getTranslation('select_date_range', language)
                                  : '${_selectedDateRange!.start.day}/${_selectedDateRange!.start.month}/${_selectedDateRange!.start.year} - ${_selectedDateRange!.end.day}/${_selectedDateRange!.end.month}/${_selectedDateRange!.end.year}',
                            ),
                            const Spacer(),
                            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[600]),
                          ],
                        ),
                      ),
                    ),

                    if (_selectedDateRange != null) ...[
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _selectedDateRange = null;
                          });
                          setModalState(() {
                            _selectedDateRange = null;
                          });
                        },
                        child: Text(_getTranslation('clear_date_range', language)),
                      ),
                    ],
                  ],
                ),
              ),

              // Apply button
              Padding(
                padding: const EdgeInsets.all(20),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(_getTranslation('apply_filters', language)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final language = authProvider.getPreference<String>('app_language', 'en');
        
        return Scaffold(
          appBar: AppBar(
            title: Text(_getTranslation('transaction_history', language)),
            backgroundColor: Colors.transparent,
            elevation: 0,
            actions: [
              IconButton(
                icon: const Icon(Icons.filter_list),
                onPressed: () => _showFilterBottomSheet(language),
              ),
            ],
          ),
          body: Consumer<ExpenseProvider>(
            builder: (context, expenseProvider, child) {
              if (expenseProvider.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              final filteredTransactions = _getFilteredTransactions();

              if (filteredTransactions.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.receipt_long, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        _getTranslation('no_transactions_found', language),
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _getTranslation('try_adjusting_filters', language),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[500],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () => context.push('/expenses/add'),
                        icon: const Icon(Icons.add),
                        label: Text(_getTranslation('add_transaction', language)),
                      ),
                    ],
                  ),
                );
              }

              // Calculate totals for filtered transactions
              final totalExpenses = filteredTransactions
                  .where((t) => t.type == 'expense')
                  .fold<double>(0, (sum, t) => sum + t.amount);

              final totalIncome = filteredTransactions
                  .where((t) => t.type == 'income')
                  .fold<double>(0, (sum, t) => sum + t.amount);

              return Column(
                children: [
                  // Filter summary
                  if (_selectedDateRange != null || _selectedType != 'all')
                    Container(
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.filter_list, color: AppColors.primary, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _buildFilterSummary(language),
                              style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: _clearFilters,
                            child: Text(_getTranslation('clear', language)),
                          ),
                        ],
                      ),
                    ),

                  // Summary stats
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            children: [
                              Text(
                                '${filteredTransactions.length}',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                              Text(
                                _getTranslation('transactions', language),
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        Container(
                          height: 40,
                          width: 1,
                          color: Colors.grey.withOpacity(0.3),
                        ),
                        Expanded(
                          child: Column(
                            children: [
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  authProvider.userModel?.formatCurrency(totalExpenses) ?? '\$${totalExpenses.toStringAsFixed(2)}',
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.error,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                _getTranslation('expenses', language),
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        Container(
                          height: 40,
                          width: 1,
                          color: Colors.grey.withOpacity(0.3),
                        ),
                        Expanded(
                          child: Column(
                            children: [
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  authProvider.userModel?.formatCurrency(totalIncome) ?? '\$${totalIncome.toStringAsFixed(2)}',
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.success,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                _getTranslation('income', language),
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Transaction list
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: filteredTransactions.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final transaction = filteredTransactions[index];
                        return Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.withOpacity(0.2)),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(16),
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: transaction.type == 'expense'
                                    ? AppColors.error.withOpacity(0.1)
                                    : AppColors.success.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                transaction.type == 'expense' ? Icons.trending_down : Icons.trending_up,
                                color: transaction.type == 'expense' ? AppColors.error : AppColors.success,
                              ),
                            ),
                            title: Text(
                              transaction.title,
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Consumer<CategoryProvider>(
                                  builder: (context, categoryProvider, child) {
                                    final category = categoryProvider.getCategoryById(transaction.categoryId);
                                    return Text(
                                      category?.getLocalizedName(language) ?? transaction.categoryName,
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 13,
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${transaction.date.day}/${transaction.date.month}/${transaction.date.year}',
                                  style: TextStyle(
                                    color: Colors.grey[500],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            trailing: SizedBox(
                              width: 100, // Fixed width to prevent overflow
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      '${transaction.type == 'expense' ? '-' : '+'}${authProvider.userModel?.formatCurrency(transaction.amount) ?? '\$${transaction.amount.toStringAsFixed(2)}'}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: transaction.type == 'expense' ? AppColors.error : AppColors.success,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (transaction.description != null && transaction.description!.isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      transaction.description!,
                                      style: TextStyle(
                                        color: Colors.grey[500],
                                        fontSize: 10,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            onTap: () {
                              // Navigate to transaction details if you have that screen
                              // context.push('/expenses/detail/${transaction.id}');
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}