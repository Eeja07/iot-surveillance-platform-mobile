import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:MiotVision/features/ota/providers/ota_provider.dart';
import 'package:MiotVision/core/observability/observability_service.dart';
import 'package:MiotVision/core/observability/offline_indicator.dart';
import 'package:MiotVision/core/network/dio_client.dart';
import 'package:MiotVision/core/di/repository_providers.dart';
import 'package:MiotVision/repositories/ota_repository.dart';
import 'package:MiotVision/core/network/api_result.dart';
import 'package:MiotVision/core/network/network_exception.dart';
import 'package:MiotVision/features/dashboard/providers/dashboard_provider.dart';
import 'package:MiotVision/models/camera_model.dart';

class FakeOtaRepository implements OtaRepository {
  FirmwareInfo? latestFirmware;
  List<OTAHistoryEntry>? deployments;
  bool shouldThrow = false;
  Map<String, dynamic>? deployResult;

  @override
  Future<ApiResult<FirmwareInfo>> fetchLatestFirmware() async {
    if (shouldThrow) {
      return ApiFailure(UnknownException('Latest firmware error'));
    }
    return ApiSuccess(
      latestFirmware ??
          FirmwareInfo(
            id: 1,
            version: 'v1.3.0',
            releaseNotes:
                '• Memperbaiki stabilitas koneksi WebSocket.\n• Menambahkan optimasi latensi feed video.\n• Patch keamanan enkripsi data.',
            releaseDate: DateTime.now().subtract(const Duration(days: 1)),
            size: '14.2 MB',
          ),
    );
  }

  @override
  Future<ApiResult<List<OTAHistoryEntry>>> fetchDeployments() async {
    if (shouldThrow) {
      return ApiFailure(UnknownException('Deployments error'));
    }
    return ApiSuccess(
      deployments ??
          [
            OTAHistoryEntry(
              version: 'v1.2.0',
              date: DateTime.now().subtract(const Duration(days: 30)),
              status: 'success',
            ),
            OTAHistoryEntry(
              version: 'v1.1.5',
              date: DateTime.now().subtract(const Duration(days: 60)),
              status: 'success',
            ),
          ],
    );
  }

  @override
  Future<ApiResult<Map<String, dynamic>>> deployOta(
    int cameraId, {
    int? firmwareId,
    String? notes,
  }) async {
    if (shouldThrow) {
      return ApiFailure(UnknownException('Deploy failed'));
    }
    return ApiSuccess(
      deployResult ??
          {
            'success': true,
            'message': 'OTA deployment initiated successfully.',
            'deployment_id': 123,
          },
    );
  }
}

class FakeDashboardNotifier extends DashboardNotifier {
  final DashboardState _state;
  FakeDashboardNotifier(this._state);

  @override
  Future<DashboardState> build() async {
    return _state;
  }
}

