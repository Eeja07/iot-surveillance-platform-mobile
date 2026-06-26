import 'package:flutter/material.dart';
import 'camera_gallery_grid.dart';
import 'camera_loading.dart';

class CameraHistorySection extends StatelessWidget {
  final ScrollController? controller;
  final List<String> minuteFolders;
  final int selectedHour;
  final Map<int, int> minutesWithRecords;
  final int? currentlyExpandedIndex;
  final Map<String, List<Map<String, dynamic>>> loadedImagesCache;
  final Map<String, bool> isLoadingMap;
  final Function(int index, bool expanded) onExpansionChanged;
  final String cameraName;

  const CameraHistorySection({
    super.key,
    this.controller,
    required this.minuteFolders,
    required this.selectedHour,
    required this.minutesWithRecords,
    this.currentlyExpandedIndex,
    required this.loadedImagesCache,
    required this.isLoadingMap,
    required this.onExpansionChanged,
    required this.cameraName,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: controller,
      itemCount: minuteFolders.length,
      itemBuilder: (context, index) {
        final minuteString = minuteFolders[index];
        final minuteInt = int.parse(minuteString);
        final hourString = selectedHour.toString().padLeft(2, '0');

        final countInData = minutesWithRecords[minuteInt];
        final hasData = countInData != null && countInData > 0;

        final isExpanded = index == currentlyExpandedIndex;
        final cacheKey = '$hourString:$minuteString';
        final images = loadedImagesCache[cacheKey];
        final isLoading = isLoadingMap[cacheKey] ?? false;

        final iconColor = hasData ? Colors.blue : Colors.grey;

        return ExpansionTile(
          leading: Icon(Icons.folder_outlined, color: iconColor),
          title: Text(
            'Pukul $hourString:$minuteString',
            style: TextStyle(
              fontWeight: hasData ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          subtitle: Text(
            images != null
                ? '${images.length} gambar dimuat'
                : (hasData ? '$countInData file tersedia' : '0 file'),
            style: TextStyle(
              fontSize: 12,
              color: hasData
                  ? (Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey[400]
                        : Colors.black54)
                  : Colors.grey,
            ),
          ),
          initiallyExpanded: isExpanded,
          onExpansionChanged: (expanded) => onExpansionChanged(index, expanded),
          children: [
            if (isLoading)
              const Padding(padding: EdgeInsets.all(20), child: CameraLoading())
            else if (images == null || images.isEmpty)
              const Padding(
                padding: EdgeInsets.all(20),
                child: Center(child: Text('Tidak ada gambar yang dimuat.')),
              )
            else
              CameraGalleryGrid(
                images: images,
                titleTime: '$hourString:$minuteString',
                cameraName: cameraName,
              ),
          ],
        );
      },
    );
  }
}
