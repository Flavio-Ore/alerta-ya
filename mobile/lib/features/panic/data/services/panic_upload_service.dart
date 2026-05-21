import 'dart:io';

import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

@lazySingleton
class PanicUploadService {
  // Instancia propia sin interceptors ni baseUrl — el signed URL de GCS es autónomo
  final _dio = Dio();

  Future<void> uploadBlock(String signedUrl, String filePath) async {
    final bytes = await File(filePath).readAsBytes();
    await _dio.put(
      signedUrl,
      data: bytes,
      options: Options(
        headers: {'Content-Type': 'application/octet-stream'},
      ),
    );
  }
}
