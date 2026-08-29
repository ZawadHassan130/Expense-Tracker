import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive_ce/hive_ce.dart';

part 'date_entry_model.g.dart';

/// A calendar day the user has added, under which they record transactions.
/// [id] is a stable `yyyy-MM-dd` string derived from [date] (see
/// `DateRepository.idFor`), so it also doubles as the Firestore document id
/// and the path segment for that day's `transactions` subcollection.
@HiveType(typeId: 4)
class DateEntryModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String userId;

  @HiveField(2)
  DateTime date;

  @HiveField(3)
  DateTime createdAt;

  /// A user-chosen label for the day (e.g. "Diwali", "Trip to Bangkok"),
  /// shown alongside the date so an occasion is easier to spot than a plain
  /// date would be.
  @HiveField(4)
  String note;

  DateEntryModel({
    required this.id,
    required this.userId,
    required this.date,
    required this.createdAt,
    this.note = '',
  });

  factory DateEntryModel.fromMap(String id, Map<String, dynamic> map) {
    return DateEntryModel(
      id: id,
      userId: map['userId'] as String,
      date: (map['date'] as Timestamp).toDate(),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      note: map['note'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'date': Timestamp.fromDate(date),
      'createdAt': Timestamp.fromDate(createdAt),
      'note': note,
    };
  }
}
