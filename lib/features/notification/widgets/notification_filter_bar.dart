import 'package:flutter/material.dart';

class NotificationFilterBar extends StatelessWidget {
  final int? selectedCameraId;
  final bool showUnreadOnly;
  final List<Map<String, dynamic>> cameras;
  final ValueChanged<int?> onCameraChanged;
  final ValueChanged<bool> onUnreadToggle;
  final VoidCallback onReset;

  const NotificationFilterBar({
    super.key,
    required this.selectedCameraId,
    required this.showUnreadOnly,
    required this.cameras,
    required this.onCameraChanged,
    required this.onUnreadToggle,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            FilterChip(
              label: const Text('Belum Dibaca', style: TextStyle(fontSize: 12)),
              selected: showUnreadOnly,
              onSelected: onUnreadToggle,
              selectedColor: Colors.blue.withValues(alpha: 0.2),
              checkmarkColor: Colors.blue,
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(
                  color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int?>(
                  value: selectedCameraId,
                  hint: const Text(
                    'Semua Kamera',
                    style: TextStyle(fontSize: 12),
                  ),
                  icon: const Icon(Icons.arrow_drop_down, size: 18),
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                  items: [
                    const DropdownMenuItem<int?>(
                      value: null,
                      child: Text('Semua Kamera'),
                    ),
                    ...cameras.map((cam) {
                      return DropdownMenuItem<int?>(
                        value: cam['id'] as int?,
                        child: Text(cam['name'] as String),
                      );
                    }),
                  ],
                  onChanged: onCameraChanged,
                ),
              ),
            ),
            const SizedBox(width: 8),
            TextButton.icon(
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Reset', style: TextStyle(fontSize: 12)),
              onPressed: onReset,
            ),
          ],
        ),
      ),
    );
  }
}
