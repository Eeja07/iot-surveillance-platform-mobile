import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DetectionFilterBar extends StatelessWidget {
  final int? selectedCameraId;
  final DateTime? selectedDate;
  final bool showUnreadOnly;
  final VoidCallback onSelectDate;
  final VoidCallback onClearDate;
  final ValueChanged<bool> onUnreadToggle;
  final List<Map<String, dynamic>> cameras;
  final ValueChanged<int?> onCameraChanged;

  const DetectionFilterBar({
    super.key,
    this.selectedCameraId,
    this.selectedDate,
    required this.showUnreadOnly,
    required this.onSelectDate,
    required this.onClearDate,
    required this.onUnreadToggle,
    required this.cameras,
    required this.onCameraChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          FilterChip(
            label: const Text('Belum Dibaca'),
            selected: showUnreadOnly,
            onSelected: onUnreadToggle,
            selectedColor: Colors.blue.withValues(alpha: 0.2),
            checkmarkColor: Colors.blue,
          ),
          const SizedBox(width: 8),
          InputChip(
            label: Text(
              selectedDate != null
                  ? DateFormat('dd MMM yyyy').format(selectedDate!)
                  : 'Pilih Tanggal',
            ),
            selected: selectedDate != null,
            onPressed: onSelectDate,
            onDeleted: selectedDate != null ? onClearDate : null,
            deleteIconColor: Colors.red,
            selectedColor: Colors.blue.withValues(alpha: 0.2),
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
        ],
      ),
    );
  }
}
