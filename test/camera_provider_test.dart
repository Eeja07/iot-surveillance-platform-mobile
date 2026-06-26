import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:MiotVision/core/di/providers.dart';
import 'package:MiotVision/core/di/repository_providers.dart';
import 'package:MiotVision/features/camera/providers/camera_provider.dart';
import 'package:MiotVision/models/camera_model.dart';
import 'session_provider_test.dart'; // import FakeSessionService

class FakeCameraRepository implements CameraRepository {
  Map<String, dynamic> historyStatsResult = {};
  List<Map<String, dynamic>> historyImagesResult = [];
  String? latestImageUrl = 'http://example.com/latest.jpg';
  Map<String, dynamic> deleteCameraResult = {
    'success': true,
    'message': 'Camera deleted',
  };

  bool shouldThrow = false;
  String? errorMessage;

  @override
  Future<Map<String, dynamic>> getHistoryStats(
    String token,
    String cameraId, {
    String? date,
    String? hour,
  }) async {
    if (shouldThrow) throw Exception(errorMessage ?? 'Error');
    return historyStatsResult;
  }

  @override
  Future<List<Map<String, dynamic>>> getHistoryImages({
    required String token,
    required String cameraId,
    required String date,
    required String hour,
    required String minute,
  }) async {
    if (shouldThrow) throw Exception(errorMessage ?? 'Error');
    return historyImagesResult;
  }

  @override
  Future<String?> getLatestImage(String token, String cameraId) async {
    if (shouldThrow) throw Exception(errorMessage ?? 'Error');
    return latestImageUrl;
  }

  @override
  Future<Map<String, dynamic>> deleteCamera(
    String token,
    String cameraId,
  ) async {
    if (shouldThrow) throw Exception(errorMessage ?? 'Error');
    return deleteCameraResult;
  }
}

