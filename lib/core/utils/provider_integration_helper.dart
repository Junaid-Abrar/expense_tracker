import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/expense_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/budget_provider.dart';

/// Helper class to coordinate data loading across providers when user authentication state changes
class ProviderIntegrationHelper {
  /// Initialize all user data after successful authentication
  static Future<void> initializeUserData(BuildContext context) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      if (!authProvider.isAuthenticated) {
        debugPrint('User not authenticated, skipping data initialization');
        return;
      }

      debugPrint('Initializing user data...');

      // Load data in parallel for better performance
      await Future.wait([
        _loadCategories(context),
        _loadExpenses(context),
        _loadBudgets(context),
      ]);

      debugPrint('User data initialization completed');
    } catch (e) {
      debugPrint('Error initializing user data: $e');
    }
  }

  /// Load categories data
  static Future<void> _loadCategories(BuildContext context) async {
    try {
      final categoryProvider = Provider.of<CategoryProvider>(context, listen: false);
      await categoryProvider.loadCategories();
      debugPrint('Categories loaded successfully');
    } catch (e) {
      debugPrint('Error loading categories: $e');
    }
  }

  /// Load expenses data
  static Future<void> _loadExpenses(BuildContext context) async {
    try {
      final expenseProvider = Provider.of<ExpenseProvider>(context, listen: false);
      await expenseProvider.loadExpenses();
      debugPrint('Expenses loaded successfully');
    } catch (e) {
      debugPrint('Error loading expenses: $e');
    }
  }

  /// Load budgets data
  static Future<void> _loadBudgets(BuildContext context) async {
    try {
      final budgetProvider = Provider.of<BudgetProvider>(context, listen: false);
      await budgetProvider.loadBudgets();
      debugPrint('Budgets loaded successfully');
    } catch (e) {
      debugPrint('Error loading budgets: $e');
    }
  }

  /// Clear all user data when user signs out
  static void clearUserData(BuildContext context) {
    try {
      debugPrint('Clearing user data...');

      // Clear data from all providers
      final expenseProvider = Provider.of<ExpenseProvider>(context, listen: false);
      final categoryProvider = Provider.of<CategoryProvider>(context, listen: false);
      final budgetProvider = Provider.of<BudgetProvider>(context, listen: false);

      expenseProvider.clearData();
      categoryProvider.clearData();
      budgetProvider.clearData();

      debugPrint('User data cleared successfully');
    } catch (e) {
      debugPrint('Error clearing user data: $e');
    }
  }

  /// Refresh all user data (useful for pull-to-refresh)
  static Future<void> refreshUserData(BuildContext context) async {
    try {
      debugPrint('Refreshing user data...');

      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      if (!authProvider.isAuthenticated) {
        debugPrint('User not authenticated, skipping data refresh');
        return;
      }

      // Refresh data in parallel
      await Future.wait([
        _loadCategories(context),
        _loadExpenses(context),
        _loadBudgets(context),
      ]);

      debugPrint('User data refresh completed');
    } catch (e) {
      debugPrint('Error refreshing user data: $e');
    }
  }

  /// Check if any provider is currently loading
  static bool isAnyProviderLoading(BuildContext context) {
    final expenseProvider = Provider.of<ExpenseProvider>(context, listen: false);
    final categoryProvider = Provider.of<CategoryProvider>(context, listen: false);
    final budgetProvider = Provider.of<BudgetProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    return expenseProvider.isLoading ||
        categoryProvider.isLoading ||
        budgetProvider.isLoading ||
        authProvider.isAuthenticating;
  }

  /// Get combined error messages from all providers
  static List<String> getAllErrors(BuildContext context) {
    final errors = <String>[];

    final expenseProvider = Provider.of<ExpenseProvider>(context, listen: false);
    final categoryProvider = Provider.of<CategoryProvider>(context, listen: false);
    final budgetProvider = Provider.of<BudgetProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (expenseProvider.errorMessage != null) {
      errors.add('Expenses: ${expenseProvider.errorMessage}');
    }
    if (categoryProvider.errorMessage != null) {
      errors.add('Categories: ${categoryProvider.errorMessage}');
    }
    if (budgetProvider.errorMessage != null) {
      errors.add('Budgets: ${budgetProvider.errorMessage}');
    }
    if (authProvider.errorMessage != null) {
      errors.add('Auth: ${authProvider.errorMessage}');
    }

    return errors;
  }

  /// Clear all error messages from providers
  static void clearAllErrors(BuildContext context) {
    final expenseProvider = Provider.of<ExpenseProvider>(context, listen: false);
    final categoryProvider = Provider.of<CategoryProvider>(context, listen: false);
    final budgetProvider = Provider.of<BudgetProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // Note: These methods should be added to respective providers
    // For now, we can call clearError on AuthProvider
    authProvider.clearError();
  }
}