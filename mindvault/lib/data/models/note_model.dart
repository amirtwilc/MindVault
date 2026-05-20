import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/note.dart';

part 'note_model.g.dart';

@JsonSerializable()
class NoteModel {
  final String id;
  @JsonKey(name: 'user_id')
  final String userId;
  @JsonKey(name: 'category_id')
  final String categoryId;
  final String title;
  final String body;
  @JsonKey(name: 'is_private')
  final bool isPrivate;
  @JsonKey(name: 'last_used_at')
  final String lastUsedAt;
  @JsonKey(name: 'created_at')
  final String createdAt;
  @JsonKey(name: 'updated_at')
  final String updatedAt;
  @JsonKey(name: 'is_pinned', defaultValue: false)
  final bool isPinned;
  @JsonKey(name: 'pinned_at')
  final String? pinnedAt;
  @JsonKey(name: 'pin_order')
  final int? pinOrder;
  @JsonKey(name: 'note_type', defaultValue: 'text')
  final String noteType;

  const NoteModel({
    required this.id,
    required this.userId,
    required this.categoryId,
    required this.title,
    required this.body,
    required this.isPrivate,
    required this.lastUsedAt,
    required this.createdAt,
    required this.updatedAt,
    this.isPinned = false,
    this.pinnedAt,
    this.pinOrder,
    this.noteType = 'text',
  });

  factory NoteModel.fromJson(Map<String, dynamic> json) =>
      _$NoteModelFromJson(json);

  Map<String, dynamic> toJson() => _$NoteModelToJson(this);

  Note toEntity() => Note(
        id: id,
        userId: userId,
        categoryId: categoryId,
        title: title,
        body: body,
        isPrivate: isPrivate,
        lastUsedAt: DateTime.parse(lastUsedAt),
        createdAt: DateTime.parse(createdAt),
        updatedAt: DateTime.parse(updatedAt),
        isPinned: isPinned,
        pinnedAt: pinnedAt != null ? DateTime.parse(pinnedAt!) : null,
        pinOrder: pinOrder,
        noteType: NoteType.fromStorage(noteType),
      );

  static NoteModel fromEntity(Note note) => NoteModel(
        id: note.id,
        userId: note.userId,
        categoryId: note.categoryId,
        title: note.title,
        body: note.body,
        isPrivate: note.isPrivate,
        lastUsedAt: note.lastUsedAt.toIso8601String(),
        createdAt: note.createdAt.toIso8601String(),
        updatedAt: note.updatedAt.toIso8601String(),
        isPinned: note.isPinned,
        pinnedAt: note.pinnedAt?.toIso8601String(),
        pinOrder: note.pinOrder,
        noteType: note.noteType.storageValue,
      );
}
