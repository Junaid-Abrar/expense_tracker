import 'package:cloud_firestore/cloud_firestore.dart';

class ExpenseModel {
  final String id;
  final String userId;
  final String title;
  final double amount;
  final String categoryId;
  final String categoryName;
  final String type; // "expense" or "income"
  final DateTime date;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? description;
  final List<String>? attachments;
  final String? location;
  final String? receiptImageUrl;
  final List<String>? tags;
  final bool isRecurring;
  final String? recurringType;
  final DateTime? recurringEndDate;
  final String? paymentMethod;

  ExpenseModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.amount,
    required this.categoryId,
    required this.categoryName,
    required this.type,
    required this.date,
    required this.createdAt,
    required this.updatedAt,
    this.description,
    this.attachments,
    this.location,
    this.receiptImageUrl,
    this.tags,
    this.isRecurring = false,
    this.recurringType,
    this.recurringEndDate,
    this.paymentMethod,
  });

  // Helper getters
  bool get isExpense => type.toLowerCase() == 'expense';
  bool get isIncome => type.toLowerCase() == 'income';

  // CopyWith for updating
  ExpenseModel copyWith({
    String? id,
    String? userId,
    String? title,
    double? amount,
    String? categoryId,
    String? categoryName,
    String? type,
    DateTime? date,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? description,
    List<String>? attachments,
    String? location,
    String? receiptImageUrl,
    List<String>? tags,
    bool? isRecurring,
    String? recurringType,
    DateTime? recurringEndDate,
    String? paymentMethod,
  }) {
    return ExpenseModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      type: type ?? this.type,
      date: date ?? this.date,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      description: description ?? this.description,
      attachments: attachments ?? this.attachments,
      location: location ?? this.location,
      receiptImageUrl: receiptImageUrl ?? this.receiptImageUrl,
      tags: tags ?? this.tags,
      isRecurring: isRecurring ?? this.isRecurring,
      recurringType: recurringType ?? this.recurringType,
      recurringEndDate: recurringEndDate ?? this.recurringEndDate,
      paymentMethod: paymentMethod ?? this.paymentMethod,
    );
  }

  // Convert from Firestore
  factory ExpenseModel.fromMap(Map<String, dynamic> map) {
    return ExpenseModel(
      id: map['id'] as String,
      userId: map['userId'] as String,
      title: map['title'] as String,
      amount: (map['amount'] as num).toDouble(),
      categoryId: map['categoryId'] as String,
      categoryName: map['categoryName'] as String,
      type: map['type'] as String,
      date: map['date'] != null ? (map['date'] as Timestamp).toDate() : DateTime.now(),
      createdAt: map['createdAt'] != null ? (map['createdAt'] as Timestamp).toDate() : DateTime.now(),
      updatedAt: map['updatedAt'] != null ? (map['updatedAt'] as Timestamp).toDate() : DateTime.now(),
      description: map['description'] as String?,
      attachments: map['attachments'] != null ? List<String>.from(map['attachments']) : null,
      location: map['location'] as String?,
      receiptImageUrl: map['receiptImageUrl'] as String?,
      tags: map['tags'] != null ? List<String>.from(map['tags']) : null,
      isRecurring: map['isRecurring'] as bool? ?? false,
      recurringType: map['recurringType'] as String?,
      recurringEndDate: map['recurringEndDate'] != null ? (map['recurringEndDate'] as Timestamp).toDate() : null,
      paymentMethod: map['paymentMethod'] as String?,
    );
  }

  // Convert to Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'amount': amount,
      'categoryId': categoryId,
      'categoryName': categoryName,
      'type': type,
      'date': Timestamp.fromDate(date),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'description': description,
      'attachments': attachments,
      'location': location,
      'receiptImageUrl': receiptImageUrl,
      'tags': tags,
      'isRecurring': isRecurring,
      'recurringType': recurringType,
      'recurringEndDate': recurringEndDate != null ? Timestamp.fromDate(recurringEndDate!) : null,
      'paymentMethod': paymentMethod,
    };
  }
}
