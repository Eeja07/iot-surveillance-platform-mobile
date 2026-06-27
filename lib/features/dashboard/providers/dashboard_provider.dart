// lib/features/dashboard/providers/dashboard_provider.dart
//
// DashboardProvider — Phase 4 Task 4 / Task 8
//
// Orchestrates dashboard data loading via Riverpod AsyncNotifier.
//
// Design contract:
// - CameraService is NOT modified — accessed via DashboardRepository bridge
// - SessionService is NOT modified — token retrieved via sessionServiceProvider
// - HomeScreen UI is NOT migrated in this task
// - GoRouter / AuthController / SessionService untouched
//
// Dependency: dashboardRepositoryProvider (repository_providers.dart)
//
// UI usage:
//   final dashboard = ref.watch(dashboardProvider);
//   dashboard.when(
//     data:    (s) => s.groups.isEmpty ? EmptyWidget() : GroupListWidget(s),
//     loading: () => CircularProgressIndicator(),
//     error:   (e, _) => ErrorWidget(e.toString()),
//   );

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/camera_model.dart';
import '../../../models/overview_model.dart';
import '../../../core/di/providers.dart';
import '../../../core/di/repository_providers.dart';
import '../../../core/network/api_result.dart';
import '../../../core/realtime/reverb_provider.dart';

// ---------------------------------------------------------------------------
// DashboardState — immutable value object
// ---------------------------------------------------------------------------

/// Immutable snapshot of the dashboard UI state.
///
/// [groups]         — filtered, non-empty camera groups ready for display.
/// [thumbnailCache] — camera-id → URL cache to survive list reloads.
/// [searchQuery]    — the current active search filter (empty = no filter).
///
/// All search/filter logic lives in [DashboardNotifier]; this class
/// is a plain data holder.
class DashboardState {
  final List<CameraGroup> groups;
  final Map<int, String> thumbnailCache;
  final String searchQuery;
  final OverviewModel? overview;

  const DashboardState({
    this.groups = const [],
    this.thumbnailCache = const {},
    this.searchQuery = '',
    this.overview,
  });

  /// Returns groups filtered by [searchQuery].
  /// When [searchQuery] is empty, returns all [groups].
  List<CameraGroup> get filteredGroups {
    if (searchQuery.isEmpty) return groups;

    final query = searchQuery.toLowerCase();
    final result = <CameraGroup>[];

    for (final group in groups) {
      final groupMatch = group.name.toLowerCase().contains(query);
      final matchingCameras = group.cameras.where((cam) {
        final nameMatch = cam.name.toLowerCase().contains(query);
        final descMatch =
            cam.description != null &&
            cam.description!.toLowerCase().contains(query);
        return nameMatch || descMatch;
      }).toList();

      if (groupMatch || matchingCameras.isNotEmpty) {
        result.add(
          CameraGroup(
            id: group.id,
            name: group.name,
            cameras: groupMatch ? group.cameras : matchingCameras,
            isExpanded: group.isExpanded,
          ),
        );
      }
    }
    return result;
  }

  /// Total number of cameras across all groups.
  int get totalCameras =>
      overview?.totalCameras ??
      groups.fold(0, (sum, g) => sum + g.cameras.length);

  /// Total number of online cameras across all groups.
  int get onlineCameras =>
      overview?.onlineCameras ??
      groups.fold(
        0,
        (sum, g) => sum + g.cameras.where((c) => c.isOnline).length,
      );

  DashboardState copyWith({
    List<CameraGroup>? groups,
    Map<int, String>? thumbnailCache,
    String? searchQuery,
    OverviewModel? overview,
  }) {
    return DashboardState(
      groups: groups ?? this.groups,
      thumbnailCache: thumbnailCache ?? this.thumbnailCache,
      searchQuery: searchQuery ?? this.searchQuery,
      overview: overview ?? this.overview,
    );
  }

  @override
  String toString() =>
      'DashboardState(groups: ${groups.length}, '
      'cameras: $totalCameras, query: "$searchQuery")';
}

// ---------------------------------------------------------------------------
// DashboardNotifier — AsyncNotifier
// ---------------------------------------------------------------------------

/// Manages dashboard data loading and state transitions.
///
/// Reads token from [sessionServiceProvider] (bridge — no SessionService change).
/// Reads camera data from [cameraServiceProvider]  (bridge — no service change).
///
/// Actions available to UI:
///   ref.read(dashboardProvider.notifier).refresh()
///   ref.read(dashboardProvider.notifier).setSearch(query)
///   ref.read(dashboardProvider.notifier).updateThumbnail(cameraId, url)
class DashboardNotifier extends AsyncNotifier<DashboardState> {
  @override
  Future<DashboardState> build() async {
    return _loadGroups();
  }

  // --------------------------------------------------------------------------
  // Public actions
  // --------------------------------------------------------------------------

  /// Reloads camera groups from the API.
  ///
  /// Sets state to loading then resolves with fresh data unless [isSilent] is true.
  Future<void> refresh({bool isSilent = false}) async {
    if (!isSilent) {
      state = const AsyncLoading();
    }
    state = await AsyncValue.guard(_loadGroups);
  }

  /// Applies a search filter to the current [DashboardState].
  ///
  /// Does NOT trigger a network call — filters in-memory data.
  void setSearch(String query) {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData(current.copyWith(searchQuery: query));
  }

