import 'package:flutter/material.dart';
import '../providers/ota_provider.dart';

class OTAProgressCard extends StatelessWidget {
  final OTAStatus status;
  final double progress;

  const OTAProgressCard({
    super.key,
    required this.status,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final isDownloading = status == OTAStatus.downloading;
    final title = isDownloading
        ? 'Mengunduh Firmware...'
        : 'Memasang Firmware...';
    final subtitle = isDownloading
        ? 'Mohon jangan matikan perangkat Anda.'
        : 'Perangkat sedang memasang pembaruan.';
    final percent = (progress * 100).toInt();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  '$percent%',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(
                isDownloading ? Colors.blue : Colors.orange,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
