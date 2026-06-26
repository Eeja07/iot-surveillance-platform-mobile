import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../providers/notification_provider.dart';

class NotificationTimeline extends StatelessWidget {
  final List<CctvNotification> notifications;
  final Function(CctvNotification) onTap;

  const NotificationTimeline({
    super.key,
    required this.notifications,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 16),
      itemCount: notifications.length,
      itemBuilder: (context, index) {
        final item = notifications[index];
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
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      dateStr,
                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 40,
                child: Stack(
                  alignment: Alignment.topCenter,
                  children: [
                    if (index != notifications.length - 1)
                      Container(width: 2, color: Colors.grey[300]),
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      width: 10,
                      height: 10,
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
                  margin: const EdgeInsets.only(right: 16, bottom: 12),
                  child: InkWell(
                    onTap: () => onTap(item),
                    child: Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.cameraName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item.message,
                            style: TextStyle(
                              fontSize: 11,
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
