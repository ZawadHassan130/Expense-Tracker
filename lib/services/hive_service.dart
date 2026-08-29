import 'package:hive_ce_flutter/hive_ce_flutter.dart';

import '../hive_registrar.g.dart';
import '../models/date_entry_model.dart';
import '../models/transaction_model.dart';

class HiveService {
  HiveService._();

  static const String transactionsBoxName = 'transactions';
  static const String datesBoxName = 'dates';

  static Future<void> init() async {
    await Hive.initFlutter();
    Hive.registerAdapters();
    await Hive.openBox<TransactionModel>(transactionsBoxName);
    await Hive.openBox<DateEntryModel>(datesBoxName);
  }

  static Box<TransactionModel> get transactionsBox =>
      Hive.box<TransactionModel>(transactionsBoxName);

  static Box<DateEntryModel> get datesBox =>
      Hive.box<DateEntryModel>(datesBoxName);

  /// Clears the local cache, e.g. on sign-out so the next user doesn't see
  /// the previous user's cached data.
  static Future<void> clearAll() async {
    await transactionsBox.clear();
    await datesBox.clear();
  }
}
