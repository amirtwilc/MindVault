import 'package:json_annotation/json_annotation.dart';

import '../../domain/entities/checklist_item.dart';

part 'checklist_item_model.g.dart';

@JsonSerializable()
class ChecklistItemModel {
  final String id;
  @JsonKey(name: 'note_id')
  final String noteId;
  @JsonKey(name: 'user_id')
  final String userId;
  final String text;
  @JsonKey(name: 'is_completed')
  final bool isCompleted;
  @JsonKey(name: 'sort_order')
  final int sortOrder;
  @JsonKey(name: 'completed_at')
  final String? completedAt;
  @JsonKey(name: 'created_at')
  final String createdAt;
  @JsonKey(name: 'updated_at')
  final String updatedAt;

  const ChecklistItemModel({
    required this.id,
    required this.noteId,
    required this.userId,
    required this.text,
    required this.isCompleted,
    required this.sortOrder,
    this.completedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ChecklistItemModel.fromJson(Map<String, dynamic> json) =>
      _$ChecklistItemModelFromJson(json);

  Map<String, dynamic> toJson() => _$ChecklistItemModelToJson(this);

  ChecklistItem toEntity({required String decryptedText}) => ChecklistItem(
        id: id,
        noteId: noteId,
        userId: userId,
        text: decryptedText,
        isCompleted: isCompleted,
        sortOrder: sortOrder,
        completedAt: completedAt != null ? DateTime.parse(completedAt!) : null,
        createdAt: DateTime.parse(createdAt),
        updatedAt: DateTime.parse(updatedAt),
      );
}
