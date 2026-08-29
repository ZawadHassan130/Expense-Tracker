// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transaction_category.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TransactionCategoryAdapter extends TypeAdapter<TransactionCategory> {
  @override
  final typeId = 5;

  @override
  TransactionCategory read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return TransactionCategory.shopping;
      case 1:
        return TransactionCategory.restaurant;
      case 2:
        return TransactionCategory.grocery;
      case 3:
        return TransactionCategory.food;
      case 4:
        return TransactionCategory.delivery;
      case 5:
        return TransactionCategory.transportation;
      case 6:
        return TransactionCategory.utilityBills;
      case 7:
        return TransactionCategory.medicine;
      case 8:
        return TransactionCategory.medicalFees;
      case 9:
        return TransactionCategory.sports;
      case 10:
        return TransactionCategory.entertainment;
      case 11:
        return TransactionCategory.other;
      default:
        return TransactionCategory.shopping;
    }
  }

  @override
  void write(BinaryWriter writer, TransactionCategory obj) {
    switch (obj) {
      case TransactionCategory.shopping:
        writer.writeByte(0);
      case TransactionCategory.restaurant:
        writer.writeByte(1);
      case TransactionCategory.grocery:
        writer.writeByte(2);
      case TransactionCategory.food:
        writer.writeByte(3);
      case TransactionCategory.delivery:
        writer.writeByte(4);
      case TransactionCategory.transportation:
        writer.writeByte(5);
      case TransactionCategory.utilityBills:
        writer.writeByte(6);
      case TransactionCategory.medicine:
        writer.writeByte(7);
      case TransactionCategory.medicalFees:
        writer.writeByte(8);
      case TransactionCategory.sports:
        writer.writeByte(9);
      case TransactionCategory.entertainment:
        writer.writeByte(10);
      case TransactionCategory.other:
        writer.writeByte(11);
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TransactionCategoryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
