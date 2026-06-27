import '../core/network/api_result.dart';
import '../core/network/dio_client.dart';
import '../core/network/network_exception.dart';
import '../models/overview_model.dart';

class OverviewRepository {
  final DioClient _client;

  const OverviewRepository(this._client);

  /// Fetches aggregated overview dashboard statistics.
  Future<ApiResult<OverviewModel>> fetchOverview() async {
    final result = await _client.get<Map<String, dynamic>>('/overview');
    if (result is ApiSuccess<Map<String, dynamic>>) {
      try {
        final model = OverviewModel.fromJson(result.data);
        return ApiSuccess(model);
      } catch (e) {
        return ApiFailure(
          UnknownException('Gagal memproses data overview: $e'),
        );
      }
    } else if (result is ApiFailure<Map<String, dynamic>>) {
      return ApiFailure(result.exception);
    }
    return ApiFailure(UnknownException('Respon tidak dikenal.'));
  }
}
