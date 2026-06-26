import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/notification/providers/notification_provider.dart';
import '../features/detection/providers/detection_provider.dart';
import '../features/detection/widgets/detection_card.dart';
import '../features/detection/widgets/detection_timeline.dart';
import '../features/detection/widgets/detection_filter_bar.dart';
import '../features/detection/widgets/detection_gallery.dart';
import '../features/detection/widgets/detection_status_views.dart';

class DetectionScreen extends ConsumerStatefulWidget {
  const DetectionScreen({super.key});

  @override
  ConsumerState<DetectionScreen> createState() => _DetectionScreenState();
}

class _DetectionScreenState extends ConsumerState<DetectionScreen> {
  int _viewMode = 0; // 0: List, 1: Timeline, 2: Gallery

  @override
  Widget build(BuildContext context) {
    final notificationAsync = ref.watch(notificationProvider);
    final detectionState = ref.watch(detectionNotifierProvider);
    final detectionNotifier = ref.read(detectionNotifierProvider.notifier);

    final cameras = detectionState.allDetections
        .map((d) => {'id': d.cameraId, 'name': d.cameraName})
        .fold<List<Map<String, dynamic>>>([], (list, element) {
          if (!list.any((c) => c['id'] == element['id'])) {
            list.add(element);
          }
          return list;
        });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Deteksi'),
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
            icon: Icon(
              Icons.grid_view,
              color: _viewMode == 2 ? Colors.blue : null,
            ),
            onPressed: () => setState(() => _viewMode = 2),
          ),
        ],
      ),
      body: Column(
        children: [
          DetectionFilterBar(
            selectedCameraId: detectionState.filter.cameraId,
            selectedDate: detectionState.filter.date,
            showUnreadOnly: detectionState.filter.showUnreadOnly,
            cameras: cameras,
            onUnreadToggle: (_) => detectionNotifier.toggleShowUnreadOnly(),
            onCameraChanged: (id) => detectionNotifier.setCameraId(id),
            onSelectDate: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: detectionState.filter.date ?? DateTime.now(),
                firstDate: DateTime(2020),
                lastDate: DateTime.now().add(const Duration(days: 1)),
              );
              if (picked != null) {
                detectionNotifier.setDate(picked);
              }
            },
            onClearDate: () => detectionNotifier.setDate(null),
          ),
          Expanded(
            child: notificationAsync.when(
              loading: () => const DetectionLoading(),
              error: (err, _) => DetectionError(
                error: err.toString(),
                onRetry: () => detectionNotifier.refresh(),
              ),
              data: (_) {
                final list = detectionState.filteredDetections;
                if (list.isEmpty) {
                  return DetectionEmpty(
                    onAction: () => detectionNotifier.resetFilters(),
                  );
                }

                if (_viewMode == 0) {
                  return ListView.builder(
                    itemCount: list.length,
                    itemBuilder: (context, index) {
                      final item = list[index];
                      return DetectionCard(
                        detection: item,
                        onTap: () {
                          detectionNotifier.markAsRead(item.id);
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
                        onLongPress: () =>
                            detectionNotifier.markAsRead(item.id),
                      );
                    },
                  );
                } else if (_viewMode == 1) {
                  return DetectionTimeline(
                    detections: list,
                    onTap: (item) {
                      detectionNotifier.markAsRead(item.id);
                      if (item.imageUrl != null && item.imageUrl!.isNotEmpty) {
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
                } else {
                  return DetectionGallery(
                    detections: list,
                    onTap: (item, index) {
                      detectionNotifier.markAsRead(item.id);
                      if (item.imageUrl != null && item.imageUrl!.isNotEmpty) {
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
        ],
      ),
    );
  }
}
