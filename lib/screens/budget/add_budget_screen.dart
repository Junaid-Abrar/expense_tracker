import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/budget_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/budget_model.dart';
import '../../models/category_model.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/currency_utils.dart';
import '../../core/utils/translation_helper.dart';

class AddBudgetScreen extends StatefulWidget {
  final BudgetModel? budget;

  const AddBudgetScreen({Key? key, this.budget}) : super(key: key);

  @override
  State<AddBudgetScreen> createState() => _AddBudgetScreenState();
}

class _AddBudgetScreenState extends State<AddBudgetScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();

  CategoryModel? _selectedCategory;
  String _selectedPeriod = 'this_month';
  bool _isLoading = false;

  IconData _iconFor(CategoryModel? category) {
    final dynamic ic = category?.icon;
    if (ic == null) return Icons.category;
    if (ic is int) return IconData(ic, fontFamily: 'MaterialIcons');
    if (ic is IconData) return ic;
    return Icons.category;
  }

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  void _initializeForm() {
    if (widget.budget != null) {
      _amountController.text = widget.budget!.amount.toStringAsFixed(2);
      _notesController.text = widget.budget!.notes ?? '';
      _selectedPeriod = widget.budget!.period;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        final categoryProvider = Provider.of<CategoryProvider>(context, listen: false);
        _selectedCategory = categoryProvider.getCategoryById(widget.budget!.categoryId);
        setState(() {});
      });
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final language = authProvider.getPreference<String>('app_language', 'en');
        String getText(String key) => TranslationHelper.getText(key, language);

        // Translated periods
        final periods = [
          {'value': 'this_month', 'label': getText('this_month')},
          {'value': 'this_year', 'label': getText('this_year')},
        ];

        return Scaffold(
          appBar: AppBar(
            title: Text(widget.budget != null ? getText('edit_budget') : getText('add_budget')),
            elevation: 0,
            actions: [
              if (widget.budget != null)
                TextButton(
                  onPressed: _isLoading ? null : () => _deleteBudget(getText),
                  child: Text(
                    getText('delete'),
                    style: TextStyle(color: AppColors.error),
                  ),
                ),
            ],
          ),
          body: Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Category Selection
                  _buildSectionTitle(getText('category')),
                  const SizedBox(height: 8),
                  _buildCategorySelector(getText, authProvider),
                  const SizedBox(height: 24),

                  // Amount Input
                  _buildSectionTitle(getText('budget_amount')),
                  const SizedBox(height: 8),
                  _buildAmountInput(getText, authProvider),
                  const SizedBox(height: 24),

                  // Period Selection
                  _buildSectionTitle(getText('budget_period')),
                  const SizedBox(height: 8),
                  _buildPeriodSelector(periods),
                  const SizedBox(height: 24),

                  // Notes Input
                  _buildSectionTitle(getText('notes_optional')),
                  const SizedBox(height: 8),
                  _buildNotesInput(getText),
                  const SizedBox(height: 32),

                  // Save Button
                  _buildSaveButton(getText),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildCategorySelector(String Function(String) getText, AuthProvider authProvider) {
    return Consumer<CategoryProvider>(
      builder: (context, categoryProvider, child) {
        final categories = categoryProvider.categories;
        final language = authProvider.getPreference<String>('app_language', 'en');

        return Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: Theme.of(context).dividerColor,
              width: 1,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => _showCategoryPicker(categories, getText, language),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _selectedCategory != null
                          ? Theme.of(context).primaryColor.withOpacity(0.1)
                          : Theme.of(context).dividerColor.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _iconFor(_selectedCategory),
                      color: _selectedCategory != null
                          ? Theme.of(context).primaryColor
                          : Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _selectedCategory?.getLocalizedName(language) ?? getText('select_category'),
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: _selectedCategory != null
                            ? Theme.of(context).textTheme.bodyLarge?.color
                            : Theme.of(context).textTheme.bodyLarge?.color?.withOpacity(0.6),
                      ),
                      overflow: TextOverflow.ellipsis, // Fix overflow
                    ),
                  ),
                  Icon(
                    Icons.arrow_drop_down,
                    color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAmountInput(String Function(String) getText, AuthProvider authProvider) {
    return TextFormField(
      controller: _amountController,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
      ],
      decoration: InputDecoration(
        hintText: '0.00',
        prefixIcon: Consumer<AuthProvider>(
          builder: (context, authProvider, child) {
            final currency = authProvider.userModel?.currency ?? 'USD';

            if (currency == 'PKR') {
              // Special handling for PKR - show "Rs" text
              return Container(
                width: 48,
                alignment: Alignment.center,
                child: Text(
                  'Rs',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                ),
              );
            }

            // For other currencies, use icons
            IconData icon;
            switch (currency) {
              case 'EUR':
                icon = Icons.euro;
                break;
              case 'GBP':
                icon = Icons.currency_pound;
                break;
              case 'JPY':
              case 'CNY':
                icon = Icons.currency_yen;
                break;
              case 'INR':
                icon = Icons.currency_rupee; // ₹ symbol for Indian Rupee
                break;
              default:
                icon = Icons.attach_money;
            }

            return Icon(icon);
          },
        ),
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
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.error, width: 2),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return getText('please_enter_budget_amount');
        }
        final amount = double.tryParse(value);
        if (amount == null || amount <= 0) {
          return getText('please_enter_valid_amount');
        }
        return null;
      },
    );
  }

  Widget _buildPeriodSelector(List<Map<String, String>> periods) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: Theme.of(context).dividerColor,
          width: 1,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: periods.map((period) {
          final isSelected = _selectedPeriod == period['value'];
          final isFirst = periods.first == period;
          final isLast = periods.last == period;

          return InkWell(
            onTap: () {
              setState(() {
                _selectedPeriod = period['value']!;
              });
            },
            borderRadius: BorderRadius.vertical(
              top: isFirst ? const Radius.circular(12) : Radius.zero,
              bottom: isLast ? const Radius.circular(12) : Radius.zero,
            ),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isSelected
                    ? Theme.of(context).primaryColor.withOpacity(0.1)
                    : null,
                border: !isLast
                    ? Border(bottom: BorderSide(color: Theme.of(context).dividerColor))
                    : null,
              ),
              child: Row(
                children: [
                  Radio<String>(
                    value: period['value']!,
                    groupValue: _selectedPeriod,
                    onChanged: (value) {
                      setState(() {
                        _selectedPeriod = value!;
                      });
                    },
                    activeColor: Theme.of(context).primaryColor,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      period['label']!,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                      overflow: TextOverflow.ellipsis, // Fix overflow
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildNotesInput(String Function(String) getText) {
    return TextFormField(
      controller: _notesController,
      maxLines: 3,
      decoration: InputDecoration(
        hintText: getText('add_budget_notes'),
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
    );
  }

  Widget _buildSaveButton(String Function(String) getText) {
    return ElevatedButton(
      onPressed: _isLoading ? null : () => _saveBudget(getText),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: _isLoading
          ? const SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      )
          : Text(
        widget.budget != null ? getText('update_budget') : getText('create_budget'),
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  void _showCategoryPicker(List<CategoryModel> categories, String Function(String) getText, String language) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                getText('select_category'),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    final category = categories[index];
                    final isSelected = _selectedCategory?.id == category.id;

                    return ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Theme.of(context).primaryColor.withOpacity(0.2)
                              : Theme.of(context).primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          _iconFor(category),
                          color: Theme.of(context).primaryColor,
                          size: 24,
                        ),
                      ),
                      title: Text(
                        category.getLocalizedName(language),
                        style: TextStyle(
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        ),
                        overflow: TextOverflow.ellipsis, // Fix overflow
                      ),
                      trailing: isSelected
                          ? Icon(
                        Icons.check,
                        color: Theme.of(context).primaryColor,
                      )
                          : null,
                      onTap: () {
                        setState(() {
                          _selectedCategory = category;
                        });
                        Navigator.of(context).pop();
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(getText('cancel')),
              ),
            ],
          ),
        );
      },
    );
  }

  void _saveBudget(String Function(String) getText) async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedCategory == null) {
      _showErrorSnackBar(getText('please_select_category'));
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final String? userId = auth.user?.uid;
    if (userId == null) {
      _showErrorSnackBar(getText('user_not_authenticated'));
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      final budgetProvider = Provider.of<BudgetProvider>(context, listen: false);
      final amount = double.parse(_amountController.text);

      if (widget.budget != null) {
        final updatedBudget = BudgetModel(
          id: widget.budget!.id,
          userId: widget.budget!.userId,
          name: widget.budget!.name,
          categoryId: _selectedCategory!.id,
          categoryName: _selectedCategory!.name,
          description: widget.budget!.description,
          startDate: widget.budget!.startDate,
          endDate: widget.budget!.endDate,
          amount: amount,
          period: _selectedPeriod,
          createdAt: widget.budget!.createdAt,
          updatedAt: DateTime.now(),
        );

        await budgetProvider.updateBudget(updatedBudget);
        _showSuccessSnackBar(getText('budget_updated_successfully'));
      } else {
        final newBudget = BudgetModel(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          userId: userId,
          name: 'New Budget',
          categoryId: _selectedCategory!.id,
          categoryName: _selectedCategory!.name,
          description: '',
          startDate: DateTime.now(),
          endDate: DateTime.now().add(const Duration(days: 30)),
          amount: amount,
          period: _selectedPeriod,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await budgetProvider.addBudget(newBudget);
        _showSuccessSnackBar(getText('budget_created_successfully'));
      }

      Navigator.of(context).pop();
    } catch (e) {
      _showErrorSnackBar('${getText('failed_to_save')} ${e.toString()}');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _deleteBudget(String Function(String) getText) async {
    if (widget.budget == null) return;

    final confirmed = await _showConfirmDialog(
      getText('delete_budget'),
      getText('delete_budget_confirmation'),
      getText,
    );

    if (!confirmed) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final budgetProvider = Provider.of<BudgetProvider>(context, listen: false);
      await budgetProvider.deleteBudget(widget.budget!.id);
      _showSuccessSnackBar(getText('budget_deleted_successfully'));
      Navigator.of(context).pop();
    } catch (e) {
      _showErrorSnackBar('${getText('failed_to_delete')} ${e.toString()}');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<bool> _showConfirmDialog(String title, String message, String Function(String) getText) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(getText('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: Text(getText('delete')),
          ),
        ],
      ),
    ) ??
        false;
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}