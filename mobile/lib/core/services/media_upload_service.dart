import 'package:image_picker/image_picker.dart';
import 'package:injectable/injectable.dart';

import 'package:alertaya/core/services/firebase_storage_service.dart';

/// Sube evidencia (fotos/videos) de reportes ciudadanos a Firebase Storage.
/// El caller maneja excepciones si la subida falla.
@lazySingleton
class MediaUploadService {
  const MediaUploadService(this._storageService);

  final FirebaseStorageService _storageService;

  Future<List<String>> uploadReportMedia(
    List<XFile> files,
    String userId,
  ) async {
    return _storageService.uploadReportMedia(files, userId);
  }
}
