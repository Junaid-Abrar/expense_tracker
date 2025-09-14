import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String email;
  final String displayName;
  final String? photoURL;
  final String? phoneNumber;
  final String currency;
  final String locale; // e.g. en_US
  final String theme; // 'light', 'dark', 'system'
  final bool notificationsEnabled;
  final bool biometricEnabled;
  final Map<String, dynamic>? preferences;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastLoginAt;

  UserModel({
    required this.id,
    required this.email,
    required this.displayName,
    this.photoURL,
    this.phoneNumber,
    this.currency = 'USD',
    this.locale = 'en_US',
    this.theme = 'system',
    this.notificationsEnabled = true,
    this.biometricEnabled = false,
    this.preferences,
    required this.createdAt,
    required this.updatedAt,
    this.lastLoginAt,
  });

  // For old code that used `user.language`
  String get language => locale;
  String get languageCode => locale.split('_').first;

  // ✅ Currency formatting helper
  String formatCurrency(double amount) {
    switch (currency) {
      case 'USD':
        return '\$${amount.toStringAsFixed(2)}';
      case 'EUR':
        return '€${amount.toStringAsFixed(2)}';
      case 'GBP':
        return '£${amount.toStringAsFixed(2)}';
      case 'JPY':
        return '¥${amount.toStringAsFixed(0)}';
      case 'INR':
        return '₹${amount.toStringAsFixed(2)}';
      case 'PKR':
        return 'Rs ${amount.toStringAsFixed(2)}';
      default:
        return '$currency ${amount.toStringAsFixed(2)}';
    }
  }

  // ✅ Map conversion for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'displayName': displayName,
      'photoURL': photoURL,
      'phoneNumber': phoneNumber,
      'currency': currency,
      'locale': locale,
      'theme': theme,
      'notificationsEnabled': notificationsEnabled,
      'biometricEnabled': biometricEnabled,
      'preferences': preferences,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'lastLoginAt': lastLoginAt != null ? Timestamp.fromDate(lastLoginAt!) : null,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] ?? '',
      email: map['email'] ?? '',
      displayName: map['displayName'] ?? '',
      photoURL: map['photoURL'],
      phoneNumber: map['phoneNumber'],
      currency: map['currency'] ?? 'USD',
      locale: map['locale'] ?? 'en_US',
      theme: map['theme'] ?? 'system',
      notificationsEnabled: map['notificationsEnabled'] ?? true,
      biometricEnabled: map['biometricEnabled'] ?? false,
      preferences: map['preferences'],
      createdAt: _convertTimestamp(map['createdAt']),
      updatedAt: _convertTimestamp(map['updatedAt']),
      lastLoginAt: map['lastLoginAt'] != null ? _convertTimestamp(map['lastLoginAt']) : null,
    );
  }

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel.fromMap(data);
  }

  // ✅ Safe timestamp conversion
  static DateTime _convertTimestamp(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.now();
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? displayName,
    String? photoURL,
    String? phoneNumber,
    String? currency,
    String? locale,
    String? theme,
    bool? notificationsEnabled,
    bool? biometricEnabled,
    Map<String, dynamic>? preferences,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastLoginAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoURL: photoURL ?? this.photoURL,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      currency: currency ?? this.currency,
      locale: locale ?? this.locale,
      theme: theme ?? this.theme,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
      preferences: preferences ?? this.preferences,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
    );
  }

  // Helpers
  String get initials {
    if (displayName.isEmpty) return '';
    final parts = displayName.trim().split(' ');
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  bool get hasProfilePhoto => photoURL != null && photoURL!.isNotEmpty;
}
