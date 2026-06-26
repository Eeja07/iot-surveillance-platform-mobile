import 'package:flutter/material.dart';
import '../providers/ota_provider.dart';

class OTAStatusChip extends StatelessWidget {
  final OTAStatus status;
  final bool hasUpdate;

  const OTAStatusChip({
    super.key,
    required this.status,
    required this.hasUpdate,
  });

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color textColor;
    String label;

    if (status == OTAStatus.downloading) {
      bgColor = Colors.blue.withValues(alpha: 0.1);
      textColor = Colors.blue;
      label = 'Mengunduh';
    } else if (status == OTAStatus.flashing) {
      bgColor = Colors.orange.withValues(alpha: 0.1);
      textColor = Colors.orange;
      label = 'Memasang';
    } else if (status == OTAStatus.success) {
      bgColor = Colors.green.withValues(alpha: 0.1);
      textColor = Colors.green;
      label = 'Berhasil';
    } else if (status == OTAStatus.failed) {
      bgColor = Colors.red.withValues(alpha: 0.1);
      textColor = Colors.red;
      label = 'Gagal';
    } else if (hasUpdate) {
      bgColor = Colors.blue.withValues(alpha: 0.1);
      textColor = Colors.blue;
      label = 'Pembaruan Tersedia';
    } else {
      bgColor = Colors.grey.withValues(alpha: 0.1);
      textColor = Colors.grey;
      label = 'Versi Terbaru';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
