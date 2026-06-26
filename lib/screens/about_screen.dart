import 'package:flutter/material.dart';
import '../config/app_colors.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tentang Aplikasi'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [

            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: SizedBox(
                width: 100,
                height: 100,
                child: Image.asset(
                  'assets/logo_MV.png',
                  fit: BoxFit.contain,
                ),
              ),
            ),
            const SizedBox(height: 24),

            Text(
              'MiotVision',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Versi 1.0.0 (Beta)',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[800],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            const SizedBox(height: 32),


            const Text(
              'MiotVision adalah solusi pemantauan keamanan cerdas yang terintegrasi. '
              'Pantau kamera CCTV Anda dari mana saja, kelola perangkat dalam grup, dan akses riwayat rekaman dengan mudah melalui smartphone Anda.',
              textAlign: TextAlign.center,
              style: TextStyle(height: 1.6, fontSize: 15),
            ),

            const SizedBox(height: 32),
            const Divider(),


            _buildInfoTile(
              context,
              icon: Icons.code,
              title: 'Dikembangkan Oleh',
              subtitle: 'Tim Magang Lab MIOT 2025',
            ),
            _buildInfoTile(
              context,
              icon: Icons.business,
              title: 'Afiliasi',
              subtitle: 'Lab. Multimedia dan Internet Of Things',
            ),
            _buildInfoTile(
              context,
              icon: Icons.update,
              title: 'Terakhir Diperbarui',
              subtitle: 'Januari 2026',
            ),

            const SizedBox(height: 20),


            Text(
              '© 2026 MiotVision. Hak Cipta Dilindungi.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile(BuildContext context, {required IconData icon, required String title, required String subtitle}) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: Theme.of(context).primaryColor, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 13)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    );
  }
}