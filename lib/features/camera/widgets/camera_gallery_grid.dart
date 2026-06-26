import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CameraGalleryGrid extends StatelessWidget {
  final List<Map<String, dynamic>> images;
  final String titleTime;
  final String cameraName;

  const CameraGalleryGrid({
    super.key,
    required this.images,
    required this.titleTime,
    required this.cameraName,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16.0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8.0,
        mainAxisSpacing: 8.0,
      ),
      itemCount: images.length,
      itemBuilder: (context, index) {
        final imageUrl = images[index]['url'];
        return GestureDetector(
          onTap: () {
            final allUrls = images.map((e) => e['url'] as String).toList();
            context.push(
              '/image-viewer',
              extra: {
                'imageUrls': allUrls,
                'initialIndex': index,
                'title': titleTime,
                'cameraName': cameraName,
              },
            );
          },
          child: Card(
            clipBehavior: Clip.antiAlias,
            elevation: 2,
            child: Hero(
              tag: imageUrl,
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Icon(Icons.broken_image),
              ),
            ),
          ),
        );
      },
    );
  }
}
