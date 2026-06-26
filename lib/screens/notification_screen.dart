import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/notification/providers/notification_provider.dart';
import '../features/notification/widgets/notification_card.dart';
import '../features/notification/widgets/notification_filter_bar.dart';
import '../features/notification/widgets/notification_timeline.dart';
import '../features/notification/widgets/notification_status_views.dart';
import '../features/notification/widgets/notification_settings_sheet.dart';

class NotificationScreen extends ConsumerStatefulWidget {
  const NotificationScreen({super.key});

  @override
  ConsumerState<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends ConsumerState<NotificationScreen> {
  int _viewMode = 0; // 0: List, 1: Timeline
  int? _selectedCameraId;
  bool _showUnreadOnly = false;

  void _showSettings() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => const NotificationSettingsSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final notificationAsync = ref.watch(notificationProvider);
    final notifier = ref.read(notificationProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifikasi CCTV'),
        actions: [
          IconButton(
            icon: Icon(Icons.list, color: _viewMode == 0 ? Colors.blue : null),
            onPressed: () => setState(() => _viewMode = 0),
          ),
          IconButton(
            icon: Icon(
              Icons.timeline,
              color: _viewMode == 1 ? Colors.blue : null,
            ),
            onPressed: () => setState(() => _viewMode = 1),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _showSettings,
          ),
        ],
      ),
      body: Column(
        children: [
          notificationAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            data: (state) {
              final cameras = state.items
                  .map((d) => {'id': d.cameraId, 'name': d.cameraName})
                  .fold<List<Map<String, dynamic>>>([], (list, element) {
                    if (!list.any((c) => c['id'] == element['id'])) {
                      list.add(element);
                    }
                    return list;
                  });

              return NotificationFilterBar(
                selectedCameraId: _selectedCameraId,
                showUnreadOnly: _showUnreadOnly,
                cameras: cameras,
                onCameraChanged: (id) => setState(() => _selectedCameraId = id),
                onUnreadToggle: (val) => setState(() => _showUnreadOnly = val),
                onReset: () => setState(() {
                  _selectedCameraId = null;
                  _showUnreadOnly = false;
                }),
              );
            },
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => notifier.refresh(),
              child: notificationAsync.when(
                loading: () => const NotificationLoading(),
                error: (err, _) => NotificationError(
                  error: err.toString(),
                  onRetry: () => notifier.refresh(),
                ),
                data: (state) {
                  var filteredList = state.items;

                  if (_selectedCameraId != null) {
                    filteredList = filteredList
                        .where((item) => item.cameraId == _selectedCameraId)
                        .toList();
                  }

                  if (_showUnreadOnly) {
                    filteredList = filteredList
                        .where((item) => !item.isRead)
                        .toList();
                  }

                  if (filteredList.isEmpty) {
                    return NotificationEmpty(
                      onAction: () => setState(() {
                        _selectedCameraId = null;
                        _showUnreadOnly = false;
                      }),
                    );
                  }

                  if (_viewMode == 0) {
                    return ListView.builder(
                      itemCount: filteredList.length,
                      itemBuilder: (context, index) {
                        final item = filteredList[index];
                        return NotificationCard(
                          notification: item,
                          onTap: () {
                            notifier.markAsRead(item.id);
                            if (item.imageUrl != null &&
                                item.imageUrl!.isNotEmpty) {
                              context.push(
                                '/image-viewer',
                                extra: {
                                  'imageUrls': [item.imageUrl!],
                                  'initialIndex': 0,
                                  'title': item.cameraName,
                                  'cameraName': item.cameraName,
                                },
                              );
                            }
                          },
                          onMarkAsRead: () => notifier.markAsRead(item.id),
                        );
                      },
                    );
                  } else {
                    return NotificationTimeline(
                      notifications: filteredList,
                      onTap: (item) {
                        notifier.markAsRead(item.id);
                        if (item.imageUrl != null &&
                            item.imageUrl!.isNotEmpty) {
                          context.push(
                            '/image-viewer',
                            extra: {
                              'imageUrls': [item.imageUrl!],
                              'initialIndex': 0,
                              'title': item.cameraName,
                              'cameraName': item.cameraName,
                            },
                          );
                        }
                      },
                    );
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
