import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/di/repository_providers.dart';
import '../../../repositories/camera_config_repository.dart';
import '../../../core/network/api_result.dart';

class CameraConfigNotifier
    extends AutoDisposeFamilyAsyncNotifier<CameraConfig, int> {
  @override
  FutureOr<CameraConfig> build(int arg) async {
    final repo = ref.read(cameraConfigRepositoryProvider);
    final result = await repo.fetchConfig(arg);
    if (result is ApiSuccess<CameraConfig>) {
      return result.data;
    } else if (result is ApiFailure<CameraConfig>) {
      throw result.exception;
    }
    throw Exception('Gagal memuat konfigurasi kamera.');
  }

  Future<void> updateConfig(CameraConfig newConfig) async {
    state = const AsyncLoading();
    final repo = ref.read(cameraConfigRepositoryProvider);
    final result = await repo.updateConfig(arg, newConfig);
    if (result is ApiSuccess<CameraConfig>) {
      state = AsyncData(result.data);
    } else if (result is ApiFailure<CameraConfig>) {
      state = AsyncError(result.exception, StackTrace.current);
      throw result.exception;
    }
  }

  Future<void> captureFrame() async {
    final repo = ref.read(cameraConfigRepositoryProvider);
    final result = await repo.captureFrame(arg);
    if (result is ApiFailure<bool>) {
      throw result.exception;
    }
  }

  Future<void> rebootCamera() async {
    final repo = ref.read(cameraConfigRepositoryProvider);
    final result = await repo.rebootCamera(arg);
    if (result is ApiFailure<bool>) {
      throw result.exception;
    }
  }
}

final cameraConfigProvider = AsyncNotifierProvider.autoDispose
    .family<CameraConfigNotifier, CameraConfig, int>(
      CameraConfigNotifier.new,
      name: 'cameraConfigProvider',
    );
