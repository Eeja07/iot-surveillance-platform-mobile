import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/di/repository_providers.dart';
import '../../../core/network/api_result.dart';
import '../../../features/dashboard/providers/dashboard_provider.dart';

class FirmwareInfo {
  final int? id;
  final String version;
  final String releaseNotes;
  final DateTime releaseDate;
  final String size;

  const FirmwareInfo({
    this.id,
    required this.version,
    required this.releaseNotes,
    required this.releaseDate,
    required this.size,
  });
}

class OTAHistoryEntry {
  final String version;
  final DateTime date;
  final String status;

  const OTAHistoryEntry({
    required this.version,
    required this.date,
    required this.status,
  });
}

enum OTAStatus { idle, downloading, flashing, success, failed }

class OTAState {
  final String currentVersion;
  final FirmwareInfo? availableUpdate;
  final OTAStatus status;
  final double progress;
  final String? errorMessage;
  final List<OTAHistoryEntry> history;
  final bool isLoading;

  const OTAState({
    required this.currentVersion,
    this.availableUpdate,
    required this.status,
    required this.progress,
    this.errorMessage,
    required this.history,
    this.isLoading = false,
  });

  OTAState copyWith({
    String? currentVersion,
    FirmwareInfo? availableUpdate,
    bool clearAvailableUpdate = false,
    OTAStatus? status,
    double? progress,
    String? errorMessage,
    bool clearErrorMessage = false,
    List<OTAHistoryEntry>? history,
    bool? isLoading,
  }) {
    return OTAState(
      currentVersion: currentVersion ?? this.currentVersion,
      availableUpdate: clearAvailableUpdate
          ? null
          : (availableUpdate ?? this.availableUpdate),
      status: status ?? this.status,
      progress: progress ?? this.progress,
      errorMessage: clearErrorMessage
          ? null
          : (errorMessage ?? this.errorMessage),
      history: history ?? this.history,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class OTANotifier extends AutoDisposeAsyncNotifier<OTAState> {
  static Duration pollingInterval = const Duration(seconds: 15);
  Timer? _pollingTimer;

  @override
  Future<OTAState> build() async {
    return _loadInitialState();
  }

  Future<OTAState> _loadInitialState() async {
    final repo = ref.read(otaRepositoryProvider);

    // Load latest firmware
    final fwResult = await repo.fetchLatestFirmware();
    FirmwareInfo? latestFw;
    if (fwResult is ApiSuccess<FirmwareInfo>) {
      latestFw = fwResult.data;
    } else if (fwResult is ApiFailure<FirmwareInfo>) {
      throw fwResult.exception;
    }

    // Load deployments history
    final historyResult = await repo.fetchDeployments();
    List<OTAHistoryEntry> history = [];
    if (historyResult is ApiSuccess<List<OTAHistoryEntry>>) {
      history = historyResult.data;
    } else if (historyResult is ApiFailure<List<OTAHistoryEntry>>) {
      throw historyResult.exception;
    }

    // Determine current version of the first camera in the dashboard (if online)
    // Or fallback to the latest successful deployment version, or default to 'v1.2.0'
    final latestSuccessDeployment = history.firstWhere(
      (e) => e.status == 'success',
      orElse: () => OTAHistoryEntry(
        version: 'v1.2.0',
        date: DateTime(2000),
        status: 'success',
      ),
    );
    final currentVersion = latestSuccessDeployment.version;

    // Check if update is available
    final availableUpdate =
        (latestFw != null && latestFw.version != currentVersion)
        ? latestFw
        : null;

    // Determine OTA status from the latest deployment in progress
    OTAStatus status = OTAStatus.idle;
    double progress = 0.0;
    final latestDeployment = history.firstOrNull;
    if (latestDeployment != null) {
      final s = latestDeployment.status.toLowerCase();
      if (s == 'pending' || s == 'running' || s == 'downloading') {
        status = OTAStatus.downloading;
        progress = 0.5;
        _startPolling();
      } else if (s == 'flashing') {
        status = OTAStatus.flashing;
        progress = 0.8;
        _startPolling();
      }
    }

    return OTAState(
      currentVersion: currentVersion,
      availableUpdate: availableUpdate,
      status: status,
      progress: progress,
      history: history,
    );
  }

  /// Exposed method to check for updates.
  Future<void> checkForUpdates() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _loadInitialState());
  }

  /// Exposed method to load latest firmware info.
  Future<FirmwareInfo?> loadFirmware() async {
    final repo = ref.read(otaRepositoryProvider);
    final result = await repo.fetchLatestFirmware();
    if (result is ApiSuccess<FirmwareInfo>) {
      return result.data;
    }
    return null;
  }

  /// Exposed method to load OTA deployments.
  Future<List<OTAHistoryEntry>> loadDeployments() async {
    final repo = ref.read(otaRepositoryProvider);
    final result = await repo.fetchDeployments();
    if (result is ApiSuccess<List<OTAHistoryEntry>>) {
      return result.data;
    }
    return [];
  }

  /// Exposed method to refresh all OTA state.
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _loadInitialState());
  }

  /// Exposed method to initiate an OTA deployment for a camera.
  Future<void> deploy(int cameraId, {int? firmwareId}) async {
    state = const AsyncLoading();
    final repo = ref.read(otaRepositoryProvider);
    final result = await repo.deployOta(cameraId, firmwareId: firmwareId);

    if (result is ApiSuccess<Map<String, dynamic>>) {
      // Successfully initiated deployment. Start polling for status.
      state = await AsyncValue.guard(() => _loadInitialState());
      _startPolling();
    } else if (result is ApiFailure<Map<String, dynamic>>) {
      throw result.exception;
    }
  }

  /// Triggered from the UI to start update on the first available camera.
  Future<void> startUpdate() async {
    final currentOtaState = state.valueOrNull;
    if (currentOtaState == null || currentOtaState.availableUpdate == null)
      return;

    final dashboard = ref.read(dashboardProvider).valueOrNull;
    final firstCam = dashboard?.groups.firstOrNull?.cameras.firstOrNull;
    if (firstCam == null) {
      throw Exception('Tidak ada kamera yang ditemukan di dashboard.');
    }

    final cameraId = int.tryParse(firstCam.id.toString()) ?? 0;
    await deploy(cameraId, firmwareId: currentOtaState.availableUpdate!.id);
  }

  void resetStatus() {
    final current = state.valueOrNull;
    if (current != null) {
      state = AsyncData(
        current.copyWith(status: OTAStatus.idle, progress: 0.0),
      );
    }
  }

  void _startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(pollingInterval, (timer) async {
      final current = state.valueOrNull;
      if (current == null) return;

      final repo = ref.read(otaRepositoryProvider);
      final historyResult = await repo.fetchDeployments();

      if (historyResult is ApiSuccess<List<OTAHistoryEntry>>) {
        final history = historyResult.data;
        final latestDeployment = history.firstOrNull;
        if (latestDeployment != null) {
          final s = latestDeployment.status.toLowerCase();
          OTAStatus status = OTAStatus.idle;
          double progress = 0.0;
          String? errorMessage;

          if (s == 'success' || s == 'completed') {
            status = OTAStatus.success;
            progress = 1.0;
            timer.cancel();
          } else if (s == 'failed') {
            status = OTAStatus.failed;
            progress = 0.0;
            errorMessage = 'Pembaruan gagal di perangkat.';
            timer.cancel();
          } else if (s == 'pending' || s == 'running' || s == 'downloading') {
            status = OTAStatus.downloading;
            progress = 0.5;
          } else if (s == 'flashing') {
            status = OTAStatus.flashing;
            progress = 0.8;
          }

          state = AsyncData(
            current.copyWith(
              status: status,
              progress: progress,
              errorMessage: errorMessage,
              history: history,
              currentVersion: status == OTAStatus.success
                  ? latestDeployment.version
                  : current.currentVersion,
              clearAvailableUpdate: status == OTAStatus.success,
            ),
          );
        } else {
          timer.cancel();
        }
      } else {
        // Keep polling even on failure
      }
    });
  }

  void stopPolling() {
    _pollingTimer?.cancel();
  }
}

final otaNotifierProvider =
    AsyncNotifierProvider.autoDispose<OTANotifier, OTAState>(
      OTANotifier.new,
      name: 'otaNotifierProvider',
    );
