import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../notification/providers/notification_provider.dart';

class DetectionTimeline extends StatelessWidget {
  final List<CctvNotification> detections;
  final Function(CctvNotification) onTap;

  const DetectionTimeline({
    super.key,
    required this.detections,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 16),
      itemCount: detections.length,
      itemBuilder: (context, index) {
        final item = detections[index];
        final timeStr = DateFormat('HH:mm').format(item.createdAt);
        final dateStr = DateFormat('dd MMM').format(item.createdAt);

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(width: 16),
              SizedBox(
                width: 55,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      timeStr,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      dateStr,
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 40,
                child: Stack(
                  alignment: Alignment.topCenter,
                  children: [
                    if (index != detections.length - 1)
                      Container(width: 2, color: Colors.grey[300]),
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: item.isRead ? Colors.grey : Colors.blue,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Card(
                  margin: const EdgeInsets.only(right: 16, bottom: 16),
                  child: InkWell(
                    onTap: () => onTap(item),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.cameraName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item.message,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
