import '../../../../core/network/api_result.dart';
import '../../../../core/network/network_exception.dart';
import '../../../../core/storage/session_service.dart';
import '../../../../repositories/base_repository.dart';
import '../../domain/model/user_model.dart';
import '../../domain/repository/auth_repository.dart';
import '../datasource/auth_remote_data_source.dart';
import '../dto/login_request_dto.dart';
import '../dto/login_response_dto.dart';
import '../dto/user_response_dto.dart';
import '../mapper/user_mapper.dart';

class AuthRepositoryImpl extends BaseRepository implements AuthRepository {
  final AuthRemoteDataSource _remoteDataSource;
  final SessionService _sessionService;
  final UserMapper _userMapper;

  AuthRepositoryImpl({
    required AuthRemoteDataSource remoteDataSource,
    required SessionService sessionService,
    required UserMapper userMapper,
  }) : _remoteDataSource = remoteDataSource,
       _sessionService = sessionService,
       _userMapper = userMapper;

  @override
  Future<ApiResult<UserModel>> login({
    required String email,
    required String password,
  }) async {
    final request = LoginRequestDto(email: email, password: password);
    final result = await _remoteDataSource.login(request);

    if (result is ApiSuccess<LoginResponseDto>) {
      final responseDto = result.data;
      final token = responseDto.token;

      if (token == null || token.isEmpty) {
        return ApiFailure(
          UnknownException('Token login tidak ditemukan di response.'),
        );
      }

      // Temporarily store token so the me() call can use it.
      await _sessionService.saveSession(
        token: token,
        user: UserModel(id: 0, name: '', email: '', role: ''),
      );

      UserResponseDto? userDto = responseDto.user;
      if (userDto == null) {
        final meResult = await _remoteDataSource.me();
        if (meResult is ApiSuccess<UserResponseDto>) {
          userDto = meResult.data;
        } else if (meResult is ApiFailure<UserResponseDto>) {
          await _sessionService.clearSession();
          return ApiFailure(meResult.exception);
        }
      }

      if (userDto == null) {
        await _sessionService.clearSession();
        return ApiFailure(
          UnknownException('Gagal mendapatkan informasi user setelah login.'),
        );
      }

      String userRole = userDto.role ?? '';
      if (userRole.isEmpty) {
        userRole = (email == 'admin@gmail.com') ? 'admin' : 'user';
      }

      final userModel = UserModel(
        id: userDto.id ?? 0,
        name: userDto.name ?? 'User',
        email: userDto.email ?? email,
        role: userRole,
      );

      await _sessionService.saveSession(token: token, user: userModel);

      return ApiSuccess(userModel);
    } else if (result is ApiFailure<LoginResponseDto>) {
      return ApiFailure(result.exception);
    }

    return ApiFailure(UnknownException('Respon tidak dikenal.'));
  }

  @override
  Future<ApiResult<void>> logout() async {
    final result = await _remoteDataSource.logout();
    await _sessionService.clearSession();
    return result;
  }

  @override
  Future<ApiResult<UserModel>> me() async {
    return safeApiCall(
      apiCall: () => _remoteDataSource.me(),
      mapper: (dto) {
        final userModel = _userMapper.toModel(dto);
        _sessionService.saveSession(token: '', user: userModel);
        return userModel;
      },
    );
  }

  @override
  Future<ApiResult<UserModel>> refreshSession() async {
    return safeApiCall(
      apiCall: () => _remoteDataSource.refreshSession(),
      mapper: (dto) {
        final userModel = _userMapper.toModel(dto);
        _sessionService.saveSession(token: '', user: userModel);
        _sessionService.notifyTokenRefreshed();
        return userModel;
      },
    );
  }

  @override
  Future<bool> isLoggedIn() async {
    return await _sessionService.isLoggedIn();
  }
}
