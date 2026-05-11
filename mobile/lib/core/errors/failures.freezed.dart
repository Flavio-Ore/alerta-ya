// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'failures.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$Failure {
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String? message) network,
    required TResult Function(int statusCode, String? message) server,
    required TResult Function(String? message) rateLimit,
    required TResult Function() unauthorized,
    required TResult Function() forbidden,
    required TResult Function() notFound,
    required TResult Function(String message) validation,
    required TResult Function(String? message) unknown,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String? message)? network,
    TResult? Function(int statusCode, String? message)? server,
    TResult? Function(String? message)? rateLimit,
    TResult? Function()? unauthorized,
    TResult? Function()? forbidden,
    TResult? Function()? notFound,
    TResult? Function(String message)? validation,
    TResult? Function(String? message)? unknown,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String? message)? network,
    TResult Function(int statusCode, String? message)? server,
    TResult Function(String? message)? rateLimit,
    TResult Function()? unauthorized,
    TResult Function()? forbidden,
    TResult Function()? notFound,
    TResult Function(String message)? validation,
    TResult Function(String? message)? unknown,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(NetworkFailure value) network,
    required TResult Function(ServerFailure value) server,
    required TResult Function(RateLimitFailure value) rateLimit,
    required TResult Function(UnauthorizedFailure value) unauthorized,
    required TResult Function(ForbiddenFailure value) forbidden,
    required TResult Function(NotFoundFailure value) notFound,
    required TResult Function(ValidationFailure value) validation,
    required TResult Function(UnknownFailure value) unknown,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(NetworkFailure value)? network,
    TResult? Function(ServerFailure value)? server,
    TResult? Function(RateLimitFailure value)? rateLimit,
    TResult? Function(UnauthorizedFailure value)? unauthorized,
    TResult? Function(ForbiddenFailure value)? forbidden,
    TResult? Function(NotFoundFailure value)? notFound,
    TResult? Function(ValidationFailure value)? validation,
    TResult? Function(UnknownFailure value)? unknown,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(NetworkFailure value)? network,
    TResult Function(ServerFailure value)? server,
    TResult Function(RateLimitFailure value)? rateLimit,
    TResult Function(UnauthorizedFailure value)? unauthorized,
    TResult Function(ForbiddenFailure value)? forbidden,
    TResult Function(NotFoundFailure value)? notFound,
    TResult Function(ValidationFailure value)? validation,
    TResult Function(UnknownFailure value)? unknown,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $FailureCopyWith<$Res> {
  factory $FailureCopyWith(Failure value, $Res Function(Failure) then) =
      _$FailureCopyWithImpl<$Res, Failure>;
}

/// @nodoc
class _$FailureCopyWithImpl<$Res, $Val extends Failure>
    implements $FailureCopyWith<$Res> {
  _$FailureCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;
}

/// @nodoc
abstract class _$$NetworkFailureImplCopyWith<$Res> {
  factory _$$NetworkFailureImplCopyWith(_$NetworkFailureImpl value,
          $Res Function(_$NetworkFailureImpl) then) =
      __$$NetworkFailureImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String? message});
}

