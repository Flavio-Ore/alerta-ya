import 'package:dartz/dartz.dart';

import 'package:alertaya/core/errors/failures.dart';

abstract class TutorialRepository {
  Future<Either<Failure, bool>> isTutorialSeen();
  Future<Either<Failure, Unit>> markTutorialSeen();
  Future<Either<Failure, Unit>> resetTutorial();
}
