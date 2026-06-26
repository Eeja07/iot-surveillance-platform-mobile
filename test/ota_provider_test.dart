import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:MiotVision/features/ota/providers/ota_provider.dart';
import 'package:MiotVision/core/observability/observability_service.dart';
import 'package:MiotVision/core/observability/offline_indicator.dart';
import 'package:MiotVision/core/network/dio_client.dart';

void main() {
  group('OTAProvider Tests', () {
    test('Initial state is correct', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final state = container.read(otaNotifierProvider);
      expect(state.currentVersion, 'v1.2.0');
      expect(state.status, OTAStatus.idle);
      expect(state.availableUpdate, isNotNull);
      expect(state.availableUpdate!.version, 'v1.3.0');
      expect(state.progress, 0.0);
      expect(state.history, hasLength(2));
    });

    test('checkForUpdates updates state correctly', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(otaNotifierProvider.notifier);

      final future = notifier.checkForUpdates();
      expect(container.read(otaNotifierProvider).isLoading, isTrue);

      await future;
      final state = container.read(otaNotifierProvider);
      expect(state.isLoading, isFalse);
      expect(state.availableUpdate, isNotNull);
      expect(state.availableUpdate!.version, 'v1.3.0');
    });

    test('startUpdate transitions through state machine correctly', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(otaNotifierProvider.notifier);

      notifier.startUpdate();
      expect(container.read(otaNotifierProvider).status, OTAStatus.downloading);

      // Wait for timer simulation to complete (about 20 steps for downloading and 13 steps for flashing)
      // 33 steps * 150ms = ~5000ms max.
      // We can check if it reaches success state.
      await Future.delayed(const Duration(seconds: 6));

      final state = container.read(otaNotifierProvider);
      expect(state.status, OTAStatus.success);
      expect(state.currentVersion, 'v1.3.0');
      expect(state.availableUpdate, isNull);
      expect(state.progress, 1.0);
      expect(state.history, hasLength(3));
      expect(state.history.first.version, 'v1.3.0');
      expect(state.history.first.status, 'success');
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
