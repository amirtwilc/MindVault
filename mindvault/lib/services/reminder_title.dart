import '../domain/entities/note.dart';

String reminderNotificationTitle(Note note, String untitledFallback) {
  final title = note.title.trim();
  if (title.isNotEmpty) return title;

  final words = note.body
      .trim()
      .split(RegExp(r'\s+'))
      .where((word) => word.isNotEmpty)
      .take(4)
      .join(' ');
  if (words.isNotEmpty) return words;

  return untitledFallback;
}
