import 'package:flutter/material.dart';
import '../../../config/app_colors.dart';
import '../../../models/camera_model.dart';
import 'camera_tile.dart';

class CameraGroupCard extends StatelessWidget {
  final CameraGroup group;
  final bool forceExpanded;
  final VoidCallback onToggleExpanded;
  final VoidCallback onMenuPressed;
  final Function(Camera) onCameraLongPress;

  const CameraGroupCard({
    super.key,
    required this.group,
    this.forceExpanded = false,
    required this.onToggleExpanded,
    required this.onMenuPressed,
    required this.onCameraLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final isExpanded = forceExpanded || group.isExpanded;

    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          _buildGroupHeader(context),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 300),
            firstChild: _buildCameraList(group.cameras),
            secondChild: _buildCameraGrid(group.cameras),
            crossFadeState: isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
          ),
          if (!forceExpanded)
            InkWell(
              onTap: onToggleExpanded,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                color: Colors.grey.withOpacity(0.05),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      group.isExpanded
                          ? 'Tutup (Fold)'
                          : 'Lihat Semua (${group.cameras.length} Total)',
                      style: TextStyle(
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      group.isExpanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      size: 20,
                      color: Theme.of(context).primaryColor,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildGroupHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16.0, 4.0, 4.0, 4.0),
      color: Theme.of(context).cardTheme.color?.withAlpha(40),
      child: Row(
        children: [
          Icon(Icons.folder_open, size: 20, color: AppColors.textPrimary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              group.name,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: onMenuPressed,
          ),
        ],
      ),
    );
  }

  Widget _buildCameraGrid(List<Camera> cameras) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16.0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16.0,
        mainAxisSpacing: 16.0,
        childAspectRatio: 1.2,
      ),
      itemCount: cameras.length,
      itemBuilder: (context, index) => CameraTile(
        camera: cameras[index],
        onLongPress: () => onCameraLongPress(cameras[index]),
      ),
    );
  }

  Widget _buildCameraList(List<Camera> cameras) {
    return Container(
      height: 120,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: cameras.length,
        itemBuilder: (context, index) => Padding(
          padding: const EdgeInsets.only(right: 10.0),
          child: CameraTile(
            camera: cameras[index],
            isHorizontal: true,
            onLongPress: () => onCameraLongPress(cameras[index]),
          ),
        ),
      ),
    );
  }
}
