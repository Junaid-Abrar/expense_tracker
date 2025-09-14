import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/category_model.dart';

class CategoryProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<CategoryModel> _categories = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  List<CategoryModel> get categories => _categories;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Get categories by type using your existing model structure
  List<CategoryModel> get expenseCategories =>
      _categories.where((cat) => cat.isExpenseCategory).toList();

  List<CategoryModel> get incomeCategories =>
      _categories.where((cat) => cat.isIncomeCategory).toList();

  // Get current user ID
  String? get _currentUserId => _auth.currentUser?.uid;

  // Initialize categories
  // In CategoryProvider, replace your existing initializeCategories method:
  Future<void> initializeCategories() async {
    if (_currentUserId == null) return;

    _setLoading(true);
    try {
      await loadCategories();

      // Auto-fix categories if they need translation keys
      final needsUpdate = await needsTranslationUpdate();
      if (needsUpdate) {
        print('DEBUG: Auto-updating categories for translation support...');
        await recreateDefaultCategories();
      }
    } catch (e) {
      _setError('Failed to initialize categories: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Load categories from Firebase
  Future<void> loadCategories() async {
    if (_currentUserId == null) return;

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('categories')
          .get();

      _categories = snapshot.docs
          .map((doc) => CategoryModel.fromMap(doc.data()))
          .toList();
      notifyListeners();
    } catch (e) {
      _setError('Failed to load categories: $e');
    }
  }

  // Add new category
  Future<void> addCategory(CategoryModel category) async {
    if (_currentUserId == null) return;

    _setLoading(true);
    try {
      final docRef = await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('categories')
          .add(category.toMap());

      final newCategory = category.copyWith(id: docRef.id);
      await docRef.update({'id': docRef.id});

      _categories.add(newCategory);
      notifyListeners();
    } catch (e) {
      _setError('Failed to add category: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Update category
  Future<void> updateCategory(CategoryModel category) async {
    if (_currentUserId == null) return;

    _setLoading(true);
    try {
      await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('categories')
          .doc(category.id)
          .update(category.toMap());

      final index = _categories.indexWhere((cat) => cat.id == category.id);
      if (index != -1) {
        _categories[index] = category;
        notifyListeners();
      }
    } catch (e) {
      _setError('Failed to update category: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Delete category
  Future<void> deleteCategory(String categoryId) async {
    if (_currentUserId == null) return;

    _setLoading(true);
    try {
      await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('categories')
          .doc(categoryId)
          .delete();

      _categories.removeWhere((cat) => cat.id == categoryId);
      notifyListeners();
    } catch (e) {
      _setError('Failed to delete category: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Get category by ID
  CategoryModel? getCategoryById(String id) {
    try {
      return _categories.firstWhere((cat) => cat.id == id);
    } catch (e) {
      return null;
    }
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
  void clearData() {
    _categories.clear();
    notifyListeners();
  }

  // Add to CategoryProvider class

// Method to recreate default categories with translation keys
  Future<void> recreateDefaultCategories() async {
    if (_currentUserId == null) return;

    _setLoading(true);
    try {
      print('DEBUG: Starting to recreate default categories...');

      // Step 1: Delete all existing default categories
      await _deleteDefaultCategories();

      // Step 2: Create new default categories with translation keys
      await _createDefaultCategories();

      // Step 3: Reload categories
      await loadCategories();

      print('DEBUG: Default categories recreated successfully');
    } catch (e) {
      print('DEBUG: Error recreating categories: $e');
      _setError('Failed to recreate default categories: $e');
    } finally {
      _setLoading(false);
    }
  }

// Delete existing default categories
  Future<void> _deleteDefaultCategories() async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('categories')
          .where('isDefault', isEqualTo: true)
          .get();

      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      print('DEBUG: Deleted ${snapshot.docs.length} default categories');
    } catch (e) {
      print('DEBUG: Error deleting default categories: $e');
    }
  }

// Create new default categories with translation keys
  Future<void> _createDefaultCategories() async {
    try {
      final defaultCategories = CategoryModel.getDefaultCategories(_currentUserId!);

      final batch = _firestore.batch();
      for (final category in defaultCategories) {
        final docRef = _firestore
            .collection('users')
            .doc(_currentUserId)
            .collection('categories')
            .doc(category.id);
        batch.set(docRef, category.toMap());
      }
      await batch.commit();

      print('DEBUG: Created ${defaultCategories.length} new default categories with translation keys');
    } catch (e) {
      print('DEBUG: Error creating default categories: $e');
    }
  }

// Check if categories need translation keys (diagnostic method)
  Future<bool> needsTranslationUpdate() async {
    if (_currentUserId == null) return false;

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('categories')
          .where('isDefault', isEqualTo: true)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return true;

      final firstCategory = snapshot.docs.first.data();
      final hasTranslationKey = firstCategory.containsKey('translationKey') &&
          firstCategory['translationKey'] != null;

      print('DEBUG: Categories need update: ${!hasTranslationKey}');
      return !hasTranslationKey;
    } catch (e) {
      print('DEBUG: Error checking translation keys: $e');
      return false;
    }
  }

  String? get errorMessage => _error;
}