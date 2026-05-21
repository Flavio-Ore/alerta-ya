import 'package:injectable/injectable.dart';

import 'package:alertaya/core/storage/secure_storage_service.dart';

class TrustedContact {
  const TrustedContact({required this.name, required this.phone});
  final String name;
  final String phone;
}

const _kName = 'trusted_contact_name';
const _kPhone = 'trusted_contact_phone';

@lazySingleton
class TrustedContactService {
  const TrustedContactService(this._storage);
  final SecureStorageService _storage;

  Future<TrustedContact?> getContact() async {
    final name = await _storage.read(_kName);
    if (name == null || name.isEmpty) return null;
    final phone = await _storage.read(_kPhone) ?? '';
    return TrustedContact(name: name, phone: phone);
  }

  Future<void> saveContact(TrustedContact contact) => Future.wait([
        _storage.write(_kName, contact.name.trim()),
        _storage.write(_kPhone, contact.phone.trim()),
      ]);

  Future<void> clearContact() => _storage.deleteAll([_kName, _kPhone]);
}
