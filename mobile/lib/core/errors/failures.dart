import 'package:freezed_annotation/freezed_annotation.dart';

part 'failures.freezed.dart';

@freezed
class Failure with _$Failure {
  const factory Failure.network({String? message}) = NetworkFailure;
  const factory Failure.server({required int statusCode, String? message}) = ServerFailure;
  const factory Failure.rateLimit({String? message}) = RateLimitFailure;
  const factory Failure.unauthorized() = UnauthorizedFailure;
  const factory Failure.forbidden() = ForbiddenFailure;
  const factory Failure.notFound() = NotFoundFailure;
  const factory Failure.validation({required String message}) = ValidationFailure;
  const factory Failure.unknown({String? message}) = UnknownFailure;
}
