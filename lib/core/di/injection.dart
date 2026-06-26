import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';
import '../logger/app_logger.dart';
import '../logger/logger.dart';
import '../network/dio_client.dart';
import '../network/dio_interceptor.dart';
import '../storage/secure_storage.dart';
import '../storage/preference_storage.dart';
import '../storage/storage_service.dart';
import '../storage/session_service.dart';

// Module registrations
import '../../features/auth/auth_module.dart';
import '../../features/auth/data/datasource/auth_local_data_source.dart';
import '../../features/auth/data/datasource/auth_remote_data_source.dart';
import '../../features/auth/data/mapper/user_mapper.dart';
import '../../features/auth/domain/repository/auth_repository.dart';
import '../../features/auth/presentation/auth_controller.dart';

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

  // Global Session Service
  late final SessionService sessionService;

  // Feature dependencies registered via module classes
  late AuthLocalDataSource authLocalDataSource;
  late AuthRemoteDataSource authRemoteDataSource;
  late UserMapper userMapper;
  late AuthRepository authRepository;
  late AuthController authController;

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

    // 5. Setup session service
    final authLocalDS = AuthLocalDataSourceImpl(storageService);
    sessionService = SessionService(authLocalDS);

    // 6. Feature Modules Registration
    AuthModule.register();

    logger.info('AppLocator successfully initialized with SessionService.');
  }
}
