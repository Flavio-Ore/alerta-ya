import 'package:dartz/dartz.dart';

import 'package:alertaya/core/errors/failures.dart';
import 'package:alertaya/features/my_reports/domain/entities/my_report_entity.dart';

abstract class MyReportsRepository {
  Future<Either<Failure, MyReportsPage>> getMyReports({
    int page = 1,
    int pageSize = 20,
  });

  /// Stream de eventos en tiempo real desde el socket. Cada evento
  /// representa un cambio de estado en un incidente que el usuario reportó.
  Stream<ReportStatusChangedEvent> watchStatusChanges();

  /// Cancela un reporte pendiente (sin incidente asignado).
  /// Falla con Failure.server si ya fue publicado.
  Future<Either<Failure, Unit>> cancelReport(String reportId);
}