/// @nodoc
class __$$NetworkFailureImplCopyWithImpl<$Res>
    extends _$FailureCopyWithImpl<$Res, _$NetworkFailureImpl>
    implements _$$NetworkFailureImplCopyWith<$Res> {
  __$$NetworkFailureImplCopyWithImpl(
      _$NetworkFailureImpl _value, $Res Function(_$NetworkFailureImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? message = freezed,
  }) {
    return _then(_$NetworkFailureImpl(
      message: freezed == message
          ? _value.message
          : message // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc

class _$NetworkFailureImpl implements NetworkFailure {
  const _$NetworkFailureImpl({this.message});

  @override
  final String? message;

  @override
  String toString() {
    return 'Failure.network(message: $message)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$NetworkFailureImpl &&
            (identical(other.message, message) || other.message == message));
  }

  @override
  int get hashCode => Object.hash(runtimeType, message);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$NetworkFailureImplCopyWith<_$NetworkFailureImpl> get copyWith =>
      __$$NetworkFailureImplCopyWithImpl<_$NetworkFailureImpl>(
          this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String? message) network,
    required TResult Function(int statusCode, String? message) server,
    required TResult Function(String? message) rateLimit,
    required TResult Function() unauthorized,
    required TResult Function() forbidden,
    required TResult Function() notFound,
    required TResult Function(String message) validation,
    required TResult Function(String? message) unknown,
  }) {
    return network(message);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String? message)? network,
    TResult? Function(int statusCode, String? message)? server,
    TResult? Function(String? message)? rateLimit,
    TResult? Function()? unauthorized,
    TResult? Function()? forbidden,
    TResult? Function()? notFound,
    TResult? Function(String message)? validation,
    TResult? Function(String? message)? unknown,
  }) {
    return network?.call(message);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String? message)? network,
    TResult Function(int statusCode, String? message)? server,
    TResult Function(String? message)? rateLimit,
    TResult Function()? unauthorized,
    TResult Function()? forbidden,
    TResult Function()? notFound,
    TResult Function(String message)? validation,
    TResult Function(String? message)? unknown,
    required TResult orElse(),
  }) {
    if (network != null) {
      return network(message);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(NetworkFailure value) network,
    required TResult Function(ServerFailure value) server,
    required TResult Function(RateLimitFailure value) rateLimit,
    required TResult Function(UnauthorizedFailure value) unauthorized,
    required TResult Function(ForbiddenFailure value) forbidden,
    required TResult Function(NotFoundFailure value) notFound,
    required TResult Function(ValidationFailure value) validation,
    required TResult Function(UnknownFailure value) unknown,
  }) {
    return network(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(NetworkFailure value)? network,
    TResult? Function(ServerFailure value)? server,
    TResult? Function(RateLimitFailure value)? rateLimit,
    TResult? Function(UnauthorizedFailure value)? unauthorized,
    TResult? Function(ForbiddenFailure value)? forbidden,
    TResult? Function(NotFoundFailure value)? notFound,
    TResult? Function(ValidationFailure value)? validation,
    TResult? Function(UnknownFailure value)? unknown,
  }) {
    return network?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(NetworkFailure value)? network,
    TResult Function(ServerFailure value)? server,
    TResult Function(RateLimitFailure value)? rateLimit,
    TResult Function(UnauthorizedFailure value)? unauthorized,
    TResult Function(ForbiddenFailure value)? forbidden,
    TResult Function(NotFoundFailure value)? notFound,
    TResult Function(ValidationFailure value)? validation,
    TResult Function(UnknownFailure value)? unknown,
    required TResult orElse(),
  }) {
    if (network != null) {
      return network(this);
    }
    return orElse();
  }
}

abstract class NetworkFailure implements Failure {
  const factory NetworkFailure({final String? message}) = _$NetworkFailureImpl;

