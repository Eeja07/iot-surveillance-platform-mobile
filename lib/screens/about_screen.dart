import 'package:flutter/material.dart';
import '../config/app_colors.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tentang Mivion'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const SizedBox(height: 24),
            // Logo Container
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: SizedBox(
                width: 100,
                height: 100,
                child: Image.asset('assets/logo_MV.png', fit: BoxFit.contain),
              ),
            ),
            const SizedBox(height: 24),

            // Application Title
            Text(
              'Mivion',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),

            // Slogan
            Text(
              'See More. Know Faster.',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
                letterSpacing: 0.2,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),

            // Version Chip
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey[200],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                'Versi 2.0.0',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: isDark ? Colors.grey[300] : Colors.grey[800],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Description
            const Text(
              'Mivion adalah platform pemantauan cerdas berbasis IoT yang dirancang untuk memberikan visibilitas keamanan secara real-time. Kelola kamera, pantau deteksi objek, terima notifikasi instan, dan lakukan konfigurasi perangkat dari mana saja melalui satu aplikasi terpadu.',
              textAlign: TextAlign.center,
              style: TextStyle(
                height: 1.6,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 32),

            // Information Card
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Column(
                  children: [
                    _buildInfoTile(
                      context,
                      icon: Icons.person_outline,
                      title: 'Dikembangkan Oleh',
                      subtitle: 'Mahija Ibad Pradipta',
                    ),
                    const Divider(indent: 56),
                    _buildInfoTile(
                      context,
                      icon: Icons.school_outlined,
                      title: 'Afiliasi',
                      subtitle: 'Laboratorium Multimedia & Internet of Things\nInstitut Teknologi Sepuluh Nopember',
                    ),
                    const Divider(indent: 56),
                    _buildInfoTile(
                      context,
                      icon: Icons.update_outlined,
                      title: 'Terakhir Diperbarui',
                      subtitle: 'Juni 2026',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Footer
            Text(
              '© 2026 Mivion. All Rights Reserved.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: Theme.of(context).primaryColor, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 13, height: 1.4),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
    );
  }
}
