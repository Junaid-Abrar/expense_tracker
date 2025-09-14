// import 'package:flutter/material.dart';
// import '../models/user_model.dart';
//
// class UserProvider with ChangeNotifier {
//   UserModel? _user;
//
//   UserModel? get user => _user;
//
//   // Set the current user (used by AuthProvider after login/signup)
//   void setUser(UserModel user) {
//     _user = user;
//     notifyListeners();
//   }
//
//   // Clear user (used on sign out)
//   void clearUser() {
//     _user = null;
//     notifyListeners();
//   }
//
//   // Update fields inside user (like currency, locale, etc.)
//   void updateUser({
//     String? displayName,
//     String? photoURL,
//     String? phoneNumber,
//     String? currency,
//     String? locale,
//     String? theme,
//     bool? notificationsEnabled,
//     bool? biometricEnabled,
//     Map<String, dynamic>? preferences,
//   }) {
//     if (_user == null) return;
//
//     _user = _user!.copyWith(
//       displayName: displayName,
//       photoURL: photoURL,
//       phoneNumber: phoneNumber,
//       currency: currency,
//       locale: locale,
//       theme: theme,
//       notificationsEnabled: notificationsEnabled,
//       biometricEnabled: biometricEnabled,
//       preferences: preferences,
//       updatedAt: DateTime.now(),
//     );
//
//     notifyListeners();
//   }
//
//   // Convenience getters
//   String get currency => _user?.currency ?? 'USD';
//   String get locale => _user?.locale ?? 'en_US';
//   String get theme => _user?.theme ?? 'system';
//   bool get isLoggedIn => _user != null;
//
//   // Currency formatting passthrough
//   String formatCurrency(double amount) {
//     if (_user == null) return amount.toStringAsFixed(2);
//     return _user!.formatCurrency(amount);
//   }
// }