  String? get message;
  @JsonKey(ignore: true)
  _$$NetworkFailureImplCopyWith<_$NetworkFailureImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$ServerFailureImplCopyWith<$Res> {
  factory _$$ServerFailureImplCopyWith(
          _$ServerFailureImpl value, $Res Function(_$ServerFailureImpl) then) =
      __$$ServerFailureImplCopyWithImpl<$Res>;
  @useResult
  $Res call({int statusCode, String? message});
}

/// @nodoc
class __$$ServerFailureImplCopyWithImpl<$Res>
    extends _$FailureCopyWithImpl<$Res, _$ServerFailureImpl>
    implements _$$ServerFailureImplCopyWith<$Res> {
  __$$ServerFailureImplCopyWithImpl(
      _$ServerFailureImpl _value, $Res Function(_$ServerFailureImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? statusCode = null,
    Object? message = freezed,
  }) {
    return _then(_$ServerFailureImpl(
      statusCode: null == statusCode
          ? _value.statusCode
          : statusCode // ignore: cast_nullable_to_non_nullable
              as int,
      message: freezed == message
          ? _value.message
          : message // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc

class _$ServerFailureImpl implements ServerFailure {
  const _$ServerFailureImpl({required this.statusCode, this.message});

  @override
  final int statusCode;
  @override
  final String? message;

  @override
  String toString() {
    return 'Failure.server(statusCode: $statusCode, message: $message)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ServerFailureImpl &&
            (identical(other.statusCode, statusCode) ||
                other.statusCode == statusCode) &&
            (identical(other.message, message) || other.message == message));
  }

  @override
  int get hashCode => Object.hash(runtimeType, statusCode, message);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$ServerFailureImplCopyWith<_$ServerFailureImpl> get copyWith =>
      __$$ServerFailureImplCopyWithImpl<_$ServerFailureImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String? message) network,
    required TResult Function(int statusCode, String? message) server,
    required TResult Function(String? message) rateLimit,
    required TResult Function() unauthorized,
    required TResult Function() forbidden,
    required TResult Function() notFound,
    required TResult Function(String message) validation,
    required TResult Function(String? message) unknown,
  }) {
    return server(statusCode, message);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String? message)? network,
    TResult? Function(int statusCode, String? message)? server,
    TResult? Function(String? message)? rateLimit,
    TResult? Function()? unauthorized,
    TResult? Function()? forbidden,
    TResult? Function()? notFound,
    TResult? Function(String message)? validation,
    TResult? Function(String? message)? unknown,
  }) {
    return server?.call(statusCode, message);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String? message)? network,
    TResult Function(int statusCode, String? message)? server,
    TResult Function(String? message)? rateLimit,
    TResult Function()? unauthorized,
    TResult Function()? forbidden,
    TResult Function()? notFound,
    TResult Function(String message)? validation,
    TResult Function(String? message)? unknown,
    required TResult orElse(),
  }) {
    if (server != null) {
      return server(statusCode, message);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(NetworkFailure value) network,
    required TResult Function(ServerFailure value) server,
    required TResult Function(RateLimitFailure value) rateLimit,
    required TResult Function(UnauthorizedFailure value) unauthorized,
    required TResult Function(ForbiddenFailure value) forbidden,
    required TResult Function(NotFoundFailure value) notFound,
    required TResult Function(ValidationFailure value) validation,
    required TResult Function(UnknownFailure value) unknown,
  }) {
    return server(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(NetworkFailure value)? network,
    TResult? Function(ServerFailure value)? server,
    TResult? Function(RateLimitFailure value)? rateLimit,
    TResult? Function(UnauthorizedFailure value)? unauthorized,
    TResult? Function(ForbiddenFailure value)? forbidden,
    TResult? Function(NotFoundFailure value)? notFound,
    TResult? Function(ValidationFailure value)? validation,
    TResult? Function(UnknownFailure value)? unknown,
  }) {
    return server?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(NetworkFailure value)? network,
    TResult Function(ServerFailure value)? server,
    TResult Function(RateLimitFailure value)? rateLimit,
    TResult Function(UnauthorizedFailure value)? unauthorized,
    TResult Function(ForbiddenFailure value)? forbidden,
    TResult Function(NotFoundFailure value)? notFound,
    TResult Function(ValidationFailure value)? validation,
    TResult Function(UnknownFailure value)? unknown,
    required TResult orElse(),
  }) {
    if (server != null) {
      return server(this);
    }
    return orElse();
  }
}

abstract class ServerFailure implements Failure {
  const factory ServerFailure(
      {required final int statusCode,
      final String? message}) = _$ServerFailureImpl;

  int get statusCode;
  String? get message;
  @JsonKey(ignore: true)
  _$$ServerFailureImplCopyWith<_$ServerFailureImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$RateLimitFailureImplCopyWith<$Res> {
  factory _$$RateLimitFailureImplCopyWith(_$RateLimitFailureImpl value,
          $Res Function(_$RateLimitFailureImpl) then) =
      __$$RateLimitFailureImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String? message});
}

