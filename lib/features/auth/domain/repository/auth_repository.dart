import '../../../../core/network/api_result.dart';
import '../model/user_model.dart';

abstract class AuthRepository {
  Future<ApiResult<UserModel>> login({
    required String email,
    required String password,
  });

  Future<ApiResult<void>> logout();

  Future<ApiResult<UserModel>> me();

  Future<ApiResult<UserModel>> refreshSession();

  Future<bool> isLoggedIn();
}
