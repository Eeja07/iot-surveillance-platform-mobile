import 'storage_service.dart';

abstract class LocalDataSource {
  final StorageService storage;
  LocalDataSource(this.storage);
}