void main() {
  late FakeSessionService fakeSessionService;
  late FakeCameraRepository fakeRepository;
  late Camera testCamera;

  setUp(() {
    fakeSessionService = FakeSessionService();
    fakeRepository = FakeCameraRepository();
    testCamera = Camera(id: 101, name: 'Main Camera', groupName: 'Living Room');
  });

  group('CameraProvider Tests', () {
    test('initial state when unauthenticated -> returns empty state', () async {
      fakeSessionService.setLoggedIn(false);

      final container = ProviderContainer(
        overrides: [
          sessionServiceProvider.overrideWithValue(fakeSessionService),
          cameraRepositoryProvider.overrideWithValue(fakeRepository),
        ],
      );
      addTearDown(container.dispose);

      final state = await container.read(
        cameraDetailProvider(testCamera).future,
      );
      expect(state.datesWithRecords, isEmpty);
      expect(state.hoursWithRecords, isEmpty);
      expect(state.minutesWithRecords, isEmpty);
    });

    test('initial state when authenticated -> loads initial dates', () async {
      fakeSessionService.setLoggedIn(true);
      fakeRepository.historyStatsResult = {
        'items': [
          {'date_raw': '2026-06-25'},
          {'date_raw': '2026-06-26'},
        ],
      };

      final container = ProviderContainer(
        overrides: [
          sessionServiceProvider.overrideWithValue(fakeSessionService),
          cameraRepositoryProvider.overrideWithValue(fakeRepository),
        ],
      );
      addTearDown(container.dispose);

      final state = await container.read(
        cameraDetailProvider(testCamera).future,
      );
      expect(state.datesWithRecords, {'2026-06-25', '2026-06-26'});
      expect(state.hasRecordOnDate('2026-06-26'), true);
      expect(state.hasRecordOnDate('2026-06-27'), false);
    });

    test('loadHours loads hour statistics correctly', () async {
      fakeSessionService.setLoggedIn(true);
      fakeRepository.historyStatsResult = {
        'items': [
          {'hour_raw': '08', 'count': '12'},
          {'hour_raw': '09', 'count': '5'},
        ],
      };

      final container = ProviderContainer(
        overrides: [
          sessionServiceProvider.overrideWithValue(fakeSessionService),
          cameraRepositoryProvider.overrideWithValue(fakeRepository),
        ],
      );
      addTearDown(container.dispose);

      // Force resolution of initial state
      await container.read(cameraDetailProvider(testCamera).future);

      // Load hours
      await container
          .read(cameraDetailProvider(testCamera).notifier)
          .loadHours('2026-06-26');

      final state = container.read(cameraDetailProvider(testCamera)).value!;
      expect(state.hoursWithRecords[8], 12);
      expect(state.hoursWithRecords[9], 5);
      expect(state.hasRecordAtHour(8), true);
      expect(state.hasRecordAtHour(10), false);
    });

    test('loadMinutes loads minute statistics correctly', () async {
      fakeSessionService.setLoggedIn(true);
      fakeRepository.historyStatsResult = {
        'items': [
          {'minute_raw': '15', 'count': '2'},
          {'minute_raw': '30', 'count': '8'},
        ],
      };

      final container = ProviderContainer(
        overrides: [
          sessionServiceProvider.overrideWithValue(fakeSessionService),
          cameraRepositoryProvider.overrideWithValue(fakeRepository),
        ],
      );
      addTearDown(container.dispose);

      // Force resolution of initial state
      await container.read(cameraDetailProvider(testCamera).future);

      // Load minutes
      await container
          .read(cameraDetailProvider(testCamera).notifier)
          .loadMinutes('2026-06-26', 9);

      final state = container.read(cameraDetailProvider(testCamera)).value!;
      expect(state.minutesWithRecords[15], 2);
      expect(state.minutesWithRecords[30], 8);
      expect(state.hasRecordAtMinute(15), true);
      expect(state.hasRecordAtMinute(45), false);
    });

    test('loadImages loads images and respects caching', () async {
      fakeSessionService.setLoggedIn(true);
      fakeRepository.historyImagesResult = [
        {'id': 1, 'url': 'http://image1.jpg'},
      ];

      final container = ProviderContainer(
        overrides: [
          sessionServiceProvider.overrideWithValue(fakeSessionService),
          cameraRepositoryProvider.overrideWithValue(fakeRepository),
        ],
      );
      addTearDown(container.dispose);

      // Force resolution of initial state
      await container.read(cameraDetailProvider(testCamera).future);

      // Load images for 09:15
      await container
          .read(cameraDetailProvider(testCamera).notifier)
          .loadImages('2026-06-26', '09', '15');

      var state = container.read(cameraDetailProvider(testCamera)).value!;
      expect(state.imagesFor('09', '15'), hasLength(1));
      expect(state.imagesFor('09', '15')!.first['url'], 'http://image1.jpg');

      // Change repo output to verify cache hit doesn't trigger new call
      fakeRepository.historyImagesResult = [
        {'id': 2, 'url': 'http://image2.jpg'},
      ];

      // Load again without forceRefresh
      await container
          .read(cameraDetailProvider(testCamera).notifier)
          .loadImages('2026-06-26', '09', '15');
      state = container.read(cameraDetailProvider(testCamera)).value!;
      expect(
        state.imagesFor('09', '15')!.first['url'],
        'http://image1.jpg',
      ); // Cached value

      // Load with forceRefresh
      await container
          .read(cameraDetailProvider(testCamera).notifier)
          .loadImages('2026-06-26', '09', '15', forceRefresh: true);
      state = container.read(cameraDetailProvider(testCamera)).value!;
      expect(
        state.imagesFor('09', '15')!.first['url'],
        'http://image2.jpg',
      ); // Fresh value
    });

    test('refreshLatestThumbnail updates thumbnail URL correctly', () async {
      fakeSessionService.setLoggedIn(true);
      fakeRepository.latestImageUrl = 'http://example.com/new_latest.jpg';

      final container = ProviderContainer(
        overrides: [
          sessionServiceProvider.overrideWithValue(fakeSessionService),
          cameraRepositoryProvider.overrideWithValue(fakeRepository),
        ],
      );
      addTearDown(container.dispose);

      await container.read(cameraDetailProvider(testCamera).future);

      await container
          .read(cameraDetailProvider(testCamera).notifier)
          .refreshLatestThumbnail();

      final state = container.read(cameraDetailProvider(testCamera)).value!;
      expect(state.latestThumbnailUrl, 'http://example.com/new_latest.jpg');
    });

    test('deleteCamera returns correct result map', () async {
      fakeSessionService.setLoggedIn(true);
      fakeRepository.deleteCameraResult = {
        'success': true,
        'message': 'Deleted successfully',
      };

      final container = ProviderContainer(
        overrides: [
          sessionServiceProvider.overrideWithValue(fakeSessionService),
          cameraRepositoryProvider.overrideWithValue(fakeRepository),
        ],
      );
      addTearDown(container.dispose);

      await container.read(cameraDetailProvider(testCamera).future);

      final result = await container
          .read(cameraDetailProvider(testCamera).notifier)
          .deleteCamera();
      expect(result['success'], true);
      expect(result['message'], 'Deleted successfully');
    });
  });
}
