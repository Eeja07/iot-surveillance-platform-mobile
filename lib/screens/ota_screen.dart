import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/ota/providers/ota_provider.dart';
import '../features/ota/widgets/firmware_card.dart';
import '../features/ota/widgets/ota_progress_card.dart';
import '../features/ota/widgets/firmware_history.dart';
import '../features/ota/widgets/ota_status_views.dart';

class OTAScreen extends ConsumerWidget {
  const OTAScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stateAsync = ref.watch(otaNotifierProvider);
    final notifier = ref.read(otaNotifierProvider.notifier);

    ref.listen<AsyncValue<OTAState>>(otaNotifierProvider, (previous, next) {
      final prevVal = previous?.valueOrNull;
      final nextVal = next.valueOrNull;
      if (nextVal != null &&
          nextVal.status == OTAStatus.success &&
          prevVal?.status != OTAStatus.success) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green),
                SizedBox(width: 8),
                Text('Pembaruan Sukses'),
              ],
            ),
            content: Text(
              'Firmware berhasil diperbarui ke versi ${nextVal.currentVersion}. Perangkat Anda telah dimulai ulang dengan sukses.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  notifier.resetStatus();
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    });

    final otaState = stateAsync.valueOrNull;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pembaruan OTA'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: otaState == null || otaState.status == OTAStatus.idle
                ? () => notifier.refresh()
                : null,
          ),
        ],
      ),
      body: stateAsync.isLoading && otaState == null
          ? const OTALoading()
          : stateAsync.hasError && otaState == null
          ? Center(child: Text('Gagal memuat data OTA: ${stateAsync.error}'))
          : otaState == null
          ? const Center(child: Text('Tidak ada data.'))
          : Column(
              children: [
                FirmwareCard(
                  currentVersion: otaState.currentVersion,
                  availableUpdate: otaState.availableUpdate,
                  status: otaState.status,
                  onUpdatePressed: () => notifier.startUpdate(),
                ),
                if (otaState.status == OTAStatus.downloading ||
                    otaState.status == OTAStatus.flashing)
                  OTAProgressCard(
                    status: otaState.status,
                    progress: otaState.progress,
                  ),
                const SizedBox(height: 8),
                Expanded(child: FirmwareHistory(history: otaState.history)),
              ],
            ),
    );
  }
}
