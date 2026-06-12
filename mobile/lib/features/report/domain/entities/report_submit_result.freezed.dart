// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'report_submit_result.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$ReportSubmitResult {
  bool get isPublished => throw _privateConstructorUsedError;
  IncidentEntity? get incident => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $ReportSubmitResultCopyWith<ReportSubmitResult> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ReportSubmitResultCopyWith<$Res> {
  factory $ReportSubmitResultCopyWith(
          ReportSubmitResult value, $Res Function(ReportSubmitResult) then) =
      _$ReportSubmitResultCopyWithImpl<$Res, ReportSubmitResult>;
  @useResult
  $Res call({bool isPublished, IncidentEntity? incident});

  $IncidentEntityCopyWith<$Res>? get incident;
}

/// @nodoc
class _$ReportSubmitResultCopyWithImpl<$Res, $Val extends ReportSubmitResult>
    implements $ReportSubmitResultCopyWith<$Res> {
  _$ReportSubmitResultCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? isPublished = null,
    Object? incident = freezed,
  }) {
    return _then(_value.copyWith(
      isPublished: null == isPublished
          ? _value.isPublished
          : isPublished // ignore: cast_nullable_to_non_nullable
              as bool,
      incident: freezed == incident
          ? _value.incident
          : incident // ignore: cast_nullable_to_non_nullable
              as IncidentEntity?,
    ) as $Val);
  }

  @override
  @pragma('vm:prefer-inline')
  $IncidentEntityCopyWith<$Res>? get incident {
    if (_value.incident == null) {
      return null;
    }

    return $IncidentEntityCopyWith<$Res>(_value.incident!, (value) {
      return _then(_value.copyWith(incident: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$ReportSubmitResultImplCopyWith<$Res>
    implements $ReportSubmitResultCopyWith<$Res> {
  factory _$$ReportSubmitResultImplCopyWith(_$ReportSubmitResultImpl value,
          $Res Function(_$ReportSubmitResultImpl) then) =
      __$$ReportSubmitResultImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({bool isPublished, IncidentEntity? incident});

  @override
  $IncidentEntityCopyWith<$Res>? get incident;
}

/// @nodoc
class __$$ReportSubmitResultImplCopyWithImpl<$Res>
    extends _$ReportSubmitResultCopyWithImpl<$Res, _$ReportSubmitResultImpl>
    implements _$$ReportSubmitResultImplCopyWith<$Res> {
  __$$ReportSubmitResultImplCopyWithImpl(_$ReportSubmitResultImpl _value,
      $Res Function(_$ReportSubmitResultImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? isPublished = null,
    Object? incident = freezed,
  }) {
    return _then(_$ReportSubmitResultImpl(
      isPublished: null == isPublished
          ? _value.isPublished
          : isPublished // ignore: cast_nullable_to_non_nullable
              as bool,
      incident: freezed == incident
          ? _value.incident
          : incident // ignore: cast_nullable_to_non_nullable
              as IncidentEntity?,
    ));
  }
}

/// @nodoc

class _$ReportSubmitResultImpl implements _ReportSubmitResult {
  const _$ReportSubmitResultImpl({required this.isPublished, this.incident});

  @override
  final bool isPublished;
  @override
  final IncidentEntity? incident;

  @override
  String toString() {
    return 'ReportSubmitResult(isPublished: $isPublished, incident: $incident)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ReportSubmitResultImpl &&
            (identical(other.isPublished, isPublished) ||
                other.isPublished == isPublished) &&
            (identical(other.incident, incident) ||
                other.incident == incident));
  }

  @override
  int get hashCode => Object.hash(runtimeType, isPublished, incident);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$ReportSubmitResultImplCopyWith<_$ReportSubmitResultImpl> get copyWith =>
      __$$ReportSubmitResultImplCopyWithImpl<_$ReportSubmitResultImpl>(
          this, _$identity);
}

abstract class _ReportSubmitResult implements ReportSubmitResult {
  const factory _ReportSubmitResult(
      {required final bool isPublished,
      final IncidentEntity? incident}) = _$ReportSubmitResultImpl;

  @override
  bool get isPublished;
  @override
  IncidentEntity? get incident;
  @override
  @JsonKey(ignore: true)
  _$$ReportSubmitResultImplCopyWith<_$ReportSubmitResultImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
