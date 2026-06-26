import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';
import '../logger/app_logger.dart';
import '../logger/logger.dart';
import '../network/dio_client.dart';
import '../network/dio_interceptor.dart';
import '../storage/secure_storage.dart';
import '../storage/preference_storage.dart';
import '../storage/storage_service.dart';

class AppLocator {
  static final AppLocator instance = AppLocator._();
  AppLocator._();

  late final AppConfig config;
  late final Logger logger;
  late final SecureStorage secureStorage;
  late final PreferenceStorage preferenceStorage;
  late final StorageService storageService;
  late final DioInterceptor dioInterceptor;
  late final DioClient dioClient;

  Future<void> initialize() async {
    // 1. Setup config (Dev by default)
    config = AppConfig.dev;

    // 2. Setup logger
    logger = AppLogger();

    // 3. Setup storage
    secureStorage = SecureStorage();
    final sharedPrefs = await SharedPreferences.getInstance();
    preferenceStorage = PreferenceStorage(sharedPrefs);
    storageService = StorageService(
      secureStorage: secureStorage,
      preferenceStorage: preferenceStorage,
    );

    // 4. Setup network
    dioInterceptor = DioInterceptor(
      secureStorage: secureStorage,
      logger: logger,
    );
    dioClient = DioClient(config: config, interceptor: dioInterceptor);

    logger.info('AppLocator successfully initialized.');
  }
}
