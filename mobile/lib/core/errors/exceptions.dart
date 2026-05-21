class NetworkException implements Exception {
  const NetworkException([this.message]);
  final String? message;
}

class ServerException implements Exception {
  const ServerException({required this.statusCode, this.message});
  final int statusCode;
  final String? message;
}

class RateLimitException implements Exception {
  const RateLimitException([this.message]);
  final String? message;
}

class UnauthorizedException implements Exception {
  const UnauthorizedException();
}

class NotFoundException implements Exception {
  const NotFoundException([this.message]);
  final String? message;
}

class CacheException implements Exception {
  const CacheException([this.message]);
  final String? message;
}

class UserCancelledException implements Exception {
  const UserCancelledException();
}
