// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'note_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NoteModel _$NoteModelFromJson(Map<String, dynamic> json) => NoteModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      categoryId: json['category_id'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      isPrivate: json['is_private'] as bool,
      lastUsedAt: json['last_used_at'] as String,
      createdAt: json['created_at'] as String,
      updatedAt: json['updated_at'] as String,
      isPinned: json['is_pinned'] as bool? ?? false,
      pinnedAt: json['pinned_at'] as String?,
      pinOrder: (json['pin_order'] as num?)?.toInt(),
      noteType: json['note_type'] as String? ?? 'text',
    );

Map<String, dynamic> _$NoteModelToJson(NoteModel instance) => <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'category_id': instance.categoryId,
      'title': instance.title,
      'body': instance.body,
      'is_private': instance.isPrivate,
      'last_used_at': instance.lastUsedAt,
      'created_at': instance.createdAt,
      'updated_at': instance.updatedAt,
      'is_pinned': instance.isPinned,
      'pinned_at': instance.pinnedAt,
      'pin_order': instance.pinOrder,
      'note_type': instance.noteType,
    };
