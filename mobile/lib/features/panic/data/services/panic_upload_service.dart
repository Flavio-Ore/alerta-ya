import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

import 'package:alertaya/features/panic/domain/entities/panic_start_result.dart';

@lazySingleton
class PanicUploadService {
  // Instancia propia sin interceptors — Cloudinary recibe requests anónimos firmados
  final _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 30),
    sendTimeout: const Duration(seconds: 60),
    receiveTimeout: const Duration(seconds: 30),
  ));

  /// Sube un bloque de audio cifrado directamente a Cloudinary usando los
  /// parámetros firmados generados por el API (sin exponer api_secret al cliente).
  Future<void> uploadBlock(
    CloudinaryUploadParams params,
    String filePath,
  ) async {
    final file = File(filePath);
    if (!file.existsSync()) {
      debugPrint('[PanicUpload] ERROR: archivo no existe → $filePath');
      return;
    }

    final bytes = await file.readAsBytes();
    debugPrint('[PanicUpload] Subiendo bloque: ${bytes.length} bytes → ${params.publicId}');

    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(
        bytes,
        filename: '${params.publicId.replaceAll('/', '_')}.bin',
        contentType: DioMediaType('application', 'octet-stream'),
      ),
      'public_id': params.publicId,
      'api_key': params.apiKey,
      'timestamp': params.timestamp.toString(),
      'signature': params.signature,
    });

    try {
      final response = await _dio.post<dynamic>(params.uploadUrl, data: formData);
      debugPrint('[PanicUpload] OK — publicId: ${params.publicId} | status: ${response.statusCode}');
    } on DioException catch (e) {
      debugPrint('[PanicUpload] ERROR DioException: ${e.type} — ${e.message}');
      if (e.response != null) {
        debugPrint('[PanicUpload] Cloudinary response ${e.response!.statusCode}: ${e.response!.data}');
      }
      rethrow;
    }
  }
}
