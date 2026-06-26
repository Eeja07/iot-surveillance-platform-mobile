import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../config/app_colors.dart';
import '../../../core/router/app_routes.dart';
import '../../../models/camera_model.dart';

class CameraTile extends StatelessWidget {
  final Camera camera;
  final bool isHorizontal;
  final VoidCallback onLongPress;

  const CameraTile({
    super.key,
    required this.camera,
    this.isHorizontal = false,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final double? cardWidth = isHorizontal ? 160 : null;
    final Color statusColor = camera.isOnline
        ? AppColors.success
        : AppColors.danger;

    return SizedBox(
      width: cardWidth,
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            context.go(AppRoutes.cameraDetail, extra: {'camera': camera});
          },
          onLongPress: onLongPress,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Container(
                color: Theme.of(context).cardTheme.color?.withAlpha(40),
                child:
                    (camera.thumbnailUrl != null &&
                        camera.thumbnailUrl!.isNotEmpty)
                    ? Image.network(
                        camera.thumbnailUrl!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                        errorBuilder: (ctx, err, stack) => Center(
                          child: Icon(
                            Icons.videocam_off,
                            size: 40,
                            color: Colors.grey[400],
                          ),
                        ),
                        loadingBuilder: (ctx, child, progress) {
                          if (progress == null) return child;
                          return Center(
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                value: progress.expectedTotalBytes != null
                                    ? progress.cumulativeBytesLoaded /
                                          progress.expectedTotalBytes!
                                    : null,
                              ),
                            ),
                          );
                        },
                      )
                    : Center(
                        child: Icon(
                          Icons.videocam,
                          size: 40,
                          color: Colors.grey[400],
                        ),
                      ),
              ),

              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.8),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),

              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: statusColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),

              Positioned(
                bottom: 8,
                left: 10,
                right: 10,
                child: Text(
                  camera.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    shadows: [Shadow(color: Colors.black, blurRadius: 2)],
                  ),
                  textAlign: TextAlign.left,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
