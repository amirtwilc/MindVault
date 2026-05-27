import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

Future<void> showMemoryHelpDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => const MemoryHelpDialog(),
  );
}

class MemoryHelpDialog extends StatelessWidget {
  const MemoryHelpDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppStrings.of(context);
    final cs = Theme.of(context).colorScheme;

    final items = [
      _HelpItem(
        icon: Icons.title,
        title: l.memoryHelpTitleField,
        body: l.memoryHelpTitleFieldBody,
      ),
      _HelpItem(
        icon: Icons.notes_outlined,
        title: l.memoryHelpType,
        body: l.memoryHelpTypeBody(l.noteTypeText, l.noteTypeChecklist),
      ),
      _HelpItem(
        icon: Icons.folder_outlined,
        title: l.memoryHelpCluster,
        body: l.memoryHelpClusterBody,
      ),
      _HelpItem(
        icon: Icons.mic_none,
        title: l.memoryHelpRecord,
        body: l.memoryHelpRecordBody,
      ),
      _HelpItem(
        icon: Icons.copy_outlined,
        title: l.memoryHelpCopy,
        body: l.memoryHelpCopyBody,
      ),
      _HelpItem(
        icon: Icons.notifications_none,
        title: l.memoryHelpReminder,
        body: l.memoryHelpReminderBody,
      ),
      _HelpItem(
        icon: Icons.lock_outline,
        title: l.memoryHelpLock,
        body: l.memoryHelpLockBody,
      ),
    ];

    return AlertDialog(
      title: Text(l.memoryHelpDialogTitle),
      contentPadding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final item in items)
                Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(item.icon, color: cs.primary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.title,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 2),
                            Text(item.body),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l.actionClose),
        ),
      ],
    );
  }
}

class _HelpItem {
  final IconData icon;
  final String title;
  final String body;

  const _HelpItem({
    required this.icon,
    required this.title,
    required this.body,
  });
}
