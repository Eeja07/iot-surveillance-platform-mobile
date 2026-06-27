import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../notification/providers/notification_provider.dart';
import '../../../core/di/repository_providers.dart';
import '../../../core/network/api_result.dart';

class DetectionFilterState {
  final int? cameraId;
  final DateTime? date;
  final bool showUnreadOnly;

  const DetectionFilterState({
    this.cameraId,
    this.date,
    this.showUnreadOnly = false,
  });

  DetectionFilterState copyWith({
    int? cameraId,
    DateTime? date,
    bool? showUnreadOnly,
    bool clearCameraId = false,
    bool clearDate = false,
  }) {
    return DetectionFilterState(
      cameraId: clearCameraId ? null : (cameraId ?? this.cameraId),
      date: clearDate ? null : (date ?? this.date),
      showUnreadOnly: showUnreadOnly ?? this.showUnreadOnly,
    );
  }
}

class DetectionState {
  final DetectionFilterState filter;
  final List<CctvNotification> allDetections;
  final List<CctvNotification> filteredDetections;
  final int page;
  final bool hasMore;

  const DetectionState({
    required this.filter,
    required this.allDetections,
    required this.filteredDetections,
    this.page = 1,
    this.hasMore = true,
  });

  DetectionState copyWith({
    DetectionFilterState? filter,
    List<CctvNotification>? allDetections,
    List<CctvNotification>? filteredDetections,
    int? page,
    bool? hasMore,
  }) {
    return DetectionState(
      filter: filter ?? this.filter,
      allDetections: allDetections ?? this.allDetections,
      filteredDetections: filteredDetections ?? this.filteredDetections,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
    );
  }
}

class DetectionNotifier extends AsyncNotifier<DetectionState> {
  @override
  Future<DetectionState> build() async {
    return _loadData(page: 1, filter: const DetectionFilterState());
  }

  Future<DetectionState> _loadData({
    required int page,
    required DetectionFilterState filter,
    List<CctvNotification> existingDetections = const [],
  }) async {
    final repository = ref.read(detectionRepositoryProvider);
    final dateStr = filter.date != null
        ? DateFormat('yyyy-MM-dd').format(filter.date!)
        : null;

    final result = await repository.fetchDetectionEvents(
      cameraId: filter.cameraId,
      date: dateStr,
      page: page,
    );

    if (result is ApiSuccess<List<CctvNotification>>) {
      final newItems = result.data;
      final allItems = page == 1
          ? newItems
          : [...existingDetections, ...newItems];
      final filteredItems = _applyClientFilters(allItems, filter);

      return DetectionState(
        filter: filter,
        allDetections: allItems,
        filteredDetections: filteredItems,
        page: page,
        hasMore: newItems.isNotEmpty,
      );
    } else if (result is ApiFailure<List<CctvNotification>>) {
      throw result.exception;
    }

    throw Exception('Gagal memuat data deteksi.');
  }

  List<CctvNotification> _applyClientFilters(
    List<CctvNotification> list,
    DetectionFilterState filter,
  ) {
    var result = list;

    // Filter by unread locally if requested
    if (filter.showUnreadOnly) {
      result = result.where((item) => !item.isRead).toList();
    }

    return result;
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => build());
  }

  Future<void> loadNextPage() async {
    final current = state.valueOrNull;
    if (current == null || !current.hasMore || state.isLoading) return;

    state = await AsyncValue.guard(() async {
      return _loadData(
        page: current.page + 1,
        filter: current.filter,
        existingDetections: current.allDetections,
      );
    });
  }

  Future<void> setCameraId(int? id) async {
    final current =
        state.valueOrNull ??
        const DetectionState(
          filter: DetectionFilterState(),
          allDetections: [],
          filteredDetections: [],
        );
    final newFilter = current.filter.copyWith(
      cameraId: id,
      clearCameraId: id == null,
    );

    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _loadData(page: 1, filter: newFilter));
  }

  Future<void> setDate(DateTime? date) async {
    final current =
        state.valueOrNull ??
        const DetectionState(
          filter: DetectionFilterState(),
          allDetections: [],
          filteredDetections: [],
        );
    final newFilter = current.filter.copyWith(
      date: date,
      clearDate: date == null,
    );

    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _loadData(page: 1, filter: newFilter));
  }

  void toggleShowUnreadOnly() {
    final current = state.valueOrNull;
    if (current == null) return;

    final newFilter = current.filter.copyWith(
      showUnreadOnly: !current.filter.showUnreadOnly,
    );
    final filteredItems = _applyClientFilters(current.allDetections, newFilter);

    state = AsyncData(
      current.copyWith(filter: newFilter, filteredDetections: filteredItems),
    );
  }

  Future<void> resetFilters() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => _loadData(page: 1, filter: const DetectionFilterState()),
    );
  }

  Future<void> markAsRead(String id) async {
    final success = await ref
        .read(notificationProvider.notifier)
        .markAsRead(id);
    if (success) {
      final current = state.valueOrNull;
      if (current != null) {
        final updatedAll = current.allDetections.map((item) {
          if (item.id == id) {
            return item.copyWith(isRead: true);
          }
          return item;
        }).toList();

        final updatedFiltered = _applyClientFilters(updatedAll, current.filter);

        state = AsyncData(
          current.copyWith(
            allDetections: updatedAll,
            filteredDetections: updatedFiltered,
          ),
        );
      }
    }
  }
}

final detectionNotifierProvider =
    AsyncNotifierProvider<DetectionNotifier, DetectionState>(
      DetectionNotifier.new,
      name: 'detectionNotifierProvider',
    );

final detectionProvider = detectionNotifierProvider;
