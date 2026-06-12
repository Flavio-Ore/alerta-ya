import 'package:firebase_auth/firebase_auth.dart' as fb;

import 'package:alertaya/features/auth/domain/entities/user_entity.dart';

class UserModel {
  const UserModel({required this.uid, this.reputationScore = 100});

  final String uid;
  final int reputationScore;

  factory UserModel.fromFirebaseUser(fb.User user) =>
      UserModel(uid: user.uid);

  UserEntity toEntity() => UserEntity(uid: uid, reputationScore: reputationScore);
}
