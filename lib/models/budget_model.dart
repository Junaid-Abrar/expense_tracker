import 'package:cloud_firestore/cloud_firestore.dart';

class BudgetModel {
  final String id;
  final String userId;
  final String name;
  final String description;
  final double amount;
  final double spent;
  final String categoryId;
  final String categoryName;
  final String period; // 'weekly', 'monthly', 'yearly'
  final DateTime startDate;
  final DateTime endDate;
  final bool isActive;
  final bool notificationEnabled;
  final double notificationThreshold; // percentage (0.0 - 1.0)
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? notes;

  // All named parameters now
  BudgetModel({
    this.notes,
    required this.id,
    required this.userId,
    required this.name,
    required this.description,
    required this.amount,
    this.spent = 0.0,
    required this.categoryId,
    required this.categoryName,
    required this.period,
    required this.startDate,
    required this.endDate,
    this.isActive = true,
    this.notificationEnabled = true,
    this.notificationThreshold = 0.8,
    required this.createdAt,
    required this.updatedAt,
  });

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'description': description,
      'amount': amount,
      'spent': spent,
      'categoryId': categoryId,
      'categoryName': categoryName,
      'period': period,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'isActive': isActive,
      'notificationEnabled': notificationEnabled,
      'notificationThreshold': notificationThreshold,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'notes': notes,
    };
  }

  // Create from Map
  factory BudgetModel.fromMap(Map<String, dynamic> map) {
    return BudgetModel(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      amount: (map['amount'] ?? 0).toDouble(),
      spent: (map['spent'] ?? 0).toDouble(),
      categoryId: map['categoryId'] ?? '',
      categoryName: map['categoryName'] ?? '',
      period: map['period'] ?? 'monthly',
      startDate: map['startDate'] is Timestamp
          ? (map['startDate'] as Timestamp).toDate()
          : DateTime.now(),
      endDate: map['endDate'] is Timestamp
          ? (map['endDate'] as Timestamp).toDate()
          : DateTime.now().add(const Duration(days: 30)),
      isActive: map['isActive'] ?? true,
      notificationEnabled: map['notificationEnabled'] ?? true,
      notificationThreshold: (map['notificationThreshold'] ?? 0.8).toDouble(),
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: map['updatedAt'] is Timestamp
          ? (map['updatedAt'] as Timestamp).toDate()
          : DateTime.now(),
      notes: map['notes'],
    );
  }

  // From Firestore DocumentSnapshot
  factory BudgetModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return BudgetModel.fromMap(data);
  }

  // CopyWith
  BudgetModel copyWith({
    String? id,
    String? userId,
    String? name,
    String? description,
    double? amount,
    double? spent,
    String? categoryId,
    String? categoryName,
    String? period,
    DateTime? startDate,
    DateTime? endDate,
    bool? isActive,
    bool? notificationEnabled,
    double? notificationThreshold,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? notes,
  }) {
    return BudgetModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      spent: spent ?? this.spent,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      period: period ?? this.period,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isActive: isActive ?? this.isActive,
      notificationEnabled: notificationEnabled ?? this.notificationEnabled,
      notificationThreshold: notificationThreshold ?? this.notificationThreshold,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      notes: notes ?? this.notes,
    );
  }

// Add your helper getters as before...
}