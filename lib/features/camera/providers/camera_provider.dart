// lib/features/camera/providers/camera_provider.dart
//
// CameraProvider — Phase 4 Task 5 / Task 8
//
// Provides reactive state for a single camera's detail view.
//
// Design contract:
// - CameraService is NOT modified — accessed via CameraRepository bridge
// - SessionService is NOT modified — token read via sessionServiceProvider
// - CameraDetailScreen UI is NOT migrated in this task
// - GoRouter / AuthController / SessionService untouched
//
// Dependency: cameraRepositoryProvider (repository_providers.dart)
//
// Provider is parameterised (family) by [Camera] so each camera's state
// is kept independently.
//
// UI usage:
//   final cameraAsync = ref.watch(cameraDetailProvider(camera));
//   cameraAsync.when(
//     data:    (s) => CameraDetailView(state: s),
//     loading: () => const CircularProgressIndicator(),
//     error:   (e, _) => ErrorView(message: e.toString()),
//   );

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/camera_model.dart';
import '../../../core/di/providers.dart';
import '../../../core/di/repository_providers.dart';

// ---------------------------------------------------------------------------
// CameraDetailState — immutable value object
// ---------------------------------------------------------------------------

/// Immutable snapshot of a single camera's detail state.
///
/// [datesWithRecords]   — set of 'yyyy-MM-dd' strings with recordings.
/// [hoursWithRecords]   — map of hour (0-23) → frame count for selected date.
/// [minutesWithRecords] — map of minute (0-59) → frame count for selected hour.
/// [imagesCache]        — 'HH:mm' → list of image maps {id, url, captured_at}.
/// [latestThumbnailUrl] — most recent image URL for this camera (nullable).
class CameraDetailState {
  final Set<String> datesWithRecords;
  final Map<int, int> hoursWithRecords;
  final Map<int, int> minutesWithRecords;
  final Map<String, List<Map<String, dynamic>>> imagesCache;
  final String? latestThumbnailUrl;

  const CameraDetailState({
    this.datesWithRecords = const {},
    this.hoursWithRecords = const {},
    this.minutesWithRecords = const {},
    this.imagesCache = const {},
    this.latestThumbnailUrl,
  });

  /// Returns images cached for a given [hour] (HH) and [minute] (mm) string.
  List<Map<String, dynamic>>? imagesFor(String hour, String minute) =>
      imagesCache['$hour:$minute'];

  /// True if the given [dateKey] ('yyyy-MM-dd') has any recordings.
  bool hasRecordOnDate(String dateKey) => datesWithRecords.contains(dateKey);

  /// True if the given [hour] has any recordings on the selected date.
  bool hasRecordAtHour(int hour) => (hoursWithRecords[hour] ?? 0) > 0;

  /// True if the given [minute] has any recordings on the selected hour/date.
  bool hasRecordAtMinute(int minute) => (minutesWithRecords[minute] ?? 0) > 0;

  CameraDetailState copyWith({
    Set<String>? datesWithRecords,
    Map<int, int>? hoursWithRecords,
    Map<int, int>? minutesWithRecords,
    Map<String, List<Map<String, dynamic>>>? imagesCache,
    String? latestThumbnailUrl,
    bool clearThumbnail = false,
  }) {
    return CameraDetailState(
      datesWithRecords: datesWithRecords ?? this.datesWithRecords,
      hoursWithRecords: hoursWithRecords ?? this.hoursWithRecords,
      minutesWithRecords: minutesWithRecords ?? this.minutesWithRecords,
      imagesCache: imagesCache ?? this.imagesCache,
      latestThumbnailUrl: clearThumbnail
          ? null
          : (latestThumbnailUrl ?? this.latestThumbnailUrl),
    );
  }

  @override
  String toString() =>
      'CameraDetailState('
      'dates: ${datesWithRecords.length}, '
      'hours: ${hoursWithRecords.length}, '
      'minutes: ${minutesWithRecords.length}, '
      'cached: ${imagesCache.length})';
}

// ---------------------------------------------------------------------------
// CameraDetailNotifier — family AsyncNotifier
// ---------------------------------------------------------------------------