  /// Clears the active search filter.
  void clearSearch() => setSearch('');

  /// Updates a single camera's thumbnail URL in the cache.
  ///
  /// Called after a successful [CameraService.getLatestImage] fetch.
  /// Does NOT reload the entire group list.
  void updateThumbnail(int cameraId, String url) {
    final current = state.valueOrNull;
    if (current == null) return;

    final newCache = Map<int, String>.from(current.thumbnailCache)
      ..[cameraId] = url;

    // Update groups list in-place so the thumbnail is immediately visible
    final updatedGroups = current.groups.map((group) {
      final updatedCameras = group.cameras.map((cam) {
        if (cam.id == cameraId) {
          return Camera(
            id: cam.id,
            name: cam.name,
            isOnline: cam.isOnline,
            groupName: cam.groupName,
            groupId: cam.groupId,
            deviceId: cam.deviceId,
            description: cam.description,
            thumbnailUrl: url,
            websocketChannelId: cam.websocketChannelId,
          );
        }
        return cam;
      }).toList();

      return CameraGroup(
        id: group.id,
        name: group.name,
        cameras: updatedCameras,
        isExpanded: group.isExpanded,
      );
    }).toList();

    state = AsyncData(
      current.copyWith(groups: updatedGroups, thumbnailCache: newCache),
    );
  }

  // --------------------------------------------------------------------------
  // Private helpers
  // --------------------------------------------------------------------------

  /// Fetches camera groups via [DashboardRepository], applies thumbnail cache,
  /// filters empty groups, fetches overview statistics, and returns a [DashboardState].
  Future<DashboardState> _loadGroups() async {
    final sessionService = ref.read(sessionServiceProvider);
    final token = await sessionService.getAccessToken();

    if (token == null || token.isEmpty) {
      // No token — return empty state rather than throwing.
      // GoRouter/RouterRedirect will handle redirection to login.
      return const DashboardState();
    }

    // Fetch camera groups
    final repository = ref.read(dashboardRepositoryProvider);
    final groups = await repository.fetchCameraGroups(token);

    // Fetch overview statistics
    final overviewRepo = ref.read(overviewRepositoryProvider);
    final overviewResult = await overviewRepo.fetchOverview();
    OverviewModel? overview;
    if (overviewResult is ApiSuccess<OverviewModel>) {
      overview = overviewResult.data;
    }

    // Preserve expansion state from previous load if state already has data
    final prevGroups = state.valueOrNull?.groups ?? [];
    final expansionMap = {for (final g in prevGroups) g.name: g.isExpanded};

    // Restore expansion states and thumbnail cache
    final cache = state.valueOrNull?.thumbnailCache ?? {};
    final processedGroups = groups.where((g) => g.cameras.isNotEmpty).map((g) {
      if (expansionMap.containsKey(g.name)) {
        g.isExpanded = expansionMap[g.name]!;
      }
      // Apply cached thumbnail for cameras missing one
      final updatedCameras = g.cameras.map((cam) {
        if ((cam.thumbnailUrl == null || cam.thumbnailUrl!.isEmpty) &&
            cache.containsKey(cam.id as int?)) {
          return Camera(
            id: cam.id,
            name: cam.name,
            isOnline: cam.isOnline,
            groupName: cam.groupName,
            groupId: cam.groupId,
            deviceId: cam.deviceId,
            description: cam.description,
            thumbnailUrl: cache[cam.id as int],
            websocketChannelId: cam.websocketChannelId,
          );
        }
        return cam;
      }).toList();

      return CameraGroup(
        id: g.id,
        name: g.name,
        cameras: updatedCameras,
        isExpanded: g.isExpanded,
      );
    }).toList();

    final currentQuery = state.valueOrNull?.searchQuery ?? '';

    // Get Reverb instance and loop cameras to subscribe
    final reverb = ref.read(reverbServiceProvider);
    for (final group in processedGroups) {
      for (final cam in group.cameras) {
        final channel = cam.websocketChannelId;
        if (channel != null && channel.isNotEmpty) {
          reverb.subscribeToCameraChannel(channel);
        }
      }
    }

    return DashboardState(
      groups: processedGroups,
      thumbnailCache: cache,
      searchQuery: currentQuery,
      overview: overview,
    );
  }
}

// ---------------------------------------------------------------------------
// Public provider
// ---------------------------------------------------------------------------

/// Watch this provider to reactively respond to dashboard state changes.
///
/// ```dart
/// // In a ConsumerWidget:
/// final dashboardAsync = ref.watch(dashboardProvider);
/// dashboardAsync.when(
///   data:    (s) => DashboardView(groups: s.filteredGroups),
///   loading: () => const CircularProgressIndicator(),
///   error:   (e, _) => ErrorView(message: e.toString()),
/// );
///
/// // Refresh:
/// ref.read(dashboardProvider.notifier).refresh();
///
/// // Filter:
/// ref.read(dashboardProvider.notifier).setSearch('Lantai 1');
/// ```
final dashboardProvider =
    AsyncNotifierProvider<DashboardNotifier, DashboardState>(
      DashboardNotifier.new,
      name: 'dashboardProvider',
    );

final overviewProvider = dashboardProvider;
final cameraProvider = dashboardProvider;
