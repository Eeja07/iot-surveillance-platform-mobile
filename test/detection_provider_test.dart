import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:MiotVision/core/di/providers.dart';
import 'package:MiotVision/core/di/repository_providers.dart';
import 'package:MiotVision/features/notification/providers/notification_provider.dart';
import 'package:MiotVision/features/detection/providers/detection_provider.dart';
import 'package:MiotVision/repositories/detection_repository.dart';
import 'session_provider_test.dart';
import 'notification_provider_test.dart';

import 'package:intl/intl.dart';
import 'package:MiotVision/core/network/api_result.dart';

class FakeDetectionRepository implements DetectionRepository {
  List<CctvNotification> notifications = [];

  @override
  Future<ApiResult<List<CctvNotification>>> fetchDetectionEvents({
    int? cameraId,
    String? date,
    int page = 1,
    int perPage = 15,
  }) async {
    var list = notifications;
    if (cameraId != null) {
      list = list.where((item) => item.cameraId == cameraId).toList();
    }
    if (date != null) {
      list = list.where((item) {
        final dStr = DateFormat('yyyy-MM-dd').format(item.createdAt);
        return dStr == date;
      }).toList();
    }
    return ApiSuccess(list);
  }

  @override
  Future<ApiResult<List<CctvNotification>>> fetchMotionEvents({
    int? cameraId,
    String? date,
    int page = 1,
    int perPage = 15,
  }) async {
    return ApiSuccess([]);
  }
}

void main() {
  late FakeSessionService fakeSessionService;
  late FakeNotificationRepository fakeRepository;
  late FakeDetectionRepository fakeDetectionRepository;

  setUp(() {
    fakeSessionService = FakeSessionService();
    fakeRepository = FakeNotificationRepository();
    fakeDetectionRepository = FakeDetectionRepository();
  });

  group('DetectionProvider Tests', () {
    test('Initializes with empty state', () async {
      fakeSessionService.setLoggedIn(true);
      fakeDetectionRepository.notifications = [];

      final container = ProviderContainer(
        overrides: [
          sessionServiceProvider.overrideWithValue(fakeSessionService),
          notificationRepositoryProvider.overrideWithValue(fakeRepository),
          detectionRepositoryProvider.overrideWithValue(
            fakeDetectionRepository,
          ),
        ],
      );
      addTearDown(container.dispose);

      final state = await container.read(detectionNotifierProvider.future);
      expect(state.allDetections, isEmpty);
      expect(state.filteredDetections, isEmpty);
    });

    test('Loads notifications and filters correctly', () async {
      fakeSessionService.setLoggedIn(true);
      final date1 = DateTime(2026, 6, 27, 10, 0);
      final date2 = DateTime(2026, 6, 28, 12, 0);

      final list = [
        CctvNotification(
          id: '1',
          cameraId: 101,
          cameraName: 'Front Yard',
          message: 'Motion detected',
          createdAt: date1,
          isRead: false,
        ),
        CctvNotification(
          id: '2',
          cameraId: 102,
          cameraName: 'Backyard',
          message: 'Person detected',
          createdAt: date2,
          isRead: true,
        ),
      ];
      fakeRepository.notifications = list;
      fakeDetectionRepository.notifications = list;

      final container = ProviderContainer(
        overrides: [
          sessionServiceProvider.overrideWithValue(fakeSessionService),
          notificationRepositoryProvider.overrideWithValue(fakeRepository),
          detectionRepositoryProvider.overrideWithValue(
            fakeDetectionRepository,
          ),
        ],
      );
      addTearDown(container.dispose);

      // Trigger initial read
      final state = await container.read(detectionNotifierProvider.future);
      expect(state.allDetections, hasLength(2));
      expect(state.filteredDetections, hasLength(2));

      // Test Camera ID filtering
      await container.read(detectionNotifierProvider.notifier).setCameraId(101);
      final stateFilteredCam = container
          .read(detectionNotifierProvider)
          .requireValue;
      expect(stateFilteredCam.filteredDetections, hasLength(1));
      expect(stateFilteredCam.filter.cameraId, 101);

      // Test Reset Filter
      await container.read(detectionNotifierProvider.notifier).resetFilters();
      expect(
        container
            .read(detectionNotifierProvider)
            .requireValue
            .filteredDetections,
        hasLength(2),
      );

      // Test Unread Only filtering
      container.read(detectionNotifierProvider.notifier).toggleShowUnreadOnly();
      final stateFilteredUnread = container
          .read(detectionNotifierProvider)
          .requireValue;
      expect(stateFilteredUnread.filteredDetections, hasLength(1));
      expect(stateFilteredUnread.filteredDetections.first.id, '1');

      // Test Date filtering
      await container.read(detectionNotifierProvider.notifier).resetFilters();
      await container.read(detectionNotifierProvider.notifier).setDate(date2);
      final stateFilteredDate = container
          .read(detectionNotifierProvider)
          .requireValue;
      expect(stateFilteredDate.filteredDetections, hasLength(1));
      expect(stateFilteredDate.filteredDetections.first.id, '2');
    });
  });
}
