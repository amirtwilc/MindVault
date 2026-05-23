class NoteReminder {
  final String noteId;
  final String userId;
  final DateTime remindAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  const NoteReminder({
    required this.noteId,
    required this.userId,
    required this.remindAt,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  bool get isDeleted => deletedAt != null;

  bool isActiveAt(DateTime now) {
    if (isDeleted) return false;
    return remindAt.isAfter(now);
  }

  bool isDueAt(DateTime now) => !isDeleted && !remindAt.isAfter(now);

  NoteReminder copyWith({
    DateTime? remindAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
  }) {
    return NoteReminder(
      noteId: noteId,
      userId: userId,
      remindAt: remindAt ?? this.remindAt,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: clearDeletedAt ? null : deletedAt ?? this.deletedAt,
    );
  }
}
