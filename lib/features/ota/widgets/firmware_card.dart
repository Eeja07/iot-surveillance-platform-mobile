import 'package:flutter/material.dart';
import '../providers/ota_provider.dart';
import 'ota_status_chip.dart';

class FirmwareCard extends StatelessWidget {
  final String currentVersion;
  final FirmwareInfo? availableUpdate;
  final OTAStatus status;
  final VoidCallback onUpdatePressed;

  const FirmwareCard({
    super.key,
    required this.currentVersion,
    this.availableUpdate,
    required this.status,
    required this.onUpdatePressed,
  });

  @override
  Widget build(BuildContext context) {
    final hasUpdate = availableUpdate != null;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: (hasUpdate ? Colors.blue : Colors.green)
                            .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.router_outlined,
                        size: 20,
                        color: hasUpdate ? Colors.blue : Colors.green,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Firmware',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                        Text(
                          currentVersion,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                OTAStatusChip(status: status, hasUpdate: hasUpdate),
              ],
            ),

            if (hasUpdate && status == OTAStatus.idle) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.blue.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.system_update_alt_outlined,
                      color: Colors.blue,
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Pembaruan Tersedia — v${availableUpdate!.version}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              color: Colors.blue,
                            ),
                          ),
                          if (availableUpdate!.releaseNotes.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              availableUpdate!.releaseNotes,
                              style: TextStyle(
                                fontSize: 12,
                                color:
                                    isDark ? Colors.grey[400] : Colors.grey[600],
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: onUpdatePressed,
                  icon: const Icon(Icons.system_update_alt, size: 18),
                  label: const Text('Update Sekarang'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
