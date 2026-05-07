// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'category_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CategoryModel _$CategoryModelFromJson(Map<String, dynamic> json) =>
    CategoryModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      name: json['name'] as String,
      sortOrder: (json['sort_order'] as num).toInt(),
      lastUsedAt: json['last_used_at'] as String,
      createdAt: json['created_at'] as String,
      color: json['color'] as String?,
    );

Map<String, dynamic> _$CategoryModelToJson(CategoryModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'name': instance.name,
      'sort_order': instance.sortOrder,
      'last_used_at': instance.lastUsedAt,
      'created_at': instance.createdAt,
      'color': instance.color,
    };
