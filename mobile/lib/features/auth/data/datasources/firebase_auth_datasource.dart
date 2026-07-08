import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:injectable/injectable.dart';

import 'package:alertaya/core/constants/app_constants.dart';
import 'package:alertaya/core/errors/exceptions.dart';
import 'package:alertaya/features/auth/data/models/user_model.dart';

abstract class FirebaseAuthDataSource {
  Stream<UserModel?> get authStateChanges;
  Future<UserModel> signInWithEmail({required String email, required String password});
  Future<UserModel> signUpWithEmail({required String email, required String password});
  Future<UserModel> signInWithGoogle();
  Future<void> signOut();
  Future<void> deleteAccount();
}

@LazySingleton(as: FirebaseAuthDataSource)
class FirebaseAuthDataSourceImpl implements FirebaseAuthDataSource {
  FirebaseAuthDataSourceImpl(this._auth);
  final FirebaseAuth _auth;
  // serverClientId requerido por google_sign_in_android v6 (Credential Manager)
  // para que el SDK emita idToken. Sin esto, idToken es null y Firebase rechaza.
  final _googleSignIn = GoogleSignIn(
    serverClientId: AppConstants.googleWebClientId,
  );

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
      final googleAccount = await _googleSignIn.signIn();
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
    } on PlatformException catch (e) {
      if (e.code == 'sign_in_cancelled') throw const UserCancelledException();
      throw ServerException(statusCode: 0, message: e.code);
    } catch (e) {
      throw ServerException(statusCode: 0, message: e.toString());
    }
  }

  @override
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  @override
  Future<void> deleteAccount() async {
    try {
      await _auth.currentUser!.delete();
    } on FirebaseAuthException catch (e) {
      throw _mapException(e);
    }
  }

  Exception _mapException(FirebaseAuthException e) => switch (e.code) {
        'user-not-found' ||
        'wrong-password' ||
        'invalid-credential' =>
          const UnauthorizedException(),
        'email-already-in-use' =>
          const ServerException(statusCode: 409, message: 'email-already-in-use'),
        'weak-password' =>
          const ServerException(statusCode: 400, message: 'weak-password'),
        'too-many-requests' => const RateLimitException(),
        'network-request-failed' => NetworkException(e.message),
        _ => ServerException(statusCode: 0, message: e.message),
      };
}
