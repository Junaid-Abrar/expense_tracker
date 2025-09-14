import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/firebase_service.dart';

class PaymentMethodsScreen extends StatefulWidget {
  const PaymentMethodsScreen({Key? key}) : super(key: key);

  @override
  State<PaymentMethodsScreen> createState() => _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends State<PaymentMethodsScreen> {
  List<Map<String, dynamic>> _paymentMethods = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadPaymentMethods();
  }

  void _loadPaymentMethods() {
    final authProvider = context.read<AuthProvider>();
    final preferences = authProvider.userModel?.preferences;

    if (preferences != null && preferences['paymentMethods'] != null) {
      setState(() {
        _paymentMethods = List<Map<String, dynamic>>.from(preferences['paymentMethods']);
      });
    } else {
      // Default payment methods
      setState(() {
        _paymentMethods = [
          {'id': 'cash', 'name': 'Cash', 'icon': 'money', 'isDefault': true},
          {'id': 'card', 'name': 'Credit/Debit Card', 'icon': 'credit_card', 'isDefault': false},
          {'id': 'bank', 'name': 'Bank Transfer', 'icon': 'account_balance', 'isDefault': false},
        ];
      });
    }
  }

  Future<void> _savePaymentMethods() async {
    setState(() => _isLoading = true);

    try {
      final authProvider = context.read<AuthProvider>();
      final currentPreferences = authProvider.userModel?.preferences ?? {};

      final updatedPreferences = {
        ...currentPreferences,
        'paymentMethods': _paymentMethods,
      };

      final success = await authProvider.updateProfile(preferences: updatedPreferences);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Text('Payment methods updated'),
              ],
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Text('Failed to update payment methods'),
              ],
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _addPaymentMethod() {
    showDialog(
      context: context,
      builder: (context) => _AddPaymentMethodDialog(
        onAdd: (method) {
          setState(() {
            _paymentMethods.add({
              'id': DateTime.now().millisecondsSinceEpoch.toString(),
              'name': method['name'],
              'icon': method['icon'],
              'isDefault': false,
            });
          });
          _savePaymentMethods();
        },
      ),
    );
  }

  void _editPaymentMethod(int index) {
    final method = _paymentMethods[index];

    showDialog(
      context: context,
      builder: (context) => _EditPaymentMethodDialog(
        method: method,
        onEdit: (updatedMethod) {
          setState(() {
            _paymentMethods[index] = updatedMethod;
          });
          _savePaymentMethods();
        },
      ),
    );
  }

  void _deletePaymentMethod(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Payment Method'),
        content: Text('Are you sure you want to delete "${_paymentMethods[index]['name']}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _paymentMethods.removeAt(index);
              });
              _savePaymentMethods();
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _setAsDefault(int index) {
    setState(() {
      // Remove default from all methods
      for (var method in _paymentMethods) {
        method['isDefault'] = false;
      }
      // Set selected as default
      _paymentMethods[index]['isDefault'] = true;
    });
    _savePaymentMethods();
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'money':
        return Icons.money;
      case 'credit_card':
        return Icons.credit_card;
      case 'account_balance':
        return Icons.account_balance;
      case 'phone':
        return Icons.phone_android;
      case 'wallet':
        return Icons.wallet;
      default:
        return Icons.payment;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Methods'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _addPaymentMethod,
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _paymentMethods.isEmpty
          ? _buildEmptyState()
          : ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _paymentMethods.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final method = _paymentMethods[index];
          final isDefault = method['isDefault'] ?? false;

          return Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDefault ? AppColors.primary : Colors.grey.withOpacity(0.2),
                width: isDefault ? 2 : 1,
              ),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDefault ? AppColors.primary.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getIconData(method['icon']),
                  color: isDefault ? AppColors.primary : Colors.grey[600],
                ),
              ),
              title: Text(
                method['name'],
                style: TextStyle(
                  fontWeight: isDefault ? FontWeight.w600 : FontWeight.w500,
                  color: isDefault ? AppColors.primary : null,
                ),
              ),
              subtitle: isDefault ? Text(
                'Default method',
                style: TextStyle(
                  color: AppColors.primary.withOpacity(0.7),
                  fontSize: 12,
                ),
              ) : null,
              trailing: PopupMenuButton<String>(
                onSelected: (value) {
                  switch (value) {
                    case 'default':
                      _setAsDefault(index);
                      break;
                    case 'edit':
                      _editPaymentMethod(index);
                      break;
                    case 'delete':
                      _deletePaymentMethod(index);
                      break;
                  }
                },
                itemBuilder: (context) => [
                  if (!isDefault)
                    const PopupMenuItem(
                      value: 'default',
                      child: Row(
                        children: [
                          Icon(Icons.star),
                          SizedBox(width: 8),
                          Text('Set as Default'),
                        ],
                      ),
                    ),
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit),
                        SizedBox(width: 8),
                        Text('Edit'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Delete', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.payment, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No Payment Methods',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add payment methods to track how you pay for expenses',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _addPaymentMethod,
            icon: const Icon(Icons.add),
            label: const Text('Add Payment Method'),
          ),
        ],
      ),
    );
  }
}

