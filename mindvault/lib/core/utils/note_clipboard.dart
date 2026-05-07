import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/app_localizations.dart';

/// Copies [body] to the system clipboard and shows a brief confirmation
/// SnackBar. No-op when [body] is empty.
///
/// Used by the "Copy note" action in the editor and view screens. Lives here
/// so the same UX applies in the main editor, the widget compose dialog, and
/// the widget view/edit dialog without duplication.
Future<void> copyNoteBody(BuildContext context, String body) async {
  if (body.isEmpty) return;
  await Clipboard.setData(ClipboardData(text: body));
  if (!context.mounted) return;
  final l = AppStrings.of(context);
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(l.editorCopiedSnack),
      duration: const Duration(seconds: 2),
      behavior: SnackBarBehavior.floating,
    ),
  );
}
