import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindvault/data/local/database/app_database.dart';
import 'package:mindvault/domain/entities/category.dart';
import 'package:mindvault/domain/entities/checklist_item.dart';
import 'package:mindvault/domain/entities/note.dart';
import 'package:mindvault/domain/repositories/note_repository.dart';
import 'package:mindvault/l10n/app_localizations.dart';
import 'package:mindvault/presentation/providers/categories_provider.dart';
import 'package:mindvault/presentation/providers/database_provider.dart';
import 'package:mindvault/presentation/providers/encryption_provider.dart';
import 'package:mindvault/presentation/providers/notes_provider.dart';
import 'package:mindvault/presentation/providers/reminder_provider.dart';
import 'package:mindvault/presentation/providers/widget_sync_provider.dart';
import 'package:mindvault/presentation/screens/widget/widget_note_view_screen.dart';
import 'package:mindvault/services/encryption_service.dart';
import 'package:mindvault/services/reminder_scheduler_service.dart';
import 'package:mindvault/services/widget_data_service.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/fake_secure_storage.dart';

class _MockNoteRepository extends Mock implements NoteRepository {}

class _FakeReminderScheduler extends ReminderSchedulerService {
  String? cancelledNoteId;

  _FakeReminderScheduler() : super();

  @override
  Future<void> cancel(String noteId) async {
    cancelledNoteId = noteId;
  }
}

class _FakeWidgetDataService extends WidgetDataService {
  String? removedNoteId;

  @override
  Future<void> patchNoteOpened({
    required Note note,
    required List<Category> categories,
  }) async {}

  @override
  Future<void> patchNoteRemoved({required String noteId}) async {
    removedNoteId = noteId;
  }
}

class _FakeCategoriesNotifier extends CategoriesNotifier {
  _FakeCategoriesNotifier(this._categories);

  final List<Category> _categories;

  @override
  Future<List<Category>> build() async => _categories;
}

Category _category() => Category(
      id: 'cat-1',
      userId: 'user-1',
      name: 'General',
      sortOrder: 0,
      color: null,
      lastUsedAt: DateTime(2024),
      createdAt: DateTime(2024),
    );

Widget _harness({
  required AppDatabase db,
  required NoteRepository repo,
  required WidgetDataService widgetDataService,
  required ReminderSchedulerService reminderScheduler,
  required VoidCallback onClose,
}) {
  final encryption = EncryptionService(FakeSecureStorage());
  return ProviderScope(
    overrides: [
      appDatabaseProvider.overrideWithValue(db),
      noteRepositoryProvider.overrideWithValue(repo),
      reminderRepositoryProvider.overrideWithValue(null),
      reminderSchedulerProvider.overrideWithValue(reminderScheduler),
      widgetDataServiceProvider.overrideWithValue(widgetDataService),
      secureStorageProvider.overrideWithValue(FakeSecureStorage()),
      encryptionServiceProvider.overrideWithValue(encryption),
      aesKeyProvider.overrideWith((_) => enc.Key.fromLength(32)),
      categoriesProvider
          .overrideWith(() => _FakeCategoriesNotifier([_category()])),
    ],
    child: MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppStrings.localizationsDelegates,
      supportedLocales: AppStrings.supportedLocales,
      home: WidgetNoteViewScreen(noteId: 'note-1', onClose: onClose),
    ),
  );
}

void main() {
  late AppDatabase db;
  late _MockNoteRepository repo;
  late _FakeWidgetDataService widgetDataService;
  late _FakeReminderScheduler reminderScheduler;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = _MockNoteRepository();
    widgetDataService = _FakeWidgetDataService();
    reminderScheduler = _FakeReminderScheduler();
  });

  tearDown(() async {
    await db.close();
  });

  testWidgets(
    'removing the only completed task from an untitled checklist note deletes it',
    (tester) async {
      final now = DateTime.now().toUtc();
      await db.upsertNote(NotesTableCompanion(
        id: const Value('note-1'),
        userId: const Value('user-1'),
        categoryId: const Value('cat-1'),
        title: const Value(''),
        body: const Value('Done'),
        isPrivate: const Value(false),
        noteType: const Value('checklist'),
        lastUsedAt: Value(now),
        createdAt: Value(now),
        updatedAt: Value(now),
      ));
      await db.upsertChecklistItem(ChecklistItemsTableCompanion(
        id: const Value('item-1'),
        noteId: const Value('note-1'),
        userId: const Value('user-1'),
        itemText: const Value('Done'),
        isCompleted: const Value(true),
        sortOrder: const Value(0),
        completedAt: Value(now),
        createdAt: Value(now),
        updatedAt: Value(now),
      ));

      when(() => repo.deleteCompletedChecklistItems('note-1'))
          .thenAnswer((_) async {
        await db.deleteCompletedChecklistItems('note-1');
      });
      when(() => repo.getChecklistItems('note-1'))
          .thenAnswer((_) async => <ChecklistItem>[]);
      when(() => repo.deleteNote('note-1')).thenAnswer((_) async {
        await db.deleteNote('note-1');
      });

      var closed = false;
      await tester.pumpWidget(_harness(
        db: db,
        repo: repo,
        widgetDataService: widgetDataService,
        reminderScheduler: reminderScheduler,
        onClose: () => closed = true,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Remove done tasks'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      verify(() => repo.deleteCompletedChecklistItems('note-1')).called(1);
      verify(() => repo.deleteNote('note-1')).called(1);
      expect(widgetDataService.removedNoteId, 'note-1');
      expect(closed, isTrue);
      expect(await db.getNote('note-1'), isNull);
    },
  );
}
