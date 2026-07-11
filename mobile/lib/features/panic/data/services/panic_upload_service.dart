import 'package:injectable/injectable.dart';

import 'package:alertaya/core/services/firebase_storage_service.dart';
import 'package:alertaya/features/panic/data/datasources/escrow_remote_datasource.dart';

@lazySingleton
class PanicUploadService {
  const PanicUploadService(this._storageService, this._escrow);

  final FirebaseStorageService _storageService;
  final EscrowRemoteDataSource _escrow;

  /// Sube un bloque de audio cifrado a Storage y, si la subida tuvo éxito,
  /// avisa al backend (POST /panic/sessions/:id/blocks) para que quede
  /// asociado a la sesión — sin esto, la web de autoridades no puede
  /// ubicar el bloque aunque tenga la clave.
  Future<void> uploadBlock(
    String filePath,
    String sessionId,
    int blockIndex,
  ) async {
    final gsPath = await _storageService.uploadPanicBlock(filePath, sessionId, blockIndex);
    if (gsPath == null) return;
    await _escrow.registerBlock(
      sessionId: sessionId,
      blockIndex: blockIndex,
      storagePath: gsPath,
    );
  }
}
