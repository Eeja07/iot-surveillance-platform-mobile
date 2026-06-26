import '../core/network/api_result.dart';
import '../core/network/network_exception.dart';

abstract class BaseRepository {
  /// Execute a network call safely, catching any exceptions and mapping them to ApiResult.
  Future<ApiResult<Domain>> safeApiCall<Dto, Domain>({
    required Future<ApiResult<Dto>> Function() apiCall,
    required Domain Function(Dto dto) mapper,
  }) async {
    try {
      final result = await apiCall();
      if (result is ApiSuccess<Dto>) {
        return ApiSuccess(mapper(result.data));
      } else if (result is ApiFailure<Dto>) {
        return ApiFailure(result.exception);
      }
      return ApiFailure(UnknownException('Respon tidak dikenal.'));
    } catch (e) {
      return ApiFailure(
        UnknownException('Terjadi kesalahan pemetaan data: $e'),
      );
    }
  }
}
