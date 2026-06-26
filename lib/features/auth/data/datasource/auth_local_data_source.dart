import '../../../../core/storage/storage_service.dart';
import '../../../../core/constants/storage_keys.dart';

abstract class AuthLocalDataSource {
  Future<void> saveAccessToken(String token);
  Future<String?> getAccessToken();
  Future<void> clearSession();
  Future<void> saveUserCache({
    required int id,
    required String name,
    required String email,
    required String role,
  });
  Future<Map<String, dynamic>?> getUserCache();
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  final StorageService _storage;

  AuthLocalDataSourceImpl(this._storage);

  @override
  Future<void> saveAccessToken(String token) async {
    await _storage.secureStorage.write(StorageKeys.token, token);
  }

  @override
  Future<String?> getAccessToken() async {
    return await _storage.secureStorage.read(StorageKeys.token);
  }

  @override
  Future<void> clearSession() async {
    await _storage.secureStorage.delete(StorageKeys.token);
    await _storage.preferenceStorage.remove(StorageKeys.userName);
    await _storage.preferenceStorage.remove(StorageKeys.userEmail);
    await _storage.preferenceStorage.remove(StorageKeys.userRole);
  }

  @override
  Future<void> saveUserCache({
    required int id,
    required String name,
    required String email,
    required String role,
  }) async {
    await _storage.preferenceStorage.setString(StorageKeys.userName, name);
    await _storage.preferenceStorage.setString(StorageKeys.userEmail, email);
    await _storage.preferenceStorage.setString(StorageKeys.userRole, role);
  }

  @override
  Future<Map<String, dynamic>?> getUserCache() async {
    final name = _storage.preferenceStorage.getString(StorageKeys.userName);
    final email = _storage.preferenceStorage.getString(StorageKeys.userEmail);
    final role = _storage.preferenceStorage.getString(StorageKeys.userRole);

    if (name == null || email == null || role == null) return null;
    return {'name': name, 'email': email, 'role': role};
  }
}
