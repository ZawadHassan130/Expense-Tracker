import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';

import '../models/date_entry_model.dart';
import '../repositories/date_repository.dart';
import '../services/auth_service.dart';
import '../services/hive_service.dart';
import '../widgets/confirm_dialog.dart';
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
      message: 'This will permanently delete $label and all of its transactions.',
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
        title: Text(title),
        content: TextField(
          controller: noteController,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Note (optional)',
            hintText: 'e.g. Diwali, Trip to Bangkok',
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
        builder: (_) =>
            DateDetailPage(userId: widget.userId, dateEntry: entry),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Expenses'),
        actions: [
          IconButton(
            onPressed: _signOut,
            icon: const Icon(Icons.logout),
            tooltip: 'Sign out',
          ),
        ],
      ),
      body: ValueListenableBuilder<Box<DateEntryModel>>(
        valueListenable: _repository.listenable(),
        builder: (context, box, _) {
          final dates = _repository.cachedDates
            ..sort((a, b) => b.date.compareTo(a.date));

          if (dates.isEmpty) {
            return const Center(
              child: Text('No dates yet. Tap "Add Date" to get started.'),
            );
          }

          return ListView.builder(
            itemCount: dates.length,
            itemBuilder: (context, index) {
              final entry = dates[index];
              return ListTile(
                leading: const Icon(Icons.calendar_today),
                title: Text(
                  entry.note.isEmpty ? formatDate(entry.date) : entry.note,
                ),
                subtitle: entry.note.isEmpty ? null : Text(formatDate(entry.date)),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: () => _editNote(entry),
                      icon: const Icon(Icons.edit),
                      tooltip: 'Edit note',
                    ),
                    IconButton(
                      onPressed: () => _deleteDate(entry),
                      icon: const Icon(Icons.delete),
                      tooltip: 'Delete date',
                    ),
                    const Icon(Icons.chevron_right),
                  ],
                ),
                onTap: () => _openDate(entry),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addDate,
        icon: const Icon(Icons.add),
        label: const Text('Add Date'),
      ),
    );
  }
}

const _monthNames = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

String formatDate(DateTime date) =>
    '${_monthNames[date.month - 1]} ${date.day}, ${date.year}';
