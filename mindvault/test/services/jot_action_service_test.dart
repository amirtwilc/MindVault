import 'package:flutter_test/flutter_test.dart';
import 'package:mindvault/domain/entities/checklist_item.dart';
import 'package:mindvault/domain/entities/jot.dart';
import 'package:mindvault/domain/entities/note.dart';
import 'package:mindvault/domain/entities/note_reminder.dart';
import 'package:mindvault/domain/repositories/jot_repository.dart';
import 'package:mindvault/domain/repositories/note_repository.dart';
import 'package:mindvault/domain/repositories/reminder_repository.dart';
import 'package:mindvault/services/jot_action_service.dart';

Jot _jot({
  String id = 'jot-1',
  String text = 'Buy milk',
  DateTime? reminderAt,
  DateTime? handledAt,
}) {
  final now = DateTime(2026, 1, 1, 9).toUtc();
  return Jot(
    id: id,
    userId: 'user-1',
    text: text,
    createdAt: now,
    updatedAt: now,
    handledAt: handledAt,
    reminderAt: reminderAt,
  );
}

Note _note({
  String id = 'note-1',
  String title = 'Note',
  String body = '',
  NoteType type = NoteType.text,
}) {
  final now = DateTime(2026, 1, 1, 9).toUtc();
  return Note(
    id: id,
    userId: 'user-1',
    categoryId: 'cat-1',
    title: title,
    body: body,
    isPrivate: false,
    lastUsedAt: now,
    createdAt: now,
    updatedAt: now,
    noteType: type,
  );
}

class _FakeJotRepository implements JotRepository {
  final Map<String, Jot> jots = {};
  final Set<String> deleted = {};

  @override
  Future<Jot> createJot({required String text}) async =>
      throw UnimplementedError();

  @override
  Future<void> deleteJot(String id) async {
    deleted.add(id);
    jots.remove(id);
  }

  @override
  Future<void> deleteJots(List<String> ids) async {
    for (final id in ids) {
      await deleteJot(id);
    }
  }

  @override
  Future<Jot?> getJotById(String id) async => jots[id];

  @override
  Future<List<Jot>> getUnhandledJots({
    JotSortOrder sortOrder = JotSortOrder.oldestFirst,
  }) async =>
      jots.values.where((jot) => !jot.isHandled).toList();

  @override
  Future<void> markHandled(String id) async {
    final jot = jots[id]!;
    jots[id] = jot.copyWith(handledAt: DateTime.now().toUtc());
  }

  @override
  void startSync() {}

  @override
  void stopSync() {}

  @override
  Future<void> syncPendingOps() async {}

  @override
  Future<Jot?> updateJot({
    required String id,
    String? text,
    DateTime? handledAt,
    DateTime? aiProcessedAt,
    String? aiSuggestionJson,
    String? aiSuggestionRunId,
    DateTime? reminderAt,
  }) async {
    final current = jots[id];
    if (current == null) return null;
    final updated = current.copyWith(
      text: text,
      handledAt: handledAt,
      aiProcessedAt: aiProcessedAt,
      aiSuggestionJson: aiSuggestionJson,
      aiSuggestionRunId: aiSuggestionRunId,
      reminderAt: reminderAt,
      updatedAt: DateTime.now().toUtc(),
    );
    jots[id] = updated;
    return updated;
  }

  @override
  Future<Jot?> clearReminder(String id) async {
    final current = jots[id];
    if (current == null) return null;
    final updated = current.copyWith(
      reminderAt: null,
      updatedAt: DateTime.now().toUtc(),
    );
    jots[id] = updated;
    return updated;
  }

  @override
  Stream<List<Jot>> watchUnhandledJots({
    JotSortOrder sortOrder = JotSortOrder.oldestFirst,
  }) =>
      Stream.value(jots.values.where((jot) => !jot.isHandled).toList());
}

class _FakeNoteRepository implements NoteRepository {
  final Map<String, Note> notes = {};
  final Map<String, List<ChecklistItem>> items = {};
  int _nextNote = 1;
  int _nextItem = 1;

  @override
  Future<Note> createNote({
    required String categoryId,
    required String title,
    required String body,
    required bool isPrivate,
    NoteType noteType = NoteType.text,
  }) async {
    final now = DateTime.now().toUtc();
    final note = Note(
      id: 'created-${_nextNote++}',
      userId: 'user-1',
      categoryId: categoryId,
      title: title,
      body: body,
      isPrivate: isPrivate,
      lastUsedAt: now,
      createdAt: now,
      updatedAt: now,
      noteType: noteType,
    );
    notes[note.id] = note;
    return note;
  }

  @override
  Future<Note?> getNoteById(String id) async => notes[id];

  @override
  Future<List<ChecklistItem>> getChecklistItems(String noteId) async =>
      items[noteId] ?? const [];

