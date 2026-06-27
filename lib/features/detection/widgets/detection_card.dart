import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../notification/providers/notification_provider.dart';

class DetectionCard extends StatelessWidget {
  final CctvNotification detection;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const DetectionCard({
    super.key,
    required this.detection,
    required this.onTap,
    this.onLongPress,
  });

  String _relativeTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'Baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes} menit lalu';
    if (diff.inHours < 24) return '${diff.inHours} jam lalu';
    if (diff.inDays < 7) return '${diff.inDays} hari lalu';
    return DateFormat('dd MMM yyyy').format(dt);
  }

  String _formatConfidence(String message) {
    // Extract confidence value like "87.5%" and format it
    final regex = RegExp(r'(\d+\.?\d*)\s*%');
    final match = regex.firstMatch(message);
    if (match != null) {
      final val = double.tryParse(match.group(1) ?? '');
      if (val != null) {
        return message.replaceFirst(
          match.group(0)!,
          '${val.toStringAsFixed(0)}%',
        );
      }
    }
    return message;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final timeAgo = _relativeTime(detection.createdAt);
    final absTime = DateFormat('HH:mm').format(detection.createdAt);
    final isUnread = !detection.isRead;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Material(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        elevation: isUnread ? 1 : 0,
        shadowColor: Colors.black.withValues(alpha: 0.08),
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Thumbnail
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: 88,
                    height: 88,
                    child: detection.imageUrl != null &&
                            detection.imageUrl!.isNotEmpty
                        ? Image.network(
                            detection.imageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: isDark
                                  ? Colors.grey[800]
                                  : Colors.grey[200],
                              child: const Icon(
                                Icons.broken_image_outlined,
                                color: Colors.grey,
                              ),
                            ),
                          )
                        : Container(
                            color:
                                isDark ? Colors.grey[800] : Colors.grey[200],
                            child: const Icon(
                              Icons.image_outlined,
                              color: Colors.grey,
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 12),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              detection.cameraName,
                              style: TextStyle(
                                fontWeight: isUnread
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                                fontSize: 14,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF1A1A2E),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (isUnread)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blue,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'Baru',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _formatConfidence(detection.message),
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.grey[300] : Colors.grey[700],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time_rounded,
                            size: 12,
                            color: isDark
                                ? Colors.grey[500]
                                : Colors.grey[500],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$timeAgo · $absTime',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark
                                  ? Colors.grey[500]
                                  : Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
