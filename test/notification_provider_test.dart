import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:Mivion/core/di/providers.dart';
import 'package:Mivion/core/di/repository_providers.dart';
import 'package:Mivion/features/notification/providers/notification_provider.dart';
import 'session_provider_test.dart'; // import FakeSessionService

class FakeNotificationRepository implements NotificationRepository {
  List<CctvNotification> notifications = [];
  bool shouldThrow = false;
  String? errorMessage;
  bool markAsReadResult = true;

  @override
  Future<List<CctvNotification>> fetchNotifications() async {
    if (shouldThrow) throw Exception(errorMessage ?? 'Error');
    return notifications;
  }

  @override
  Future<bool> markAsRead(String id) async {
    if (shouldThrow) throw Exception(errorMessage ?? 'Error');
    return markAsReadResult;
  }
}

void main() {
  late FakeSessionService fakeSessionService;
  late FakeNotificationRepository fakeRepository;

  setUp(() {
    fakeSessionService = FakeSessionService();
    fakeRepository = FakeNotificationRepository();
  });

  group('NotificationProvider Model Tests', () {
    test('CctvNotification copyWith works correctly', () {
      final notification = CctvNotification(
        id: '1',
        cameraId: 10,
        cameraName: 'Camera 1',
        message: 'Movement detected',
        createdAt: DateTime(2026, 6, 27),
        isRead: false,
      );

      final updated = notification.copyWith(isRead: true);

      expect(updated.id, '1');
      expect(updated.cameraId, 10);
      expect(updated.cameraName, 'Camera 1');
      expect(updated.message, 'Movement detected');
      expect(updated.isRead, true);
    });

    test('NotificationState copyWith works correctly', () {
      const state = NotificationState(unreadCount: 5);
      final updated = state.copyWith(unreadCount: 10);
      expect(updated.unreadCount, 10);
    });
  });

  group('NotificationProvider Notifier Tests', () {
    test('initial state when unauthenticated -> returns empty state', () async {
      fakeSessionService.setLoggedIn(false);

      final container = ProviderContainer(
        overrides: [
          sessionServiceProvider.overrideWithValue(fakeSessionService),
          notificationRepositoryProvider.overrideWithValue(fakeRepository),
        ],
      );
      addTearDown(container.dispose);

      final state = await container.read(notificationProvider.future);
      expect(state.items, isEmpty);
      expect(state.unreadCount, 0);
    });

    test('successful fetch updates state correctly', () async {
      fakeSessionService.setLoggedIn(true);
      fakeRepository.notifications = [
        CctvNotification(
          id: '100',
          cameraId: 1,
          cameraName: 'Front Door',
          message: 'Motion detected',
          createdAt: DateTime.now(),
          isRead: false,
        ),
        CctvNotification(
          id: '101',
          cameraId: 2,
          cameraName: 'Back Door',
          message: 'Person detected',
          createdAt: DateTime.now(),
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

      final state = await container.read(notificationProvider.future);
      expect(state.items, hasLength(2));
      expect(state.unreadCount, 1);
      expect(state.items.first.cameraName, 'Front Door');
    });

    test('error state is propagated cleanly by AsyncValue', () async {
      fakeSessionService.setLoggedIn(true);
      fakeRepository.shouldThrow = true;
      fakeRepository.errorMessage = 'Notification Service Offline';

      final container = ProviderContainer(
        overrides: [
          sessionServiceProvider.overrideWithValue(fakeSessionService),
          notificationRepositoryProvider.overrideWithValue(fakeRepository),
        ],
      );
      addTearDown(container.dispose);

      final future = container.read(notificationProvider.future);
      expect(future, throwsA(isA<Exception>()));

      try {
        await future;
      } catch (_) {}

      expect(container.read(notificationProvider) is AsyncError, true);
      final errorState = container.read(notificationProvider) as AsyncError;
      expect(
        errorState.error.toString(),
        contains('Notification Service Offline'),
      );
    });

    test('markAsRead updates item status locally on success', () async {
      fakeSessionService.setLoggedIn(true);
      fakeRepository.notifications = [
        CctvNotification(
          id: '100',
          cameraId: 1,
          cameraName: 'Front Door',
          message: 'Motion detected',
          createdAt: DateTime.now(),
          isRead: false,
        ),
      ];
      fakeRepository.markAsReadResult = true;

      final container = ProviderContainer(
        overrides: [
          sessionServiceProvider.overrideWithValue(fakeSessionService),
          notificationRepositoryProvider.overrideWithValue(fakeRepository),
        ],
      );
      addTearDown(container.dispose);

      await container.read(notificationProvider.future);

      final success = await container
          .read(notificationProvider.notifier)
          .markAsRead('100');
      expect(success, true);

      final state = container.read(notificationProvider).value!;
      expect(state.unreadCount, 0);
      expect(state.items.first.isRead, true);
    });

    test('markAsRead does not update item status on failure', () async {
      fakeSessionService.setLoggedIn(true);
      fakeRepository.notifications = [
        CctvNotification(
          id: '100',
          cameraId: 1,
          cameraName: 'Front Door',
          message: 'Motion detected',
          createdAt: DateTime.now(),
          isRead: false,
        ),
      ];
      fakeRepository.markAsReadResult = false;

      final container = ProviderContainer(
        overrides: [
          sessionServiceProvider.overrideWithValue(fakeSessionService),
          notificationRepositoryProvider.overrideWithValue(fakeRepository),
        ],
      );
      addTearDown(container.dispose);

      await container.read(notificationProvider.future);

      final success = await container
          .read(notificationProvider.notifier)
          .markAsRead('100');
      expect(success, false);

      final state = container.read(notificationProvider).value!;
      expect(state.unreadCount, 1);
      expect(state.items.first.isRead, false);
    });

    test('regular vs silent refresh behaves correctly', () async {
      fakeSessionService.setLoggedIn(true);
      fakeRepository.notifications = [];

      final container = ProviderContainer(
        overrides: [
          sessionServiceProvider.overrideWithValue(fakeSessionService),
          notificationRepositoryProvider.overrideWithValue(fakeRepository),
        ],
      );
      addTearDown(container.dispose);

      await container.read(notificationProvider.future);

      // 1. Regular refresh -> goes to Loading
      final regularFuture = container
          .read(notificationProvider.notifier)
          .refresh(isSilent: false);
      expect(container.read(notificationProvider) is AsyncLoading, true);
      await regularFuture;
      expect(container.read(notificationProvider) is AsyncData, true);

      // 2. Silent refresh -> stays in Data state
      final silentFuture = container
          .read(notificationProvider.notifier)
          .refresh(isSilent: true);
      expect(container.read(notificationProvider) is AsyncData, true);
      await silentFuture;
      expect(container.read(notificationProvider) is AsyncData, true);
    });
  });
}
