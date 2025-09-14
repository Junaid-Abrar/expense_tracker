import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/expense_model.dart';
import '../core/services/firebase_service.dart';

class ExpenseProvider with ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();

  List<ExpenseModel> _expenses = [];
  List<ExpenseModel> _filteredExpenses = [];
  bool _isLoading = false;
  String? _errorMessage;
  String _currentFilter = 'all'; // 'all', 'expense', 'income'
  DateTime? _startDate;
  DateTime? _endDate;
  String? _selectedCategoryId;
  String _searchQuery = '';

  // Getters
  List<ExpenseModel> get expenses => _filteredExpenses;
  List<ExpenseModel> get allExpenses => _expenses;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get currentFilter => _currentFilter;
  DateTime? get startDate => _startDate;
  DateTime? get endDate => _endDate;
  String? get selectedCategoryId => _selectedCategoryId;
  String get searchQuery => _searchQuery;

  // Analytics getters
  double get totalExpenses => _filteredExpenses
      .where((e) => e.isExpense)
      .fold(0.0, (sum, e) => sum + e.amount);

  double get totalIncome => _filteredExpenses
      .where((e) => e.isIncome)
      .fold(0.0, (sum, e) => sum + e.amount);

  double get netAmount => totalIncome - totalExpenses;

  Map<String, double> get categoryWiseExpenses {
    final Map<String, double> totals = {};
    for (final e in _filteredExpenses.where((e) => e.isExpense)) {
      totals[e.categoryName] = (totals[e.categoryName] ?? 0) + e.amount;
    }
    return totals;
  }

  Map<String, List<ExpenseModel>> get expensesByCategory {
    final Map<String, List<ExpenseModel>> grouped = {};
    for (final e in _filteredExpenses) {
      grouped.putIfAbsent(e.categoryName, () => []);
      grouped[e.categoryName]!.add(e);
    }
    return grouped;
  }

  // Recent expenses (last 5)
  List<ExpenseModel> get recentExpenses =>
      _expenses.take(5).toList();

  // Top spending categories
  List<MapEntry<String, double>> get topSpendingCategories {
    final categories = categoryWiseExpenses.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return categories.take(5).toList();
  }

  // Load expenses from Firestore using FirebaseService
  Future<void> loadExpenses() async {
    if (!_firebaseService.isSignedIn) {
      _setError('User not signed in');
      return;
    }

    _setLoading(true);
    try {
      _expenses = await _firebaseService.getExpenses();
      _applyFilters();
      _clearError();
    } catch (e) {
      _setError('Failed to load expenses: $e');
    }
    _setLoading(false);
  }

  // Load expenses by date range
  Future<void> loadExpensesByDateRange(DateTime startDate, DateTime endDate) async {
    if (!_firebaseService.isSignedIn) {
      _setError('User not signed in');
      return;
    }

    _setLoading(true);
    try {
      _expenses = await _firebaseService.getExpensesByDateRange(startDate, endDate);
      _applyFilters();
      _clearError();
    } catch (e) {
      _setError('Failed to load expenses: $e');
    }
    _setLoading(false);
  }

  // Get specific expense by ID
  ExpenseModel? getExpenseById(String id) {
    try {
      return _expenses.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }

  // Add expense using FirebaseService
  Future<bool> addExpense({
    required String title,
    String? description,
    required double amount,
    required String categoryId,
    required String categoryName,
    required String type,
    required DateTime date,
    String? receiptImageUrl,
    List<String>? tags,
    bool isRecurring = false,
    String? recurringType,
    DateTime? recurringEndDate,
    String? paymentMethod,
  }) async {
    if (!_firebaseService.isSignedIn) {
      _setError('User not signed in');
      return false;
    }

    try {
      _setLoading(true);

      final newExpense = ExpenseModel(
        id: '', // FirebaseService will generate this
        userId: _firebaseService.currentUserId!,
        title: title,
        description: description,
        amount: amount,
        categoryId: categoryId,
        categoryName: categoryName,
        type: type,
        date: date,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        receiptImageUrl: receiptImageUrl,
        tags: tags,
        isRecurring: isRecurring,
        recurringType: recurringType,
        recurringEndDate: recurringEndDate,
        paymentMethod: paymentMethod,
      );

      final addedExpense = await _firebaseService.addExpense(newExpense);

      // Add to local list and sort by date
      _expenses.insert(0, addedExpense);
      _expenses.sort((a, b) => b.date.compareTo(a.date));

      _applyFilters();
      _clearError();

      // Handle recurring expenses
      if (isRecurring && recurringType != null && recurringEndDate != null) {
        await _createRecurringExpenses(addedExpense);
      }

      return true;
    } catch (e) {
      _setError('Failed to add expense: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Update expense using FirebaseService
  Future<bool> updateExpense({
    required String expenseId,
    String? title,
    String? description,
    double? amount,
    String? categoryId,
    String? categoryName,
    DateTime? date,
    String? type,
    String? receiptImageUrl,
    List<String>? tags,
    bool? isRecurring,
    String? recurringType,
    DateTime? recurringEndDate,
    String? paymentMethod,
  }) async {
    if (!_firebaseService.isSignedIn) {
      _setError('User not signed in');
      return false;
    }

    try {
      _setLoading(true);

      final index = _expenses.indexWhere((e) => e.id == expenseId);
      if (index == -1) {
        _setError('Expense not found');
        return false;
      }

      final current = _expenses[index];
      final updated = current.copyWith(
        title: title,
        description: description,
        amount: amount,
        categoryId: categoryId,
        categoryName: categoryName,
        date: date,
        type: type,
        receiptImageUrl: receiptImageUrl,
        tags: tags,
        isRecurring: isRecurring,
        recurringType: recurringType,
        recurringEndDate: recurringEndDate,
        paymentMethod: paymentMethod,
        updatedAt: DateTime.now(),
      );

      await _firebaseService.updateExpense(updated);

      _expenses[index] = updated;
      _expenses.sort((a, b) => b.date.compareTo(a.date));
      _applyFilters();
      _clearError();

      return true;
    } catch (e) {
      _setError('Failed to update expense: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Delete expense using FirebaseService
  Future<bool> deleteExpense(String expenseId) async {
    if (!_firebaseService.isSignedIn) {
      _setError('User not signed in');
      return false;
    }

    try {
      _setLoading(true);

      await _firebaseService.deleteExpense(expenseId);

      _expenses.removeWhere((e) => e.id == expenseId);
      _applyFilters();
      _clearError();

      return true;
    } catch (e) {
      _setError('Failed to delete expense: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Filtering methods
  void setFilter(String filter) {
    if (_currentFilter != filter) {
      _currentFilter = filter;
      _applyFilters();
    }
  }

  void setDateRange(DateTime? start, DateTime? end) {
    _startDate = start;
    _endDate = end;
    _applyFilters();
  }

  void setCategoryFilter(String? categoryId) {
    _selectedCategoryId = categoryId;
    _applyFilters();
  }

  void setSearchQuery(String query) {
    _searchQuery = query.toLowerCase();
    _applyFilters();
  }

  void clearFilters() {
    _currentFilter = 'all';
    _startDate = null;
    _endDate = null;
    _selectedCategoryId = null;
    _searchQuery = '';
    _applyFilters();
  }

  // Apply all active filters
  void _applyFilters() {
    _filteredExpenses = _expenses.where((e) {
      // Type filter
      if (_currentFilter == 'expense' && !e.isExpense) return false;
      if (_currentFilter == 'income' && !e.isIncome) return false;

      // Date range filter - add null safety for corrupted data
      if (_startDate != null && e.date.isBefore(_startDate!)) return false;
      if (_endDate != null && e.date.isAfter(_endDate!)) return false;

      // Category filter
      if (_selectedCategoryId != null && e.categoryId != _selectedCategoryId) return false;

      // Search filter
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final matchesTitle = e.title.toLowerCase().contains(query);
        final matchesDescription = e.description?.toLowerCase().contains(query) ?? false;
        final matchesCategory = e.categoryName.toLowerCase().contains(query);
        final matchesTags = e.tags?.any((tag) => tag.toLowerCase().contains(query)) ?? false;

        if (!matchesTitle && !matchesDescription && !matchesCategory && !matchesTags) {
          return false;
        }
      }

      return true;
    }).toList();

    notifyListeners();
  }

  // Recurring expenses helper
  Future<void> _createRecurringExpenses(ExpenseModel base) async {
    if (!base.isRecurring || base.recurringType == null || base.recurringEndDate == null) return;

    try {
      DateTime nextDate = _getNextRecurringDate(base.date, base.recurringType!);
      int count = 0;
      const maxRecurring = 100; // Prevent infinite loops

      while (nextDate.isBefore(base.recurringEndDate!) && count < maxRecurring) {
        final recurring = base.copyWith(
          id: '', // Will be generated by FirebaseService
          date: nextDate,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await _firebaseService.addExpense(recurring);
        nextDate = _getNextRecurringDate(nextDate, base.recurringType!);
        count++;
      }

      // Reload expenses to get the new recurring ones
      await loadExpenses();
    } catch (e) {
      _setError('Failed to create recurring expenses: $e');
    }
  }

  DateTime _getNextRecurringDate(DateTime current, String type) {
    switch (type.toLowerCase()) {
      case 'daily':
        return current.add(const Duration(days: 1));
      case 'weekly':
        return current.add(const Duration(days: 7));
      case 'monthly':
        return DateTime(current.year, current.month + 1, current.day);
      case 'yearly':
        return DateTime(current.year + 1, current.month, current.day);
      default:
        return current.add(const Duration(days: 30));
    }
  }

  // Analytics methods with additional safety checks
  double getTotalForPeriod(DateTime start, DateTime end, {bool expensesOnly = true}) {
    return _expenses.where((e) {
      if (expensesOnly && !e.isExpense) return false;
      // Additional safety check for date comparisons
      try {
        return e.date.isAfter(start.subtract(const Duration(days: 1))) &&
            e.date.isBefore(end.add(const Duration(days: 1)));
      } catch (e) {
        // Skip this expense if date comparison fails
        return false;
      }
    }).fold(0.0, (sum, e) => sum + e.amount);
  }

  Map<String, double> getCategoryTotalsForPeriod(DateTime start, DateTime end) {
    final Map<String, double> totals = {};
    final periodExpenses = _expenses.where((e) {
      if (!e.isExpense) return false;
      // Additional safety check for date comparisons
      try {
        return e.date.isAfter(start.subtract(const Duration(days: 1))) &&
            e.date.isBefore(end.add(const Duration(days: 1)));
      } catch (e) {
        // Skip this expense if date comparison fails
        return false;
      }
    });

    for (final expense in periodExpenses) {
      totals[expense.categoryName] = (totals[expense.categoryName] ?? 0) + expense.amount;
    }

    return totals;
  }

  // Utility methods
  void _setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
    }
  }

  void _setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  void _clearError() {
    if (_errorMessage != null) {
      _errorMessage = null;
      notifyListeners();
    }
  }

  // Clear all data (useful when user signs out)
  void clearData() {
    _expenses.clear();
    _filteredExpenses.clear();
    _currentFilter = 'all';
    _startDate = null;
    _endDate = null;
    _selectedCategoryId = null;
    _searchQuery = '';
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();
  }
}