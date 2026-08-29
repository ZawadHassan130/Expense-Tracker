import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';

import '../models/date_entry_model.dart';
import '../models/transaction_category.dart';
import '../models/transaction_model.dart';
import '../repositories/transaction_repository.dart';
import '../theme/app_theme.dart';
import '../widgets/app_background.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/glass_card.dart';
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
    debugPrint(
      '[DateDetailPage] Edit transaction tapped: id=${transaction.id}',
    );
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
    debugPrint(
      '[DateDetailPage] Delete transaction tapped: id=${transaction.id}',
    );
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
          title: Text(title, overflow: TextOverflow.ellipsis),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: amountController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: const InputDecoration(
                        labelText: 'Amount',
                        prefixIcon: Icon(
                          Icons.payments_outlined,
                          color: AppColors.primary,
                        ),
                      ),
                      validator: (value) => double.tryParse(value ?? '') == null
                          ? 'Enter a valid amount'
                          : null,
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<TransactionCategory>(
                      initialValue: selectedCategory,
                      dropdownColor: AppColors.surfaceElevated,
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: const InputDecoration(
                        labelText: 'Category',
                        prefixIcon: Icon(
                          Icons.category_outlined,
                          color: AppColors.primary,
                        ),
                      ),
                      items: TransactionCategory.values
                          .map(
                            (category) => DropdownMenuItem(
                              value: category,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    category.icon,
                                    size: 18,
                                    color: category.color,
                                  ),
                                  const SizedBox(width: 10),
                                  Text(category.label),
                                ],
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (value) =>
                          setDialogState(() => selectedCategory = value),
                      validator: (value) =>
                          value == null ? 'Select a category' : null,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: noteController,
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: const InputDecoration(
                        labelText: 'Note (optional)',
                        prefixIcon: Icon(
                          Icons.sticky_note_2_outlined,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
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
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          widget.dateEntry.note.isEmpty
              ? formatDate(widget.dateEntry.date)
              : widget.dateEntry.note,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
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
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
      ),
      body: AppBackground(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: ValueListenableBuilder<Box<TransactionModel>>(
                valueListenable: _repository.listenable(),
                builder: (context, box, _) {
                  final transactions = _repository.cachedTransactions
                    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

                  if (transactions.isEmpty) {
                    return const _EmptyTransactions();
                  }

                  final total = transactions.fold<double>(
                    0,
                    (sum, t) => sum + t.amount,
                  );

                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 100, 20, 100),
                    itemCount: transactions.length + 1,
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return _TotalCard(
                          total: total,
                          count: transactions.length,
                        );
                      }
                      final transaction = transactions[index - 1];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: _TransactionRow(
                          transaction: transaction,
                          onEdit: () => _editTransaction(transaction),
                          onDelete: () => _deleteTransaction(transaction),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addTransaction,
        tooltip: 'Add transaction',
        backgroundColor: AppColors.primary,
        elevation: 6,
        child: const Icon(Icons.add_rounded),
      ),
    );
  }
}

class _TotalCard extends StatelessWidget {
  const _TotalCard({required this.total, required this.count});

  final double total;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: GlassCard(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'TOTAL SPENT',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 6),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: ShaderMask(
                      shaderCallback: (bounds) =>
                          AppColors.primaryGradient.createShader(bounds),
                      child: Text(
                        total.toStringAsFixed(2),
                        maxLines: 1,
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          height: 1.2,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppColors.accent.withValues(alpha: 0.35),
                ),
              ),
              child: Text(
                '$count ${count == 1 ? 'item' : 'items'}',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TransactionRow extends StatelessWidget {
  const _TransactionRow({
    required this.transaction,
    required this.onEdit,
    required this.onDelete,
  });

  final TransactionModel transaction;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final category = transaction.category;
    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: category.color.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(category.icon, color: category.color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category.label,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 2),
                Text(
                  transaction.note.isEmpty ? 'No note' : transaction.note,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                transaction.amount.toStringAsFixed(2),
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  _RowIconButton(icon: Icons.edit_rounded, onTap: onEdit),
                  const SizedBox(width: 4),
                  _RowIconButton(
                    icon: Icons.delete_rounded,
                    onTap: onDelete,
                    color: AppColors.danger,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RowIconButton extends StatelessWidget {
  const _RowIconButton({
    required this.icon,
    required this.onTap,
    this.color = AppColors.textSecondary,
  });

  final IconData icon;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.textPrimary.withValues(alpha: 0.05),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(7),
          child: Icon(icon, size: 16, color: color),
        ),
      ),
    );
  }
}

class _EmptyTransactions extends StatelessWidget {
  const _EmptyTransactions();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.4),
                    blurRadius: 30,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: const Icon(
                Icons.receipt_long_rounded,
                color: Colors.white,
                size: 36,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No transactions yet',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            const Text(
              'Tap the + button to log your first expense for this day.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}
