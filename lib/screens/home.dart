import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';

import '../models/date_entry_model.dart';
import '../repositories/date_repository.dart';
import '../services/auth_service.dart';
import '../services/hive_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_background.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/glass_card.dart';
import '../widgets/gradient_button.dart';
import 'date_detail.dart';

/// Owns the `DateRepository` for the signed-in user identified by [userId]
/// (`FirebaseAuth.instance.currentUser!.uid`, supplied by `AuthGate`), and
/// starts/stops its Firestore sync with this widget's lifecycle. Lists the
/// dates the user has added; tapping one opens [DateDetailPage] for that
/// date's transactions.
class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.userId});

  final String userId;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final DateRepository _repository;

  @override
  void initState() {
    super.initState();
    _repository = DateRepository(userId: widget.userId)..startSync();
  }

  @override
  void dispose() {
    _repository.dispose();
    super.dispose();
  }

  Future<void> _signOut() async {
    debugPrint('[HomePage] Sign out tapped');
    try {
      await AuthService.signOut();
      await HiveService.clearAll();
      debugPrint('[HomePage] Sign out: local cache cleared');
    } catch (e) {
      debugPrint('[HomePage] Sign out failed: $e');
    }
  }

  Future<void> _addDate() async {
    debugPrint('[HomePage] Add date tapped');
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 5),
    );
    if (picked == null) {
      debugPrint('[HomePage] Add date: picker cancelled');
      return;
    }
    if (!mounted) return;

    final existing = _repository.cachedDates
        .where((entry) => entry.id == DateRepository.idFor(picked))
        .firstOrNull;
    final note = await _promptForNote(
      title: formatDate(picked),
      initialNote: existing?.note ?? '',
    );
    if (note == null) {
      debugPrint('[HomePage] Add date: note dialog cancelled');
      return;
    }

    try {
      final entry = await _repository.addDate(picked, note: note);
      if (!mounted) return;
      _openDate(entry);
    } catch (e) {
      debugPrint('[HomePage] Add date failed: $e');
    }
  }

  /// Lets the user rename an already-added date's note. The date itself
  /// (and so which day's transactions it points to) is never editable here.
  Future<void> _editNote(DateEntryModel entry) async {
    debugPrint('[HomePage] Edit note tapped: id=${entry.id}');
    final note = await _promptForNote(
      title: formatDate(entry.date),
      initialNote: entry.note,
    );
    if (note == null) {
      debugPrint('[HomePage] Edit note: dialog cancelled');
      return;
    }

    try {
      await _repository.addDate(entry.date, note: note);
    } catch (e) {
      debugPrint('[HomePage] Edit note failed: $e');
    }
  }

  Future<void> _deleteDate(DateEntryModel entry) async {
    debugPrint('[HomePage] Delete date tapped: id=${entry.id}');
    final label = entry.note.isEmpty ? formatDate(entry.date) : entry.note;
    final confirmed = await confirmDelete(
      context,
      title: 'Delete this date?',
      message:
          'This will permanently delete $label and all of its transactions.',
    );
    if (!confirmed) {
      debugPrint('[HomePage] Delete date: cancelled');
      return;
    }

    try {
      await _repository.deleteDate(entry.id);
    } catch (e) {
      debugPrint('[HomePage] Delete date failed: $e');
    }
  }

  /// Shows a dialog to enter/edit a date's note. Returns the trimmed note on
  /// Save, or null if the dialog was cancelled.
  Future<String?> _promptForNote({
    required String title,
    required String initialNote,
  }) async {
    final noteController = TextEditingController(text: initialNote);

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title, overflow: TextOverflow.ellipsis),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: SingleChildScrollView(
            child: TextField(
              controller: noteController,
              autofocus: true,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                labelText: 'Note (optional)',
                hintText: 'e.g. Eid, Trip to Afghanistan',
                prefixIcon: Icon(
                  Icons.sticky_note_2_outlined,
                  color: AppColors.primary,
                ),
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
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    return saved == true ? noteController.text.trim() : null;
  }

  void _openDate(DateEntryModel entry) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DateDetailPage(userId: widget.userId, dateEntry: entry),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Expenses'),
        actions: [
          IconButton(
            onPressed: _signOut,
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Sign out',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: AppBackground(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: ValueListenableBuilder<Box<DateEntryModel>>(
                valueListenable: _repository.listenable(),
                builder: (context, box, _) {
                  final dates = _repository.cachedDates
                    ..sort((a, b) => b.date.compareTo(a.date));

                  if (dates.isEmpty) {
                    return _EmptyState(onAddDate: _addDate);
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 100, 20, 100),
                    itemCount: dates.length + 1,
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return _HeaderCard(count: dates.length);
                      }
                      final entry = dates[index - 1];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: _DateRow(
                          entry: entry,
                          onTap: () => _openDate(entry),
                          onEdit: () => _editNote(entry),
                          onDelete: () => _deleteDate(entry),
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
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 200),
        child: IntrinsicWidth(
          child: GradientButton(
            onPressed: _addDate,
            height: 52,
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add_rounded, size: 20),
                  SizedBox(width: 6),
                  Flexible(
                    child: Text('Add Date', overflow: TextOverflow.ellipsis),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: GlassCard(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.calendar_month_rounded,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$count tracked ${count == 1 ? 'day' : 'days'}',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Tap a day to view its transactions',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DateRow extends StatelessWidget {
  const _DateRow({
    required this.entry,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  final DateEntryModel entry;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final hasNote = entry.note.isNotEmpty;
    return GlassCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppColors.accent.withValues(alpha: 0.35),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${entry.date.day}',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    height: 1,
                  ),
                ),
                Text(
                  _shortMonth(entry.date.month),
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasNote ? entry.note : formatDate(entry.date),
                  style: Theme.of(context).textTheme.titleMedium,
                  overflow: TextOverflow.ellipsis,
                ),
                if (hasNote) ...[
                  const SizedBox(height: 2),
                  Text(
                    formatDate(entry.date),
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
          _RowIconButton(icon: Icons.edit_rounded, onTap: onEdit),
          const SizedBox(width: 6),
          _RowIconButton(
            icon: Icons.delete_rounded,
            onTap: onDelete,
            color: AppColors.danger,
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
          padding: const EdgeInsets.all(9),
          child: Icon(icon, size: 18, color: color),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAddDate});

  final VoidCallback onAddDate;

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
                Icons.calendar_today_rounded,
                color: Colors.white,
                size: 36,
              ),
            ),
            const SizedBox(height: 24),
            Text('No dates yet', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            const Text(
              'Add a date to start logging transactions for it.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}

const _monthNames = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

String _shortMonth(int month) => _monthNames[month - 1].toUpperCase();

String formatDate(DateTime date) =>
    '${_monthNames[date.month - 1]} ${date.day}, ${date.year}';
