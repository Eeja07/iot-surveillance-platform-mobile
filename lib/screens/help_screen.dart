import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/app_colors.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  Future<void> _launchEmail() async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'b300iotlab@gmail.com',
      query: 'subject=Keluhan Aplikasi Mivion',
    );

    try {
      if (!await launchUrl(
        emailLaunchUri,
        mode: LaunchMode.externalApplication,
      )) {
        throw 'Could not launch email';
      }
    } catch (e) {
      debugPrint('Error launching email: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bantuan & Panduan')),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.support_agent, color: Colors.white, size: 40),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Pusat Bantuan',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Temukan jawaban untuk pertanyaan umum di sini.',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          Text(
            'Pertanyaan Umum (FAQ)',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          _buildFaqItem(
            'Bagaimana cara menambahkan kamera baru?',
            'Tekan ikon (+) di halaman utama, lalu pilih "Scan QR Code" untuk memindai kode pada perangkat, atau pilih "Manual" untuk memasukkan Device ID secara langsung.',
          ),
          _buildFaqItem(
            'Apa arti indikator warna pada kamera?',
            '• Titik Hijau: Kamera Aktif (Online) dan berfungsi normal.\n• Titik Merah: Kamera Tidak Aktif (Offline) atau terputus dari jaringan.',
          ),
          _buildFaqItem(
            'Bagaimana cara melihat rekaman masa lalu?',
            'Klik pada salah satu kamera di halaman utama untuk masuk ke detail. Gunakan filter Tanggal dan Jam di bagian atas untuk memilih waktu rekaman yang ingin dilihat.',
          ),
          _buildFaqItem(
            'Bagaimana cara membuat Grup Kamera?',
            'Tekan tombol (+) lalu pilih "Tambah Grup". Masukkan nama grup dan pilih kamera-kamera yang ingin Anda gabungkan dalam satu folder.',
          ),
          _buildFaqItem(
            'Bagaimana cara memindahkan kamera ke grup lain?',
            'Tekan titik tiga pada grup tujuan, pilih "Edit Grup", lalu centang kamera yang ingin dimasukkan. Kamera akan otomatis berpindah dari grup lamanya.',
          ),
          _buildFaqItem(
            'Saya tidak bisa login, apa yang harus dilakukan?',
            'Pastikan email dan password benar. Jika lupa password, gunakan fitur "Lupa Password" di halaman login untuk mereset kata sandi Anda melalui email.',
          ),

          const SizedBox(height: 24),

          const Divider(),
          const SizedBox(height: 16),
          const Center(
            child: Text(
              'Masih butuh bantuan?',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: ElevatedButton.icon(
              onPressed: _launchEmail,
              icon: const Icon(Icons.email_outlined),
              label: const Text('Hubungi Support'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
              ),
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildFaqItem(String question, String answer) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        title: Text(
          question,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(
              answer,
              style: TextStyle(
                color: Colors.grey[700],
                height: 1.5,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
