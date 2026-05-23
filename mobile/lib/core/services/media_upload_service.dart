import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:injectable/injectable.dart';

import 'package:alertaya/features/panic/domain/entities/panic_start_result.dart';

/// Servicio para subir evidencia (fotos/videos) de reportes ciudadanos a
/// **Cloudinary** vía signed upload params generados por el API.
///
/// Flujo:
///  1. Pedir N upload params al API (`POST /incidents/reports/upload-params`).
///  2. Subir cada archivo en paralelo a la URL firmada de Cloudinary.
///  3. Devolver las `secure_url` que Cloudinary retorna.
///
/// Las fotos/videos se almacenan en `reports/{userId}/{uuid}` (path lo decide
/// el API). El cifrado AES-256 NO aplica a estos archivos — eso es solo para
/// grabaciones de audio del botón de pánico (ver SECURITY_RULES.md).
@lazySingleton
class MediaUploadService {
  MediaUploadService(this._apiDio);

  /// `_apiDio` lleva los interceptors de auth (Bearer Firebase token) configurados.
  /// Se usa SOLO para pedir los upload params al API. La subida real a
  /// Cloudinary va por un Dio nuevo (sin interceptors).
  final Dio _apiDio;

  // Dio aparte para Cloudinary — sin interceptors, timeouts más generosos.
  final Dio _cloudinaryDio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 60),
      receiveTimeout: const Duration(seconds: 30),
    ),
  );

  /// Sube todos los archivos a Cloudinary y devuelve las `secure_url`.
  /// Si una subida falla, propaga la excepción (no swallow).
  ///
  /// `userId` ya no se usa — el path lo decide el API basándose en el UID
  /// autenticado. Se mantiene en la firma para evitar romper callers.
  Future<List<String>> uploadReportMedia(
    List<XFile> files,
    String userId,
  ) async {
    if (files.isEmpty) return const [];

    // 1) Pedir N upload params al API
    final paramsResp = await _apiDio.post<Map<String, dynamic>>(
      '/incidents/reports/upload-params',
      data: {'count': files.length},
    );
    final rawParams = paramsResp.data!['params'] as List<dynamic>;
    final allParams = rawParams
        .cast<Map<String, dynamic>>()
        .map(CloudinaryUploadParams.fromJson)
        .toList();

    if (allParams.length != files.length) {
      throw StateError(
        'API devolvió ${allParams.length} upload params para ${files.length} archivos',
      );
    }

    // 2) Subir cada archivo a Cloudinary y juntar las secure_url.
    final urls = <String>[];
    for (var i = 0; i < files.length; i++) {
      final url = await _uploadToCloudinary(files[i], allParams[i]);
      urls.add(url);
    }
    return urls;
  }

  Future<String> _uploadToCloudinary(
    XFile file,
    CloudinaryUploadParams params,
  ) async {
    final f = File(file.path);
    if (!f.existsSync()) {
      throw StateError('Archivo no existe: ${file.path}');
    }

    final filename = '${params.publicId.split('/').last}${_extensionFor(file)}';
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(f.path, filename: filename),
      'public_id': params.publicId,
      'api_key': params.apiKey,
      'timestamp': params.timestamp.toString(),
      'signature': params.signature,
    });

    try {
      final resp = await _cloudinaryDio.post<Map<String, dynamic>>(
        params.uploadUrl,
        data: formData,
      );
      final secureUrl = resp.data!['secure_url'] as String?;
      if (secureUrl == null) {
        throw StateError('Cloudinary no devolvió secure_url: ${resp.data}');
      }
      debugPrint('[MediaUpload] OK → $secureUrl');
      return secureUrl;
    } on DioException catch (e) {
      debugPrint('[MediaUpload] ⚠ DioException ${e.type} — ${e.message}');
      if (e.response != null) {
        debugPrint('[MediaUpload] Cloudinary response ${e.response!.statusCode}: ${e.response!.data}');
      }
      rethrow;
    }
  }

  String _extensionFor(XFile file) {
    final mime = file.mimeType;
    if (mime != null) {
      switch (mime) {
        case 'image/jpeg':
        case 'image/jpg':
          return '.jpg';
        case 'image/png':
          return '.png';
        case 'image/heic':
          return '.heic';
        case 'image/webp':
          return '.webp';
        case 'video/mp4':
          return '.mp4';
        case 'video/quicktime':
          return '.mov';
      }
    }
    // Fallback: extension de path
    final dotIndex = file.path.lastIndexOf('.');
    if (dotIndex != -1 && dotIndex < file.path.length - 1) {
      return file.path.substring(dotIndex).toLowerCase();
    }
    return '';
  }
}
