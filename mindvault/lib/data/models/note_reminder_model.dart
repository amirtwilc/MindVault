import 'package:json_annotation/json_annotation.dart';

import '../../domain/entities/note_reminder.dart';

part 'note_reminder_model.g.dart';

@JsonSerializable()
class NoteReminderModel {
  @JsonKey(name: 'note_id')
  final String noteId;
  @JsonKey(name: 'user_id')
  final String userId;
  @JsonKey(name: 'remind_at')
  final String remindAt;
  @JsonKey(name: 'created_at')
  final String createdAt;
  @JsonKey(name: 'updated_at')
  final String updatedAt;
  @JsonKey(name: 'deleted_at')
  final String? deletedAt;

  const NoteReminderModel({
    required this.noteId,
    required this.userId,
    required this.remindAt,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  factory NoteReminderModel.fromJson(Map<String, dynamic> json) =>
      _$NoteReminderModelFromJson(json);

  Map<String, dynamic> toJson() => _$NoteReminderModelToJson(this);

  NoteReminder toEntity() => NoteReminder(
        noteId: noteId,
        userId: userId,
        remindAt: DateTime.parse(remindAt),
        createdAt: DateTime.parse(createdAt),
        updatedAt: DateTime.parse(updatedAt),
        deletedAt: deletedAt == null ? null : DateTime.parse(deletedAt!),
      );

  static NoteReminderModel fromEntity(NoteReminder reminder) {
    return NoteReminderModel(
      noteId: reminder.noteId,
      userId: reminder.userId,
      remindAt: reminder.remindAt.toUtc().toIso8601String(),
      createdAt: reminder.createdAt.toUtc().toIso8601String(),
      updatedAt: reminder.updatedAt.toUtc().toIso8601String(),
      deletedAt: reminder.deletedAt?.toUtc().toIso8601String(),
    );
  }
}
