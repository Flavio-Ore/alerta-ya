// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'panic_session_entity.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$PanicSessionEntity {
  String get id => throw _privateConstructorUsedError;
  double get lat => throw _privateConstructorUsedError;
  double get lng => throw _privateConstructorUsedError;
  DateTime get startedAt => throw _privateConstructorUsedError;
  DateTime? get endedAt => throw _privateConstructorUsedError;
  String get status => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $PanicSessionEntityCopyWith<PanicSessionEntity> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PanicSessionEntityCopyWith<$Res> {
  factory $PanicSessionEntityCopyWith(
          PanicSessionEntity value, $Res Function(PanicSessionEntity) then) =
      _$PanicSessionEntityCopyWithImpl<$Res, PanicSessionEntity>;
  @useResult
  $Res call(
      {String id,
      double lat,
      double lng,
      DateTime startedAt,
      DateTime? endedAt,
      String status});
}

/// @nodoc
class _$PanicSessionEntityCopyWithImpl<$Res, $Val extends PanicSessionEntity>
    implements $PanicSessionEntityCopyWith<$Res> {
  _$PanicSessionEntityCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? lat = null,
    Object? lng = null,
    Object? startedAt = null,
    Object? endedAt = freezed,
    Object? status = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      lat: null == lat
          ? _value.lat
          : lat // ignore: cast_nullable_to_non_nullable
              as double,
      lng: null == lng
          ? _value.lng
          : lng // ignore: cast_nullable_to_non_nullable
              as double,
      startedAt: null == startedAt
          ? _value.startedAt
          : startedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      endedAt: freezed == endedAt
          ? _value.endedAt
          : endedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$PanicSessionEntityImplCopyWith<$Res>
    implements $PanicSessionEntityCopyWith<$Res> {
  factory _$$PanicSessionEntityImplCopyWith(_$PanicSessionEntityImpl value,
          $Res Function(_$PanicSessionEntityImpl) then) =
      __$$PanicSessionEntityImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      double lat,
      double lng,
      DateTime startedAt,
      DateTime? endedAt,
      String status});
}

/// @nodoc
class __$$PanicSessionEntityImplCopyWithImpl<$Res>
    extends _$PanicSessionEntityCopyWithImpl<$Res, _$PanicSessionEntityImpl>
    implements _$$PanicSessionEntityImplCopyWith<$Res> {
  __$$PanicSessionEntityImplCopyWithImpl(_$PanicSessionEntityImpl _value,
      $Res Function(_$PanicSessionEntityImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? lat = null,
    Object? lng = null,
    Object? startedAt = null,
    Object? endedAt = freezed,
    Object? status = null,
  }) {
    return _then(_$PanicSessionEntityImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      lat: null == lat
          ? _value.lat
          : lat // ignore: cast_nullable_to_non_nullable
              as double,
      lng: null == lng
          ? _value.lng
          : lng // ignore: cast_nullable_to_non_nullable
              as double,
      startedAt: null == startedAt
          ? _value.startedAt
          : startedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      endedAt: freezed == endedAt
          ? _value.endedAt
          : endedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class _$PanicSessionEntityImpl implements _PanicSessionEntity {
  const _$PanicSessionEntityImpl(
      {required this.id,
      required this.lat,
      required this.lng,
      required this.startedAt,
      this.endedAt,
      this.status = 'ACTIVE'});

  @override
  final String id;
  @override
  final double lat;
  @override
  final double lng;
  @override
  final DateTime startedAt;
  @override
  final DateTime? endedAt;
  @override
  @JsonKey()
  final String status;

  @override
  String toString() {
    return 'PanicSessionEntity(id: $id, lat: $lat, lng: $lng, startedAt: $startedAt, endedAt: $endedAt, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PanicSessionEntityImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.lat, lat) || other.lat == lat) &&
            (identical(other.lng, lng) || other.lng == lng) &&
            (identical(other.startedAt, startedAt) ||
                other.startedAt == startedAt) &&
            (identical(other.endedAt, endedAt) || other.endedAt == endedAt) &&
            (identical(other.status, status) || other.status == status));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, id, lat, lng, startedAt, endedAt, status);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$PanicSessionEntityImplCopyWith<_$PanicSessionEntityImpl> get copyWith =>
      __$$PanicSessionEntityImplCopyWithImpl<_$PanicSessionEntityImpl>(
          this, _$identity);
}

abstract class _PanicSessionEntity implements PanicSessionEntity {
  const factory _PanicSessionEntity(
      {required final String id,
      required final double lat,
      required final double lng,
      required final DateTime startedAt,
      final DateTime? endedAt,
      final String status}) = _$PanicSessionEntityImpl;

  @override
  String get id;
  @override
  double get lat;
  @override
  double get lng;
  @override
  DateTime get startedAt;
  @override
  DateTime? get endedAt;
  @override
  String get status;
  @override
  @JsonKey(ignore: true)
  _$$PanicSessionEntityImplCopyWith<_$PanicSessionEntityImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
