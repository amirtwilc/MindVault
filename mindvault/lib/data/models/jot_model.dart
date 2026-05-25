import '../../domain/entities/jot.dart';

class JotModel {
  final String id;
  final String userId;
  final String text;
  final String createdAt;
  final String updatedAt;
  final String? handledAt;
  final String? aiProcessedAt;
  final String? aiSuggestionJson;
  final String? aiSuggestionRunId;
  final String? reminderAt;

  const JotModel({
    required this.id,
    required this.userId,
    required this.text,
    required this.createdAt,
    required this.updatedAt,
    this.handledAt,
    this.aiProcessedAt,
    this.aiSuggestionJson,
    this.aiSuggestionRunId,
    this.reminderAt,
  });

  factory JotModel.fromJson(Map<String, dynamic> json) => JotModel(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        text: json['text'] as String,
        createdAt: json['created_at'] as String,
        updatedAt: json['updated_at'] as String,
        handledAt: json['handled_at'] as String?,
        aiProcessedAt: json['ai_processed_at'] as String?,
        aiSuggestionJson: json['ai_suggestion_json'] as String?,
        aiSuggestionRunId: json['ai_suggestion_run_id'] as String?,
        reminderAt: json['reminder_at'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'text': text,
        'created_at': createdAt,
        'updated_at': updatedAt,
        'handled_at': handledAt,
        'ai_processed_at': aiProcessedAt,
        'ai_suggestion_json': aiSuggestionJson,
        'ai_suggestion_run_id': aiSuggestionRunId,
        'reminder_at': reminderAt,
      };

  Jot toEntity() => Jot(
        id: id,
        userId: userId,
        text: text,
        createdAt: DateTime.parse(createdAt).toUtc(),
        updatedAt: DateTime.parse(updatedAt).toUtc(),
        handledAt:
            handledAt == null ? null : DateTime.parse(handledAt!).toUtc(),
        aiProcessedAt: aiProcessedAt == null
            ? null
            : DateTime.parse(aiProcessedAt!).toUtc(),
        aiSuggestionJson: aiSuggestionJson,
        aiSuggestionRunId: aiSuggestionRunId,
        reminderAt:
            reminderAt == null ? null : DateTime.parse(reminderAt!).toUtc(),
      );
}
