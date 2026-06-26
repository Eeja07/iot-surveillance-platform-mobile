import '../../../../core/network/api_result.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/network/network_exception.dart';
import '../../../../core/constants/api_constants.dart';
import '../dto/login_request_dto.dart';
import '../dto/login_response_dto.dart';
import '../dto/user_response_dto.dart';

abstract class AuthRemoteDataSource {
  Future<ApiResult<LoginResponseDto>> login(LoginRequestDto request);
  Future<ApiResult<void>> logout();
  Future<ApiResult<UserResponseDto>> me();
  Future<ApiResult<UserResponseDto>> refreshSession();
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final DioClient _client;

  AuthRemoteDataSourceImpl(this._client);

  @override
  Future<ApiResult<LoginResponseDto>> login(LoginRequestDto request) async {
    final result = await _client.post<dynamic>(
      ApiConstants.login,
      data: request.toJson(),
    );

    if (result is ApiSuccess<dynamic>) {
      try {
        final dataMap = result.data as Map<String, dynamic>;
        return ApiSuccess(LoginResponseDto.fromJson(dataMap));
      } catch (e) {
        return ApiFailure(UnknownException('Gagal memformat data login: $e'));
      }
    } else if (result is ApiFailure<dynamic>) {
      return ApiFailure(result.exception);
    }
    return ApiFailure(UnknownException('Respon tidak dikenal.'));
  }

  @override
  Future<ApiResult<void>> logout() async {
    try {
      final result = await _client.post<dynamic>('/logout');
      if (result is ApiSuccess) {
        return const ApiSuccess(null);
      } else if (result is ApiFailure) {
        return ApiFailure(result.exception);
      }
      return const ApiSuccess(null);
    } catch (_) {
      return const ApiSuccess(null);
    }
  }

  @override
  Future<ApiResult<UserResponseDto>> me() async {
    final result = await _client.get<dynamic>(ApiConstants.user);

    if (result is ApiSuccess<dynamic>) {
      try {
        final dataMap = result.data as Map<String, dynamic>;
        Map<String, dynamic> userMap = dataMap;
        if (dataMap.containsKey('data') &&
            dataMap['data'] is Map<String, dynamic>) {
          userMap = dataMap['data'] as Map<String, dynamic>;
        }
        return ApiSuccess(UserResponseDto.fromJson(userMap));
      } catch (e) {
        return ApiFailure(UnknownException('Gagal memformat data user: $e'));
      }
    } else if (result is ApiFailure<dynamic>) {
      return ApiFailure(result.exception);
    }
    return ApiFailure(UnknownException('Respon tidak dikenal.'));
  }

  @override
  Future<ApiResult<UserResponseDto>> refreshSession() async {
    return me();
  }
}
