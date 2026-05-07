import 'package:freezed_annotation/freezed_annotation.dart';

part 'category.freezed.dart';

@freezed
class Category with _$Category {
  const factory Category({
    required String id,
    required String userId,
    required String name,
    required int sortOrder,
    required DateTime lastUsedAt,
    required DateTime createdAt,
    String? color,
  }) = _Category;
}
