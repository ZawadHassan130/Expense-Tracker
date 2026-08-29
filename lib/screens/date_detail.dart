import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';

import '../models/date_entry_model.dart';
import '../models/transaction_category.dart';
import '../models/transaction_model.dart';
import '../repositories/transaction_repository.dart';
import '../widgets/confirm_dialog.dart';
import 'home.dart' show formatDate;

/// Owns the `TransactionRepository` scoped to [dateEntry] and starts/stops
/// its Firestore sync with this widget's lifecycle. Lists the transactions
/// recorded for that date and lets the user add or delete them.
class DateDetailPage extends StatefulWidget {
  const DateDetailPage({
    super.key,
    required this.userId,
    required this.dateEntry,
  });

  final String userId;
  final DateEntryModel dateEntry;

  @override
  State<DateDetailPage> createState() => _DateDetailPageState();
}

class _DateDetailPageState extends State<DateDetailPage> {
  late final TransactionRepository _repository;

  @override
  void initState() {
    super.initState();
    _repository = TransactionRepository(
      userId: widget.userId,
      dateId: widget.dateEntry.id,
    )..startSync();
  }

  @override
  void dispose() {
    _repository.dispose();
    super.dispose();
  }

  Future<void> _addTransaction() async {
    debugPrint('[DateDetailPage] Add transaction tapped');
    final result = await _promptForTransaction(title: 'Add Transaction');
    if (result == null) {
      debugPrint('[DateDetailPage] Add transaction: dialog cancelled');
      return;
    }

    try {
      await _repository.addTransaction(
        amount: result.amount,
        category: result.category,
        note: result.note,
      );
    } catch (e) {
      debugPrint('[DateDetailPage] Add transaction failed: $e');
    }
  }

  Future<void> _editTransaction(TransactionModel transaction) async {
    debugPrint('[DateDetailPage] Edit transaction tapped: id=${transaction.id}');
    final result = await _promptForTransaction(
      title: 'Edit Transaction',
      initialAmount: transaction.amount,
      initialCategory: transaction.category,
      initialNote: transaction.note,
    );
    if (result == null) {
      debugPrint('[DateDetailPage] Edit transaction: dialog cancelled');
      return;
    }

    transaction
      ..amount = result.amount
      ..category = result.category
      ..note = result.note;
    try {
      await _repository.updateTransaction(transaction);
    } catch (e) {
      debugPrint('[DateDetailPage] Edit transaction failed: $e');
    }
  }

  Future<void> _deleteTransaction(TransactionModel transaction) async {
    debugPrint('[DateDetailPage] Delete transaction tapped: id=${transaction.id}');
    final confirmed = await confirmDelete(
      context,
      title: 'Delete this transaction?',
      message:
          'This will permanently delete the ${transaction.category.label} '
          'transaction of ${transaction.amount.toStringAsFixed(2)}.',
    );
    if (!confirmed) {
      debugPrint('[DateDetailPage] Delete transaction: cancelled');
      return;
    }

    try {
      await _repository.deleteTransaction(transaction.id);
    } catch (e) {
      debugPrint('[DateDetailPage] Delete transaction failed: $e');
    }
  }

  /// Shows the add/edit transaction dialog. Returns the entered values on
  /// Save, or null if the dialog was cancelled.
  Future<({double amount, TransactionCategory category, String note})?>
  _promptForTransaction({
    required String title,
    double? initialAmount,
    TransactionCategory? initialCategory,
    String initialNote = '',
  }) async {
    final formKey = GlobalKey<FormState>();
    final amountController = TextEditingController(
      text: initialAmount == null ? '' : initialAmount.toString(),
    );
    final noteController = TextEditingController(text: initialNote);
    TransactionCategory? selectedCategory = initialCategory;

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(title),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: amountController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(labelText: 'Amount'),
                  validator: (value) => double.tryParse(value ?? '') == null
                      ? 'Enter a valid amount'
                      : null,
                ),
                DropdownButtonFormField<TransactionCategory>(
                  initialValue: selectedCategory,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: TransactionCategory.values
                      .map(
                        (category) => DropdownMenuItem(
                          value: category,
                          child: Text(category.label),
                        ),
                      )
                      .toList(),
                  onChanged: (value) =>
                      setDialogState(() => selectedCategory = value),
                  validator: (value) =>
                      value == null ? 'Select a category' : null,
                ),
                TextFormField(
                  controller: noteController,
                  decoration: const InputDecoration(
                    labelText: 'Note (optional)',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.of(context).pop(true);
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );

    if (saved != true) return null;
    return (
      amount: double.parse(amountController.text),
      category: selectedCategory!,
      note: noteController.text.trim(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.dateEntry.note.isEmpty
              ? formatDate(widget.dateEntry.date)
              : widget.dateEntry.note,
        ),
        // Note is the primary title here; keep the raw date visible too
        // since the note alone may not pin down which day this is.
        bottom: widget.dateEntry.note.isEmpty
            ? null
            : PreferredSize(
                preferredSize: const Size.fromHeight(20),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    formatDate(widget.dateEntry.date),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ),
      ),
      body: ValueListenableBuilder<Box<TransactionModel>>(
        valueListenable: _repository.listenable(),
        builder: (context, box, _) {
          final transactions = _repository.cachedTransactions
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

          if (transactions.isEmpty) {
            return const Center(child: Text('No transactions yet.'));
          }

          return ListView.builder(
            itemCount: transactions.length,
            itemBuilder: (context, index) {
              final transaction = transactions[index];
              return ListTile(
                title: Text(transaction.category.label),
                subtitle: Text(
                  transaction.note.isEmpty
                      ? transaction.amount.toStringAsFixed(2)
                      : '${transaction.amount.toStringAsFixed(2)} • ${transaction.note}',
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: () => _editTransaction(transaction),
                      icon: const Icon(Icons.edit),
                      tooltip: 'Edit transaction',
                    ),
                    IconButton(
                      onPressed: () => _deleteTransaction(transaction),
                      icon: const Icon(Icons.delete),
                      tooltip: 'Delete transaction',
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addTransaction,
        tooltip: 'Add transaction',
        child: const Icon(Icons.add),
      ),
    );
  }
}