/// Manages all async data operations for a single [Camera] detail screen.
///
/// One notifier instance per [Camera] argument (via `.family`).
///
/// Actions available to UI:
///   ref.read(cameraDetailProvider(cam).notifier).loadDates()
///   ref.read(cameraDetailProvider(cam).notifier).loadHours(date)
///   ref.read(cameraDetailProvider(cam).notifier).loadMinutes(date, hour)
///   ref.read(cameraDetailProvider(cam).notifier).loadImages(date, hour, min)
///   ref.read(cameraDetailProvider(cam).notifier).refreshLatestThumbnail()
///   ref.read(cameraDetailProvider(cam).notifier).deleteCamera()
class CameraDetailNotifier
    extends FamilyAsyncNotifier<CameraDetailState, Camera> {
  // Held internally so actions can reference the family arg
  late Camera _camera;

  @override
  Future<CameraDetailState> build(Camera arg) async {
    _camera = arg;
    // Initial state: load available recording dates
    return _loadInitialDates();
  }

  // --------------------------------------------------------------------------
  // Public actions
  // --------------------------------------------------------------------------

  /// Loads dates that have recordings for this camera.
  Future<void> loadDates() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final fresh = await _loadInitialDates();
      final current = state.valueOrNull ?? const CameraDetailState();
      return current.copyWith(datesWithRecords: fresh.datesWithRecords);
    });
  }

  /// Loads hours with recordings for [dateStr] ('yyyy-MM-dd').
  Future<void> loadHours(String dateStr) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final token = await _getToken();
      if (token == null) throw Exception('Sesi tidak valid.');

      final result = await ref
          .read(cameraRepositoryProvider)
          .getHistoryStats(token, _camera.id.toString(), date: dateStr);

      final hours = <int, int>{};
      final items = result['items'];
      if (items is List) {
        for (final item in items) {
          final h = int.tryParse(item['hour_raw']?.toString() ?? '');
          final c = int.tryParse(item['count']?.toString() ?? '0');
          if (h != null) hours[h] = c ?? 0;
        }
      }

      final current = state.valueOrNull ?? const CameraDetailState();
      return current.copyWith(hoursWithRecords: hours);
    });
  }

  /// Loads minutes with recordings for [dateStr] and [hour].
  Future<void> loadMinutes(String dateStr, int hour) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final token = await _getToken();
      if (token == null) throw Exception('Sesi tidak valid.');

      final hourStr = hour.toString().padLeft(2, '0');
      final result = await ref
          .read(cameraRepositoryProvider)
          .getHistoryStats(
            token,
            _camera.id.toString(),
            date: dateStr,
            hour: hourStr,
          );

      final minutes = <int, int>{};
      final items = result['items'];
      if (items is List) {
        for (final item in items) {
          final m = int.tryParse(item['minute_raw']?.toString() ?? '');
          final c = int.tryParse(item['count']?.toString() ?? '0');
          if (m != null) minutes[m] = c ?? 0;
        }
      }

      final current = state.valueOrNull ?? const CameraDetailState();
      return current.copyWith(minutesWithRecords: minutes);
    });
  }

  /// Loads images for the given [dateStr], [hourStr] (HH), [minuteStr] (mm).
  ///
  /// Uses in-memory cache — skips network call if already loaded.
  /// Pass [forceRefresh] = true to bypass cache (e.g. background poll).
  Future<void> loadImages(
    String dateStr,
    String hourStr,
    String minuteStr, {
    bool forceRefresh = false,
  }) async {
    final cacheKey = '$hourStr:$minuteStr';
    final current = state.valueOrNull ?? const CameraDetailState();

    if (!forceRefresh && current.imagesCache.containsKey(cacheKey)) return;

    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final token = await _getToken();
      if (token == null) throw Exception('Sesi tidak valid.');

      final images = await ref
          .read(cameraRepositoryProvider)
          .getHistoryImages(
            token: token,
            cameraId: _camera.id.toString(),
            date: dateStr,
            hour: hourStr,
            minute: minuteStr,
          );

      final newCache = Map<String, List<Map<String, dynamic>>>.from(
        current.imagesCache,
      )..[cacheKey] = images;

      return current.copyWith(imagesCache: newCache);
    });
  }

  /// Fetches the latest thumbnail image URL for this camera.
  Future<void> refreshLatestThumbnail() async {
    state = await AsyncValue.guard(() async {
      final token = await _getToken();
      if (token == null) throw Exception('Sesi tidak valid.');

      final url = await ref
          .read(cameraRepositoryProvider)
          .getLatestImage(token, _camera.id.toString());

      final current = state.valueOrNull ?? const CameraDetailState();
      if (url != null) {
        return current.copyWith(latestThumbnailUrl: url);
      }
      return current;
    });
  }

  /// Deletes this camera via [CameraRepository].
  ///
  /// Returns a result map: `{'success': bool, 'message': String}`.
  Future<Map<String, dynamic>> deleteCamera() async {
    final token = await _getToken();
    if (token == null) {
      return {'success': false, 'message': 'Sesi tidak valid.'};
    }
    return ref
        .read(cameraRepositoryProvider)
        .deleteCamera(token, _camera.id.toString());
  }

  // --------------------------------------------------------------------------
  // Private helpers
  // --------------------------------------------------------------------------

  Future<CameraDetailState> _loadInitialDates() async {
    final token = await _getToken();
    if (token == null) return const CameraDetailState();

    final result = await ref
        .read(cameraRepositoryProvider)
        .getHistoryStats(token, _camera.id.toString());

    final dates = <String>{};
    final items = result['items'];
    if (items is List) {
      for (final item in items) {
        final d = item['date_raw']?.toString();
        if (d != null) dates.add(d);
      }
    }

    return CameraDetailState(datesWithRecords: dates);
  }

  Future<String?> _getToken() async {
    final sessionService = ref.read(sessionServiceProvider);
    return sessionService.getAccessToken();
  }
}

// ---------------------------------------------------------------------------
// Public provider
// ---------------------------------------------------------------------------

/// Watch this provider to reactively respond to camera detail state changes.
///
/// Parameterised by [Camera] — each camera gets its own isolated state.
///
/// ```dart
/// // In a ConsumerWidget receiving Camera as argument:
/// final cameraAsync = ref.watch(cameraDetailProvider(widget.camera));
/// cameraAsync.when(
///   data:    (s) => CameraDetailBody(state: s),
///   loading: () => const CircularProgressIndicator(),
///   error:   (e, _) => Text(e.toString()),
/// );
///
/// // Load hours when user selects a date:
/// await ref.read(cameraDetailProvider(camera).notifier).loadHours(dateStr);
///
/// // Load images when user expands a minute folder:
/// await ref.read(cameraDetailProvider(camera).notifier)
///     .loadImages(dateStr, hourStr, minuteStr);
/// ```
///
/// CameraService, SessionService, and GoRouter are NOT affected.
final cameraDetailProvider =
    AsyncNotifierProvider.family<
      CameraDetailNotifier,
      CameraDetailState,
      Camera
    >(CameraDetailNotifier.new, name: 'cameraDetailProvider');
