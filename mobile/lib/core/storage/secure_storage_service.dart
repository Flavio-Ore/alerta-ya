import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:injectable/injectable.dart';

@lazySingleton
class SecureStorageService {
  const SecureStorageService();

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  Future<String?> read(String key) => _storage.read(key: key);

  Future<void> delete(String key) => _storage.delete(key: key);

  Future<void> deleteAll(List<String> keys) async {
    for (final key in keys) {
      await _storage.delete(key: key);
    }
  }
}
