import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CameraTimelineSelector extends StatelessWidget {
  final DateTime selectedDate;
  final int? selectedHour;
  final int? selectedMinute;
  final Map<int, int> hoursWithRecords;
  final Map<int, int> minutesWithRecords;
  final VoidCallback onDateTap;
  final ValueChanged<int?> onHourChanged;
  final ValueChanged<int?> onMinuteChanged;

  const CameraTimelineSelector({
    super.key,
    required this.selectedDate,
    this.selectedHour,
    this.selectedMinute,
    required this.hoursWithRecords,
    required this.minutesWithRecords,
    required this.onDateTap,
    required this.onHourChanged,
    required this.onMinuteChanged,
  });

  @override
  Widget build(BuildContext context) {
    final dateBtn = OutlinedButton.icon(
      icon: const Icon(Icons.calendar_today, size: 20),
      label: Text(DateFormat('dd MMM yyyy').format(selectedDate)),
      onPressed: onDateTap,
      style: OutlinedButton.styleFrom(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
      ),
    );

    final hourDrop = DropdownButtonFormField<int>(
      value: selectedHour,
      isExpanded: true,
      hint: const Text('Jam'),
      menuMaxHeight: 300,
      items: List.generate(24, (i) {
        final count = hoursWithRecords[i];
        final hasData = count != null && count > 0;
        return DropdownMenuItem(
          value: i,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(i.toString().padLeft(2, '0')),
              if (hasData)
                const Icon(Icons.circle, size: 8, color: Colors.green),
            ],
          ),
        );
      }),
      onChanged: onHourChanged,
      decoration: const InputDecoration(
        labelText: 'Jam',
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 10),
      ),
    );

    final minuteDrop = DropdownButtonFormField<int?>(
      value: selectedMinute,
      isExpanded: true,
      hint: const Text('Menit'),
      menuMaxHeight: 300,
      items: [
        const DropdownMenuItem<int?>(value: null, child: Text('Semua')),
        ...List.generate(60, (i) {
          final count = minutesWithRecords[i];
          final hasData = count != null && count > 0;
          return DropdownMenuItem(
            value: i,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(i.toString().padLeft(2, '0')),
                if (hasData)
                  const Icon(Icons.circle, size: 8, color: Colors.green),
              ],
            ),
          );
        }),
      ],
      onChanged: selectedHour == null ? null : onMinuteChanged,
      decoration: const InputDecoration(
        labelText: 'Menit',
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 10),
      ),
    );

    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                "Filter Perekaman",
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              Column(
                children: [
                  SizedBox(width: double.infinity, child: dateBtn),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: hourDrop),
                      const SizedBox(width: 12),
                      Expanded(child: minuteDrop),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