/// @nodoc
class __$$RateLimitFailureImplCopyWithImpl<$Res>
    extends _$FailureCopyWithImpl<$Res, _$RateLimitFailureImpl>
    implements _$$RateLimitFailureImplCopyWith<$Res> {
  __$$RateLimitFailureImplCopyWithImpl(_$RateLimitFailureImpl _value,
      $Res Function(_$RateLimitFailureImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? message = freezed,
  }) {
    return _then(_$RateLimitFailureImpl(
      message: freezed == message
          ? _value.message
          : message // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc

class _$RateLimitFailureImpl implements RateLimitFailure {
  const _$RateLimitFailureImpl({this.message});

  @override
  final String? message;

  @override
  String toString() {
    return 'Failure.rateLimit(message: $message)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$RateLimitFailureImpl &&
            (identical(other.message, message) || other.message == message));
  }

  @override
  int get hashCode => Object.hash(runtimeType, message);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$RateLimitFailureImplCopyWith<_$RateLimitFailureImpl> get copyWith =>
      __$$RateLimitFailureImplCopyWithImpl<_$RateLimitFailureImpl>(
          this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String? message) network,
    required TResult Function(int statusCode, String? message) server,
    required TResult Function(String? message) rateLimit,
    required TResult Function() unauthorized,
    required TResult Function() forbidden,
    required TResult Function() notFound,
    required TResult Function(String message) validation,
    required TResult Function(String? message) unknown,
  }) {
    return rateLimit(message);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String? message)? network,
    TResult? Function(int statusCode, String? message)? server,
    TResult? Function(String? message)? rateLimit,
    TResult? Function()? unauthorized,
    TResult? Function()? forbidden,
    TResult? Function()? notFound,
    TResult? Function(String message)? validation,
    TResult? Function(String? message)? unknown,
  }) {
    return rateLimit?.call(message);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String? message)? network,
    TResult Function(int statusCode, String? message)? server,
    TResult Function(String? message)? rateLimit,
    TResult Function()? unauthorized,
    TResult Function()? forbidden,
    TResult Function()? notFound,
    TResult Function(String message)? validation,
    TResult Function(String? message)? unknown,
    required TResult orElse(),
  }) {
    if (rateLimit != null) {
      return rateLimit(message);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(NetworkFailure value) network,
    required TResult Function(ServerFailure value) server,
    required TResult Function(RateLimitFailure value) rateLimit,
    required TResult Function(UnauthorizedFailure value) unauthorized,
    required TResult Function(ForbiddenFailure value) forbidden,
    required TResult Function(NotFoundFailure value) notFound,
    required TResult Function(ValidationFailure value) validation,
    required TResult Function(UnknownFailure value) unknown,
  }) {
    return rateLimit(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(NetworkFailure value)? network,
    TResult? Function(ServerFailure value)? server,
    TResult? Function(RateLimitFailure value)? rateLimit,
    TResult? Function(UnauthorizedFailure value)? unauthorized,
    TResult? Function(ForbiddenFailure value)? forbidden,
    TResult? Function(NotFoundFailure value)? notFound,
    TResult? Function(ValidationFailure value)? validation,
    TResult? Function(UnknownFailure value)? unknown,
  }) {
    return rateLimit?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(NetworkFailure value)? network,
    TResult Function(ServerFailure value)? server,
    TResult Function(RateLimitFailure value)? rateLimit,
    TResult Function(UnauthorizedFailure value)? unauthorized,
    TResult Function(ForbiddenFailure value)? forbidden,
    TResult Function(NotFoundFailure value)? notFound,
    TResult Function(ValidationFailure value)? validation,
    TResult Function(UnknownFailure value)? unknown,
    required TResult orElse(),
  }) {
    if (rateLimit != null) {
      return rateLimit(this);
    }
    return orElse();
  }
}

abstract class RateLimitFailure implements Failure {
  const factory RateLimitFailure({final String? message}) =
      _$RateLimitFailureImpl;

  String? get message;
  @JsonKey(ignore: true)
  _$$RateLimitFailureImplCopyWith<_$RateLimitFailureImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$UnauthorizedFailureImplCopyWith<$Res> {
  factory _$$UnauthorizedFailureImplCopyWith(_$UnauthorizedFailureImpl value,
          $Res Function(_$UnauthorizedFailureImpl) then) =
      __$$UnauthorizedFailureImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$UnauthorizedFailureImplCopyWithImpl<$Res>
    extends _$FailureCopyWithImpl<$Res, _$UnauthorizedFailureImpl>
    implements _$$UnauthorizedFailureImplCopyWith<$Res> {
  __$$UnauthorizedFailureImplCopyWithImpl(_$UnauthorizedFailureImpl _value,
      $Res Function(_$UnauthorizedFailureImpl) _then)
      : super(_value, _then);
}

/// @nodoc

class _$UnauthorizedFailureImpl implements UnauthorizedFailure {
  const _$UnauthorizedFailureImpl();

  @override
  String toString() {
    return 'Failure.unauthorized()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UnauthorizedFailureImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String? message) network,
    required TResult Function(int statusCode, String? message) server,
    required TResult Function(String? message) rateLimit,
    required TResult Function() unauthorized,
    required TResult Function() forbidden,
    required TResult Function() notFound,
    required TResult Function(String message) validation,
    required TResult Function(String? message) unknown,
  }) {
    return unauthorized();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String? message)? network,
    TResult? Function(int statusCode, String? message)? server,
    TResult? Function(String? message)? rateLimit,
    TResult? Function()? unauthorized,
    TResult? Function()? forbidden,
    TResult? Function()? notFound,
    TResult? Function(String message)? validation,
    TResult? Function(String? message)? unknown,
  }) {
    return unauthorized?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String? message)? network,
    TResult Function(int statusCode, String? message)? server,
    TResult Function(String? message)? rateLimit,
    TResult Function()? unauthorized,
    TResult Function()? forbidden,
    TResult Function()? notFound,
    TResult Function(String message)? validation,
    TResult Function(String? message)? unknown,
    required TResult orElse(),
  }) {
    if (unauthorized != null) {
      return unauthorized();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(NetworkFailure value) network,
    required TResult Function(ServerFailure value) server,
    required TResult Function(RateLimitFailure value) rateLimit,
    required TResult Function(UnauthorizedFailure value) unauthorized,
    required TResult Function(ForbiddenFailure value) forbidden,
    required TResult Function(NotFoundFailure value) notFound,
    required TResult Function(ValidationFailure value) validation,
    required TResult Function(UnknownFailure value) unknown,
  }) {
    return unauthorized(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(NetworkFailure value)? network,
    TResult? Function(ServerFailure value)? server,
    TResult? Function(RateLimitFailure value)? rateLimit,
    TResult? Function(UnauthorizedFailure value)? unauthorized,
    TResult? Function(ForbiddenFailure value)? forbidden,
    TResult? Function(NotFoundFailure value)? notFound,
    TResult? Function(ValidationFailure value)? validation,
    TResult? Function(UnknownFailure value)? unknown,
  }) {
    return unauthorized?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(NetworkFailure value)? network,
    TResult Function(ServerFailure value)? server,
    TResult Function(RateLimitFailure value)? rateLimit,
    TResult Function(UnauthorizedFailure value)? unauthorized,
    TResult Function(ForbiddenFailure value)? forbidden,
    TResult Function(NotFoundFailure value)? notFound,
    TResult Function(ValidationFailure value)? validation,
    TResult Function(UnknownFailure value)? unknown,
    required TResult orElse(),
  }) {
    if (unauthorized != null) {
      return unauthorized(this);
    }
    return orElse();
  }
}

