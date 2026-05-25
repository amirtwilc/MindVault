import 'dart:convert';

enum JotSortOrder {
  oldestFirst,
  newestFirst;

  bool get newestFirstSelected => this == JotSortOrder.newestFirst;

  static JotSortOrder fromStorage(String? value) => value == 'newest_first'
      ? JotSortOrder.newestFirst
      : JotSortOrder.oldestFirst;

  String get storageValue => switch (this) {
        JotSortOrder.oldestFirst => 'oldest_first',
        JotSortOrder.newestFirst => 'newest_first',
      };
}

enum JotSuggestedAction {
  createNote,
  addToNote,
  reminder;

  static JotSuggestedAction? fromStorage(String? value) => switch (value) {
        'create_note' => JotSuggestedAction.createNote,
        'add_to_note' => JotSuggestedAction.addToNote,
        'reminder' => JotSuggestedAction.reminder,
        _ => null,
      };

  String get storageValue => switch (this) {
        JotSuggestedAction.createNote => 'create_note',
        JotSuggestedAction.addToNote => 'add_to_note',
        JotSuggestedAction.reminder => 'reminder',
      };
}

class JotAiSuggestion {
  final String jotId;
  final JotSuggestedAction action;
  final double confidence;
  final String? title;
  final String? categoryId;
  final String? categoryName;
  final String? noteId;
  final String? noteType;
  final bool? isPrivate;
  final DateTime? reminderAt;
  final String? updatedText;
  final String? reason;

  const JotAiSuggestion({
    required this.jotId,
    required this.action,
    required this.confidence,
    this.title,
    this.categoryId,
    this.categoryName,
    this.noteId,
    this.noteType,
    this.isPrivate,
    this.reminderAt,
    this.updatedText,
    this.reason,
  });

  bool get isHighConfidence => confidence >= 0.55;

  factory JotAiSuggestion.fromJson(Map<String, dynamic> json) {
    final action = JotSuggestedAction.fromStorage(json['action'] as String?);
    if (action == null) {
      throw FormatException('Unknown jot AI action: ${json['action']}');
    }
    final rawReminderAt = json['reminder_at'] as String?;
    return JotAiSuggestion(
      jotId: json['jot_id'] as String,
      action: action,
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0,
      title: json['title'] as String?,
      categoryId: json['category_id'] as String?,
      categoryName: json['category_name'] as String?,
      noteId: json['note_id'] as String?,
      noteType: json['note_type'] as String?,
      isPrivate: json['is_private'] as bool?,
      reminderAt:
          rawReminderAt == null ? null : DateTime.tryParse(rawReminderAt),
      updatedText: json['updated_text'] as String?,
      reason: json['reason'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'jot_id': jotId,
        'action': action.storageValue,
        'confidence': confidence,
        if (title != null) 'title': title,
        if (categoryId != null) 'category_id': categoryId,
        if (categoryName != null) 'category_name': categoryName,
        if (noteId != null) 'note_id': noteId,
        if (noteType != null) 'note_type': noteType,
        if (isPrivate != null) 'is_private': isPrivate,
        if (reminderAt != null)
          'reminder_at': reminderAt!.toUtc().toIso8601String(),
        if (updatedText != null) 'updated_text': updatedText,
        if (reason != null) 'reason': reason,
      };
}

class Jot {
  final String id;
  final String userId;
  final String text;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? handledAt;
  final DateTime? aiProcessedAt;
  final String? aiSuggestionJson;
  final String? aiSuggestionRunId;
  final DateTime? reminderAt;

  const Jot({
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

  bool get isHandled => handledAt != null;
  bool get wasSentToAi => aiProcessedAt != null;

  JotAiSuggestion? get aiSuggestion {
    final raw = aiSuggestionJson;
    if (raw == null || raw.trim().isEmpty) return null;
    try {
      return JotAiSuggestion.fromJson(
        Map<String, dynamic>.from(jsonDecode(raw) as Map),
      );
    } catch (_) {
      return null;
    }
  }

  Jot copyWith({
    String? id,
    String? userId,
    String? text,
    DateTime? createdAt,
    DateTime? updatedAt,
    Object? handledAt = _sentinel,
    Object? aiProcessedAt = _sentinel,
    Object? aiSuggestionJson = _sentinel,
    Object? aiSuggestionRunId = _sentinel,
    Object? reminderAt = _sentinel,
  }) {
    return Jot(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      text: text ?? this.text,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      handledAt:
          handledAt == _sentinel ? this.handledAt : handledAt as DateTime?,
      aiProcessedAt: aiProcessedAt == _sentinel
          ? this.aiProcessedAt
          : aiProcessedAt as DateTime?,
      aiSuggestionJson: aiSuggestionJson == _sentinel
          ? this.aiSuggestionJson
          : aiSuggestionJson as String?,
      aiSuggestionRunId: aiSuggestionRunId == _sentinel
          ? this.aiSuggestionRunId
          : aiSuggestionRunId as String?,
      reminderAt:
          reminderAt == _sentinel ? this.reminderAt : reminderAt as DateTime?,
    );
  }
}

const Object _sentinel = Object();
