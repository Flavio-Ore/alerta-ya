// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'incident_entity.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$IncidentEntity {
  String get id => throw _privateConstructorUsedError;
  IncidentType get type => throw _privateConstructorUsedError;
  Severity get severity => throw _privateConstructorUsedError;
  IncidentStatus get status => throw _privateConstructorUsedError;
  double get lat => throw _privateConstructorUsedError;
  double get lng => throw _privateConstructorUsedError;
  String get district => throw _privateConstructorUsedError;
  int get confirmCount => throw _privateConstructorUsedError;
  int get denyCount => throw _privateConstructorUsedError;
  int get reportCount => throw _privateConstructorUsedError;
  DateTime get expiresAt => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;
  DateTime get updatedAt => throw _privateConstructorUsedError;
  String? get unitAssigned => throw _privateConstructorUsedError;
  String? get feedback => throw _privateConstructorUsedError;
  double? get aiScore => throw _privateConstructorUsedError;
  bool? get aiVerified => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $IncidentEntityCopyWith<IncidentEntity> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $IncidentEntityCopyWith<$Res> {
  factory $IncidentEntityCopyWith(
          IncidentEntity value, $Res Function(IncidentEntity) then) =
      _$IncidentEntityCopyWithImpl<$Res, IncidentEntity>;
  @useResult
  $Res call(
      {String id,
      IncidentType type,
      Severity severity,
      IncidentStatus status,
      double lat,
      double lng,
      String district,
      int confirmCount,
      int denyCount,
      int reportCount,
      DateTime expiresAt,
      DateTime createdAt,
      DateTime updatedAt,
      String? unitAssigned,
      String? feedback,
      double? aiScore,
      bool? aiVerified});
}

/// @nodoc
class _$IncidentEntityCopyWithImpl<$Res, $Val extends IncidentEntity>
    implements $IncidentEntityCopyWith<$Res> {
  _$IncidentEntityCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? type = null,
    Object? severity = null,
    Object? status = null,
    Object? lat = null,
    Object? lng = null,
    Object? district = null,
    Object? confirmCount = null,
    Object? denyCount = null,
    Object? reportCount = null,
    Object? expiresAt = null,
    Object? createdAt = null,
    Object? updatedAt = null,
    Object? unitAssigned = freezed,
    Object? feedback = freezed,
    Object? aiScore = freezed,
    Object? aiVerified = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as IncidentType,
      severity: null == severity
          ? _value.severity
          : severity // ignore: cast_nullable_to_non_nullable
              as Severity,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as IncidentStatus,
      lat: null == lat
          ? _value.lat
          : lat // ignore: cast_nullable_to_non_nullable
              as double,
      lng: null == lng
          ? _value.lng
          : lng // ignore: cast_nullable_to_non_nullable
              as double,
      district: null == district
          ? _value.district
          : district // ignore: cast_nullable_to_non_nullable
              as String,
      confirmCount: null == confirmCount
          ? _value.confirmCount
          : confirmCount // ignore: cast_nullable_to_non_nullable
              as int,
      denyCount: null == denyCount
          ? _value.denyCount
          : denyCount // ignore: cast_nullable_to_non_nullable
              as int,
      reportCount: null == reportCount
          ? _value.reportCount
          : reportCount // ignore: cast_nullable_to_non_nullable
              as int,
      expiresAt: null == expiresAt
          ? _value.expiresAt
          : expiresAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updatedAt: null == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      unitAssigned: freezed == unitAssigned
          ? _value.unitAssigned
          : unitAssigned // ignore: cast_nullable_to_non_nullable
              as String?,
      feedback: freezed == feedback
          ? _value.feedback
          : feedback // ignore: cast_nullable_to_non_nullable
              as String?,
      aiScore: freezed == aiScore
          ? _value.aiScore
          : aiScore // ignore: cast_nullable_to_non_nullable
              as double?,
      aiVerified: freezed == aiVerified
          ? _value.aiVerified
          : aiVerified // ignore: cast_nullable_to_non_nullable
              as bool?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$IncidentEntityImplCopyWith<$Res>
    implements $IncidentEntityCopyWith<$Res> {
  factory _$$IncidentEntityImplCopyWith(_$IncidentEntityImpl value,
          $Res Function(_$IncidentEntityImpl) then) =
      __$$IncidentEntityImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      IncidentType type,
      Severity severity,
      IncidentStatus status,
      double lat,
      double lng,
      String district,
      int confirmCount,
      int denyCount,
      int reportCount,
      DateTime expiresAt,
      DateTime createdAt,
      DateTime updatedAt,
      String? unitAssigned,
      String? feedback,
      double? aiScore,
      bool? aiVerified});
}