abstract class UnauthorizedFailure implements Failure {
  const factory UnauthorizedFailure() = _$UnauthorizedFailureImpl;
}

/// @nodoc
abstract class _$$ForbiddenFailureImplCopyWith<$Res> {
  factory _$$ForbiddenFailureImplCopyWith(_$ForbiddenFailureImpl value,
          $Res Function(_$ForbiddenFailureImpl) then) =
      __$$ForbiddenFailureImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$ForbiddenFailureImplCopyWithImpl<$Res>
    extends _$FailureCopyWithImpl<$Res, _$ForbiddenFailureImpl>
    implements _$$ForbiddenFailureImplCopyWith<$Res> {
  __$$ForbiddenFailureImplCopyWithImpl(_$ForbiddenFailureImpl _value,
      $Res Function(_$ForbiddenFailureImpl) _then)
      : super(_value, _then);
}

/// @nodoc

class _$ForbiddenFailureImpl implements ForbiddenFailure {
  const _$ForbiddenFailureImpl();

  @override
  String toString() {
    return 'Failure.forbidden()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is _$ForbiddenFailureImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String? message) network,
    required TResult Function(int statusCode, String? message) server,
    required TResult Function(String? message) rateLimit,
    required TResult Function() unauthorized,
    required TResult Function() forbidden,
    required TResult Function() notFound,
    required TResult Function(String message) validation,
    required TResult Function(String? message) unknown,
  }) {
    return forbidden();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String? message)? network,
    TResult? Function(int statusCode, String? message)? server,
    TResult? Function(String? message)? rateLimit,
    TResult? Function()? unauthorized,
    TResult? Function()? forbidden,
    TResult? Function()? notFound,
    TResult? Function(String message)? validation,
    TResult? Function(String? message)? unknown,
  }) {
    return forbidden?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String? message)? network,
    TResult Function(int statusCode, String? message)? server,
    TResult Function(String? message)? rateLimit,
    TResult Function()? unauthorized,
    TResult Function()? forbidden,
    TResult Function()? notFound,
    TResult Function(String message)? validation,
    TResult Function(String? message)? unknown,
    required TResult orElse(),
  }) {
    if (forbidden != null) {
      return forbidden();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(NetworkFailure value) network,
    required TResult Function(ServerFailure value) server,
    required TResult Function(RateLimitFailure value) rateLimit,
    required TResult Function(UnauthorizedFailure value) unauthorized,
    required TResult Function(ForbiddenFailure value) forbidden,
    required TResult Function(NotFoundFailure value) notFound,
    required TResult Function(ValidationFailure value) validation,
    required TResult Function(UnknownFailure value) unknown,
  }) {
    return forbidden(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(NetworkFailure value)? network,
    TResult? Function(ServerFailure value)? server,
    TResult? Function(RateLimitFailure value)? rateLimit,
    TResult? Function(UnauthorizedFailure value)? unauthorized,
    TResult? Function(ForbiddenFailure value)? forbidden,
    TResult? Function(NotFoundFailure value)? notFound,
    TResult? Function(ValidationFailure value)? validation,
    TResult? Function(UnknownFailure value)? unknown,
  }) {
    return forbidden?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(NetworkFailure value)? network,
    TResult Function(ServerFailure value)? server,
    TResult Function(RateLimitFailure value)? rateLimit,
    TResult Function(UnauthorizedFailure value)? unauthorized,
    TResult Function(ForbiddenFailure value)? forbidden,
    TResult Function(NotFoundFailure value)? notFound,
    TResult Function(ValidationFailure value)? validation,
    TResult Function(UnknownFailure value)? unknown,
    required TResult orElse(),
  }) {
    if (forbidden != null) {
      return forbidden(this);
    }
    return orElse();
  }
}

