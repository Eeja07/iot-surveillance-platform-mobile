import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:MiotVision/core/di/providers.dart';
import 'package:MiotVision/core/di/repository_providers.dart';
import 'package:MiotVision/features/notification/providers/notification_provider.dart';
import 'package:MiotVision/features/detection/providers/detection_provider.dart';
import 'session_provider_test.dart';
import 'notification_provider_test.dart';

void main() {
  late FakeSessionService fakeSessionService;
  late FakeNotificationRepository fakeRepository;

  setUp(() {
    fakeSessionService = FakeSessionService();
    fakeRepository = FakeNotificationRepository();
  });

  group('DetectionProvider Tests', () {
    test('Initializes with empty state', () async {
      fakeSessionService.setLoggedIn(true);
      fakeRepository.notifications = [];

      final container = ProviderContainer(
        overrides: [
          sessionServiceProvider.overrideWithValue(fakeSessionService),
          notificationRepositoryProvider.overrideWithValue(fakeRepository),
        ],
      );
      addTearDown(container.dispose);

      final state = container.read(detectionNotifierProvider);
      expect(state.allDetections, isEmpty);
      expect(state.filteredDetections, isEmpty);
    });

    test('Loads notifications and filters correctly', () async {
      fakeSessionService.setLoggedIn(true);
      final date1 = DateTime(2026, 6, 27, 10, 0);
      final date2 = DateTime(2026, 6, 28, 12, 0);

      fakeRepository.notifications = [
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

      final container = ProviderContainer(
        overrides: [
          sessionServiceProvider.overrideWithValue(fakeSessionService),
          notificationRepositoryProvider.overrideWithValue(fakeRepository),
        ],
      );
      addTearDown(container.dispose);

      // Trigger initial read
      await container.read(notificationProvider.future);

      final state = container.read(detectionNotifierProvider);
      expect(state.allDetections, hasLength(2));
      expect(state.filteredDetections, hasLength(2));

      // Test Camera ID filtering
      container.read(detectionNotifierProvider.notifier).setCameraId(101);
      final stateFilteredCam = container.read(detectionNotifierProvider);
      expect(stateFilteredCam.filteredDetections, hasLength(1));
      expect(stateFilteredCam.filteredDetections.first.cameraId, 101);

      // Test Reset Filter
      container.read(detectionNotifierProvider.notifier).resetFilters();
      expect(
        container.read(detectionNotifierProvider).filteredDetections,
        hasLength(2),
      );

      // Test Unread Only filtering
      container.read(detectionNotifierProvider.notifier).toggleShowUnreadOnly();
      final stateFilteredUnread = container.read(detectionNotifierProvider);
      expect(stateFilteredUnread.filteredDetections, hasLength(1));
      expect(stateFilteredUnread.filteredDetections.first.id, '1');

      // Test Date filtering
      container.read(detectionNotifierProvider.notifier).resetFilters();
      container.read(detectionNotifierProvider.notifier).setDate(date2);
      final stateFilteredDate = container.read(detectionNotifierProvider);
      expect(stateFilteredDate.filteredDetections, hasLength(1));
      expect(stateFilteredDate.filteredDetections.first.id, '2');
    });
  });
}
