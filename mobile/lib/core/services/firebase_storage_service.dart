import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:injectable/injectable.dart';
import 'package:uuid/uuid.dart';

@lazySingleton
class FirebaseStorageService {
  const FirebaseStorageService(this._storage);

  final FirebaseStorage _storage;
  static const _uuid = Uuid();

  /// Sube evidencia de un reporte y devuelve las download URLs.
  /// Los archivos se guardan en: reports/{userId}/{reportId}/{uuid}.ext
  /// Si una subida falla, propaga la excepción — el caller es responsable de manejarla.
  Future<List<String>> uploadReportMedia(
    List<XFile> files,
    String userId,
  ) async {
    if (files.isEmpty) return const [];
    final reportId = _uuid.v4();
    final urls = <String>[];

    for (final file in files) {
      final f = File(file.path);
      final stat = await FileStat.stat(f.path);
      if (stat.type == FileSystemEntityType.notFound) {
        debugPrint('[FirebaseStorage] SKIP — archivo no existe: ${file.path}');
        continue;
      }
      final ext = _extensionFor(file);
      final ref = _storage.ref('reports/$userId/$reportId/${_uuid.v4()}$ext');
      await ref.putFile(f);
      // No usamos getDownloadURL() — las reglas de Storage tienen read:false por
      // diseño (la evidencia solo la lee el backend vía Admin SDK). Guardamos la
      // ruta gs:// y el backend la resuelve cuando necesita acceder al archivo.
      final gsPath = 'gs://${ref.bucket}/${ref.fullPath}';
      debugPrint('[FirebaseStorage] reporte OK → $gsPath');
      urls.add(gsPath);
    }
    return urls;
  }

  /// Sube un bloque de audio cifrado (AES-256) del pánico.
  /// Los bloques se guardan en: panic/{sessionId}/audio/block_{index}.bin
  /// Fire-and-forget: no lanza si el archivo no existe.
  Future<void> uploadPanicBlock(
    String filePath,
    String sessionId,
    int blockIndex,
  ) async {
    final file = File(filePath);
    final stat = await FileStat.stat(file.path);
    if (stat.type == FileSystemEntityType.notFound) {
      debugPrint(
          '[FirebaseStorage] SKIP bloque — archivo no existe: $filePath');
      return;
    }
    final ref = _storage.ref('panic/$sessionId/audio/block_$blockIndex.bin');
    await ref.putFile(
      file,
      SettableMetadata(contentType: 'application/octet-stream'),
    );
    debugPrint(
      '[FirebaseStorage] bloque OK → panic/$sessionId/audio/block_$blockIndex.bin',
    );
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
    final dotIndex = file.path.lastIndexOf('.');
    if (dotIndex != -1 && dotIndex < file.path.length - 1) {
      return file.path.substring(dotIndex).toLowerCase();
    }
    return '';
  }
}
