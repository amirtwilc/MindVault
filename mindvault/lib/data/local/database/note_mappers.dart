import '../../../domain/entities/note.dart';
import '../../../domain/entities/checklist_item.dart';
import '../../../domain/entities/jot.dart';
import '../../../domain/entities/note_reminder.dart';
import 'app_database.dart';

Note rowToNote(NotesTableData r) => Note(
      id: r.id,
      userId: r.userId,
      categoryId: r.categoryId,
      title: r.title,
      body: r.body,
      isPrivate: r.isPrivate,
      lastUsedAt: r.lastUsedAt,
      createdAt: r.createdAt,
      updatedAt: r.updatedAt,
      lastOpenedAt: r.lastOpenedAt,
      noteType: NoteType.fromStorage(r.noteType),
      isPinned: r.isPinned,
      pinnedAt: r.pinnedAt,
      pinOrder: r.pinOrder,
    );

ChecklistItem rowToChecklistItem(ChecklistItemsTableData r) => ChecklistItem(
      id: r.id,
      noteId: r.noteId,
      userId: r.userId,
      text: r.itemText,
      isCompleted: r.isCompleted,
      sortOrder: r.sortOrder,
      completedAt: r.completedAt,
      createdAt: r.createdAt,
      updatedAt: r.updatedAt,
    );

NoteReminder rowToReminder(NoteRemindersTableData r) => NoteReminder(
      noteId: r.noteId,
      userId: r.userId,
      remindAt: r.remindAt,
      createdAt: r.createdAt,
      updatedAt: r.updatedAt,
      deletedAt: r.deletedAt,
    );

Jot rowToJot(JotsTableData r) => Jot(
      id: r.id,
      userId: r.userId,
      text: r.jotText,
      createdAt: r.createdAt,
      updatedAt: r.updatedAt,
      handledAt: r.handledAt,
      aiProcessedAt: r.aiProcessedAt,
      aiSuggestionJson: r.aiSuggestionJson,
      aiSuggestionRunId: r.aiSuggestionRunId,
      reminderAt: r.reminderAt,
    );
