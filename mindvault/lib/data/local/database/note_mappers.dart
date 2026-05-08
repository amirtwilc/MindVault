import '../../../domain/entities/note.dart';
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
      isPinned: r.isPinned,
      pinnedAt: r.pinnedAt,
      pinOrder: r.pinOrder,
    );
