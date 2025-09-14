import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/expense_model.dart';
import '../../models/category_model.dart';
import '../../models/budget_model.dart';
import '../../models/user_model.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  // User collection reference
  CollectionReference get _users => _firestore.collection('users');

  // User-specific collections
  CollectionReference _userExpenses(String userId) =>
      _users.doc(userId).collection('expenses');

  CollectionReference _userCategories(String userId) =>
      _users.doc(userId).collection('categories');

  CollectionReference _userBudgets(String userId) =>
      _users.doc(userId).collection('budgets');

  // AUTHENTICATION METHODS

  // Sign in with email and password
  Future<UserModel?> signInWithEmailAndPassword(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        return await getUserData(credential.user!.uid);
      }
      return null;
    } catch (e) {
      throw Exception('Sign in failed: $e');
    }
  }

  // Register with email and password
  Future<UserModel?> registerWithEmailAndPassword(
      String displayName,
      String email,
      String password
      ) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        // Create user document
        final user = UserModel(
          id: credential.user!.uid,
          displayName: displayName,
          email: email,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await createUserDocument(user);
        return user;
      }
      return null;
    } catch (e) {
      throw Exception('Registration failed: $e');
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      throw Exception('Password reset failed: $e');
    }
  }

  // USER METHODS

  // Create user document
  Future<void> createUserDocument(UserModel user) async {
    try {
      await _users.doc(user.id).set(user.toMap());
    } catch (e) {
      throw Exception('Failed to create user document: $e');
    }
  }

  // Get user data
  Future<UserModel?> getUserData(String userId) async {
    try {
      final doc = await _users.doc(userId).get();
      if (doc.exists) {
        return UserModel.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get user data: $e');
    }
  }

  // Update user data
  Future<void> updateUserData(UserModel user) async {
    try {
      await _users.doc(user.id).update(user.toMap());
    } catch (e) {
      throw Exception('Failed to update user data: $e');
    }
  }

  // EXPENSE METHODS

  // Add expense
  Future<ExpenseModel> addExpense(ExpenseModel expense) async {
    try {
      if (currentUserId == null) throw Exception('User not authenticated');

      final docRef = await _userExpenses(currentUserId!).add(expense.toMap());
      final newExpense = expense.copyWith(id: docRef.id);

      // Update the document with the ID
      await docRef.update({'id': docRef.id});

      return newExpense;
    } catch (e) {
      throw Exception('Failed to add expense: $e');
    }
  }

  // Get expenses
  Future<List<ExpenseModel>> getExpenses() async {
    try {
      if (currentUserId == null) throw Exception('User not authenticated');

      final querySnapshot = await _userExpenses(currentUserId!)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => ExpenseModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to get expenses: $e');
    }
  }

  // Get expenses by date range
  Future<List<ExpenseModel>> getExpensesByDateRange(DateTime startDate, DateTime endDate) async {
    try {
      if (currentUserId == null) throw Exception('User not authenticated');

      final querySnapshot = await _userExpenses(currentUserId!)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .orderBy('date', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => ExpenseModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to get expenses by date range: $e');
    }
  }

  // Update expense
  Future<void> updateExpense(ExpenseModel expense) async {
    try {
      if (currentUserId == null) throw Exception('User not authenticated');

      await _userExpenses(currentUserId!).doc(expense.id).update(expense.toMap());
    } catch (e) {
      throw Exception('Failed to update expense: $e');
    }
  }

  // Delete expense
  Future<void> deleteExpense(String expenseId) async {
    try {
      if (currentUserId == null) throw Exception('User not authenticated');

      await _userExpenses(currentUserId!).doc(expenseId).delete();
    } catch (e) {
      throw Exception('Failed to delete expense: $e');
    }
  }

  // CATEGORY METHODS

  // Add category
  Future<CategoryModel> addCategory(CategoryModel category) async {
    try {
      if (currentUserId == null) throw Exception('User not authenticated');

      final docRef = await _userCategories(currentUserId!).add(category.toMap());
      final newCategory = category.copyWith(id: docRef.id);

      // Update the document with the ID
      await docRef.update({'id': docRef.id});

      return newCategory;
    } catch (e) {
      throw Exception('Failed to add category: $e');
    }
  }

  // Get categories
  Future<List<CategoryModel>> getCategories() async {
    try {
      if (currentUserId == null) throw Exception('User not authenticated');

      final querySnapshot = await _userCategories(currentUserId!)
          .orderBy('name')
          .get();

      return querySnapshot.docs
          .map((doc) => CategoryModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to get categories: $e');
    }
  }

  // Update category
  Future<void> updateCategory(CategoryModel category) async {
    try {
      if (currentUserId == null) throw Exception('User not authenticated');

      await _userCategories(currentUserId!).doc(category.id).update(category.toMap());
    } catch (e) {
      throw Exception('Failed to update category: $e');
    }
  }

  // Delete category
  Future<void> deleteCategory(String categoryId) async {
    try {
      if (currentUserId == null) throw Exception('User not authenticated');

      await _userCategories(currentUserId!).doc(categoryId).delete();
    } catch (e) {
      throw Exception('Failed to delete category: $e');
    }
  }

  // BUDGET METHODS

  // Add budget
  Future<BudgetModel> addBudget(BudgetModel budget) async {
    try {
      if (currentUserId == null) throw Exception('User not authenticated');

      final docRef = await _userBudgets(currentUserId!).add(budget.toMap());
      final newBudget = budget.copyWith(id: docRef.id);

      // Update the document with the ID
      await docRef.update({'id': docRef.id});

      return newBudget;
    } catch (e) {
      throw Exception('Failed to add budget: $e');
    }
  }

  // Get budgets
  Future<List<BudgetModel>> getBudgets() async {
    try {
      if (currentUserId == null) throw Exception('User not authenticated');

      final querySnapshot = await _userBudgets(currentUserId!)
          .orderBy('startDate', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => BudgetModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to get budgets: $e');
    }
  }

  // Update budget
  Future<void> updateBudget(BudgetModel budget) async {
    try {
      if (currentUserId == null) throw Exception('User not authenticated');

      await _userBudgets(currentUserId!).doc(budget.id).update(budget.toMap());
    } catch (e) {
      throw Exception('Failed to update budget: $e');
    }
  }

  // Delete budget
  Future<void> deleteBudget(String budgetId) async {
    try {
      if (currentUserId == null) throw Exception('User not authenticated');

      await _userBudgets(currentUserId!).doc(budgetId).delete();
    } catch (e) {
      throw Exception('Failed to delete budget: $e');
    }
  }

  // UTILITY METHODS

  // Listen to auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Check if user is signed in
  bool get isSignedIn => _auth.currentUser != null;

  // Get current user
  User? get currentUser => _auth.currentUser;
}