abstract class ForbiddenFailure implements Failure {
  const factory ForbiddenFailure() = _$ForbiddenFailureImpl;
}

/// @nodoc
abstract class _$$NotFoundFailureImplCopyWith<$Res> {
  factory _$$NotFoundFailureImplCopyWith(_$NotFoundFailureImpl value,
          $Res Function(_$NotFoundFailureImpl) then) =
      __$$NotFoundFailureImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$NotFoundFailureImplCopyWithImpl<$Res>
    extends _$FailureCopyWithImpl<$Res, _$NotFoundFailureImpl>
    implements _$$NotFoundFailureImplCopyWith<$Res> {
  __$$NotFoundFailureImplCopyWithImpl(
      _$NotFoundFailureImpl _value, $Res Function(_$NotFoundFailureImpl) _then)
      : super(_value, _then);
}

/// @nodoc

class _$NotFoundFailureImpl implements NotFoundFailure {
  const _$NotFoundFailureImpl();

  @override
  String toString() {
    return 'Failure.notFound()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is _$NotFoundFailureImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String? message) network,
    required TResult Function(int statusCode, String? message) server,
    required TResult Function(String? message) rateLimit,
    required TResult Function() unauthorized,
    required TResult Function() forbidden,
    required TResult Function() notFound,
    required TResult Function(String message) validation,
    required TResult Function(String? message) unknown,
  }) {
    return notFound();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String? message)? network,
    TResult? Function(int statusCode, String? message)? server,
    TResult? Function(String? message)? rateLimit,
    TResult? Function()? unauthorized,
    TResult? Function()? forbidden,
    TResult? Function()? notFound,
    TResult? Function(String message)? validation,
    TResult? Function(String? message)? unknown,
  }) {
    return notFound?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String? message)? network,
    TResult Function(int statusCode, String? message)? server,
    TResult Function(String? message)? rateLimit,
    TResult Function()? unauthorized,
    TResult Function()? forbidden,
    TResult Function()? notFound,
    TResult Function(String message)? validation,
    TResult Function(String? message)? unknown,
    required TResult orElse(),
  }) {
    if (notFound != null) {
      return notFound();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(NetworkFailure value) network,
    required TResult Function(ServerFailure value) server,
    required TResult Function(RateLimitFailure value) rateLimit,
    required TResult Function(UnauthorizedFailure value) unauthorized,
    required TResult Function(ForbiddenFailure value) forbidden,
    required TResult Function(NotFoundFailure value) notFound,
    required TResult Function(ValidationFailure value) validation,
    required TResult Function(UnknownFailure value) unknown,
  }) {
    return notFound(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(NetworkFailure value)? network,
    TResult? Function(ServerFailure value)? server,
    TResult? Function(RateLimitFailure value)? rateLimit,
    TResult? Function(UnauthorizedFailure value)? unauthorized,
    TResult? Function(ForbiddenFailure value)? forbidden,
    TResult? Function(NotFoundFailure value)? notFound,
    TResult? Function(ValidationFailure value)? validation,
    TResult? Function(UnknownFailure value)? unknown,
  }) {
    return notFound?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(NetworkFailure value)? network,
    TResult Function(ServerFailure value)? server,
    TResult Function(RateLimitFailure value)? rateLimit,
    TResult Function(UnauthorizedFailure value)? unauthorized,
    TResult Function(ForbiddenFailure value)? forbidden,
    TResult Function(NotFoundFailure value)? notFound,
    TResult Function(ValidationFailure value)? validation,
    TResult Function(UnknownFailure value)? unknown,
    required TResult orElse(),
  }) {
    if (notFound != null) {
      return notFound(this);
    }
    return orElse();
  }
}

