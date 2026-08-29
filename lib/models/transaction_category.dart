import 'package:flutter/material.dart';
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

  /// A distinct icon per category, used to make transaction rows scannable
  /// at a glance instead of relying on text alone.
  IconData get icon {
    switch (this) {
      case TransactionCategory.shopping:
        return Icons.shopping_bag_rounded;
      case TransactionCategory.restaurant:
        return Icons.restaurant_rounded;
      case TransactionCategory.grocery:
        return Icons.local_grocery_store_rounded;
      case TransactionCategory.food:
        return Icons.fastfood_rounded;
      case TransactionCategory.delivery:
        return Icons.delivery_dining_rounded;
      case TransactionCategory.transportation:
        return Icons.directions_car_rounded;
      case TransactionCategory.utilityBills:
        return Icons.bolt_rounded;
      case TransactionCategory.medicine:
        return Icons.medication_rounded;
      case TransactionCategory.medicalFees:
        return Icons.local_hospital_rounded;
      case TransactionCategory.sports:
        return Icons.sports_basketball_rounded;
      case TransactionCategory.entertainment:
        return Icons.movie_rounded;
      case TransactionCategory.other:
        return Icons.category_rounded;
    }
  }

  /// A distinct accent color per category, paired with [icon] on badges.
  Color get color {
    switch (this) {
      case TransactionCategory.shopping:
        return const Color(0xFFFF6B9D);
      case TransactionCategory.restaurant:
        return const Color(0xFFFFA451);
      case TransactionCategory.grocery:
        return const Color(0xFF4ADE80);
      case TransactionCategory.food:
        return const Color(0xFFFBBF24);
      case TransactionCategory.delivery:
        return const Color(0xFF60A5FA);
      case TransactionCategory.transportation:
        return const Color(0xFF818CF8);
      case TransactionCategory.utilityBills:
        return const Color(0xFFFACC15);
      case TransactionCategory.medicine:
        return const Color(0xFF2DD4BF);
      case TransactionCategory.medicalFees:
        return const Color(0xFFF87171);
      case TransactionCategory.sports:
        return const Color(0xFFFB923C);
      case TransactionCategory.entertainment:
        return const Color(0xFFC084FC);
      case TransactionCategory.other:
        return const Color(0xFF94A3B8);
    }
  }
}
