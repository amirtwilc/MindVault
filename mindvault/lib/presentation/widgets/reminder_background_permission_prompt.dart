import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../providers/reminder_provider.dart';

Future<void> maybeShowReminderBackgroundPermissionPrompt(
  BuildContext context,
  WidgetRef ref,
) async {
  final scheduler = ref.read(reminderSchedulerProvider);
  if (!await scheduler.shouldPromptBackgroundPermission()) return;
  await scheduler.markBackgroundPermissionPromptDone();
  if (!context.mounted) return;

  final l = AppStrings.of(context);
  final openSettings = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(l.reminderBackgroundPermissionTitle),
      content: Text(l.reminderBackgroundPermissionBody),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: Text(l.actionNotNow),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          child: Text(l.reminderBackgroundPermissionOpenSettings),
        ),
      ],
    ),
  );

  if (openSettings == true) {
    await scheduler.openBackgroundPermissionSettings();
  }
}