  @override
  Future<List<ChecklistItem>> replaceChecklistItems({
    required String noteId,
    required List<String> texts,
    List<bool>? completionStates,
    List<String?>? rowIds,
  }) async {
    final now = DateTime.now().toUtc();
    final rows = <ChecklistItem>[
      for (var i = 0; i < texts.length; i++)
        ChecklistItem(
          id: rowIds != null && rowIds[i] != null
              ? rowIds[i]!
              : 'item-${_nextItem++}',
          noteId: noteId,
          userId: 'user-1',
          text: texts[i],
          isCompleted: completionStates?[i] ?? false,
          sortOrder: i,
          createdAt: now,
          updatedAt: now,
        ),
    ];
    items[noteId] = rows;
    final note = notes[noteId];
    if (note != null) {
      notes[noteId] = note.copyWith(
        body: texts.join('\n'),
        noteType: NoteType.checklist,
        updatedAt: now,
      );
    }
    return rows;
  }

  @override
  Future<Note> updateNote({
    required String id,
    String? title,
    String? body,
    bool? isPrivate,
    String? categoryId,
    NoteType? noteType,
  }) async {
    final note = notes[id]!;
    final updated = note.copyWith(
      title: title ?? note.title,
      body: body ?? note.body,
      isPrivate: isPrivate ?? note.isPrivate,
      categoryId: categoryId ?? note.categoryId,
      noteType: noteType ?? note.noteType,
      updatedAt: DateTime.now().toUtc(),
    );
    notes[id] = updated;
    return updated;
  }

  @override
  Future<void> convertNoteType({
    required String noteId,
    required NoteType noteType,
  }) async {}

  @override
  Future<void> deleteCompletedChecklistItems(String noteId) async {}

  @override
  Future<void> deleteNote(String id) async {}

  @override
  Future<void> markNoteOpened(String id) async {}

  @override
  Future<void> reorderChecklistItems({
    required String noteId,
    required List<String> orderedIds,
  }) async {}

  @override
  Future<void> reorderPinnedNotes(List<String> orderedIds) async {}

  @override
  Future<List<Note>> searchNotes(String query) async => const [];

  @override
  Future<void> setNotePinned(
      {required String id, required bool isPinned}) async {}

  @override
  Future<void> syncPendingOps() async {}

  @override
  Future<void> toggleChecklistItem({
    required String id,
    required bool isCompleted,
  }) async {}

  @override
  Stream<List<ChecklistItem>> watchChecklistItems(String noteId) =>
      Stream.value(items[noteId] ?? const []);

  @override
  Stream<List<Note>> watchAllNotes() => Stream.value(notes.values.toList());

  @override
  Stream<List<Note>> watchNotesByCategory(String categoryId) => Stream.value(
      notes.values.where((n) => n.categoryId == categoryId).toList());
}

class _FakeReminderRepository implements ReminderRepository {
  final Map<String, NoteReminder> reminders = {};

  @override
  Future<NoteReminder> setReminder(String noteId, DateTime remindAtUtc) async {
    final now = DateTime.now().toUtc();
    final reminder = NoteReminder(
      noteId: noteId,
      userId: 'user-1',
      remindAt: remindAtUtc,
      createdAt: now,
      updatedAt: now,
    );
    reminders[noteId] = reminder;
    return reminder;
  }

  @override
  Future<void> cleanupExpiredReminders(DateTime now) async {}

  @override
  Future<List<NoteReminder>> getActiveReminders() async =>
      reminders.values.toList();

  @override
  Future<NoteReminder?> getReminderForNote(String noteId) async =>
      reminders[noteId];

  @override
  Future<void> removeReminder(String noteId) async {
    reminders.remove(noteId);
  }

  @override
  Future<void> syncAllReminders() async {}

  @override
  Future<void> syncPendingOps() async {}

  @override
  Stream<NoteReminder?> watchReminderForNote(String noteId) =>
      Stream.value(reminders[noteId]);
}

