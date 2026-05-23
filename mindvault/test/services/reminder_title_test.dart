import 'package:flutter_test/flutter_test.dart';
import 'package:mindvault/domain/entities/note.dart';
import 'package:mindvault/services/reminder_title.dart';

Note _note({String title = '', String body = ''}) {
  final now = DateTime(2024).toUtc();
  return Note(
    id: 'note-1',
    userId: 'user-1',
    categoryId: 'cat-1',
    title: title,
    body: body,
    isPrivate: false,
    lastUsedAt: now,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  test('uses note title when present', () {
    expect(
      reminderNotificationTitle(_note(title: 'Meeting'), '(untitled)'),
      'Meeting',
    );
  });

  test('uses first four body words when title is empty', () {
    expect(
      reminderNotificationTitle(
        _note(body: 'buy milk and eggs tomorrow'),
        '(untitled)',
      ),
      'buy milk and eggs',
    );
  });

  test('uses untitled fallback when title and body are empty', () {
    expect(
      reminderNotificationTitle(_note(), '(untitled)'),
      '(untitled)',
    );
  });
}
