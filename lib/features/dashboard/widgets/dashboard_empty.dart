import 'package:flutter/material.dart';

class DashboardEmpty extends StatelessWidget {
  final bool isSearching;
  final VoidCallback? onRefresh;

  const DashboardEmpty({super.key, required this.isSearching, this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.videocam_off_outlined, size: 80, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            isSearching
                ? 'Tidak ada kamera yang cocok.'
                : 'Tidak ada kamera ditemukan.',
            style: const TextStyle(color: Colors.grey),
          ),
          if (!isSearching && onRefresh != null) ...[
            const SizedBox(height: 8),
            ElevatedButton(onPressed: onRefresh, child: const Text('Refresh')),
          ],
        ],
      ),
    );
  }
}
