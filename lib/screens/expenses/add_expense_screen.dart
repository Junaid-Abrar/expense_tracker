import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../models/expense_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/expense_provider.dart';
import '../../providers/category_provider.dart';
import '../../models/category_model.dart';
import '../../core/constants/app_colors.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_text_field.dart';
import '../../core/utils/translation_helper.dart';

class AddExpenseScreen extends StatefulWidget {
  final ExpenseModel? expense;

  const AddExpenseScreen({Key? key, this.expense}) : super(key: key);

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();

  late TabController _tabController;

  CategoryModel? _selectedCategory;
  DateTime _selectedDate = DateTime.now();
  String _selectedType = 'expense';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _selectedType = _tabController.index == 0 ? 'expense' : 'income';
        _selectedCategory = null;
      });
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CategoryProvider>().initializeCategories();
      _checkForTypeParameter();
    });
  }

  void _checkForTypeParameter() {
    final uri = GoRouterState.of(context).uri;
    final typeParam = uri.queryParameters['type'];
    if (typeParam == 'income') {
      setState(() {
        _selectedType = 'income';
        _tabController.index = 1;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _titleController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  String _getTranslation(String key) {
    final language = context.read<AuthProvider>().getPreference<String>('app_language', 'en');
    return TranslationHelper.getText(key, language);
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
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
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _saveExpense() async {
    if (!_formKey.currentState!.validate() || _selectedCategory == null) {
      if (_selectedCategory == null) {
        _showSnackBar(_getTranslation('please_select_category'), isError: true);
      }
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authProvider = context.read<AuthProvider>();
      final expenseProvider = context.read<ExpenseProvider>();

      if (authProvider.user == null) {
        _showSnackBar(_getTranslation('user_not_authenticated'), isError: true);
        return;
      }

      final success = await expenseProvider.addExpense(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        amount: double.tryParse(_amountController.text.trim()) ?? 0.0,
        categoryId: _selectedCategory!.id,
        categoryName: _selectedCategory!.name,
        date: _selectedDate,
        type: _selectedType,
        paymentMethod: 'cash',
      );

      if (success && mounted) {
        // Show success message
        _showSnackBar(
          _selectedType == 'expense'
              ? _getTranslation('expense_added_successfully')
              : _getTranslation('income_added_successfully'),
        );

        // Reset form
        _resetForm();

        // Navigate back after a short delay to ensure user sees the message
        await Future.delayed(const Duration(milliseconds: 1500));
        if (mounted) {
          context.go('/home');
        }
      } else {
        _showSnackBar(_getTranslation('failed_to_save'), isError: true);
      }

    } catch (e) {
      _showSnackBar('${_getTranslation('failed_to_save')}: ${e.toString()}', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _resetForm() {
    _titleController.clear();
    _amountController.clear();
    _descriptionController.clear();
    setState(() {
      _selectedCategory = null;
      _selectedDate = DateTime.now();
    });
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(_getTranslation('add_transaction')),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
        actions: [
          TextButton(
            onPressed: _resetForm,
            child: Text(
              _getTranslation('reset'),
              style: TextStyle(color: AppColors.primary),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            height: 50,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: AppColors.primary,
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              indicatorPadding: const EdgeInsets.all(4),
              labelColor: Colors.white,
              unselectedLabelColor: Colors.grey[600],
              labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
              tabs: [
                Tab(text: _getTranslation('expense')),
                Tab(text: _getTranslation('income')),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTitleInput(),
                    const SizedBox(height: 20),
                    _buildAmountInput(),
                    const SizedBox(height: 20),
                    _buildCategorySelection(),
                    const SizedBox(height: 20),
                    _buildDateSelection(),
                    const SizedBox(height: 20),
                    _buildDescriptionInput(),
                    const SizedBox(height: 32),
                    _buildSaveButton(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitleInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _getTranslation('title'),
          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        CustomTextField(
          controller: _titleController,
          hintText: _getTranslation('enter_title'),
          prefixIcon: Icons.title,
          validator: (value) {
            if (value == null || value.isEmpty) return _getTranslation('please_enter_title');
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildAmountInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _getTranslation('amount'),
          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    bottomLeft: Radius.circular(12),
                  ),
                ),
                child: Consumer<AuthProvider>(
                  builder: (context, authProvider, child) {
                    final currency = authProvider.userModel?.currency ?? 'USD';
                    String symbol;
                    switch (currency) {
                      case 'USD': symbol = '\$'; break;
                      case 'EUR': symbol = '€'; break;
                      case 'GBP': symbol = '£'; break;
                      case 'JPY': symbol = '¥'; break;
                      case 'INR': symbol = '₹'; break;
                      case 'PKR': symbol = 'Rs'; break;
                      case 'CAD': symbol = 'C\$'; break;
                      case 'AUD': symbol = 'A\$'; break;
                      case 'CNY': symbol = '¥'; break;
                      case 'SGD': symbol = 'S\$'; break;
                      default: symbol = currency;
                    }
                    return Text(symbol, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary));
                  },
                ),
              ),
              Expanded(
                child: TextFormField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  decoration: InputDecoration(
                    hintText: '0.00',
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return _getTranslation('please_enter_amount');
                    final amount = double.tryParse(value);
                    if (amount == null || amount <= 0) return _getTranslation('please_enter_valid_amount');
                    return null;
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCategorySelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _getTranslation('category'),
          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Consumer<CategoryProvider>(
          builder: (context, categoryProvider, child) {
            if (categoryProvider.isLoading) {
              return Container(
                height: 120,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(child: CircularProgressIndicator()),
              );
            }

            final categories = _selectedType == 'expense'
                ? categoryProvider.expenseCategories
                : categoryProvider.incomeCategories;

            if (categories.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Icon(Icons.category, size: 48, color: Colors.grey[400]),
                    const SizedBox(height: 12),
                    Text(_getTranslation('no_categories_available')),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () => context.push('/categories/add'),
                      icon: const Icon(Icons.add),
                      label: Text(_getTranslation('add_category')),
                    ),
                  ],
                ),
              );
            }

            final popularCategoryIds = _selectedType == 'expense'
                ? ['food', 'transport', 'shopping', 'bills', 'healthcare', 'entertainment']
                : ['salary', 'freelance', 'investment', 'gift', 'bonus', 'other_income'];

            final popularCategories = categories
                .where((c) => popularCategoryIds.contains(c.id))
                .toList();
            final otherCategories = categories
                .where((c) => !popularCategoryIds.contains(c.id))
                .toList();

            return Column(
              children: [
                if (_selectedCategory != null)
                  _buildSelectedCategoryChip(_selectedCategory!),
                if (_selectedCategory == null) ...[
                  if (popularCategories.isNotEmpty)
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        childAspectRatio: 1.0,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemCount: popularCategories.length > 6 ? 6 : popularCategories.length,
                      itemBuilder: (context, index) {
                        return _buildCategoryTile(popularCategories[index]);
                      },
                    ),
                  const SizedBox(height: 16),
                  if (otherCategories.isNotEmpty || popularCategories.length > 6)
                    OutlinedButton.icon(
                      onPressed: () => _showAllCategoriesBottomSheet(categories),
                      icon: const Icon(Icons.grid_view, size: 20),
                      label: Text(
                        '${_getTranslation('more_categories')} (${otherCategories.length + (popularCategories.length > 6 ? popularCategories.length - 6 : 0)})',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        side: BorderSide(color: Colors.grey[400]!),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final result = await context.push('/categories/add');
                      if (result == true && mounted) {
                        await context.read<CategoryProvider>().loadCategories();
                      }
                    },
                    icon: const Icon(Icons.add_circle_outline, size: 20),
                    label: Text(_getTranslation('add_custom_category'),
                        style: const TextStyle(fontWeight: FontWeight.w500)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      side: BorderSide(color: AppColors.primary.withOpacity(0.5)),
                      foregroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildCategoryTile(CategoryModel category) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final language = authProvider.getPreference<String>('app_language', 'en');

        return GestureDetector(
          onTap: () => setState(() => _selectedCategory = category),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: category.colorData.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: category.colorData.withOpacity(0.3), width: 1),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(category.iconData, color: category.colorData, size: 22),
                const SizedBox(height: 4),
                Text(
                  category.getLocalizedName(language),
                  style: TextStyle(color: category.colorData, fontSize: 10, fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSelectedCategoryChip(CategoryModel category) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary, width: 2),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(category.iconData, color: category.colorData, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Consumer<AuthProvider>(
              builder: (context, authProvider, child) {
                final language = authProvider.getPreference<String>('app_language', 'en');
                return Text(
                  category.getLocalizedName(language),
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                );
              },
            ),
          ),
          GestureDetector(
            onTap: () => setState(() => _selectedCategory = null),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.close, color: AppColors.primary, size: 20),
            ),
          ),
        ],
      ),
    );
  }


  void _showAllCategoriesBottomSheet(List<CategoryModel> categories) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 8, bottom: 12),
              width: 40,
              height: 3,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Consumer<AuthProvider>(
                    builder: (context, authProvider, child) {
                      final language = authProvider.getPreference<String>('app_language', 'en');
                      return Text(
                        TranslationHelper.getText('all_categories', language),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      );
                    },
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, size: 20),
                    padding: const EdgeInsets.all(4),
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Consumer<AuthProvider>(
                builder: (context, authProvider, child) {
                  final language = authProvider.getPreference<String>('app_language', 'en');

                  return GridView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      childAspectRatio: 0.9,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      final category = categories[index];
                      return GestureDetector(
                        onTap: () {
                          setState(() => _selectedCategory = category);
                          Navigator.pop(context);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Color(category.color).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Color(category.color).withOpacity(0.3), width: 1),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                IconData(category.icon, fontFamily: 'MaterialIcons'),
                                color: Color(category.color),
                                size: 24,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                category.getLocalizedName(language), // Use proper localization
                                style: TextStyle(
                                  color: Color(category.color),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildDateSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _getTranslation('date'),
          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _selectDate,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(12),
              color: Theme.of(context).cardColor,
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.calendar_today, color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
                  ),
                ),
                Icon(Icons.arrow_drop_down, color: Colors.grey[600]),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDescriptionInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _getTranslation('description_optional'),
          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        CustomTextField(
          controller: _descriptionController,
          hintText: _getTranslation('add_note_transaction'),
          maxLines: 3,
          prefixIcon: Icons.note,
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: CustomButton(
        text: _isLoading
            ? _getTranslation('saving')
            : _selectedType == 'expense'
            ? _getTranslation('add_expense')
            : _getTranslation('add_income'),
        onPressed: _isLoading ? null : _saveExpense,
        isLoading: _isLoading,
        gradient: _selectedType == 'expense' ? AppColors.expenseGradient : AppColors.incomeGradient,
      ),
    );
  }
}