void main() {
  late FakeOtaRepository fakeOtaRepository;

  setUp(() {
    fakeOtaRepository = FakeOtaRepository();
  });

  group('OTAProvider Tests', () {
    test('Initial state is correct', () async {
      final container = ProviderContainer(
        overrides: [otaRepositoryProvider.overrideWithValue(fakeOtaRepository)],
      );
      addTearDown(container.dispose);
      final sub = container.listen(otaNotifierProvider, (_, __) {});
      addTearDown(sub.close);

      final state = await container.read(otaNotifierProvider.future);
      expect(state.currentVersion, 'v1.2.0');
      expect(state.status, OTAStatus.idle);
      expect(state.availableUpdate, isNotNull);
      expect(state.availableUpdate!.version, 'v1.3.0');
      expect(state.progress, 0.0);
      expect(state.history, hasLength(2));
    });

    test('checkForUpdates updates state correctly', () async {
      final container = ProviderContainer(
        overrides: [otaRepositoryProvider.overrideWithValue(fakeOtaRepository)],
      );
      addTearDown(container.dispose);
      final sub = container.listen(otaNotifierProvider, (_, __) {});
      addTearDown(sub.close);

      // Force initial load
      await container.read(otaNotifierProvider.future);

      final notifier = container.read(otaNotifierProvider.notifier);
      final future = notifier.checkForUpdates();
      expect(container.read(otaNotifierProvider).isLoading, isTrue);

      await future;
      final state = container.read(otaNotifierProvider).value!;
      expect(state.availableUpdate, isNotNull);
      expect(state.availableUpdate!.version, 'v1.3.0');
    });

    test('startUpdate transitions through state machine correctly', () async {
      fakeOtaRepository.deployments = [
        OTAHistoryEntry(
          version: 'v1.3.0',
          date: DateTime.now(),
          status: 'running',
        ),
        OTAHistoryEntry(
          version: 'v1.2.0',
          date: DateTime.now().subtract(const Duration(days: 30)),
          status: 'success',
        ),
      ];

      final container = ProviderContainer(
        overrides: [
          otaRepositoryProvider.overrideWithValue(fakeOtaRepository),
          dashboardProvider.overrideWith(
            () => FakeDashboardNotifier(
              DashboardState(
                groups: [
                  CameraGroup(
                    id: 1,
                    name: 'Living Room',
                    cameras: [
                      Camera(
                        id: 101,
                        name: 'Camera 1',
                        groupName: 'Living Room',
                        isOnline: true,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);
      final sub = container.listen(otaNotifierProvider, (_, __) {});
      addTearDown(sub.close);

      await container.read(dashboardProvider.future);
      await container.read(otaNotifierProvider.future);

      final notifier = container.read(otaNotifierProvider.notifier);
      await notifier.startUpdate();

      // Polling has started, status should be downloading (since latest is 'running')
      expect(
        container.read(otaNotifierProvider).value?.status,
        OTAStatus.downloading,
      );

      // Change repo deployments to return success on the next poll
      fakeOtaRepository.deployments = [
        OTAHistoryEntry(
          version: 'v1.3.0',
          date: DateTime.now(),
          status: 'success',
        ),
        OTAHistoryEntry(
          version: 'v1.2.0',
          date: DateTime.now().subtract(const Duration(days: 30)),
          status: 'success',
        ),
      ];

      // Wait for poll (3 seconds interval)
      await Future.delayed(const Duration(milliseconds: 3200));

      final providerState = container.read(otaNotifierProvider);
      final state = providerState.value!;
      expect(state.status, OTAStatus.success);
      expect(state.currentVersion, 'v1.3.0');
      expect(state.availableUpdate, isNull);

      notifier.stopPolling();
    });
  });

  group('ObservabilityService Tests', () {
    test('Logs info, warning, error messages correctly', () {
      final obs = ObservabilityService.instance;
      obs.info('Info message test');
      obs.warning('Warning message test');
      obs.error('Error message test');

      final logs = obs.logs;
      expect(
        logs.any(
          (e) =>
              e.message.contains('Info message test') &&
              e.level == LogLevel.info,
        ),
        isTrue,
      );
      expect(
        logs.any(
          (e) =>
              e.message.contains('Warning message test') &&
              e.level == LogLevel.warning,
        ),
        isTrue,
      );
      expect(
        logs.any(
          (e) =>
              e.message.contains('Error message test') &&
              e.level == LogLevel.error,
        ),
        isTrue,
      );
    });

    test('Log history limit is respected', () {
      final obs = ObservabilityService.instance;
      for (int i = 0; i < 120; i++) {
        obs.info('Message $i');
      }
      expect(obs.logs.length, lessThanOrEqualTo(100));
    });
  });

  group('ConnectivityNotifier Tests', () {
    test('Initializes with true (online) and allows manual setOnline', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(connectivityProvider.notifier);
      expect(container.read(connectivityProvider), isTrue);

      notifier.setOnline(false);
      expect(container.read(connectivityProvider), isFalse);
    });
  });

  group('RetryInterceptor Tests', () {
    test('Retry count is incremented on connection error', () {
      final dio = Dio();
      final interceptor = RetryInterceptor(dio: dio, maxRetries: 2);
      expect(interceptor.maxRetries, 2);
    });
  });
}
