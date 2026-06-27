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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 12.0),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          _buildGroupHeader(context),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 280),
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
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.06)
                          : Colors.black.withValues(alpha: 0.05),
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      group.isExpanded
                          ? 'Tutup'
                          : 'Lihat Semua (${group.cameras.length})',
                      style: TextStyle(
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      group.isExpanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      size: 18,
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
    final onlineCount = group.cameras.where((c) => c.isOnline).length;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 12.0, 4.0, 12.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.folder_outlined,
              size: 18,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  group.name,
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  '$onlineCount/${group.cameras.length} online',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.more_vert,
              color: AppColors.textSecondary,
            ),
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
      padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 16.0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12.0,
        mainAxisSpacing: 12.0,
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
    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 8.0),
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
