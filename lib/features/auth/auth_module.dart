import '../../core/di/injection.dart';
import 'data/datasource/auth_local_data_source.dart';
import 'data/datasource/auth_remote_data_source.dart';
import 'data/mapper/user_mapper.dart';
import 'data/repository/auth_repository_impl.dart';
import 'presentation/auth_controller.dart';

class AuthModule {
  static void register() {
    final locator = AppLocator.instance;

    locator.authLocalDataSource = AuthLocalDataSourceImpl(
      locator.storageService,
    );
    locator.authRemoteDataSource = AuthRemoteDataSourceImpl(locator.dioClient);
    locator.userMapper = UserMapper();
    locator.authRepository = AuthRepositoryImpl(
      remoteDataSource: locator.authRemoteDataSource,
      sessionService: locator.sessionService,
      userMapper: locator.userMapper,
    );
    locator.authController = AuthController(
      authRepository: locator.authRepository,
      sessionService: locator.sessionService,
    );
  }
}
