import 'package:dartz/dartz.dart';

import 'package:alertaya/core/errors/failures.dart';
import '../entities/panic_session_entity.dart';

abstract class PanicRepository {
  Future<Either<Failure, PanicSessionEntity>> startSession({
    required double lat,
    required double lng,
  });

  Future<Either<Failure, Unit>> stopSession(String sessionId);
}
