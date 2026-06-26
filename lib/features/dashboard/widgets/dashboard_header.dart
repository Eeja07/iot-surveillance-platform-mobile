import 'package:flutter/material.dart';

class DashboardHeader extends StatelessWidget {
  final String title;
  final int? totalCount;
  final int? onlineCount;

  const DashboardHeader({
    super.key,
    required this.title,
    this.totalCount,
    this.onlineCount,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4.0, bottom: 8.0, top: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          if (totalCount != null && onlineCount != null)
            Row(
              children: [
                _buildStatChip(
                  context,
                  label: 'Online',
                  count: onlineCount!,
                  color: Colors.green,
                ),
                const SizedBox(width: 8),
                _buildStatChip(
                  context,
                  label: 'Total',
                  count: totalCount!,
                  color: Colors.blue,
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildStatChip(
    BuildContext context, {
    required String label,
    required int count,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        '$label: $count',
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
