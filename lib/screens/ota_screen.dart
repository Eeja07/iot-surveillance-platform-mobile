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
    final state = ref.watch(otaNotifierProvider);
    final notifier = ref.read(otaNotifierProvider.notifier);

    ref.listen<OTAState>(otaNotifierProvider, (previous, next) {
      if (next.status == OTAStatus.success &&
          previous?.status != OTAStatus.success) {
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
              'Firmware berhasil diperbarui ke versi ${next.currentVersion}. Perangkat Anda telah dimulai ulang dengan sukses.',
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pembaruan OTA'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: state.status == OTAStatus.idle
                ? () => notifier.checkForUpdates()
                : null,
          ),
        ],
      ),
      body: state.isLoading
          ? const OTALoading()
          : Column(
              children: [
                FirmwareCard(
                  currentVersion: state.currentVersion,
                  availableUpdate: state.availableUpdate,
                  status: state.status,
                  onUpdatePressed: () => notifier.startUpdate(),
                ),
                if (state.status == OTAStatus.downloading ||
                    state.status == OTAStatus.flashing)
                  OTAProgressCard(
                    status: state.status,
                    progress: state.progress,
                  ),
                const SizedBox(height: 8),
                Expanded(child: FirmwareHistory(history: state.history)),
              ],
            ),
    );
  }
}
