import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';

import '../models/transaction_category.dart';
import '../models/transaction_model.dart';
import '../services/firestore_service.dart';
import '../services/hive_service.dart';

/// Firestore is the source of truth for transactions; Hive mirrors it
/// locally so the UI has instant, typed data on cold start before the
/// Firestore stream reconnects.
///
/// Scoped to one user's one date entry: transactions live at
/// `users/{userId}/dates/{dateId}/transactions/{id}`.
class TransactionRepository {
  TransactionRepository({required this.userId, required this.dateId})
    : _firestore = FirestoreCollectionService<TransactionModel>(
        collection: FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('dates')
            .doc(dateId)
            .collection('transactions'),
        fromMap: TransactionModel.fromMap,
        toMap: (transaction) => transaction.toMap(),
      );

  final String userId;
  final String dateId;
  final FirestoreCollectionService<TransactionModel> _firestore;
  StreamSubscription<List<TransactionModel>>? _subscription;

  Box<TransactionModel> get _box => HiveService.transactionsBox;

  bool _belongsHere(TransactionModel transaction) =>
      transaction.userId == userId && transaction.dateId == dateId;

  /// Transactions currently cached locally for this date, available
  /// synchronously (e.g. for first paint before the stream syncs).
  List<TransactionModel> get cachedTransactions =>
      _box.values.where(_belongsHere).toList();

  ValueListenable<Box<TransactionModel>> listenable() => _box.listenable();

  /// Starts mirroring Firestore changes into the local Hive cache. Call
  /// once when the date's page opens and cancel on close via [dispose].
  void startSync() {
    debugPrint(
      '[TransactionRepository] startSync: userId=$userId dateId=$dateId',
    );
    _subscription?.cancel();
    _subscription = _firestore.streamAll().listen(
      (remoteTransactions) async {
        debugPrint(
          '[TransactionRepository] sync: received ${remoteTransactions.length} '
          'transaction(s) for userId=$userId dateId=$dateId',
        );
        final staleIds = _box.values
            .where(_belongsHere)
            .map((transaction) => transaction.id)
            .toSet();

        for (final transaction in remoteTransactions) {
          staleIds.remove(transaction.id);
          await _box.put(transaction.id, transaction);
        }
        for (final id in staleIds) {
          await _box.delete(id);
        }
      },
      onError: (Object e) {
        debugPrint(
          '[TransactionRepository] sync: error for userId=$userId dateId=$dateId - $e',
        );
      },
    );
  }

  Future<void> dispose() async {
    debugPrint(
      '[TransactionRepository] dispose: userId=$userId dateId=$dateId',
    );
    await _subscription?.cancel();
    _subscription = null;
  }

  Future<TransactionModel> addTransaction({
    required double amount,
    required TransactionCategory category,
    String note = '',
  }) async {
    debugPrint(
      '[TransactionRepository] addTransaction: userId=$userId dateId=$dateId '
      'amount=$amount category=${category.name}',
    );
    final now = DateTime.now();
    final transaction = TransactionModel(
      id: _firestore.newId(),
      userId: userId,
      dateId: dateId,
      amount: amount,
      category: category,
      note: note,
      createdAt: now,
      updatedAt: now,
    );
    try {
      await _box.put(transaction.id, transaction);
      await _firestore.set(transaction.id, transaction);
      debugPrint(
        '[TransactionRepository] addTransaction: succeeded id=${transaction.id}',
      );
      return transaction;
    } catch (e) {
      debugPrint('[TransactionRepository] addTransaction: failed - $e');
      rethrow;
    }
  }

  Future<void> updateTransaction(TransactionModel transaction) async {
    debugPrint(
      '[TransactionRepository] updateTransaction: id=${transaction.id}',
    );
    transaction.updatedAt = DateTime.now();
    try {
      await _box.put(transaction.id, transaction);
      await _firestore.set(transaction.id, transaction);
      debugPrint(
        '[TransactionRepository] updateTransaction: succeeded id=${transaction.id}',
      );
    } catch (e) {
      debugPrint(
        '[TransactionRepository] updateTransaction: failed id=${transaction.id} - $e',
      );
      rethrow;
    }
  }

  Future<void> deleteTransaction(String id) async {
    debugPrint('[TransactionRepository] deleteTransaction: id=$id');
    try {
      await _box.delete(id);
      await _firestore.delete(id);
      debugPrint('[TransactionRepository] deleteTransaction: succeeded id=$id');
    } catch (e) {
      debugPrint(
        '[TransactionRepository] deleteTransaction: failed id=$id - $e',
      );
      rethrow;
    }
  }
}
