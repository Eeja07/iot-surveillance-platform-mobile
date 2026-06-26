import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:MiotVision/core/di/providers.dart';
import 'package:MiotVision/core/di/repository_providers.dart';
import 'package:MiotVision/features/dashboard/providers/dashboard_provider.dart';
import 'package:MiotVision/models/camera_model.dart';
import 'session_provider_test.dart'; // import FakeSessionService

class FakeDashboardRepository implements DashboardRepository {
  List<CameraGroup> cameraGroups = [];
  bool shouldThrow = false;
  String? errorMessage;

  @override
  Future<List<CameraGroup>> fetchCameraGroups(String token) async {
    if (shouldThrow) {
      throw Exception(errorMessage ?? 'Fetch groups failed');
    }
    return cameraGroups;
  }

  @override
  Future<String?> getLatestImage(String token, String cameraId) async {
    return 'http://example.com/thumb_$cameraId.jpg';
  }
}

void main() {
  late FakeSessionService fakeSessionService;
  late FakeDashboardRepository fakeRepository;

  setUp(() {
    fakeSessionService = FakeSessionService();
    fakeRepository = FakeDashboardRepository();
  });

  group('DashboardProvider Tests', () {
    test(
      'initial state is unauthenticated (no token) -> empty state',
      () async {
        fakeSessionService.setLoggedIn(false);

        final container = ProviderContainer(
          overrides: [
            sessionServiceProvider.overrideWithValue(fakeSessionService),
            dashboardRepositoryProvider.overrideWithValue(fakeRepository),
          ],
        );
        addTearDown(container.dispose);

        // Initially loading
        expect(container.read(dashboardProvider) is AsyncLoading, true);

        final state = await container.read(dashboardProvider.future);
        expect(state.groups, isEmpty);
        expect(state.searchQuery, '');
      },
    );

    test('successful fetch updates state correctly', () async {
      fakeSessionService.setLoggedIn(true);
      fakeRepository.cameraGroups = [
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
      ];

      final container = ProviderContainer(
        overrides: [
          sessionServiceProvider.overrideWithValue(fakeSessionService),
          dashboardRepositoryProvider.overrideWithValue(fakeRepository),
        ],
      );
      addTearDown(container.dispose);

      final state = await container.read(dashboardProvider.future);
      expect(state.groups, hasLength(1));
      expect(state.groups.first.name, 'Living Room');
      expect(state.groups.first.cameras.first.name, 'Camera 1');
    });

    test('error state is handled correctly by AsyncValue', () async {
      fakeSessionService.setLoggedIn(true);
      fakeRepository.shouldThrow = true;
      fakeRepository.errorMessage = 'Network Error';

      final container = ProviderContainer(
        overrides: [
          sessionServiceProvider.overrideWithValue(fakeSessionService),
          dashboardRepositoryProvider.overrideWithValue(fakeRepository),
        ],
      );
      addTearDown(container.dispose);

      // Verify the stream returns an error
      final future = container.read(dashboardProvider.future);
      expect(future, throwsA(isA<Exception>()));

      try {
        await future;
      } catch (_) {}

      expect(container.read(dashboardProvider) is AsyncError, true);
      final errorState = container.read(dashboardProvider) as AsyncError;
      expect(errorState.error.toString(), contains('Network Error'));
    });

    test('setSearch filters groups correctly in state', () async {
      fakeSessionService.setLoggedIn(true);
      fakeRepository.cameraGroups = [
        CameraGroup(
          id: 1,
          name: 'Living Room',
          cameras: [
            Camera(id: 101, name: 'Interior Cam', groupName: 'Living Room'),
          ],
        ),
        CameraGroup(
          id: 2,
          name: 'Backyard',
          cameras: [
            Camera(id: 102, name: 'Outdoor Cam', groupName: 'Backyard'),
          ],
        ),
      ];

      final container = ProviderContainer(
        overrides: [
          sessionServiceProvider.overrideWithValue(fakeSessionService),
          dashboardRepositoryProvider.overrideWithValue(fakeRepository),
        ],
      );
      addTearDown(container.dispose);

      await container.read(dashboardProvider.future);

      // Initial filter is empty
      expect(
        container.read(dashboardProvider).value?.filteredGroups,
        hasLength(2),
      );

      // Filter by 'interior'
      container.read(dashboardProvider.notifier).setSearch('interior');
      var state = container.read(dashboardProvider).value!;
      expect(state.searchQuery, 'interior');
      expect(state.filteredGroups, hasLength(1));
      expect(state.filteredGroups.first.name, 'Living Room');

      // Clear search
      container.read(dashboardProvider.notifier).clearSearch();
      state = container.read(dashboardProvider).value!;
      expect(state.searchQuery, '');
      expect(state.filteredGroups, hasLength(2));
    });

    test('updateThumbnail updates specific camera correctly', () async {
      fakeSessionService.setLoggedIn(true);
      fakeRepository.cameraGroups = [
        CameraGroup(
          id: 1,
          name: 'Living Room',
          cameras: [
            Camera(id: 101, name: 'Interior Cam', groupName: 'Living Room'),
          ],
        ),
      ];

      final container = ProviderContainer(
        overrides: [
          sessionServiceProvider.overrideWithValue(fakeSessionService),
          dashboardRepositoryProvider.overrideWithValue(fakeRepository),
        ],
      );
      addTearDown(container.dispose);

      await container.read(dashboardProvider.future);

      // Verify no thumbnail URL originally
      expect(
        container
            .read(dashboardProvider)
            .value
            ?.groups
            .first
            .cameras
            .first
            .thumbnailUrl,
        isNull,
      );

      // Update thumbnail
      container
          .read(dashboardProvider.notifier)
          .updateThumbnail(101, 'http://new-thumbnail.png');

      final updatedState = container.read(dashboardProvider).value!;
      expect(updatedState.thumbnailCache[101], 'http://new-thumbnail.png');
      expect(
        updatedState.groups.first.cameras.first.thumbnailUrl,
        'http://new-thumbnail.png',
      );
    });

    test('regular vs silent refresh behaves correctly', () async {
      fakeSessionService.setLoggedIn(true);
      fakeRepository.cameraGroups = [
        CameraGroup(
          id: 1,
          name: 'Living Room',
          cameras: [
            Camera(id: 101, name: 'Interior Cam', groupName: 'Living Room'),
          ],
        ),
      ];

      final container = ProviderContainer(
        overrides: [
          sessionServiceProvider.overrideWithValue(fakeSessionService),
          dashboardRepositoryProvider.overrideWithValue(fakeRepository),
        ],
      );
      addTearDown(container.dispose);

      await container.read(dashboardProvider.future);

      // 1. Regular refresh -> goes into Loading state
      final regularFuture = container
          .read(dashboardProvider.notifier)
          .refresh(isSilent: false);
      expect(container.read(dashboardProvider) is AsyncLoading, true);
      await regularFuture;
      expect(container.read(dashboardProvider) is AsyncData, true);

      // 2. Silent refresh -> stays in Data state (no loading indicator)
      final silentFuture = container
          .read(dashboardProvider.notifier)
          .refresh(isSilent: true);
      expect(container.read(dashboardProvider) is AsyncData, true);
      await silentFuture;
      expect(container.read(dashboardProvider) is AsyncData, true);
    });
  });
}
