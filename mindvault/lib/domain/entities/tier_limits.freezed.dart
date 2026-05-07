// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'tier_limits.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$TierLimits {
  String get tier => throw _privateConstructorUsedError;
  int get maxNotes => throw _privateConstructorUsedError;
  int get maxCategories => throw _privateConstructorUsedError;
  int get maxCharsPerNote => throw _privateConstructorUsedError;
  int get aiSearchesPerDay => throw _privateConstructorUsedError;

  /// Create a copy of TierLimits
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $TierLimitsCopyWith<TierLimits> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TierLimitsCopyWith<$Res> {
  factory $TierLimitsCopyWith(
          TierLimits value, $Res Function(TierLimits) then) =
      _$TierLimitsCopyWithImpl<$Res, TierLimits>;
  @useResult
  $Res call(
      {String tier,
      int maxNotes,
      int maxCategories,
      int maxCharsPerNote,
      int aiSearchesPerDay});
}

/// @nodoc
class _$TierLimitsCopyWithImpl<$Res, $Val extends TierLimits>
    implements $TierLimitsCopyWith<$Res> {
  _$TierLimitsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of TierLimits
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? tier = null,
    Object? maxNotes = null,
    Object? maxCategories = null,
    Object? maxCharsPerNote = null,
    Object? aiSearchesPerDay = null,
  }) {
    return _then(_value.copyWith(
      tier: null == tier
          ? _value.tier
          : tier // ignore: cast_nullable_to_non_nullable
              as String,
      maxNotes: null == maxNotes
          ? _value.maxNotes
          : maxNotes // ignore: cast_nullable_to_non_nullable
              as int,
      maxCategories: null == maxCategories
          ? _value.maxCategories
          : maxCategories // ignore: cast_nullable_to_non_nullable
              as int,
      maxCharsPerNote: null == maxCharsPerNote
          ? _value.maxCharsPerNote
          : maxCharsPerNote // ignore: cast_nullable_to_non_nullable
              as int,
      aiSearchesPerDay: null == aiSearchesPerDay
          ? _value.aiSearchesPerDay
          : aiSearchesPerDay // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$TierLimitsImplCopyWith<$Res>
    implements $TierLimitsCopyWith<$Res> {
  factory _$$TierLimitsImplCopyWith(
          _$TierLimitsImpl value, $Res Function(_$TierLimitsImpl) then) =
      __$$TierLimitsImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String tier,
      int maxNotes,
      int maxCategories,
      int maxCharsPerNote,
      int aiSearchesPerDay});
}

/// @nodoc
class __$$TierLimitsImplCopyWithImpl<$Res>
    extends _$TierLimitsCopyWithImpl<$Res, _$TierLimitsImpl>
    implements _$$TierLimitsImplCopyWith<$Res> {
  __$$TierLimitsImplCopyWithImpl(
      _$TierLimitsImpl _value, $Res Function(_$TierLimitsImpl) _then)
      : super(_value, _then);

  /// Create a copy of TierLimits
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? tier = null,
    Object? maxNotes = null,
    Object? maxCategories = null,
    Object? maxCharsPerNote = null,
    Object? aiSearchesPerDay = null,
  }) {
    return _then(_$TierLimitsImpl(
      tier: null == tier
          ? _value.tier
          : tier // ignore: cast_nullable_to_non_nullable
              as String,
      maxNotes: null == maxNotes
          ? _value.maxNotes
          : maxNotes // ignore: cast_nullable_to_non_nullable
              as int,
      maxCategories: null == maxCategories
          ? _value.maxCategories
          : maxCategories // ignore: cast_nullable_to_non_nullable
              as int,
      maxCharsPerNote: null == maxCharsPerNote
          ? _value.maxCharsPerNote
          : maxCharsPerNote // ignore: cast_nullable_to_non_nullable
              as int,
      aiSearchesPerDay: null == aiSearchesPerDay
          ? _value.aiSearchesPerDay
          : aiSearchesPerDay // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc

class _$TierLimitsImpl implements _TierLimits {
  const _$TierLimitsImpl(
      {required this.tier,
      required this.maxNotes,
      required this.maxCategories,
      required this.maxCharsPerNote,
      required this.aiSearchesPerDay});

  @override
  final String tier;
  @override
  final int maxNotes;
  @override
  final int maxCategories;
  @override
  final int maxCharsPerNote;
  @override
  final int aiSearchesPerDay;

  @override
  String toString() {
    return 'TierLimits(tier: $tier, maxNotes: $maxNotes, maxCategories: $maxCategories, maxCharsPerNote: $maxCharsPerNote, aiSearchesPerDay: $aiSearchesPerDay)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TierLimitsImpl &&
            (identical(other.tier, tier) || other.tier == tier) &&
            (identical(other.maxNotes, maxNotes) ||
                other.maxNotes == maxNotes) &&
            (identical(other.maxCategories, maxCategories) ||
                other.maxCategories == maxCategories) &&
            (identical(other.maxCharsPerNote, maxCharsPerNote) ||
                other.maxCharsPerNote == maxCharsPerNote) &&
            (identical(other.aiSearchesPerDay, aiSearchesPerDay) ||
                other.aiSearchesPerDay == aiSearchesPerDay));
  }

  @override
  int get hashCode => Object.hash(runtimeType, tier, maxNotes, maxCategories,
      maxCharsPerNote, aiSearchesPerDay);

  /// Create a copy of TierLimits
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TierLimitsImplCopyWith<_$TierLimitsImpl> get copyWith =>
      __$$TierLimitsImplCopyWithImpl<_$TierLimitsImpl>(this, _$identity);
}

abstract class _TierLimits implements TierLimits {
  const factory _TierLimits(
      {required final String tier,
      required final int maxNotes,
      required final int maxCategories,
      required final int maxCharsPerNote,
      required final int aiSearchesPerDay}) = _$TierLimitsImpl;

  @override
  String get tier;
  @override
  int get maxNotes;
  @override
  int get maxCategories;
  @override
  int get maxCharsPerNote;
  @override
  int get aiSearchesPerDay;

  /// Create a copy of TierLimits
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TierLimitsImplCopyWith<_$TierLimitsImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
