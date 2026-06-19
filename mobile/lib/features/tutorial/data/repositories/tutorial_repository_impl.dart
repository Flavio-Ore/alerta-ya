import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import 'package:alertaya/core/errors/failures.dart';
import 'package:alertaya/features/tutorial/data/datasources/tutorial_local_datasource.dart';
import 'package:alertaya/features/tutorial/domain/repositories/tutorial_repository.dart';

@LazySingleton(as: TutorialRepository)
class TutorialRepositoryImpl implements TutorialRepository {
  const TutorialRepositoryImpl(this._dataSource);

  final TutorialLocalDataSource _dataSource;

  @override
  Future<Either<Failure, bool>> isTutorialSeen() async {
    try {
      return Right(_dataSource.isTutorialSeen());
    } catch (e) {
      return Left(Failure.unknown(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> markTutorialSeen() async {
    try {
      await _dataSource.markTutorialSeen();
      return const Right(unit);
    } catch (e) {
      return Left(Failure.unknown(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> resetTutorial() async {
    try {
      await _dataSource.resetTutorial();
      return const Right(unit);
    } catch (e) {
      return Left(Failure.unknown(message: e.toString()));
    }
  }
}
