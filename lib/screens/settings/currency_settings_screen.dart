import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/constants/app_colors.dart';

class CurrencySettingsScreen extends StatefulWidget {
  const CurrencySettingsScreen({Key? key}) : super(key: key);

  @override
  State<CurrencySettingsScreen> createState() => _CurrencySettingsScreenState();
}

class _CurrencySettingsScreenState extends State<CurrencySettingsScreen> {
  String _selectedCurrency = 'USD';
  bool _isLoading = false;
  String _searchQuery = '';

  // Fixed currencies list with proper syntax
  final List<Map<String, String>> _currencies = [
    {'code': 'USD', 'name': 'US Dollar', 'symbol': '\$'},
    {'code': 'EUR', 'name': 'Euro', 'symbol': '€'},
    {'code': 'GBP', 'name': 'British Pound', 'symbol': '£'},
    {'code': 'JPY', 'name': 'Japanese Yen', 'symbol': '¥'},
    {'code': 'INR', 'name': 'Indian Rupee', 'symbol': '₹'},
    {'code': 'PKR', 'name': 'Pakistani Rupee', 'symbol': 'Rs'},
    {'code': 'CAD', 'name': 'Canadian Dollar', 'symbol': 'C\$'},
    {'code': 'AUD', 'name': 'Australian Dollar', 'symbol': 'A\$'},
    {'code': 'CNY', 'name': 'Chinese Yuan', 'symbol': '¥'},
    {'code': 'SGD', 'name': 'Singapore Dollar', 'symbol': 'S\$'},
    {'code': 'CHF', 'name': 'Swiss Franc', 'symbol': 'CHF'},
    {'code': 'SEK', 'name': 'Swedish Krona', 'symbol': 'kr'},
    {'code': 'NOK', 'name': 'Norwegian Krone', 'symbol': 'kr'},
    {'code': 'DKK', 'name': 'Danish Krone', 'symbol': 'kr'},
    {'code': 'RUB', 'name': 'Russian Ruble', 'symbol': '₽'},
    {'code': 'BRL', 'name': 'Brazilian Real', 'symbol': 'R\$'},
    {'code': 'MXN', 'name': 'Mexican Peso', 'symbol': '\$'},
    {'code': 'ZAR', 'name': 'South African Rand', 'symbol': 'R'},
    {'code': 'KRW', 'name': 'South Korean Won', 'symbol': '₩'},
    {'code': 'TRY', 'name': 'Turkish Lira', 'symbol': '₺'},
  ];

  @override
  void initState() {
    super.initState();
    _loadCurrentCurrency();
  }

  void _loadCurrentCurrency() {
    final authProvider = context.read<AuthProvider>();
    _selectedCurrency = authProvider.userModel?.currency ?? 'USD';
    print('DEBUG: Loaded current currency: $_selectedCurrency');
  }

  List<Map<String, String>> get _filteredCurrencies {
    if (_searchQuery.isEmpty) return _currencies;
    return _currencies.where((currency) {
      return currency['name']!.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          currency['code']!.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  Future<void> _saveCurrency() async {
    setState(() => _isLoading = true);

    try {
      final authProvider = context.read<AuthProvider>();
      final success = await authProvider.updateProfile(currency: _selectedCurrency);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Text('Currency updated successfully'),
              ],
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Text('Failed to update currency'),
              ],
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Currency Settings',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveCurrency,
            child: _isLoading
                ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            )
                : Text(
              'Save',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Current currency display
          Container(
            width: double.infinity,
            margin: EdgeInsets.all(16),
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Current Currency',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          _currencies.firstWhere(
                                (currency) => currency['code'] == _selectedCurrency,
                            orElse: () => _currencies.first,
                          )['symbol']!,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _currencies.firstWhere(
                                (currency) => currency['code'] == _selectedCurrency,
                            orElse: () => _currencies.first,
                          )['name']!,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          _selectedCurrency,
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Search bar
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search currencies...',
                hintStyle: TextStyle(color: AppColors.textSecondary),
                prefixIcon: Icon(Icons.search, color: AppColors.textSecondary),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              style: TextStyle(color: AppColors.textPrimary),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),

          SizedBox(height: 16),

          // Currency list
          Expanded(
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: _filteredCurrencies.length,
                separatorBuilder: (context, index) => Divider(
                  height: 1,
                  color: AppColors.border,
                  indent: 72,
                ),
                itemBuilder: (context, index) {
                  final currency = _filteredCurrencies[index];
                  final isSelected = _selectedCurrency == currency['code'];

                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary.withOpacity(0.1)
                            : Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          currency['symbol']!,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? AppColors.primary : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                    title: Text(
                      currency['name']!,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                        color: isSelected ? AppColors.primary : AppColors.textPrimary,
                      ),
                    ),
                    subtitle: Text(
                      currency['code']!,
                      style: TextStyle(
                        fontSize: 14,
                        color: isSelected
                            ? AppColors.primary.withOpacity(0.7)
                            : AppColors.textSecondary,
                      ),
                    ),
                    trailing: isSelected
                        ? Icon(
                      Icons.check_circle,
                      color: AppColors.primary,
                      size: 24,
                    )
                        : null,
                    onTap: () {
                      setState(() {
                        _selectedCurrency = currency['code']!;
                      });
                    },
                  );
                },
              ),
            ),
          ),

          // Info section
          Container(
            width: double.infinity,
            margin: EdgeInsets.all(16),
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.info.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.info.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: AppColors.info,
                  size: 20,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'All your expenses and budgets will be displayed in the selected currency.',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.info,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}