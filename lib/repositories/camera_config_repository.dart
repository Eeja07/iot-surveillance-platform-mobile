import '../core/network/api_result.dart';
import '../core/network/dio_client.dart';
import '../core/network/network_exception.dart';

class CameraConfig {
  final int jpegQuality;
  final String frameSize;
  final int captureIntervalMs;
  final int telemetryIntervalMs;
  final int mqttBuffer;
  final bool imageEnabled;
  final bool telemetryEnabled;
  final bool otaEnabled;

  const CameraConfig({
    required this.jpegQuality,
    required this.frameSize,
    required this.captureIntervalMs,
    required this.telemetryIntervalMs,
    required this.mqttBuffer,
    required this.imageEnabled,
    required this.telemetryEnabled,
    required this.otaEnabled,
  });

  factory CameraConfig.fromJson(Map<String, dynamic> json) {
    return CameraConfig(
      jpegQuality: (json['jpeg_quality'] as num?)?.toInt() ?? 20,
      frameSize: json['frame_size'] as String? ?? 'VGA',
      captureIntervalMs: (json['capture_interval_ms'] as num?)?.toInt() ?? 3000,
      telemetryIntervalMs:
          (json['telemetry_interval_ms'] as num?)?.toInt() ?? 3000,
      mqttBuffer: (json['mqtt_buffer'] as num?)?.toInt() ?? 32768,
      imageEnabled: json['image_enabled'] as bool? ?? true,
      telemetryEnabled: json['telemetry_enabled'] as bool? ?? true,
      otaEnabled: json['ota_enabled'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'jpeg_quality': jpegQuality,
      'frame_size': frameSize,
      'capture_interval_ms': captureIntervalMs,
      'telemetry_interval_ms': telemetryIntervalMs,
      'mqtt_buffer': mqttBuffer,
      'image_enabled': imageEnabled,
      'telemetry_enabled': telemetryEnabled,
      'ota_enabled': otaEnabled,
    };
  }

  CameraConfig copyWith({
    int? jpegQuality,
    String? frameSize,
    int? captureIntervalMs,
    int? telemetryIntervalMs,
    int? mqttBuffer,
    bool? imageEnabled,
    bool? telemetryEnabled,
    bool? otaEnabled,
  }) {
    return CameraConfig(
      jpegQuality: jpegQuality ?? this.jpegQuality,
      frameSize: frameSize ?? this.frameSize,
      captureIntervalMs: captureIntervalMs ?? this.captureIntervalMs,
      telemetryIntervalMs: telemetryIntervalMs ?? this.telemetryIntervalMs,
      mqttBuffer: mqttBuffer ?? this.mqttBuffer,
      imageEnabled: imageEnabled ?? this.imageEnabled,
      telemetryEnabled: telemetryEnabled ?? this.telemetryEnabled,
      otaEnabled: otaEnabled ?? this.otaEnabled,
    );
  }
}

class CameraConfigRepository {
  final DioClient _client;

  const CameraConfigRepository(this._client);

  Future<ApiResult<CameraConfig>> fetchConfig(int cameraId) async {
    final result = await _client.get<Map<String, dynamic>>(
      '/cameras/$cameraId/config',
    );
    if (result is ApiSuccess<Map<String, dynamic>>) {
      try {
        final data = result.data;
        final configJson = data['data'] as Map<String, dynamic>? ?? data;
        return ApiSuccess(CameraConfig.fromJson(configJson));
      } catch (e) {
        return ApiFailure(
          UnknownException('Gagal memproses data konfigurasi: $e'),
        );
      }
    } else if (result is ApiFailure<Map<String, dynamic>>) {
      return ApiFailure(result.exception);
    }
    return ApiFailure(UnknownException('Respon tidak dikenal.'));
  }

  Future<ApiResult<CameraConfig>> updateConfig(
    int cameraId,
    CameraConfig config,
  ) async {
    final result = await _client.put<Map<String, dynamic>>(
      '/cameras/$cameraId/config',
      data: config.toJson(),
    );
    if (result is ApiSuccess<Map<String, dynamic>>) {
      try {
        final data = result.data;
        final configJson = data['data'] as Map<String, dynamic>? ?? data;
        return ApiSuccess(CameraConfig.fromJson(configJson));
      } catch (e) {
        return ApiFailure(
          UnknownException('Gagal memproses data konfigurasi terupdate: $e'),
        );
      }
    } else if (result is ApiFailure<Map<String, dynamic>>) {
      return ApiFailure(result.exception);
    }
    return ApiFailure(UnknownException('Respon tidak dikenal.'));
  }

  Future<ApiResult<bool>> captureFrame(int cameraId) async {
    final result = await _client.post<Map<String, dynamic>>(
      '/cameras/$cameraId/capture',
    );
    if (result is ApiSuccess<Map<String, dynamic>>) {
      return const ApiSuccess(true);
    } else if (result is ApiFailure<Map<String, dynamic>>) {
      return ApiFailure(result.exception);
    }
    return ApiFailure(UnknownException('Respon tidak dikenal.'));
  }

  Future<ApiResult<bool>> rebootCamera(int cameraId) async {
    final result = await _client.post<Map<String, dynamic>>(
      '/cameras/$cameraId/reboot',
    );
    if (result is ApiSuccess<Map<String, dynamic>>) {
      return const ApiSuccess(true);
    } else if (result is ApiFailure<Map<String, dynamic>>) {
      return ApiFailure(result.exception);
    }
    return ApiFailure(UnknownException('Respon tidak dikenal.'));
  }
}