abstract class NotFoundFailure implements Failure {
  const factory NotFoundFailure() = _$NotFoundFailureImpl;
}

/// @nodoc
abstract class _$$ValidationFailureImplCopyWith<$Res> {
  factory _$$ValidationFailureImplCopyWith(_$ValidationFailureImpl value,
          $Res Function(_$ValidationFailureImpl) then) =
      __$$ValidationFailureImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String message});
}

/// @nodoc
class __$$ValidationFailureImplCopyWithImpl<$Res>
    extends _$FailureCopyWithImpl<$Res, _$ValidationFailureImpl>
    implements _$$ValidationFailureImplCopyWith<$Res> {
  __$$ValidationFailureImplCopyWithImpl(_$ValidationFailureImpl _value,
      $Res Function(_$ValidationFailureImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? message = null,
  }) {
    return _then(_$ValidationFailureImpl(
      message: null == message
          ? _value.message
          : message // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class _$ValidationFailureImpl implements ValidationFailure {
  const _$ValidationFailureImpl({required this.message});

  @override
  final String message;

  @override
  String toString() {
    return 'Failure.validation(message: $message)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ValidationFailureImpl &&
            (identical(other.message, message) || other.message == message));
  }

  @override
  int get hashCode => Object.hash(runtimeType, message);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$ValidationFailureImplCopyWith<_$ValidationFailureImpl> get copyWith =>
      __$$ValidationFailureImplCopyWithImpl<_$ValidationFailureImpl>(
          this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String? message) network,
    required TResult Function(int statusCode, String? message) server,
    required TResult Function(String? message) rateLimit,
    required TResult Function() unauthorized,
    required TResult Function() forbidden,
    required TResult Function() notFound,
    required TResult Function(String message) validation,
    required TResult Function(String? message) unknown,
  }) {
    return validation(message);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String? message)? network,
    TResult? Function(int statusCode, String? message)? server,
    TResult? Function(String? message)? rateLimit,
    TResult? Function()? unauthorized,
    TResult? Function()? forbidden,
    TResult? Function()? notFound,
    TResult? Function(String message)? validation,
    TResult? Function(String? message)? unknown,
  }) {
    return validation?.call(message);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String? message)? network,
    TResult Function(int statusCode, String? message)? server,
    TResult Function(String? message)? rateLimit,
    TResult Function()? unauthorized,
    TResult Function()? forbidden,
    TResult Function()? notFound,
    TResult Function(String message)? validation,
    TResult Function(String? message)? unknown,
    required TResult orElse(),
  }) {
    if (validation != null) {
      return validation(message);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(NetworkFailure value) network,
    required TResult Function(ServerFailure value) server,
    required TResult Function(RateLimitFailure value) rateLimit,
    required TResult Function(UnauthorizedFailure value) unauthorized,
    required TResult Function(ForbiddenFailure value) forbidden,
    required TResult Function(NotFoundFailure value) notFound,
    required TResult Function(ValidationFailure value) validation,
    required TResult Function(UnknownFailure value) unknown,
  }) {
    return validation(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(NetworkFailure value)? network,
    TResult? Function(ServerFailure value)? server,
    TResult? Function(RateLimitFailure value)? rateLimit,
    TResult? Function(UnauthorizedFailure value)? unauthorized,
    TResult? Function(ForbiddenFailure value)? forbidden,
    TResult? Function(NotFoundFailure value)? notFound,
    TResult? Function(ValidationFailure value)? validation,
    TResult? Function(UnknownFailure value)? unknown,
  }) {
    return validation?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(NetworkFailure value)? network,
    TResult Function(ServerFailure value)? server,
    TResult Function(RateLimitFailure value)? rateLimit,
    TResult Function(UnauthorizedFailure value)? unauthorized,
    TResult Function(ForbiddenFailure value)? forbidden,
    TResult Function(NotFoundFailure value)? notFound,
    TResult Function(ValidationFailure value)? validation,
    TResult Function(UnknownFailure value)? unknown,
    required TResult orElse(),
  }) {
    if (validation != null) {
      return validation(this);
    }
    return orElse();
  }
}

