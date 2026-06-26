import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';

class CameraCalendarDialog extends StatefulWidget {
  final DateTime initialDate;
  final Set<String> datesWithRecords;

  const CameraCalendarDialog({
    super.key,
    required this.initialDate,
    required this.datesWithRecords,
  });

  @override
  State<CameraCalendarDialog> createState() => _CameraCalendarDialogState();
}

class _CameraCalendarDialogState extends State<CameraCalendarDialog> {
  late DateTime _displayDate;

  @override
  void initState() {
    super.initState();
    _displayDate = widget.initialDate;
  }

  @override
  Widget build(BuildContext context) {
    final daysInMonth = DateUtils.getDaysInMonth(
      _displayDate.year,
      _displayDate.month,
    );
    final firstDayOfMonth = DateTime(_displayDate.year, _displayDate.month, 1);
    final int weekdayOffset = firstDayOfMonth.weekday - 1;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;
    final subtitleColor = isDark ? Colors.grey[400] : Colors.grey[600];

    return AlertDialog(
      contentPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () => setState(
              () => _displayDate = DateTime(
                _displayDate.year,
                _displayDate.month - 1,
              ),
            ),
          ),
          Text(
            DateFormat('MMMM yyyy').format(_displayDate),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () => setState(
              () => _displayDate = DateTime(
                _displayDate.year,
                _displayDate.month + 1,
              ),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 320,
        height: 350,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: ['Sn', 'Sl', 'Rb', 'Km', 'Jm', 'Sb', 'Mg']
                  .map(
                    (d) => SizedBox(
                      width: 30,
                      child: Center(
                        child: Text(
                          d,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: subtitleColor,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 10),
            const Divider(),
            Expanded(
              child: GridView.builder(
                itemCount: daysInMonth + weekdayOffset,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                ),
                itemBuilder: (context, index) {
                  if (index < weekdayOffset) return const SizedBox();

                  final day = index - weekdayOffset + 1;
                  final date = DateTime(
                    _displayDate.year,
                    _displayDate.month,
                    day,
                  );
                  final dateKey = DateFormat('yyyy-MM-dd').format(date);

                  final hasRecord = widget.datesWithRecords.contains(dateKey);
                  final isSelected = DateUtils.isSameDay(
                    date,
                    widget.initialDate,
                  );
                  final isToday = DateUtils.isSameDay(date, DateTime.now());

                  return InkWell(
                    onTap: () => context.pop(date),
                    customBorder: const CircleBorder(),
                    child: Container(
                      margin: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected
                            ? Theme.of(context).primaryColor
                            : (isToday ? Colors.blue.withOpacity(0.1) : null),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Text(
                            '$day',
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : (isToday ? Colors.blue : textColor),
                              fontWeight: (isSelected || isToday)
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                          if (hasRecord)
                            Positioned(
                              bottom: 6,
                              child: Container(
                                width: 5,
                                height: 5,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.green,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.circle, size: 8, color: Colors.green),
                const SizedBox(width: 4),
                Text(
                  "= Ada Rekaman",
                  style: TextStyle(fontSize: 12, color: subtitleColor),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
