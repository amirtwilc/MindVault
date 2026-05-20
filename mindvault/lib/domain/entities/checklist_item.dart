import 'package:freezed_annotation/freezed_annotation.dart';

part 'checklist_item.freezed.dart';

@freezed
class ChecklistItem with _$ChecklistItem {
  const factory ChecklistItem({
    required String id,
    required String noteId,
    required String userId,
    required String text,
    required bool isCompleted,
    required int sortOrder,
    @Default(null) DateTime? completedAt,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _ChecklistItem;
}
