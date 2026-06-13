import 'package:injectable/injectable.dart';

import 'package:alertaya/core/services/firebase_storage_service.dart';

@lazySingleton
class PanicUploadService {
  const PanicUploadService(this._storageService);

  final FirebaseStorageService _storageService;

  /// Sube un bloque de audio cifrado (AES-256) a Firebase Storage.
  /// Ruta: panic/{sessionId}/audio/block_{blockIndex}.bin
  /// Fire-and-forget desde el BLoC: no lanza si el archivo no existe.
  Future<void> uploadBlock(
    String filePath,
    String sessionId,
    int blockIndex,
  ) async {
    await _storageService.uploadPanicBlock(filePath, sessionId, blockIndex);
  }
}
