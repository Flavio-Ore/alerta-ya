import 'package:dartz/dartz.dart';

import 'package:alertaya/core/errors/failures.dart';
import 'package:alertaya/features/panic/domain/entities/panic_start_result.dart';

abstract class PanicRepository {
  Future<Either<Failure, PanicStartResult>> startSession({
    required double lat,
    required double lng,
  });

  Future<Either<Failure, Unit>> stopSession(String sessionId);
}