/// @nodoc
class __$$IncidentEntityImplCopyWithImpl<$Res>
    extends _$IncidentEntityCopyWithImpl<$Res, _$IncidentEntityImpl>
    implements _$$IncidentEntityImplCopyWith<$Res> {
  __$$IncidentEntityImplCopyWithImpl(
      _$IncidentEntityImpl _value, $Res Function(_$IncidentEntityImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? type = null,
    Object? severity = null,
    Object? status = null,
    Object? lat = null,
    Object? lng = null,
    Object? district = null,
    Object? confirmCount = null,
    Object? denyCount = null,
    Object? reportCount = null,
    Object? expiresAt = null,
    Object? createdAt = null,
    Object? updatedAt = null,
    Object? unitAssigned = freezed,
    Object? feedback = freezed,
    Object? aiScore = freezed,
    Object? aiVerified = freezed,
  }) {
    return _then(_$IncidentEntityImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as IncidentType,
      severity: null == severity
          ? _value.severity
          : severity // ignore: cast_nullable_to_non_nullable
              as Severity,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as IncidentStatus,
      lat: null == lat
          ? _value.lat
          : lat // ignore: cast_nullable_to_non_nullable
              as double,
      lng: null == lng
          ? _value.lng
          : lng // ignore: cast_nullable_to_non_nullable
              as double,
      district: null == district
          ? _value.district
          : district // ignore: cast_nullable_to_non_nullable
              as String,
      confirmCount: null == confirmCount
          ? _value.confirmCount
          : confirmCount // ignore: cast_nullable_to_non_nullable
              as int,
      denyCount: null == denyCount
          ? _value.denyCount
          : denyCount // ignore: cast_nullable_to_non_nullable
              as int,
      reportCount: null == reportCount
          ? _value.reportCount
          : reportCount // ignore: cast_nullable_to_non_nullable
              as int,
      expiresAt: null == expiresAt
          ? _value.expiresAt
          : expiresAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updatedAt: null == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      unitAssigned: freezed == unitAssigned
          ? _value.unitAssigned
          : unitAssigned // ignore: cast_nullable_to_non_nullable
              as String?,
      feedback: freezed == feedback
          ? _value.feedback
          : feedback // ignore: cast_nullable_to_non_nullable
              as String?,
      aiScore: freezed == aiScore
          ? _value.aiScore
          : aiScore // ignore: cast_nullable_to_non_nullable
              as double?,
      aiVerified: freezed == aiVerified
          ? _value.aiVerified
          : aiVerified // ignore: cast_nullable_to_non_nullable
              as bool?,
    ));
  }
}

/// @nodoc

class _$IncidentEntityImpl implements _IncidentEntity {
  const _$IncidentEntityImpl(
      {required this.id,
      required this.type,
      required this.severity,
      required this.status,
      required this.lat,
      required this.lng,
      required this.district,
      required this.confirmCount,
      required this.denyCount,
      required this.reportCount,
      required this.expiresAt,
      required this.createdAt,
      required this.updatedAt,
      this.unitAssigned,
      this.feedback,
      this.aiScore,
      this.aiVerified});

  @override
  final String id;
  @override
  final IncidentType type;
  @override
  final Severity severity;
  @override
  final IncidentStatus status;
  @override
  final double lat;
  @override
  final double lng;
  @override
  final String district;
  @override
  final int confirmCount;
  @override
  final int denyCount;
  @override
  final int reportCount;
  @override
  final DateTime expiresAt;
  @override
  final DateTime createdAt;
  @override
  final DateTime updatedAt;
  @override
  final String? unitAssigned;
  @override
  final String? feedback;
  @override
  final double? aiScore;
  @override
  final bool? aiVerified;

