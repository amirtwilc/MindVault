// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'note_reminder_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NoteReminderModel _$NoteReminderModelFromJson(Map<String, dynamic> json) =>
    NoteReminderModel(
      noteId: json['note_id'] as String,
      userId: json['user_id'] as String,
      remindAt: json['remind_at'] as String,
      createdAt: json['created_at'] as String,
      updatedAt: json['updated_at'] as String,
      deletedAt: json['deleted_at'] as String?,
    );

Map<String, dynamic> _$NoteReminderModelToJson(NoteReminderModel instance) =>
    <String, dynamic>{
      'note_id': instance.noteId,
      'user_id': instance.userId,
      'remind_at': instance.remindAt,
      'created_at': instance.createdAt,
      'updated_at': instance.updatedAt,
      'deleted_at': instance.deletedAt,
    };