abstract class ValidationFailure implements Failure {
  const factory ValidationFailure({required final String message}) =
      _$ValidationFailureImpl;

  String get message;
  @JsonKey(ignore: true)
  _$$ValidationFailureImplCopyWith<_$ValidationFailureImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$UnknownFailureImplCopyWith<$Res> {
  factory _$$UnknownFailureImplCopyWith(_$UnknownFailureImpl value,
          $Res Function(_$UnknownFailureImpl) then) =
      __$$UnknownFailureImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String? message});
}

/// @nodoc
class __$$UnknownFailureImplCopyWithImpl<$Res>
    extends _$FailureCopyWithImpl<$Res, _$UnknownFailureImpl>
    implements _$$UnknownFailureImplCopyWith<$Res> {
  __$$UnknownFailureImplCopyWithImpl(
      _$UnknownFailureImpl _value, $Res Function(_$UnknownFailureImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? message = freezed,
  }) {
    return _then(_$UnknownFailureImpl(
      message: freezed == message
          ? _value.message
          : message // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc

class _$UnknownFailureImpl implements UnknownFailure {
  const _$UnknownFailureImpl({this.message});

  @override
  final String? message;

  @override
  String toString() {
    return 'Failure.unknown(message: $message)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UnknownFailureImpl &&
            (identical(other.message, message) || other.message == message));
  }

  @override
  int get hashCode => Object.hash(runtimeType, message);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$UnknownFailureImplCopyWith<_$UnknownFailureImpl> get copyWith =>
      __$$UnknownFailureImplCopyWithImpl<_$UnknownFailureImpl>(
          this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String? message) network,
    required TResult Function(int statusCode, String? message) server,
    required TResult Function(String? message) rateLimit,
    required TResult Function() unauthorized,
    required TResult Function() forbidden,
    required TResult Function() notFound,
    required TResult Function(String message) validation,
    required TResult Function(String? message) unknown,
  }) {
    return unknown(message);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String? message)? network,
    TResult? Function(int statusCode, String? message)? server,
    TResult? Function(String? message)? rateLimit,
    TResult? Function()? unauthorized,
    TResult? Function()? forbidden,
    TResult? Function()? notFound,
    TResult? Function(String message)? validation,
    TResult? Function(String? message)? unknown,
  }) {
    return unknown?.call(message);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String? message)? network,
    TResult Function(int statusCode, String? message)? server,
    TResult Function(String? message)? rateLimit,
    TResult Function()? unauthorized,
    TResult Function()? forbidden,
    TResult Function()? notFound,
    TResult Function(String message)? validation,
    TResult Function(String? message)? unknown,
    required TResult orElse(),
  }) {
    if (unknown != null) {
      return unknown(message);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(NetworkFailure value) network,
    required TResult Function(ServerFailure value) server,
    required TResult Function(RateLimitFailure value) rateLimit,
    required TResult Function(UnauthorizedFailure value) unauthorized,
    required TResult Function(ForbiddenFailure value) forbidden,
    required TResult Function(NotFoundFailure value) notFound,
    required TResult Function(ValidationFailure value) validation,
    required TResult Function(UnknownFailure value) unknown,
  }) {
    return unknown(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(NetworkFailure value)? network,
    TResult? Function(ServerFailure value)? server,
    TResult? Function(RateLimitFailure value)? rateLimit,
    TResult? Function(UnauthorizedFailure value)? unauthorized,
    TResult? Function(ForbiddenFailure value)? forbidden,
    TResult? Function(NotFoundFailure value)? notFound,
    TResult? Function(ValidationFailure value)? validation,
    TResult? Function(UnknownFailure value)? unknown,
  }) {
    return unknown?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(NetworkFailure value)? network,
    TResult Function(ServerFailure value)? server,
    TResult Function(RateLimitFailure value)? rateLimit,
    TResult Function(UnauthorizedFailure value)? unauthorized,
    TResult Function(ForbiddenFailure value)? forbidden,
    TResult Function(NotFoundFailure value)? notFound,
    TResult Function(ValidationFailure value)? validation,
    TResult Function(UnknownFailure value)? unknown,
    required TResult orElse(),
  }) {
    if (unknown != null) {
      return unknown(this);
    }
    return orElse();
  }
}

abstract class UnknownFailure implements Failure {
  const factory UnknownFailure({final String? message}) = _$UnknownFailureImpl;

  String? get message;
  @JsonKey(ignore: true)
  _$$UnknownFailureImplCopyWith<_$UnknownFailureImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