  @override
  String toString() {
    return 'IncidentEntity(id: $id, type: $type, severity: $severity, status: $status, lat: $lat, lng: $lng, district: $district, confirmCount: $confirmCount, denyCount: $denyCount, reportCount: $reportCount, expiresAt: $expiresAt, createdAt: $createdAt, updatedAt: $updatedAt, unitAssigned: $unitAssigned, feedback: $feedback, aiScore: $aiScore, aiVerified: $aiVerified)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$IncidentEntityImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.severity, severity) ||
                other.severity == severity) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.lat, lat) || other.lat == lat) &&
            (identical(other.lng, lng) || other.lng == lng) &&
            (identical(other.district, district) ||
                other.district == district) &&
            (identical(other.confirmCount, confirmCount) ||
                other.confirmCount == confirmCount) &&
            (identical(other.denyCount, denyCount) ||
                other.denyCount == denyCount) &&
            (identical(other.reportCount, reportCount) ||
                other.reportCount == reportCount) &&
            (identical(other.expiresAt, expiresAt) ||
                other.expiresAt == expiresAt) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt) &&
            (identical(other.unitAssigned, unitAssigned) ||
                other.unitAssigned == unitAssigned) &&
            (identical(other.feedback, feedback) ||
                other.feedback == feedback) &&
            (identical(other.aiScore, aiScore) || other.aiScore == aiScore) &&
            (identical(other.aiVerified, aiVerified) ||
                other.aiVerified == aiVerified));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      type,
      severity,
      status,
      lat,
      lng,
      district,
      confirmCount,
      denyCount,
      reportCount,
      expiresAt,
      createdAt,
      updatedAt,
      unitAssigned,
      feedback,
      aiScore,
      aiVerified);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$IncidentEntityImplCopyWith<_$IncidentEntityImpl> get copyWith =>
      __$$IncidentEntityImplCopyWithImpl<_$IncidentEntityImpl>(
          this, _$identity);
}

abstract class _IncidentEntity implements IncidentEntity {
  const factory _IncidentEntity(
      {required final String id,
      required final IncidentType type,
      required final Severity severity,
      required final IncidentStatus status,
      required final double lat,
      required final double lng,
      required final String district,
      required final int confirmCount,
      required final int denyCount,
      required final int reportCount,
      required final DateTime expiresAt,
      required final DateTime createdAt,
      required final DateTime updatedAt,
      final String? unitAssigned,
      final String? feedback,
      final double? aiScore,
      final bool? aiVerified}) = _$IncidentEntityImpl;

