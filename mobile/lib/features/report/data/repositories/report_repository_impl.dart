import 'package:dartz/dartz.dart';
import 'package:exif/exif.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:injectable/injectable.dart';

import 'package:alertaya/core/errors/exceptions.dart';
import 'package:alertaya/core/errors/failures.dart';
import 'package:alertaya/core/services/media_upload_service.dart';
import 'package:alertaya/features/report/data/datasources/report_remote_datasource.dart';
import 'package:alertaya/features/report/data/schemas/report_form_schemas.dart';
import 'package:alertaya/features/report/domain/entities/form_question_entity.dart';
import 'package:alertaya/features/report/domain/entities/incident_type.dart';
import 'package:alertaya/features/report/domain/entities/report_entity.dart';
import 'package:alertaya/features/report/domain/entities/report_submit_result.dart';
import 'package:alertaya/features/report/domain/repositories/report_repository.dart';

@LazySingleton(as: ReportRepository)
class ReportRepositoryImpl implements ReportRepository {
  const ReportRepositoryImpl(
    this._remoteDataSource,
    this._mediaUploadService,
    this._firebaseAuth,
  );

  final ReportRemoteDataSource _remoteDataSource;
  final MediaUploadService _mediaUploadService;
  final FirebaseAuth _firebaseAuth;

  @override
  DynamicFormSchema getFormSchema(IncidentType type) =>
      ReportFormSchemas.schemaFor(type);

  @override
  Future<Either<Failure, ReportSubmitResult>> createReport(
    ReportEntity report,
  ) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        return const Left(Failure.unauthorized());
      }

      // 1. Extraer timestamp EXIF antes de subir (bytes aún frescos en disco)
      final paths = report.mediaPaths;
      DateTime? photoTakenAt;
      String? photoSource;

      if (paths != null && paths.isNotEmpty) {
        final firstFile = XFile(paths.first);
        final exifResult = await _extractPhotoTimestamp(firstFile);
        photoTakenAt = exifResult.photoTakenAt;
        photoSource = exifResult.photoSource;
      }

      // 2. Subir evidencia a Firebase Storage (si hay)
      final mediaUrls = <String>[];
      if (paths != null && paths.isNotEmpty) {
        final files = paths.map((p) => XFile(p)).toList();
        final uploaded = await _mediaUploadService.uploadReportMedia(
          files,
          user.uid,
        );
        mediaUrls.addAll(uploaded);
      }

      // 3. Armar formData final con notas (si las hay)
      final formData = <String, dynamic>{...report.formData};
      final notes = report.notes;
      if (notes != null && notes.trim().isNotEmpty) {
        formData['notes'] = notes.trim();
      }

      // 4. Enviar al backend
      final result = await _remoteDataSource.submitReport(
        lat: report.lat,
        lng: report.lng,
        type: report.type,
        formData: formData,
        mediaUrls: mediaUrls,
        photoTakenAt: photoTakenAt,
        photoSource: photoSource,
      );

      return Right(result);
    } on UnauthorizedException {
      return const Left(Failure.unauthorized());
    } on RateLimitException catch (e) {
      return Left(
        Failure.rateLimit(
          message: e.message ?? 'Llegaste al límite de 3 reportes por hora',
        ),
      );
    } on ValidationException catch (e) {
      return Left(
        Failure.validation(
          message: e.message ?? 'Datos inválidos',
        ),
      );
    } on ServerException catch (e) {
      return Left(
        Failure.server(
          statusCode: e.statusCode,
          message: e.message,
        ),
      );
    } on NetworkException catch (e) {
      return Left(Failure.network(message: e.message));
    } catch (e) {
      return Left(Failure.unknown(message: e.toString()));
    }
  }

  /// Extrae el timestamp de captura desde los metadatos EXIF de una foto.
  ///
  /// Formato EXIF DateTimeOriginal: "YYYY:MM:DD HH:mm:ss"
  /// - Si el tag está presente y es parseable → (photoTakenAt: DateTime UTC, photoSource: 'exif')
  /// - Si falta o falla el parseo       → (photoTakenAt: DateTime.now(), photoSource: 'device_clock')
  Future<({DateTime photoTakenAt, String photoSource})> _extractPhotoTimestamp(
    XFile file,
  ) async {
    try {
      final bytes = await file.readAsBytes();
      final tags = await readExifFromBytes(bytes);
      final raw = tags['EXIF DateTimeOriginal']?.printable;
      if (raw != null && raw.length == 19) {
        // "2024:06:19 14:30:05" → "2024-06-19 14:30:05"
        final normalized = raw
            .replaceFirst(':', '-', 4)
            .replaceFirst(':', '-', 7);
        final parsed = DateTime.tryParse(normalized);
        if (parsed != null) {
          return (photoTakenAt: parsed.toUtc(), photoSource: 'exif');
        }
      }
    } catch (_) {
      // Fallo silencioso — cae al fallback
    }
    return (photoTakenAt: DateTime.now().toUtc(), photoSource: 'device_clock');
  }
}
