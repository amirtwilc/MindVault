// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'checklist_item_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ChecklistItemModel _$ChecklistItemModelFromJson(Map<String, dynamic> json) =>
    ChecklistItemModel(
      id: json['id'] as String,
      noteId: json['note_id'] as String,
      userId: json['user_id'] as String,
      text: json['text'] as String,
      isCompleted: json['is_completed'] as bool,
      sortOrder: (json['sort_order'] as num).toInt(),
      completedAt: json['completed_at'] as String?,
      createdAt: json['created_at'] as String,
      updatedAt: json['updated_at'] as String,
    );

Map<String, dynamic> _$ChecklistItemModelToJson(ChecklistItemModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'note_id': instance.noteId,
      'user_id': instance.userId,
      'text': instance.text,
      'is_completed': instance.isCompleted,
      'sort_order': instance.sortOrder,
      'completed_at': instance.completedAt,
      'created_at': instance.createdAt,
      'updated_at': instance.updatedAt,
    };
