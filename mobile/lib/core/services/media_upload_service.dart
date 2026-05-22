import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:injectable/injectable.dart';
import 'package:uuid/uuid.dart';

/// Servicio para subir evidencia (fotos/videos) de reportes ciudadanos a
/// Firebase Storage.
///
/// Las fotos/videos del reporte se almacenan en texto plano (sin cifrar) en
/// `reports/{userId}/{uuid}.{ext}`. El cifrado AES-256 aplica únicamente a
/// grabaciones de audio del botón de pánico — ver
/// `docs/rules/SECURITY_RULES.md` § "GRABACIONES".
@lazySingleton
class MediaUploadService {
  MediaUploadService() : this._(FirebaseStorage.instance, const Uuid());

  @visibleForTesting
  MediaUploadService.forTesting({
    required FirebaseStorage storage,
    required Uuid uuid,
  }) : this._(storage, uuid);

  MediaUploadService._(this._storage, this._uuid);

  final FirebaseStorage _storage;
  final Uuid _uuid;

  /// Sube todos los archivos a Firebase Storage y devuelve las download URLs.
  ///
  /// Si una subida falla, propaga la excepción (no swallow).
  Future<List<String>> uploadReportMedia(
    List<XFile> files,
    String userId,
  ) async {
    final urls = <String>[];
    for (final file in files) {
      final ext = _extensionFor(file);
      final path = 'reports/$userId/${_uuid.v4()}$ext';
      final ref = _storage.ref().child(path);

      final mime = file.mimeType;
      final metadata = mime != null ? SettableMetadata(contentType: mime) : null;

      final task = await ref.putFile(File(file.path), metadata);
      final downloadUrl = await task.ref.getDownloadURL();
      urls.add(downloadUrl);
    }
    return urls;
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
