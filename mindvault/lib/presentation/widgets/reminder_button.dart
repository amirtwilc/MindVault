import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/note.dart';
import '../../domain/entities/note_reminder.dart';
import '../../l10n/app_localizations.dart';
import '../providers/reminder_provider.dart';
import 'reminder_background_permission_prompt.dart';

class ReminderButton extends ConsumerStatefulWidget {
  final String? noteId;
  final Future<Note?> Function() loadOrCreateNote;
  final VisualDensity visualDensity;

  const ReminderButton({
    super.key,
    required this.noteId,
    required this.loadOrCreateNote,
    this.visualDensity = VisualDensity.standard,
  });

  @override
  ConsumerState<ReminderButton> createState() => _ReminderButtonState();
}

class _ReminderButtonState extends ConsumerState<ReminderButton> {
  Timer? _expiryTimer;
  DateTime? _armedFor;

  @override
  void dispose() {
    _expiryTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppStrings.of(context);
    final id = widget.noteId;
    final watchedReminder =
        id == null ? null : ref.watch(reminderForNoteProvider(id)).valueOrNull;
    final now = DateTime.now().toUtc();
    final reminder =
        watchedReminder != null && watchedReminder.remindAt.isAfter(now)
            ? watchedReminder
            : null;
    _syncExpiryTimer(reminder);
    final active = reminder != null;
    return IconButton(
      tooltip: active ? l.reminderTooltipActive : l.reminderTooltipSet,
      visualDensity: widget.visualDensity,
      color: active ? Theme.of(context).colorScheme.primary : null,
      icon:
          Icon(active ? Icons.notifications_active : Icons.notifications_none),
      onPressed: () => active
          ? _showActiveDialog(context, ref, reminder)
          : _createOrEditReminder(context, ref, null),
    );
  }

  void _syncExpiryTimer(NoteReminder? reminder) {
    final remindAt = reminder?.remindAt.toUtc();
    if (remindAt == null) {
      _expiryTimer?.cancel();
      _expiryTimer = null;
      _armedFor = null;
      return;
    }
    if (_armedFor == remindAt && _expiryTimer?.isActive == true) return;

    _expiryTimer?.cancel();
    _armedFor = remindAt;
    final delay = remindAt.difference(DateTime.now().toUtc());
    if (delay <= Duration.zero) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() {});
      });
      return;
    }
    _expiryTimer = Timer(delay, () {
      if (mounted) setState(() {});
    });
  }

  Future<void> _showActiveDialog(
    BuildContext context,
    WidgetRef ref,
    NoteReminder reminder,
  ) async {
    final l = AppStrings.of(context);
    final formatter = DateFormat.yMMMd().add_jm();
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.reminderDialogTitle),
        content: Text(l.reminderScheduledFor(
          formatter.format(reminder.remindAt.toLocal()),
        )),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l.actionClose),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(reminderRepositoryProvider)?.removeReminder(
                    reminder.noteId,
                  );
              await ref.read(reminderSchedulerProvider).cancel(reminder.noteId);
            },
            child: Text(l.reminderRemove),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              _createOrEditReminder(context, ref, reminder.remindAt.toLocal());
            },
            child: Text(l.reminderEdit),
          ),
        ],
      ),
    );
  }

  Future<void> _createOrEditReminder(
    BuildContext context,
    WidgetRef ref,
    DateTime? initial,
  ) async {
    final l = AppStrings.of(context);
    final note = await widget.loadOrCreateNote();
    if (!context.mounted) return;
    if (note == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.reminderSaveNoteFirst)),
      );
      return;
    }

    final permission = await ref
        .read(reminderSchedulerProvider)
        .ensureSchedulingPermissionsForUserAction();
    if (!context.mounted) return;
    if (!permission.notificationsAllowed) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.reminderNotificationsRequired)),
      );
      return;
    }

    final now = DateTime.now();
    final seed = initial != null && initial.isAfter(now)
        ? initial
        : now.add(const Duration(minutes: 5));
    final date = await showDatePicker(
      context: context,
      initialDate: seed,
      firstDate: now,
      lastDate: now.add(const Duration(days: 3650)),
    );
    if (date == null || !context.mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(seed),
    );
    if (time == null || !context.mounted) return;

    final scheduledLocal = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
    if (!scheduledLocal.isAfter(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.reminderMustBeFuture)),
      );
      return;
    }

    final repo = ref.read(reminderRepositoryProvider);
    final reminder = await repo?.setReminder(note.id, scheduledLocal.toUtc());
    if (reminder == null) return;
    await ref.read(reminderSchedulerProvider).schedule(
          reminder: reminder,
          note: note,
          untitledFallback: l.noteUntitled,
          notificationBody: l.reminderNotificationBody,
        );
    if (!permission.exactAlarmsAllowed && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.reminderMayBeDelayed)),
      );
    }
    if (context.mounted) {
      await maybeShowReminderBackgroundPermissionPrompt(context, ref);
    }
  }
}
