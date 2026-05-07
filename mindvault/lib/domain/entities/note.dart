import 'package:freezed_annotation/freezed_annotation.dart';

part 'note.freezed.dart';

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
    @Default(false) bool isPinned,
    @Default(null) DateTime? pinnedAt,
    @Default(null) int? pinOrder,
  }) = _Note;
}
