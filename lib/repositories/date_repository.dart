import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';

import '../models/date_entry_model.dart';
import '../services/firestore_service.dart';
import '../services/hive_service.dart';

/// Firestore is the source of truth for a user's date entries; Hive mirrors
/// it locally the same way `TransactionRepository` mirrors transactions.
class DateRepository {
  DateRepository({required this.userId})
    : _firestore = FirestoreCollectionService<DateEntryModel>(
        collection: FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('dates'),
        fromMap: DateEntryModel.fromMap,
        toMap: (entry) => entry.toMap(),
      );

  final String userId;
  final FirestoreCollectionService<DateEntryModel> _firestore;
  StreamSubscription<List<DateEntryModel>>? _subscription;

  Box<DateEntryModel> get _box => HiveService.datesBox;

  /// Date entries currently cached locally for this user, available
  /// synchronously (e.g. for first paint before the stream syncs).
  List<DateEntryModel> get cachedDates =>
      _box.values.where((entry) => entry.userId == userId).toList();

  ValueListenable<Box<DateEntryModel>> listenable() => _box.listenable();

  /// A stable `yyyy-MM-dd` id for the calendar day [date] falls on,
  /// regardless of its time-of-day component.
  static String idFor(DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day);
    return '${normalized.year.toString().padLeft(4, '0')}-'
        '${normalized.month.toString().padLeft(2, '0')}-'
        '${normalized.day.toString().padLeft(2, '0')}';
  }

  /// Starts mirroring Firestore changes into the local Hive cache. Call
  /// once after login and cancel on sign-out via [dispose].
  void startSync() {
    debugPrint('[DateRepository] startSync: userId=$userId');
    _subscription?.cancel();
    _subscription = _firestore.streamAll().listen(
      (remoteDates) async {
        debugPrint(
          '[DateRepository] sync: received ${remoteDates.length} date(s) '
          'for userId=$userId',
        );
        final staleIds = _box.values
            .where((entry) => entry.userId == userId)
            .map((entry) => entry.id)
            .toSet();

        for (final entry in remoteDates) {
          staleIds.remove(entry.id);
          await _box.put(entry.id, entry);
        }
        for (final id in staleIds) {
          await _box.delete(id);
        }
      },
      onError: (Object e) {
        debugPrint('[DateRepository] sync: error for userId=$userId - $e');
      },
    );
  }

  Future<void> dispose() async {
    debugPrint('[DateRepository] dispose: userId=$userId');
    await _subscription?.cancel();
    _subscription = null;
  }

  /// Creates the date entry for the calendar day [date] falls on, or — if
  /// one already exists — updates its [note]. The entry's id is derived
  /// purely from the day itself via [idFor], so adding the same day twice
  /// is an upsert rather than a duplicate.
  Future<DateEntryModel> addDate(DateTime date, {String note = ''}) async {
    final id = idFor(date);

    final existing = _box.get(id);
    if (existing != null && existing.userId == userId) {
      if (existing.note == note) {
        debugPrint('[DateRepository] addDate: $id already exists, reusing');
        return existing;
      }
      debugPrint('[DateRepository] addDate: $id already exists, updating note');
      existing.note = note;
      try {
        await _box.put(existing.id, existing);
        await _firestore.set(existing.id, existing);
        return existing;
      } catch (e) {
        debugPrint('[DateRepository] addDate: note update failed id=$id - $e');
        rethrow;
      }
    }

    debugPrint('[DateRepository] addDate: creating $id for userId=$userId');
    final entry = DateEntryModel(
      id: id,
      userId: userId,
      date: DateTime(date.year, date.month, date.day),
      createdAt: DateTime.now(),
      note: note,
    );
    try {
      await _box.put(entry.id, entry);
      await _firestore.set(entry.id, entry);
      debugPrint('[DateRepository] addDate: succeeded id=$id');
      return entry;
    } catch (e) {
      debugPrint('[DateRepository] addDate: failed id=$id - $e');
      rethrow;
    }
  }

  /// Deletes the date entry [id] and every transaction under it. Firestore
  /// doesn't cascade-delete a document's subcollections on its own, so the
  /// transactions have to be deleted individually before the date document
  /// itself; the matching Hive-cached transactions are cleared the same way.
  Future<void> deleteDate(String id) async {
    debugPrint('[DateRepository] deleteDate: id=$id');
    try {
      final dateDoc = FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('dates')
          .doc(id);
      final transactionDocs = await dateDoc.collection('transactions').get();

      final batch = FirebaseFirestore.instance.batch();
      for (final doc in transactionDocs.docs) {
        batch.delete(doc.reference);
      }
      batch.delete(dateDoc);
      await batch.commit();

      final transactionsBox = HiveService.transactionsBox;
      final staleTransactionIds = transactionsBox.values
          .where(
            (transaction) =>
                transaction.userId == userId && transaction.dateId == id,
          )
          .map((transaction) => transaction.id)
          .toList();
      for (final transactionId in staleTransactionIds) {
        await transactionsBox.delete(transactionId);
      }
      await _box.delete(id);

      debugPrint('[DateRepository] deleteDate: succeeded id=$id');
    } catch (e) {
      debugPrint('[DateRepository] deleteDate: failed id=$id - $e');
      rethrow;
    }
  }
}
