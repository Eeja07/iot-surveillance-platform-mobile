import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../notification/providers/notification_provider.dart';

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

  const DetectionState({
    required this.filter,
    required this.allDetections,
    required this.filteredDetections,
  });

  DetectionState copyWith({
    DetectionFilterState? filter,
    List<CctvNotification>? allDetections,
    List<CctvNotification>? filteredDetections,
  }) {
    return DetectionState(
      filter: filter ?? this.filter,
      allDetections: allDetections ?? this.allDetections,
      filteredDetections: filteredDetections ?? this.filteredDetections,
    );
  }
}

class DetectionNotifier extends StateNotifier<DetectionState> {
  final Ref _ref;

  DetectionNotifier(this._ref)
    : super(
        const DetectionState(
          filter: DetectionFilterState(),
          allDetections: [],
          filteredDetections: [],
        ),
      ) {
    _ref.listen<AsyncValue<NotificationState>>(notificationProvider, (
      prev,
      next,
    ) {
      final value = next.valueOrNull;
      if (value != null) {
        _updateDetections(value.items);
      }
    }, fireImmediately: true);
  }

  void _updateDetections(List<CctvNotification> list) {
    state = state.copyWith(allDetections: list);
    _applyFilters();
  }

  void setCameraId(int? id) {
    state = state.copyWith(
      filter: state.filter.copyWith(cameraId: id, clearCameraId: id == null),
    );
    _applyFilters();
  }

  void setDate(DateTime? date) {
    state = state.copyWith(
      filter: state.filter.copyWith(date: date, clearDate: date == null),
    );
    _applyFilters();
  }

  void toggleShowUnreadOnly() {
    state = state.copyWith(
      filter: state.filter.copyWith(
        showUnreadOnly: !state.filter.showUnreadOnly,
      ),
    );
    _applyFilters();
  }

  void resetFilters() {
    state = state.copyWith(filter: const DetectionFilterState());
    _applyFilters();
  }

  void _applyFilters() {
    var list = state.allDetections;
    final filter = state.filter;

    if (filter.cameraId != null) {
      list = list.where((item) => item.cameraId == filter.cameraId).toList();
    }

    if (filter.date != null) {
      list = list.where((item) {
        return item.createdAt.year == filter.date!.year &&
            item.createdAt.month == filter.date!.month &&
            item.createdAt.day == filter.date!.day;
      }).toList();
    }

    if (filter.showUnreadOnly) {
      list = list.where((item) => !item.isRead).toList();
    }

    state = state.copyWith(filteredDetections: list);
  }

  Future<void> refresh() async {
    await _ref.read(notificationProvider.notifier).refresh();
  }

  Future<void> markAsRead(String id) async {
    await _ref.read(notificationProvider.notifier).markAsRead(id);
  }
}

final detectionNotifierProvider =
    StateNotifierProvider<DetectionNotifier, DetectionState>((ref) {
      return DetectionNotifier(ref);
    });