  @override
  String get id;
  @override
  IncidentType get type;
  @override
  Severity get severity;
  @override
  IncidentStatus get status;
  @override
  double get lat;
  @override
  double get lng;
  @override
  String get district;
  @override
  int get confirmCount;
  @override
  int get denyCount;
  @override
  int get reportCount;
  @override
  DateTime get expiresAt;
  @override
  DateTime get createdAt;
  @override
  DateTime get updatedAt;
  @override
  String? get unitAssigned;
  @override
  String? get feedback;
  @override
  double? get aiScore;
  @override
  bool? get aiVerified;
  @override
  @JsonKey(ignore: true)
  _$$IncidentEntityImplCopyWith<_$IncidentEntityImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$IncidentDetailEntity {
  String get id => throw _privateConstructorUsedError;
  IncidentType get type => throw _privateConstructorUsedError;
  Severity get severity => throw _privateConstructorUsedError;
  IncidentStatus get status => throw _privateConstructorUsedError;
  double get lat => throw _privateConstructorUsedError;
  double get lng => throw _privateConstructorUsedError;
  String get district => throw _privateConstructorUsedError;
  int get confirmCount => throw _privateConstructorUsedError;
  int get denyCount => throw _privateConstructorUsedError;
  int get reportCount => throw _privateConstructorUsedError;
  DateTime get expiresAt => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;
  DateTime get updatedAt => throw _privateConstructorUsedError;
  String? get unitAssigned => throw _privateConstructorUsedError;
  String? get feedback => throw _privateConstructorUsedError;
  double? get aiScore => throw _privateConstructorUsedError;
  bool? get aiVerified => throw _privateConstructorUsedError;
  int get weaponReports => throw _privateConstructorUsedError;
  int get injuredReports => throw _privateConstructorUsedError;
  int get stillHereReports => throw _privateConstructorUsedError;
  String? get reporterTrust => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $IncidentDetailEntityCopyWith<IncidentDetailEntity> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $IncidentDetailEntityCopyWith<$Res> {
  factory $IncidentDetailEntityCopyWith(IncidentDetailEntity value,
          $Res Function(IncidentDetailEntity) then) =
      _$IncidentDetailEntityCopyWithImpl<$Res, IncidentDetailEntity>;
  @useResult
  $Res call(
      {String id,
      IncidentType type,
      Severity severity,
      IncidentStatus status,
      double lat,
      double lng,
      String district,
      int confirmCount,
      int denyCount,
      int reportCount,
      DateTime expiresAt,
      DateTime createdAt,
      DateTime updatedAt,
      String? unitAssigned,
      String? feedback,
      double? aiScore,
      bool? aiVerified,
      int weaponReports,
      int injuredReports,
      int stillHereReports,
      String? reporterTrust});
}

/// @nodoc
class _$IncidentDetailEntityCopyWithImpl<$Res,
        $Val extends IncidentDetailEntity>
    implements $IncidentDetailEntityCopyWith<$Res> {
  _$IncidentDetailEntityCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? type = null,
    Object? severity = null,
    Object? status = null,
    Object? lat = null,
    Object? lng = null,
    Object? district = null,
    Object? confirmCount = null,
    Object? denyCount = null,
    Object? reportCount = null,
    Object? expiresAt = null,
    Object? createdAt = null,
    Object? updatedAt = null,
    Object? unitAssigned = freezed,
    Object? feedback = freezed,
    Object? aiScore = freezed,
    Object? aiVerified = freezed,
    Object? weaponReports = null,
    Object? injuredReports = null,
    Object? stillHereReports = null,
    Object? reporterTrust = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as IncidentType,
      severity: null == severity
          ? _value.severity
          : severity // ignore: cast_nullable_to_non_nullable
              as Severity,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as IncidentStatus,
      lat: null == lat
          ? _value.lat
          : lat // ignore: cast_nullable_to_non_nullable
              as double,
      lng: null == lng
          ? _value.lng
          : lng // ignore: cast_nullable_to_non_nullable
              as double,
      district: null == district
          ? _value.district
          : district // ignore: cast_nullable_to_non_nullable
              as String,
      confirmCount: null == confirmCount
          ? _value.confirmCount
          : confirmCount // ignore: cast_nullable_to_non_nullable
              as int,
      denyCount: null == denyCount
          ? _value.denyCount
          : denyCount // ignore: cast_nullable_to_non_nullable
              as int,
      reportCount: null == reportCount
          ? _value.reportCount
          : reportCount // ignore: cast_nullable_to_non_nullable
              as int,
      expiresAt: null == expiresAt
          ? _value.expiresAt
          : expiresAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updatedAt: null == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      unitAssigned: freezed == unitAssigned
          ? _value.unitAssigned
          : unitAssigned // ignore: cast_nullable_to_non_nullable
              as String?,
      feedback: freezed == feedback
          ? _value.feedback
          : feedback // ignore: cast_nullable_to_non_nullable
              as String?,
      aiScore: freezed == aiScore
          ? _value.aiScore
          : aiScore // ignore: cast_nullable_to_non_nullable
              as double?,
      aiVerified: freezed == aiVerified
          ? _value.aiVerified
          : aiVerified // ignore: cast_nullable_to_non_nullable
              as bool?,
      weaponReports: null == weaponReports
          ? _value.weaponReports
          : weaponReports // ignore: cast_nullable_to_non_nullable
              as int,
      injuredReports: null == injuredReports
          ? _value.injuredReports
          : injuredReports // ignore: cast_nullable_to_non_nullable
              as int,
      stillHereReports: null == stillHereReports
          ? _value.stillHereReports
          : stillHereReports // ignore: cast_nullable_to_non_nullable
              as int,
      reporterTrust: freezed == reporterTrust
          ? _value.reporterTrust
          : reporterTrust // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$IncidentDetailEntityImplCopyWith<$Res>
    implements $IncidentDetailEntityCopyWith<$Res> {
  factory _$$IncidentDetailEntityImplCopyWith(_$IncidentDetailEntityImpl value,
          $Res Function(_$IncidentDetailEntityImpl) then) =
      __$$IncidentDetailEntityImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      IncidentType type,
      Severity severity,
      IncidentStatus status,
      double lat,
      double lng,
      String district,
      int confirmCount,
      int denyCount,
      int reportCount,
      DateTime expiresAt,
      DateTime createdAt,
      DateTime updatedAt,
      String? unitAssigned,
      String? feedback,
      double? aiScore,
      bool? aiVerified,
      int weaponReports,
      int injuredReports,
      int stillHereReports,
      String? reporterTrust});
}

/// @nodoc
class __$$IncidentDetailEntityImplCopyWithImpl<$Res>
    extends _$IncidentDetailEntityCopyWithImpl<$Res, _$IncidentDetailEntityImpl>
    implements _$$IncidentDetailEntityImplCopyWith<$Res> {
  __$$IncidentDetailEntityImplCopyWithImpl(_$IncidentDetailEntityImpl _value,
      $Res Function(_$IncidentDetailEntityImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? type = null,
    Object? severity = null,
    Object? status = null,
    Object? lat = null,
    Object? lng = null,
    Object? district = null,
    Object? confirmCount = null,
    Object? denyCount = null,
    Object? reportCount = null,
    Object? expiresAt = null,
    Object? createdAt = null,
    Object? updatedAt = null,
    Object? unitAssigned = freezed,
    Object? feedback = freezed,
    Object? aiScore = freezed,
    Object? aiVerified = freezed,
    Object? weaponReports = null,
    Object? injuredReports = null,
    Object? stillHereReports = null,
    Object? reporterTrust = freezed,
  }) {
    return _then(_$IncidentDetailEntityImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as IncidentType,
      severity: null == severity
          ? _value.severity
          : severity // ignore: cast_nullable_to_non_nullable
              as Severity,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as IncidentStatus,
      lat: null == lat
          ? _value.lat
          : lat // ignore: cast_nullable_to_non_nullable
              as double,
      lng: null == lng
          ? _value.lng
          : lng // ignore: cast_nullable_to_non_nullable
              as double,
      district: null == district
          ? _value.district
          : district // ignore: cast_nullable_to_non_nullable
              as String,
      confirmCount: null == confirmCount
          ? _value.confirmCount
          : confirmCount // ignore: cast_nullable_to_non_nullable
              as int,
      denyCount: null == denyCount
          ? _value.denyCount
          : denyCount // ignore: cast_nullable_to_non_nullable
              as int,
      reportCount: null == reportCount
          ? _value.reportCount
          : reportCount // ignore: cast_nullable_to_non_nullable
              as int,
      expiresAt: null == expiresAt
          ? _value.expiresAt
          : expiresAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updatedAt: null == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      unitAssigned: freezed == unitAssigned
          ? _value.unitAssigned
          : unitAssigned // ignore: cast_nullable_to_non_nullable
              as String?,
      feedback: freezed == feedback
          ? _value.feedback
          : feedback // ignore: cast_nullable_to_non_nullable
              as String?,
      aiScore: freezed == aiScore
          ? _value.aiScore
          : aiScore // ignore: cast_nullable_to_non_nullable
              as double?,
      aiVerified: freezed == aiVerified
          ? _value.aiVerified
          : aiVerified // ignore: cast_nullable_to_non_nullable
              as bool?,
      weaponReports: null == weaponReports
          ? _value.weaponReports
          : weaponReports // ignore: cast_nullable_to_non_nullable
              as int,
      injuredReports: null == injuredReports
          ? _value.injuredReports
          : injuredReports // ignore: cast_nullable_to_non_nullable
              as int,
      stillHereReports: null == stillHereReports
          ? _value.stillHereReports
          : stillHereReports // ignore: cast_nullable_to_non_nullable
              as int,
      reporterTrust: freezed == reporterTrust
          ? _value.reporterTrust
          : reporterTrust // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc

class _$IncidentDetailEntityImpl implements _IncidentDetailEntity {
  const _$IncidentDetailEntityImpl(
      {required this.id,
      required this.type,
      required this.severity,
      required this.status,
      required this.lat,
      required this.lng,
      required this.district,
      required this.confirmCount,
      required this.denyCount,
      required this.reportCount,
      required this.expiresAt,
      required this.createdAt,
      required this.updatedAt,
      this.unitAssigned,
      this.feedback,
      this.aiScore,
      this.aiVerified,
      this.weaponReports = 0,
      this.injuredReports = 0,
      this.stillHereReports = 0,
      this.reporterTrust});

  @override
  final String id;
  @override
  final IncidentType type;
  @override
  final Severity severity;
  @override
  final IncidentStatus status;
  @override
  final double lat;
  @override
  final double lng;
  @override
  final String district;
  @override
  final int confirmCount;
  @override
  final int denyCount;
  @override
  final int reportCount;
  @override
  final DateTime expiresAt;
  @override
  final DateTime createdAt;
  @override
  final DateTime updatedAt;
  @override
  final String? unitAssigned;
  @override
  final String? feedback;
  @override
  final double? aiScore;
  @override
  final bool? aiVerified;
  @override
  @JsonKey()
  final int weaponReports;
  @override
  @JsonKey()
  final int injuredReports;
  @override
  @JsonKey()
  final int stillHereReports;
  @override
  final String? reporterTrust;

  @override
  String toString() {
    return 'IncidentDetailEntity(id: $id, type: $type, severity: $severity, status: $status, lat: $lat, lng: $lng, district: $district, confirmCount: $confirmCount, denyCount: $denyCount, reportCount: $reportCount, expiresAt: $expiresAt, createdAt: $createdAt, updatedAt: $updatedAt, unitAssigned: $unitAssigned, feedback: $feedback, aiScore: $aiScore, aiVerified: $aiVerified, weaponReports: $weaponReports, injuredReports: $injuredReports, stillHereReports: $stillHereReports, reporterTrust: $reporterTrust)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$IncidentDetailEntityImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.severity, severity) ||
                other.severity == severity) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.lat, lat) || other.lat == lat) &&
            (identical(other.lng, lng) || other.lng == lng) &&
            (identical(other.district, district) ||
                other.district == district) &&
            (identical(other.confirmCount, confirmCount) ||
                other.confirmCount == confirmCount) &&
            (identical(other.denyCount, denyCount) ||
                other.denyCount == denyCount) &&
            (identical(other.reportCount, reportCount) ||
                other.reportCount == reportCount) &&
            (identical(other.expiresAt, expiresAt) ||
                other.expiresAt == expiresAt) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt) &&
            (identical(other.unitAssigned, unitAssigned) ||
                other.unitAssigned == unitAssigned) &&
            (identical(other.feedback, feedback) ||
                other.feedback == feedback) &&
            (identical(other.aiScore, aiScore) || other.aiScore == aiScore) &&
            (identical(other.aiVerified, aiVerified) ||
                other.aiVerified == aiVerified) &&
            (identical(other.weaponReports, weaponReports) ||
                other.weaponReports == weaponReports) &&
            (identical(other.injuredReports, injuredReports) ||
                other.injuredReports == injuredReports) &&
            (identical(other.stillHereReports, stillHereReports) ||
                other.stillHereReports == stillHereReports) &&
            (identical(other.reporterTrust, reporterTrust) ||
                other.reporterTrust == reporterTrust));
  }

  @override
  int get hashCode => Object.hashAll([
        runtimeType,
        id,
        type,
        severity,
        status,
        lat,
        lng,
        district,
        confirmCount,
        denyCount,
        reportCount,
        expiresAt,
        createdAt,
        updatedAt,
        unitAssigned,
        feedback,
        aiScore,
        aiVerified,
        weaponReports,
        injuredReports,
        stillHereReports,
        reporterTrust
      ]);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$IncidentDetailEntityImplCopyWith<_$IncidentDetailEntityImpl>
      get copyWith =>
          __$$IncidentDetailEntityImplCopyWithImpl<_$IncidentDetailEntityImpl>(
              this, _$identity);
}

