import '../core/network/api_result.dart';
import '../core/network/dio_client.dart';
import '../core/network/network_exception.dart';
import '../features/ota/providers/ota_provider.dart';

class OtaRepository {
  final DioClient _client;

  const OtaRepository(this._client);

  /// Fetches the latest firmware info available.
  Future<ApiResult<FirmwareInfo>> fetchLatestFirmware() async {
    final result = await _client.get<Map<String, dynamic>>('/firmware/latest');
    if (result is ApiSuccess<Map<String, dynamic>>) {
      try {
        final data = result.data;
        final info = FirmwareInfo(
          id: data['id'] as int?,
          version: data['version'] as String? ?? 'Unknown',
          releaseNotes: data['release_notes'] as String? ?? '',
          releaseDate: data['created_at'] != null
              ? DateTime.tryParse(data['created_at'].toString()) ??
                    DateTime.now()
              : DateTime.now(),
          size:
              data['formatted_size'] as String? ??
              (data['size'] != null ? '${data['size']} bytes' : '0 MB'),
        );
        return ApiSuccess(info);
      } catch (e) {
        return ApiFailure(
          UnknownException('Gagal memproses data firmware: $e'),
        );
      }
    } else if (result is ApiFailure<Map<String, dynamic>>) {
      return ApiFailure(result.exception);
    }
    return ApiFailure(UnknownException('Respon tidak dikenal.'));
  }

  /// Fetches the OTA deployment history.
  Future<ApiResult<List<OTAHistoryEntry>>> fetchDeployments() async {
    final result = await _client.get<Map<String, dynamic>>('/ota/deployments');
    if (result is ApiSuccess<Map<String, dynamic>>) {
      try {
        final List<dynamic> data = result.data['data'] ?? [];
        final list = data.map((json) {
          return OTAHistoryEntry(
            version: json['target_version'] as String? ?? 'Unknown',
            date: json['created_at'] != null
                ? DateTime.tryParse(json['created_at'].toString()) ??
                      DateTime.now()
                : DateTime.now(),
            status: json['status'] as String? ?? 'unknown',
          );
        }).toList();
        return ApiSuccess(list);
      } catch (e) {
        return ApiFailure(
          UnknownException('Gagal memproses data riwayat OTA: $e'),
        );
      }
    } else if (result is ApiFailure<Map<String, dynamic>>) {
      return ApiFailure(result.exception);
    }
    return ApiFailure(UnknownException('Respon tidak dikenal.'));
  }

  /// Initiates an OTA deployment for a camera.
  Future<ApiResult<Map<String, dynamic>>> deployOta(
    int cameraId, {
    int? firmwareId,
    String? notes,
  }) async {
    final Map<String, dynamic> body = {};
    if (firmwareId != null) {
      body['firmware_id'] = firmwareId;
    }
    if (notes != null) {
      body['notes'] = notes;
    }

    final result = await _client.post<Map<String, dynamic>>(
      '/cameras/$cameraId/ota',
      data: body,
    );

    if (result is ApiSuccess<Map<String, dynamic>>) {
      return ApiSuccess(result.data);
    } else if (result is ApiFailure<Map<String, dynamic>>) {
      return ApiFailure(result.exception);
    }
    return ApiFailure(UnknownException('Respon tidak dikenal.'));
  }
}
