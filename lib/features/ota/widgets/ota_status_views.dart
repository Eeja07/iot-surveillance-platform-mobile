import 'package:flutter/material.dart';

class OTAEmpty extends StatelessWidget {
  final String message;
  final VoidCallback? onAction;

  const OTAEmpty({
    super.key,
    this.message = 'Tidak ada data firmware.',
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.system_update_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            if (onAction != null) ...[
              const SizedBox(height: 16),
              ElevatedButton(onPressed: onAction, child: const Text('Refresh')),
            ],
          ],
        ),
      ),
    );
  }
}

class OTALoading extends StatelessWidget {
  const OTALoading({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}

class OTAError extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const OTAError({super.key, required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              error,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: onRetry, child: const Text('Coba Lagi')),
          ],
        ),
      ),
    );
  }
}
