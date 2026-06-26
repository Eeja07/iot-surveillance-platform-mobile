import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../providers/notification_provider.dart';

class NotificationCard extends StatelessWidget {
  final CctvNotification notification;
  final VoidCallback onTap;
  final VoidCallback? onMarkAsRead;

  const NotificationCard({
    super.key,
    required this.notification,
    required this.onTap,
    this.onMarkAsRead,
  });

  @override
  Widget build(BuildContext context) {
    final timeStr = DateFormat('HH:mm').format(notification.createdAt);
    final dateStr = DateFormat('dd MMM yyyy').format(notification.createdAt);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: notification.isRead ? 1 : 3,
      color: notification.isRead
          ? (isDark ? Colors.grey[900] : Colors.grey[50])
          : (isDark ? Colors.grey[850] : Colors.white),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: notification.isRead
                ? Colors.grey.withValues(alpha: 0.1)
                : Colors.blue.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.notifications_active,
            color: notification.isRead ? Colors.grey : Colors.blue,
          ),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              notification.cameraName,
              style: TextStyle(
                fontWeight: notification.isRead
                    ? FontWeight.normal
                    : FontWeight.bold,
                fontSize: 14,
              ),
            ),
            Text(
              timeStr,
              style: TextStyle(fontSize: 11, color: Colors.grey[500]),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                notification.message,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.grey[300] : Colors.grey[700],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                dateStr,
                style: TextStyle(fontSize: 10, color: Colors.grey[500]),
              ),
            ],
          ),
        ),
        trailing: !notification.isRead && onMarkAsRead != null
            ? IconButton(
                icon: const Icon(
                  Icons.mark_chat_read_outlined,
                  size: 20,
                  color: Colors.blue,
                ),
                onPressed: onMarkAsRead,
              )
            : null,
      ),
    );
  }
}
