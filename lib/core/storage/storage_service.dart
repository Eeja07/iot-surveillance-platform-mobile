import 'secure_storage.dart';
import 'preference_storage.dart';

class StorageService {
  final SecureStorage secureStorage;
  final PreferenceStorage preferenceStorage;

  StorageService({
    required this.secureStorage,
    required this.preferenceStorage,
  });
}
