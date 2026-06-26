import 'package:flutter/material.dart';
import '../../notification/providers/notification_provider.dart';

class DetectionGallery extends StatelessWidget {
  final List<CctvNotification> detections;
  final Function(CctvNotification, int index) onTap;

  const DetectionGallery({
    super.key,
    required this.detections,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasImages = detections
        .where((d) => d.imageUrl != null && d.imageUrl!.isNotEmpty)
        .toList();

    if (hasImages.isEmpty) {
      return const Center(
        child: Text(
          'Tidak ada gambar deteksi tersedia.',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.3,
      ),
      itemCount: hasImages.length,
      itemBuilder: (context, index) {
        final item = hasImages[index];
        return GestureDetector(
          onTap: () => onTap(item, index),
          child: Card(
            clipBehavior: Clip.antiAlias,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.network(
                  item.imageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      const Center(child: Icon(Icons.broken_image)),
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    color: Colors.black54,
                    child: Text(
                      item.cameraName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
