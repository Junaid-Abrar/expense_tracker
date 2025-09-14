import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:intl/intl.dart';

import '../models/user_model.dart';
import '../models/category_model.dart';
import '../core/services/firebase_service.dart';

enum AuthStatus { uninitialized, authenticated, unauthenticated, authenticating }

class AuthProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseService _firebaseService = FirebaseService();
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    serverClientId: '1035536884162-96duq1a9s7t4u1pv3rmlvfnij1sd8rc5.apps.googleusercontent.com',
  );

  User? _user;
  UserModel? _userModel;
  AuthStatus _status = AuthStatus.uninitialized;
  String? _errorMessage;
  bool _isSigningIn = false; // Flag to prevent auth state listener during sign-in

  // ---------------- GETTERS ----------------
  User? get user => _user;
  UserModel? get userModel => _userModel;
  AuthStatus get status => _status;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get isAuthenticating => _status == AuthStatus.authenticating;

  String get currency => _userModel?.currency ?? 'USD';
  String get locale => _userModel?.locale ?? 'en_US';
  String get theme => _userModel?.theme ?? 'system';
  bool get notificationsEnabled => _userModel?.notificationsEnabled ?? true;

  // ---------------- FORMATTERS ----------------
  String formatCurrency(num amount) {
    final code = currency;
    final format = NumberFormat.currency(locale: locale, symbol: code);
    return format.format(amount);
  }

  // ---------------- CONSTRUCTOR ----------------
  AuthProvider() {
    _auth.authStateChanges().listen(_onAuthStateChanged);
  }

  // ---------------- AUTH STATE ----------------
  Future<void> _onAuthStateChanged(User? user) async {
    // Skip processing if we're in the middle of signing in
    if (_isSigningIn) {
      debugPrint('Skipping auth state change during sign-in process');
      return;
    }
    
    // Prevent duplicate state changes that cause unnecessary rebuilds
    if (user == null) {
      if (_user != null) {  // Only update if state actually changed
        _user = null;
        _userModel = null;
        _status = AuthStatus.unauthenticated;
        notifyListeners();
      }
    } else {
      // Only process if this is a new user or user data changed
      if (_user?.uid != user.uid || _status != AuthStatus.authenticated) {
        _user = user;
        await _loadUserModel();
        _status = AuthStatus.authenticated;
        clearError();
        notifyListeners();
      }
    }
  }

  Future<void> _loadUserModel() async {
    if (_user == null) return;
    try {
      _userModel = await _firebaseService.getUserData(_user!.uid);
      if (_userModel == null) {
        final doc = await _firestore.collection('users').doc(_user!.uid).get();
        if (doc.exists) {
          _userModel = UserModel.fromFirestore(doc);
        }
      }
    } catch (e) {
      debugPrint('Error loading user model: $e');
    }
  }

  // ---------------- EMAIL/PASSWORD LOGIN ----------------
  Future<bool> signInWithEmailPassword(String email, String password) async {
    try {
      _isSigningIn = true; // Block auth state listener
      // Don't call _setAuthenticating() to prevent UI rebuilds
      
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      if (userCredential.user != null) {
        _user = userCredential.user!;
        await _loadUserModel();
        await _updateLastLogin(userCredential.user!.uid);
        clearError();
        _status = AuthStatus.authenticated;
        _isSigningIn = false; // Re-enable auth state listener
        notifyListeners();
        return true;
      }
    } catch (e) {
      _isSigningIn = false; // Re-enable auth state listener
      _handleAuthError(e, defaultMsg: 'Sign in failed. Please try again.');
    }
    _isSigningIn = false; // Re-enable auth state listener
    _status = AuthStatus.unauthenticated;
    notifyListeners();
    return false;
  }

  // ---------------- EMAIL/PASSWORD SIGNUP ----------------
  Future<bool> signUpWithEmailPassword({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      _setAuthenticating();
      final userModel = await _firebaseService.registerWithEmailAndPassword(
        displayName.trim(),
        email.trim(),
        password,
      );

      if (userModel != null) {
        _userModel = userModel;
        await _createDefaultCategories(userModel.id);
        clearError();
        _status = AuthStatus.authenticated;
        notifyListeners();
        return true;
      }
    } catch (e) {
      setError('Registration failed. Please try again.');
    }
    _status = AuthStatus.unauthenticated;
    notifyListeners();
    return false;
  }

  // ---------------- GOOGLE LOGIN ----------------
  Future<bool> signInWithGoogle() async {
    try {
      // Check and clear existing session in background (non-blocking)
      _googleSignIn.isSignedIn().then((isSignedIn) {
        if (isSignedIn) _googleSignIn.signOut();
      });

      // Immediately show Google Sign-in dialog
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        // User cancelled the sign-in process - no state change needed
        return false;
      }

      // Block auth state listener to prevent UI rebuilds
      _isSigningIn = true;
      
      final googleAuth = await googleUser.authentication;
      if (googleAuth.accessToken == null || googleAuth.idToken == null) {
        _isSigningIn = false;
        setError('Google Sign-In failed to retrieve tokens.');
        _status = AuthStatus.unauthenticated;
        notifyListeners();
        return false;
      }

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      if (userCredential.user != null) {
        // Set user and userModel BEFORE Firebase auth state change triggers
        _user = userCredential.user!;
        
        // Pre-load user data before updating authentication status
        await _createUserDocumentIfNeeded(userCredential.user!);
        await _updateLastLogin(userCredential.user!.uid);
        clearError();
        
        // Update status and re-enable auth listener
        _status = AuthStatus.authenticated;
        _isSigningIn = false;
        
        // Single notification after everything is ready
        notifyListeners();
        return true;
      }
    } catch (e) {
      _isSigningIn = false;
      setError('Google Sign-In failed. Please try again.');
    }

    _isSigningIn = false;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
    return false;
  }

  // ---------------- SIGN OUT ----------------
  Future<void> signOut() async {
    try {
      if (await _googleSignIn.isSignedIn()) await _googleSignIn.signOut();
      await _firebaseService.signOut();
      _user = null;
      _userModel = null;
      _status = AuthStatus.unauthenticated;
      clearError();
      notifyListeners();
    } catch (e) {
      setError('Error signing out. Please try again.');
    }
  }

  // ---------------- PROFILE / PREFERENCES ----------------
  Future<bool> updateProfile({
    String? displayName,
    String? photoURL,
    String? phoneNumber,
    String? currency,
    String? locale,
    String? theme,
    bool? notificationsEnabled,
    bool? biometricEnabled,
    Map<String, dynamic>? preferences,
  }) async {
    if (_user == null || _userModel == null) return false;
    try {
      if (displayName != null && displayName != _userModel!.displayName) {
        await _user!.updateDisplayName(displayName);
      }

      final updatedPreferences = {
        ...(_userModel!.preferences ?? {}),
        ...?preferences,
      };

      final updatedUser = _userModel!.copyWith(
        displayName: displayName,
        photoURL: photoURL,
        phoneNumber: phoneNumber,
        currency: currency,
        locale: locale,
        theme: theme,
        notificationsEnabled: notificationsEnabled,
        biometricEnabled: biometricEnabled,
        preferences: updatedPreferences,
        updatedAt: DateTime.now(),
      );

      await _firebaseService.updateUserData(updatedUser);
      _userModel = updatedUser;
      notifyListeners();
      return true;
    } catch (e) {
      setError('Error updating profile.');
      return false;
    }
  }

  // ---------------- PASSWORD / ACCOUNT MGMT ----------------
  Future<bool> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      clearError();
      return true;
    } catch (e) {
      setError('Password reset failed: $e');
      return false;
    }
  }


  Future<bool> updatePassword(String currentPassword, String newPassword) async {
    try {
      debugPrint("=== DEBUG: Starting password update ===");
      final user = _auth.currentUser;
      if (user == null) {
        debugPrint("DEBUG: No user logged in");
        setError("No user logged in");
        return false;
      }

      debugPrint("DEBUG: Current user email: ${user.email}");
      debugPrint("DEBUG: User providers: ${user.providerData.map((p) => p.providerId).toList()}");

      // Check if user signed in with email/password
      bool hasEmailProvider = false;
      for (final info in user.providerData) {
        debugPrint("DEBUG: Provider ID: ${info.providerId}");
        if (info.providerId == 'password') {
          hasEmailProvider = true;
          break;
        }
      }

      debugPrint("DEBUG: Has email provider: $hasEmailProvider");

      if (!hasEmailProvider) {
        debugPrint("DEBUG: User signed in with Google, cannot change password");
        setError("Password change is only available for email/password accounts. You signed in with Google.");
        return false;
      }

      // Check if new password is same as current password
      if (currentPassword == newPassword) {
        debugPrint("DEBUG: New password is same as current password");
        setError("New password must be different from your current password");
        return false;
      }

      debugPrint("DEBUG: Creating credential for reauthentication");
      // Reauthenticate with email/password before changing password
      final cred = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      
      debugPrint("DEBUG: Attempting reauthentication...");
      // This will throw an error if the current password is wrong
      await user.reauthenticateWithCredential(cred);
      debugPrint("DEBUG: Reauthentication successful!");

      debugPrint("DEBUG: Updating password...");
      // If we get here, the current password was correct
      await user.updatePassword(newPassword);
      debugPrint("DEBUG: Password updated successfully!");
      
      clearError();
      return true;
    } catch (e) {
      debugPrint("DEBUG: Error occurred: $e");
      debugPrint("DEBUG: Error type: ${e.runtimeType}");
      debugPrint("DEBUG: Error string: ${e.toString()}");
      
      // Handle specific Firebase Auth errors
      String errorMessage = "Password update failed";
      
      if (e.toString().contains('wrong-password') || 
          e.toString().contains('invalid-credential') ||
          e.toString().contains('INVALID_PASSWORD') ||
          e.toString().contains('invalid-password')) {
        errorMessage = "Current password is incorrect";
        debugPrint("DEBUG: Detected wrong password error");
      } else if (e.toString().contains('weak-password')) {
        errorMessage = "New password is too weak";
        debugPrint("DEBUG: Detected weak password error");
      } else if (e.toString().contains('requires-recent-login')) {
        errorMessage = "Please sign out and sign in again before changing password";
        debugPrint("DEBUG: Detected requires recent login error");
      } else {
        errorMessage = "Password update failed: ${e.toString()}";
        debugPrint("DEBUG: Unknown error type");
      }
      
      debugPrint("DEBUG: Setting error message: $errorMessage");
      setError(errorMessage);
      return false;
    }
  }

  Future<bool> deleteAccount(String password) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception("No user logged in");

      // Reauthenticate before deleting
      final cred = EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );
      await user.reauthenticateWithCredential(cred);

      await user.delete();
      _userModel = null;
      notifyListeners();
      return true;
    } catch (e) {
      setError("Account deletion failed: $e");
      return false;
    }
  }
  // ---------------- PREFERENCES ----------------
  T getPreference<T>(String key, T defaultValue) {
    if (_userModel?.preferences == null) return defaultValue;
    final value = _userModel!.preferences![key];
    return value is T ? value : defaultValue;
  }

  Future<bool> setPreference(String key, dynamic value) async {
    if (_userModel == null) return false;
    try {
      final updatedPrefs = {
        ...(_userModel!.preferences ?? {}),
        key: value,
      };
      final updatedUser = _userModel!.copyWith(
        preferences: updatedPrefs,
        updatedAt: DateTime.now(),
      );
      await _firebaseService.updateUserData(updatedUser);
      _userModel = updatedUser;
      notifyListeners();
      return true;
    } catch (e) {
      setError('Failed to update preferences.');
      return false;
    }
  }

  // ---------------- HELPERS ----------------
  void _setAuthenticating() {
    if (_status != AuthStatus.authenticating) {
      _status = AuthStatus.authenticating;
      clearError();
      // Only notify listeners if the UI actually needs to know about this state
      notifyListeners();
    }
  }
  
  void _setAuthenticatedSilently() {
    _status = AuthStatus.authenticated;
    // Don't notify listeners to prevent UI rebuilds during navigation
  }

  void setError(String message) {
    if (_errorMessage != message) {
      _errorMessage = message;
      notifyListeners();
    }
  }

  void clearError() {
    if (_errorMessage != null) {
      _errorMessage = null;
      notifyListeners();
    }
  }

  void _handleAuthError(Object e, {required String defaultMsg}) {
    debugPrint('Auth error: $e');
    setError(defaultMsg);
  }

  Future<void> _createUserDocumentIfNeeded(User user) async {
    final existingUser = await _firebaseService.getUserData(user.uid);
    if (existingUser == null) {
      final userModel = UserModel(
        id: user.uid,
        email: user.email!,
        displayName: user.displayName ?? user.email!.split('@')[0],
        photoURL: user.photoURL,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        lastLoginAt: DateTime.now(),
      );
      await _firebaseService.createUserDocument(userModel);
      await _createDefaultCategories(user.uid);
      _userModel = userModel;
    } else {
      _userModel = existingUser;
    }
  }

  Future<void> _createDefaultCategories(String userId) async {
    try {
      final defaultCategories = CategoryModel.getDefaultCategories(userId);

      // Use batch operations for better performance
      final batch = _firestore.batch();
      for (final category in defaultCategories) {
        final docRef = _firestore
            .collection('users')
            .doc(userId)
            .collection('categories')
            .doc(category.id);
        batch.set(docRef, category.toMap());
      }
      await batch.commit();

      print('DEBUG: Created ${defaultCategories.length} default categories with translation keys');
    } catch (e) {
      debugPrint('Error creating default categories: $e');
    }
  }

  Future<void> _updateLastLogin(String userId) async {
    await _firestore.collection('users').doc(userId).update({
      'lastLoginAt': Timestamp.now(),
    });
  }
}
