import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/category.dart';

part 'category_model.g.dart';

@JsonSerializable()
class CategoryModel {
  final String id;
  @JsonKey(name: 'user_id')
  final String userId;
  final String name;
  @JsonKey(name: 'sort_order')
  final int sortOrder;
  @JsonKey(name: 'last_used_at')
  final String lastUsedAt;
  @JsonKey(name: 'created_at')
  final String createdAt;
  final String? color;

  const CategoryModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.sortOrder,
    required this.lastUsedAt,
    required this.createdAt,
    this.color,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) =>
      _$CategoryModelFromJson(json);

  Map<String, dynamic> toJson() => _$CategoryModelToJson(this);

  Category toEntity() => Category(
        id: id,
        userId: userId,
        name: name,
        sortOrder: sortOrder,
        lastUsedAt: DateTime.parse(lastUsedAt),
        createdAt: DateTime.parse(createdAt),
        color: color,
      );
}
