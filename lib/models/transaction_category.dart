import 'package:hive_ce/hive_ce.dart';

part 'transaction_category.g.dart';

@HiveType(typeId: 5)
enum TransactionCategory {
  @HiveField(0)
  shopping,
  @HiveField(1)
  restaurant,
  @HiveField(2)
  grocery,
  @HiveField(3)
  food,
  @HiveField(4)
  delivery,
  @HiveField(5)
  transportation,
  @HiveField(6)
  utilityBills,
  @HiveField(7)
  medicine,
  @HiveField(8)
  medicalFees,
  @HiveField(9)
  sports,
  @HiveField(10)
  entertainment,
  @HiveField(11)
  other;

  String get label {
    switch (this) {
      case TransactionCategory.shopping:
        return 'Shopping';
      case TransactionCategory.restaurant:
        return 'Restaurant';
      case TransactionCategory.grocery:
        return 'Grocery';
      case TransactionCategory.food:
        return 'Food';
      case TransactionCategory.delivery:
        return 'Delivery';
      case TransactionCategory.transportation:
        return 'Transportation';
      case TransactionCategory.utilityBills:
        return 'Utility Bills';
      case TransactionCategory.medicine:
        return 'Medicine';
      case TransactionCategory.medicalFees:
        return 'Medical Fees';
      case TransactionCategory.sports:
        return 'Sports';
      case TransactionCategory.entertainment:
        return 'Entertainment';
      case TransactionCategory.other:
        return 'Other';
    }
  }
}
