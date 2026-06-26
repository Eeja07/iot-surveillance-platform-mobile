import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FirmwareInfo {
  final String version;
  final String releaseNotes;
  final DateTime releaseDate;
  final String size;

  const FirmwareInfo({
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

class OTANotifier extends StateNotifier<OTAState> {
  Timer? _simulationTimer;

  OTANotifier()
    : super(
        OTAState(
          currentVersion: 'v1.2.0',
          availableUpdate: FirmwareInfo(
            version: 'v1.3.0',
            releaseNotes:
                '• Memperbaiki stabilitas koneksi WebSocket.\n• Menambahkan optimasi latensi feed video.\n• Patch keamanan enkripsi data.',
            releaseDate: DateTime.now().subtract(const Duration(days: 1)),
            size: '14.2 MB',
          ),
          status: OTAStatus.idle,
          progress: 0.0,
          history: [
            OTAHistoryEntry(
              version: 'v1.2.0',
              date: DateTime.now().subtract(const Duration(days: 30)),
              status: 'success',
            ),
            OTAHistoryEntry(
              version: 'v1.1.5',
              date: DateTime.now().subtract(const Duration(days: 60)),
              status: 'success',
            ),
          ],
        ),
      );

  Future<void> checkForUpdates() async {
    state = state.copyWith(isLoading: true);
    await Future.delayed(const Duration(seconds: 1));
    state = state.copyWith(
      isLoading: false,
      availableUpdate: FirmwareInfo(
        version: 'v1.3.0',
        releaseNotes:
            '• Memperbaiki stabilitas koneksi WebSocket.\n• Menambahkan optimasi latensi feed video.\n• Patch keamanan enkripsi data.',
        releaseDate: DateTime.now().subtract(const Duration(days: 1)),
        size: '14.2 MB',
      ),
    );
  }

  void startUpdate() {
    if (state.availableUpdate == null || state.status != OTAStatus.idle) return;

    state = state.copyWith(status: OTAStatus.downloading, progress: 0.0);

    _simulationTimer?.cancel();
    double currentProgress = 0.0;

    _simulationTimer = Timer.periodic(const Duration(milliseconds: 150), (
      timer,
    ) {
      if (state.status == OTAStatus.downloading) {
        currentProgress += 0.05;
        if (currentProgress >= 1.0) {
          state = state.copyWith(status: OTAStatus.flashing, progress: 0.0);
          currentProgress = 0.0;
        } else {
          state = state.copyWith(progress: currentProgress);
        }
      } else if (state.status == OTAStatus.flashing) {
        currentProgress += 0.08;
        if (currentProgress >= 1.0) {
          timer.cancel();
          final nextVersion = state.availableUpdate!.version;
          final updatedHistory = [
            OTAHistoryEntry(
              version: nextVersion,
              date: DateTime.now(),
              status: 'success',
            ),
            ...state.history,
          ];
          state = state.copyWith(
            currentVersion: nextVersion,
            status: OTAStatus.success,
            progress: 1.0,
            clearAvailableUpdate: true,
            history: updatedHistory,
          );
        } else {
          state = state.copyWith(progress: currentProgress);
        }
      }
    });
  }

  void resetStatus() {
    state = state.copyWith(status: OTAStatus.idle, progress: 0.0);
  }

  @override
  void dispose() {
    _simulationTimer?.cancel();
    super.dispose();
  }
}

final otaNotifierProvider = StateNotifierProvider<OTANotifier, OTAState>((ref) {
  return OTANotifier();
});
