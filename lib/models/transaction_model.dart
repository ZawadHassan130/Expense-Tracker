import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive_ce/hive_ce.dart';

import 'transaction_category.dart';

part 'transaction_model.g.dart';

@HiveType(typeId: 3)
class TransactionModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String userId;

  /// The `DateEntryModel.id` (a `yyyy-MM-dd` string) this transaction
  /// belongs to. Also the path segment for the Firestore subcollection this
  /// transaction lives under: `users/{userId}/dates/{dateId}/transactions`.
  @HiveField(2)
  String dateId;

  @HiveField(3)
  double amount;

  @HiveField(4)
  TransactionCategory category;

  @HiveField(5)
  String note;

  @HiveField(6)
  DateTime createdAt;

  @HiveField(7)
  DateTime updatedAt;

  TransactionModel({
    required this.id,
    required this.userId,
    required this.dateId,
    required this.amount,

    required this.category,
    required this.note,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TransactionModel.fromMap(String id, Map<String, dynamic> map) {
    return TransactionModel(
      id: id,
      userId: map['userId'] as String,
      dateId: map['dateId'] as String,
      amount: (map['amount'] as num).toDouble(),
      category: TransactionCategory.values.firstWhere(
        (value) => value.name == map['category'],
        orElse: () => TransactionCategory.other,
      ),
      note: map['note'] as String? ?? '',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'dateId': dateId,
      'amount': amount,
      'category': category.name,
      'note': note,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}
