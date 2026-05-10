import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:injectable/injectable.dart';

import 'package:alertaya/core/errors/exceptions.dart';
import '../models/user_model.dart';

abstract class FirebaseAuthDataSource {
  Stream<UserModel?> get authStateChanges;
  Future<UserModel> signInWithEmail({required String email, required String password});
  Future<UserModel> signUpWithEmail({required String email, required String password});
  Future<UserModel> signInWithGoogle();
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
  Future<UserModel> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
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
  Future<UserModel> signInWithGoogle() async {
    try {
      final googleSignIn = GoogleSignIn();
      final googleAccount = await googleSignIn.signIn();
      if (googleAccount == null) throw const UserCancelledException();

      final googleAuth = await googleAccount.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final userCredential = await _auth.signInWithCredential(credential);
      if (userCredential.user == null) throw const UnauthorizedException();
      return UserModel.fromFirebaseUser(userCredential.user!);
    } on UserCancelledException {
      rethrow;
    } on FirebaseAuthException catch (e) {
      throw _mapException(e);
    } catch (e) {
      throw ServerException(statusCode: 0, message: e.toString());
    }
  }

  @override
  Future<void> signOut() => _auth.signOut();

  Exception _mapException(FirebaseAuthException e) => switch (e.code) {
        'user-not-found' ||
        'wrong-password' ||
        'invalid-credential' =>
          const UnauthorizedException(),
        'email-already-in-use' =>
          ServerException(statusCode: 409, message: 'email-already-in-use'),
        'weak-password' =>
          ServerException(statusCode: 400, message: 'weak-password'),
        'too-many-requests' => const RateLimitException(),
        'network-request-failed' => NetworkException(e.message),
        _ => ServerException(statusCode: 0, message: e.message),
      };
}
