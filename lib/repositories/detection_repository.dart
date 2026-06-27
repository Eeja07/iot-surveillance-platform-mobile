import '../core/network/api_result.dart';
import '../core/network/dio_client.dart';
import '../core/network/network_exception.dart';
import '../features/notification/providers/notification_provider.dart';

class DetectionRepository {
  final DioClient _client;

  const DetectionRepository(this._client);

  /// Fetches paginated detection events.
  Future<ApiResult<List<CctvNotification>>> fetchDetectionEvents({
    int? cameraId,
    String? date,
    int page = 1,
    int perPage = 15,
  }) async {
    final Map<String, dynamic> queryParameters = {
      'page': page,
      'per_page': perPage,
    };
    if (cameraId != null) {
      queryParameters['camera_id'] = cameraId;
    }
    if (date != null) {
      queryParameters['date'] = date;
    }

    final result = await _client.get<Map<String, dynamic>>(
      '/detection-events',
      queryParameters: queryParameters,
    );

    if (result is ApiSuccess<Map<String, dynamic>>) {
      final List<dynamic> data = result.data['data'] ?? [];
      final list = data.map((json) {
        return CctvNotification(
          id: json['id']?.toString() ?? '',
          cameraId: json['camera_id'] as int? ?? 0,
          cameraName: json['camera_name'] as String? ?? 'Kamera',
          imageUrl: json['image_url'] as String?,
          message:
              'Objek terdeteksi (Confidence: ${(json['confidence'] as num?)?.toStringAsFixed(1) ?? '0.0'}%)',
          createdAt: json['detected_at'] != null
              ? DateTime.tryParse(json['detected_at'].toString()) ??
                    DateTime.now()
              : DateTime.now(),
          isRead: json['is_read'] as bool? ?? false,
        );
      }).toList();
      return ApiSuccess(list);
    } else if (result is ApiFailure<Map<String, dynamic>>) {
      return ApiFailure(result.exception);
    }
    return ApiFailure(UnknownException('Respon tidak dikenal.'));
  }

  /// Fetches paginated motion events.
  Future<ApiResult<List<CctvNotification>>> fetchMotionEvents({
    int? cameraId,
    String? date,
    int page = 1,
    int perPage = 15,
  }) async {
    final Map<String, dynamic> queryParameters = {
      'page': page,
      'per_page': perPage,
    };
    if (cameraId != null) {
      queryParameters['camera_id'] = cameraId;
    }
    if (date != null) {
      queryParameters['date'] = date;
    }

    final result = await _client.get<Map<String, dynamic>>(
      '/motion-events',
      queryParameters: queryParameters,
    );

    if (result is ApiSuccess<Map<String, dynamic>>) {
      final List<dynamic> data = result.data['data'] ?? [];
      final list = data.map((json) {
        final personConf = json['person_confidence'] as num?;
        final confStr = personConf != null
            ? ' (Person: ${personConf.toStringAsFixed(1)}%)'
            : '';
        return CctvNotification(
          id: json['id']?.toString() ?? '',
          cameraId: json['camera_id'] as int? ?? 0,
          cameraName: json['camera_name'] as String? ?? 'Kamera',
          imageUrl: json['image_url'] as String?,
          message:
              'Gerakan terdeteksi (Score: ${(json['motion_score'] as num?)?.toStringAsFixed(1) ?? '0.0'})$confStr',
          createdAt: json['detected_at'] != null
              ? DateTime.tryParse(json['detected_at'].toString()) ??
                    DateTime.now()
              : DateTime.now(),
          isRead: json['is_read'] as bool? ?? false,
        );
      }).toList();
      return ApiSuccess(list);
    } else if (result is ApiFailure<Map<String, dynamic>>) {
      return ApiFailure(result.exception);
    }
    return ApiFailure(UnknownException('Respon tidak dikenal.'));
  }
}
