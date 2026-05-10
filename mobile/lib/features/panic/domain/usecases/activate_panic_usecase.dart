import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import 'package:alertaya/core/errors/failures.dart';
import '../entities/panic_session_entity.dart';
import '../repositories/panic_repository.dart';

class ActivatePanicParams {
  const ActivatePanicParams({required this.lat, required this.lng});
  final double lat;
  final double lng;
}

@injectable
class ActivatePanicUseCase {
  const ActivatePanicUseCase(this._repository);
  final PanicRepository _repository;

  Future<Either<Failure, PanicSessionEntity>> call(
          ActivatePanicParams params) =>
      _repository.startSession(lat: params.lat, lng: params.lng);
}