abstract class _IncidentDetailEntity implements IncidentDetailEntity {
  const factory _IncidentDetailEntity(
      {required final String id,
      required final IncidentType type,
      required final Severity severity,
      required final IncidentStatus status,
      required final double lat,
      required final double lng,
      required final String district,
      required final int confirmCount,
      required final int denyCount,
      required final int reportCount,
      required final DateTime expiresAt,
      required final DateTime createdAt,
      required final DateTime updatedAt,
      final String? unitAssigned,
      final String? feedback,
      final double? aiScore,
      final bool? aiVerified,
      final int weaponReports,
      final int injuredReports,
      final int stillHereReports,
      final String? reporterTrust}) = _$IncidentDetailEntityImpl;

  @override
  String get id;
  @override
  IncidentType get type;
  @override
  Severity get severity;
  @override
  IncidentStatus get status;
  @override
  double get lat;
  @override
  double get lng;
  @override
  String get district;
  @override
  int get confirmCount;
  @override
  int get denyCount;
  @override
  int get reportCount;
  @override
  DateTime get expiresAt;
  @override
  DateTime get createdAt;
  @override
  DateTime get updatedAt;
  @override
  String? get unitAssigned;
  @override
  String? get feedback;
  @override
  double? get aiScore;
  @override
  bool? get aiVerified;
  @override
  int get weaponReports;
  @override
  int get injuredReports;
  @override
  int get stillHereReports;
  @override
  String? get reporterTrust;
  @override
  @JsonKey(ignore: true)
  _$$IncidentDetailEntityImplCopyWith<_$IncidentDetailEntityImpl>
      get copyWith => throw _privateConstructorUsedError;
}
