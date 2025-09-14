import 'package:flutter/foundation.dart';
import '../models/budget_model.dart';
import '../models/expense_model.dart';
import '../core/services/firebase_service.dart';

class BudgetProvider extends ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();

  List<BudgetModel> _budgets = [];
  bool _isLoading = false;
  String? _error;
  Map<String, double> _categorySpending = {};

  // Getters
  List<BudgetModel> get budgets => _budgets;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<String, double> get categorySpending => _categorySpending;

  // Get active budgets
  List<BudgetModel> get activeBudgets =>
      _budgets.where((budget) => budget.isActive).toList();

  // Get budgets for current month
  List<BudgetModel> get currentMonthBudgets {
    final now = DateTime.now();
    return _budgets.where((budget) {
      return budget.startDate.month == now.month &&
          budget.startDate.year == now.year;
    }).toList();
  }

  // Initialize budgets
  Future<void> initializeBudgets() async {
    _setLoading(true);
    try {
      await loadBudgets();
      await _calculateCategorySpending();
    } catch (e) {
      _setError('Failed to initialize budgets: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Load budgets from Firebase
  Future<void> loadBudgets() async {
    try {
      _budgets = await _firebaseService.getBudgets();
      notifyListeners();
    } catch (e) {
      _setError('Failed to load budgets: $e');
    }
  }

  // Add new budget
  Future<void> addBudget(BudgetModel budget) async {
    _setLoading(true);
    try {
      final newBudget = await _firebaseService.addBudget(budget);
      _budgets.add(newBudget);
      await _calculateCategorySpending();
      notifyListeners();
    } catch (e) {
      _setError('Failed to add budget: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Update budget
  Future<void> updateBudget(BudgetModel budget) async {
    _setLoading(true);
    try {
      await _firebaseService.updateBudget(budget);
      final index = _budgets.indexWhere((b) => b.id == budget.id);
      if (index != -1) {
        _budgets[index] = budget;
        await _calculateCategorySpending();
        notifyListeners();
      }
    } catch (e) {
      _setError('Failed to update budget: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Delete budget
  Future<void> deleteBudget(String budgetId) async {
    _setLoading(true);
    try {
      await _firebaseService.deleteBudget(budgetId);
      _budgets.removeWhere((budget) => budget.id == budgetId);
      await _calculateCategorySpending();
      notifyListeners();
    } catch (e) {
      _setError('Failed to delete budget: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Get budget by ID
  BudgetModel? getBudgetById(String id) {
    try {
      return _budgets.firstWhere((budget) => budget.id == id);
    } catch (e) {
      return null;
    }
  }

  // Get budget by category
  BudgetModel? getBudgetByCategory(String categoryId) {
    try {
      final now = DateTime.now();
      return _budgets.firstWhere((budget) =>
      budget.categoryId == categoryId &&
          budget.isActive &&
          budget.startDate.month == now.month &&
          budget.startDate.year == now.year);
    } catch (e) {
      return null;
    }
  }

  // Get budget progress for category
  double getBudgetProgress(String categoryId) {
    final budget = getBudgetByCategory(categoryId);
    if (budget == null) return 0.0;

    final spent = _categorySpending[categoryId] ?? 0.0;
    return spent / budget.amount;
  }

  // Get remaining budget for category
  double getRemainingBudget(String categoryId) {
    final budget = getBudgetByCategory(categoryId);
    if (budget == null) return 0.0;

    final spent = _categorySpending[categoryId] ?? 0.0;
    return budget.amount - spent;
  }

  // Check if budget is exceeded
  bool isBudgetExceeded(String categoryId) {
    return getBudgetProgress(categoryId) > 1.0;
  }

  // Get budget status
  BudgetStatus getBudgetStatus(String categoryId) {
    final progress = getBudgetProgress(categoryId);

    if (progress >= 1.0) return BudgetStatus.exceeded;
    if (progress >= 0.8) return BudgetStatus.warning;
    return BudgetStatus.onTrack;
  }

  // Get total budget for current month
  double get totalMonthlyBudget {
    return currentMonthBudgets.fold(0.0, (sum, budget) => sum + budget.amount);
  }

  // Get total spent for current month
  double get totalMonthlySpent {
    return _categorySpending.values.fold(0.0, (sum, amount) => sum + amount);
  }

  // Get overall budget progress
  double get overallBudgetProgress {
    final total = totalMonthlyBudget;
    if (total == 0) return 0.0;
    return totalMonthlySpent / total;
  }

  // Calculate category spending
  Future<void> _calculateCategorySpending() async {
    try {
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      final endOfMonth = DateTime(now.year, now.month + 1, 0);

      final expenses = await _firebaseService.getExpensesByDateRange(
          startOfMonth,
          endOfMonth
      );

      _categorySpending.clear();

      for (final expense in expenses) {
        final categoryId = expense.categoryId;
        _categorySpending[categoryId] =
            (_categorySpending[categoryId] ?? 0.0) + expense.amount;
      }

      notifyListeners();
    } catch (e) {
      _setError('Failed to calculate spending: $e');
    }
  }

  // Refresh budget data
  Future<void> refresh() async {
    await loadBudgets();
    await _calculateCategorySpending();
  }

  // Helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
  // Add this at the bottom before the closing brace
  void clearData() {
    _budgets.clear();
    _categorySpending.clear();
    notifyListeners();
  }

  String? get errorMessage => _error;
}

enum BudgetStatus {
  onTrack,
  warning,
  exceeded,
}