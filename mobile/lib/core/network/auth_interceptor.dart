import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthInterceptor extends Interceptor {
  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final token = await user.getIdToken();
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode == 401) {
      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          // Token expirado: forzar refresh y reintentar la request original
          final token = await user.getIdToken(true);
          err.requestOptions.headers['Authorization'] = 'Bearer $token';
          final response = await Dio().fetch<dynamic>(err.requestOptions);
          return handler.resolve(response);
        }
      } catch (_) {
        // Refresh fallido — dejar pasar el 401 para que el AuthBloc lo maneje
      }
    }
    handler.next(err);
  }
}
