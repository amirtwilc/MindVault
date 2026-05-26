import 'package:freezed_annotation/freezed_annotation.dart';

part 'note.freezed.dart';

enum NoteType {
  text,
  checklist;

  static NoteType fromStorage(String value) =>
      value == 'checklist' || value == 'plan'
          ? NoteType.checklist
          : NoteType.text;

  String get storageValue => switch (this) {
        NoteType.text => 'record',
        NoteType.checklist => 'plan',
      };
}

@freezed
class Note with _$Note {
  const factory Note({
    required String id,
    required String userId,
    required String categoryId,
    required String title,
    required String body,
    required bool isPrivate,
    required DateTime lastUsedAt,
    required DateTime createdAt,
    required DateTime updatedAt,
    @Default(null) DateTime? lastOpenedAt,
    @Default(NoteType.text) NoteType noteType,
    @Default(false) bool isPinned,
    @Default(null) DateTime? pinnedAt,
    @Default(null) int? pinOrder,
  }) = _Note;
}
