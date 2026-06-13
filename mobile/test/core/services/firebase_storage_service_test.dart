import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:firebase_storage/firebase_storage.dart';

import 'package:alertaya/core/services/firebase_storage_service.dart';

class MockFirebaseStorage extends Mock implements FirebaseStorage {}

void main() {
  late MockFirebaseStorage mockStorage;
  late FirebaseStorageService service;

  setUp(() {
    mockStorage = MockFirebaseStorage();
    service = FirebaseStorageService(mockStorage);
  });

  group('uploadReportMedia', () {
    test('devuelve lista vacía cuando no hay archivos — sin llamar a Firebase', () async {
      final result = await service.uploadReportMedia([], 'user-123');
      expect(result, isEmpty);
      // Verificar que no se llamó ningún método en mockStorage
      verifyZeroInteractions(mockStorage);
    });
  });

  group('uploadPanicBlock', () {
    test('retorna silenciosamente cuando el archivo no existe — sin llamar a Firebase', () async {
      // '/ruta/que/no/existe.bin' no existe en el sistema de archivos
      await expectLater(
        service.uploadPanicBlock('/ruta/que/no/existe.bin', 'session-abc', 0),
        completes,
      );
      // Firebase nunca fue tocado
      verifyZeroInteractions(mockStorage);
    });
  });
}