class _AddPaymentMethodDialog extends StatefulWidget {
  final Function(Map<String, dynamic>) onAdd;

  const _AddPaymentMethodDialog({required this.onAdd});

  @override
  State<_AddPaymentMethodDialog> createState() => _AddPaymentMethodDialogState();
}

class _AddPaymentMethodDialogState extends State<_AddPaymentMethodDialog> {
  final _nameController = TextEditingController();
  String _selectedIcon = 'payment';

  final List<Map<String, String>> _iconOptions = [
    {'id': 'money', 'name': 'Cash'},
    {'id': 'credit_card', 'name': 'Card'},
    {'id': 'account_balance', 'name': 'Bank'},
    {'id': 'phone', 'name': 'Mobile Payment'},
    {'id': 'wallet', 'name': 'Digital Wallet'},
    {'id': 'payment', 'name': 'Other'},
  ];

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Payment Method'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Method Name',
              hintText: 'e.g., My Credit Card',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _selectedIcon,
            decoration: const InputDecoration(
              labelText: 'Icon',
              border: OutlineInputBorder(),
            ),
            items: _iconOptions.map((option) {
              return DropdownMenuItem(
                value: option['id'],
                child: Row(
                  children: [
                    Icon(_getIconData(option['id']!)),
                    const SizedBox(width: 8),
                    Text(option['name']!),
                  ],
                ),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedIcon = value!;
              });
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_nameController.text.trim().isNotEmpty) {
              widget.onAdd({
                'name': _nameController.text.trim(),
                'icon': _selectedIcon,
              });
              Navigator.pop(context);
            }
          },
          child: const Text('Add'),
        ),
      ],
    );
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'money':
        return Icons.money;
      case 'credit_card':
        return Icons.credit_card;
      case 'account_balance':
        return Icons.account_balance;
      case 'phone':
        return Icons.phone_android;
      case 'wallet':
        return Icons.wallet;
      default:
        return Icons.payment;
    }
  }
}

class _EditPaymentMethodDialog extends StatefulWidget {
  final Map<String, dynamic> method;
  final Function(Map<String, dynamic>) onEdit;

  const _EditPaymentMethodDialog({required this.method, required this.onEdit});

  @override
  State<_EditPaymentMethodDialog> createState() => _EditPaymentMethodDialogState();
}

class _EditPaymentMethodDialogState extends State<_EditPaymentMethodDialog> {
  late TextEditingController _nameController;
  late String _selectedIcon;

  final List<Map<String, String>> _iconOptions = [
    {'id': 'money', 'name': 'Cash'},
    {'id': 'credit_card', 'name': 'Card'},
    {'id': 'account_balance', 'name': 'Bank'},
    {'id': 'phone', 'name': 'Mobile Payment'},
    {'id': 'wallet', 'name': 'Digital Wallet'},
    {'id': 'payment', 'name': 'Other'},
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.method['name']);
    _selectedIcon = widget.method['icon'];
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Payment Method'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Method Name',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _selectedIcon,
            decoration: const InputDecoration(
              labelText: 'Icon',
              border: OutlineInputBorder(),
            ),
            items: _iconOptions.map((option) {
              return DropdownMenuItem(
                value: option['id'],
                child: Row(
                  children: [
                    Icon(_getIconData(option['id']!)),
                    const SizedBox(width: 8),
                    Text(option['name']!),
                  ],
                ),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedIcon = value!;
              });
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_nameController.text.trim().isNotEmpty) {
              final updatedMethod = Map<String, dynamic>.from(widget.method);
              updatedMethod['name'] = _nameController.text.trim();
              updatedMethod['icon'] = _selectedIcon;

              widget.onEdit(updatedMethod);
              Navigator.pop(context);
            }
          },
          child: const Text('Save'),
        ),
      ],
    );
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'money':
        return Icons.money;
      case 'credit_card':
        return Icons.credit_card;
      case 'account_balance':
        return Icons.account_balance;
      case 'phone':
        return Icons.phone_android;
      case 'wallet':
        return Icons.wallet;
      default:
        return Icons.payment;
    }
  }
}