void main() {
  late _FakeJotRepository jotRepo;
  late _FakeNoteRepository noteRepo;
  late _FakeReminderRepository reminderRepo;
  late JotActionService service;

  setUp(() {
    jotRepo = _FakeJotRepository();
    noteRepo = _FakeNoteRepository();
    reminderRepo = _FakeReminderRepository();
    service = JotActionService(
      jotRepository: jotRepo,
      noteRepository: noteRepo,
      reminderRepository: reminderRepo,
    );
    jotRepo.jots['jot-1'] = _jot();
  });

  test('create note writes jot text and marks the jot handled', () async {
    final result = await service.apply(
      jot: jotRepo.jots['jot-1']!,
      request: const JotActionRequest(
        createNote: true,
        newNoteCategoryId: 'cat-1',
        newNoteTitle: 'Groceries',
      ),
    );

    expect(result.note!.title, equals('Groceries'));
    expect(result.note!.body, equals('Buy milk'));
    expect(jotRepo.jots['jot-1']!.isHandled, isTrue);
  });

  test('updated thought text is used when creating a note', () async {
    jotRepo.jots['jot-1'] = _jot(text: 'I want to see Lord of the Rings');

    final result = await service.apply(
      jot: jotRepo.jots['jot-1']!,
      request: const JotActionRequest(
        createNote: true,
        newNoteCategoryId: 'cat-1',
        updatedText: 'Lord of the Rings',
      ),
    );

    expect(result.note!.body, equals('Lord of the Rings'));
    expect(jotRepo.jots['jot-1']!.text, equals('Lord of the Rings'));
    expect(jotRepo.jots['jot-1']!.isHandled, isTrue);
  });

  test('create note can lock the created note', () async {
    final result = await service.apply(
      jot: jotRepo.jots['jot-1']!,
      request: const JotActionRequest(
        createNote: true,
        newNoteCategoryId: 'cat-1',
        newNoteLocked: true,
      ),
    );

    expect(result.note!.isPrivate, isTrue);
    expect(jotRepo.jots['jot-1']!.isHandled, isTrue);
  });

  test('create checklist note creates an unchecked checklist row', () async {
    final result = await service.apply(
      jot: jotRepo.jots['jot-1']!,
      request: const JotActionRequest(
        createNote: true,
        newNoteCategoryId: 'cat-1',
        newNoteType: NoteType.checklist,
      ),
    );

    final rows = noteRepo.items[result.note!.id]!;
    expect(result.note!.noteType, equals(NoteType.checklist));
    expect(rows.single.text, equals('Buy milk'));
    expect(rows.single.isCompleted, isFalse);
  });

  test('add to text note appends the jot as a new line', () async {
    noteRepo.notes['note-1'] = _note(body: 'Existing line');

    await service.apply(
      jot: jotRepo.jots['jot-1']!,
      request: const JotActionRequest(
        addToNote: true,
        existingNoteId: 'note-1',
      ),
    );

    expect(noteRepo.notes['note-1']!.body, equals('Existing line\nBuy milk'));
    expect(jotRepo.jots['jot-1']!.isHandled, isTrue);
  });

  test('updated thought text is used when adding to an existing note',
      () async {
    jotRepo.jots['jot-1'] = _jot(text: 'I want to see Lord of the Rings');
    noteRepo.notes['note-1'] = _note(body: 'Movies');

    await service.apply(
      jot: jotRepo.jots['jot-1']!,
      request: const JotActionRequest(
        addToNote: true,
        existingNoteId: 'note-1',
        updatedText: 'Lord of the Rings',
      ),
    );

    expect(noteRepo.notes['note-1']!.body, equals('Movies\nLord of the Rings'));
    expect(jotRepo.jots['jot-1']!.text, equals('Lord of the Rings'));
  });

  test('add to checklist note creates an unchecked checklist row', () async {
    noteRepo.notes['note-1'] = _note(type: NoteType.checklist);
    final now = DateTime.now().toUtc();
    noteRepo.items['note-1'] = [
      ChecklistItem(
        id: 'existing',
        noteId: 'note-1',
        userId: 'user-1',
        text: 'Already here',
        isCompleted: true,
        sortOrder: 0,
        createdAt: now,
        updatedAt: now,
      ),
    ];

    await service.apply(
      jot: jotRepo.jots['jot-1']!,
      request: const JotActionRequest(
        addToNote: true,
        existingNoteId: 'note-1',
      ),
    );

    final rows = noteRepo.items['note-1']!;
    expect(rows.map((row) => row.text), equals(['Already here', 'Buy milk']));
    expect(rows.map((row) => row.isCompleted), equals([true, false]));
  });

  test('alert with note action creates a note reminder', () async {
    final when = DateTime(2026, 1, 2, 12).toUtc();

    final result = await service.apply(
      jot: jotRepo.jots['jot-1']!,
      request: JotActionRequest(
        createNote: true,
        newNoteCategoryId: 'cat-1',
        createAlert: true,
        reminderAt: when,
      ),
    );

    expect(result.noteReminder!.noteId, equals(result.note!.id));
    expect(result.noteReminder!.remindAt, equals(when));
    expect(result.jotReminder, isNull);
  });

  test('standalone alert keeps jot unhandled with reminderAt', () async {
    final when = DateTime(2026, 1, 2, 12).toUtc();

    final result = await service.apply(
      jot: jotRepo.jots['jot-1']!,
      request: JotActionRequest(createAlert: true, reminderAt: when),
    );

    expect(result.handled, isFalse);
    expect(result.jotReminder!.reminderAt, equals(when));
    expect(jotRepo.jots['jot-1']!.isHandled, isFalse);
  });

  test('update-only action keeps jot unhandled with edited text', () async {
    jotRepo.jots['jot-1'] = _jot(text: 'I want to see Lord of the Rings');

    final result = await service.apply(
      jot: jotRepo.jots['jot-1']!,
      request: const JotActionRequest(updatedText: 'Lord of the Rings'),
    );

    expect(result.updated, isTrue);
    expect(result.handled, isFalse);
    expect(jotRepo.jots['jot-1']!.text, equals('Lord of the Rings'));
    expect(jotRepo.jots['jot-1']!.isHandled, isFalse);
  });

  test('delete thought is exclusive and deletes the jot', () async {
    final result = await service.apply(
      jot: jotRepo.jots['jot-1']!,
      request: const JotActionRequest(deleteThought: true),
    );

    expect(result.deleted, isTrue);
    expect(jotRepo.deleted, contains('jot-1'));
    expect(noteRepo.notes, isEmpty);
  });
}
