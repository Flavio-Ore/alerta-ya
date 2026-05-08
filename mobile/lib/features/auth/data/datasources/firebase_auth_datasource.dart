import 'package:firebase_auth/firebase_auth.dart';
import 'package:injectable/injectable.dart';

import 'package:alertaya/core/errors/exceptions.dart';
import '../models/user_model.dart';

abstract class FirebaseAuthDataSource {
  Stream<UserModel?> get authStateChanges;
  Future<UserModel> signInWithEmail({required String email, required String password});
  Future<void> signOut();
}

@LazySingleton(as: FirebaseAuthDataSource)
class FirebaseAuthDataSourceImpl implements FirebaseAuthDataSource {
  const FirebaseAuthDataSourceImpl(this._auth);
  final FirebaseAuth _auth;

  @override
  Stream<UserModel?> get authStateChanges => _auth
      .authStateChanges()
      .map((user) => user != null ? UserModel.fromFirebaseUser(user) : null);

  @override
  Future<UserModel> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (credential.user == null) throw const UnauthorizedException();
      return UserModel.fromFirebaseUser(credential.user!);
    } on FirebaseAuthException catch (e) {
      throw _mapException(e);
    }
  }

  @override
  Future<void> signOut() => _auth.signOut();

  Exception _mapException(FirebaseAuthException e) => switch (e.code) {
        'user-not-found' ||
        'wrong-password' ||
        'invalid-credential' =>
          const UnauthorizedException(),
        'too-many-requests' => const RateLimitException(),
        'network-request-failed' => NetworkException(e.message),
        _ => ServerException(statusCode: 0, message: e.message),
      };
}
