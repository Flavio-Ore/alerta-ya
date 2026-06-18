import 'package:injectable/injectable.dart';

import 'package:alertaya/core/services/firebase_storage_service.dart';

@lazySingleton
class PanicUploadService {
  const PanicUploadService(this._storageService);

  final FirebaseStorageService _storageService;

  /// Sube un bloque de audio cifrado (AES-256) a Firebase Storage.
  /// Ruta: panic/{sessionId}/audio/block_{blockIndex}.bin
  Future<void> uploadBlock(
    String filePath,
    String sessionId,
    int blockIndex,
  ) async {
    await _storageService.uploadPanicBlock(filePath, sessionId, blockIndex);
  }

  /// Sube un clip de video cifrado (AES-256) a Firebase Storage.
  /// Ruta: panic/{sessionId}/video/clip_{clipIndex}.bin
  Future<void> uploadVideoClip(
    String filePath,
    String sessionId,
    int clipIndex,
  ) async {
    await _storageService.uploadPanicVideoClip(filePath, sessionId, clipIndex);
  }
}
