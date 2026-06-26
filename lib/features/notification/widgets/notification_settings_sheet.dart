import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationSettingsSheet extends StatefulWidget {
  const NotificationSettingsSheet({super.key});

  @override
  State<NotificationSettingsSheet> createState() =>
      _NotificationSettingsSheetState();
}

class _NotificationSettingsSheetState extends State<NotificationSettingsSheet> {
  bool _pushEnabled = true;
  bool _motionEnabled = true;
  bool _soundEnabled = true;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _pushEnabled = prefs.getBool('push_notifications_enabled') ?? true;
        _motionEnabled = prefs.getBool('motion_alerts_enabled') ?? true;
        _soundEnabled = prefs.getBool('sound_enabled') ?? true;
        _isLoading = false;
      });
    }
  }

  Future<void> _updateSetting(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
    if (mounted) {
      setState(() {
        if (key == 'push_notifications_enabled') _pushEnabled = value;
        if (key == 'motion_alerts_enabled') _motionEnabled = value;
        if (key == 'sound_enabled') _soundEnabled = value;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(
        height: 250,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Pengaturan Notifikasi',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            title: const Text('Push Notifikasi'),
            subtitle: const Text(
              'Terima notifikasi real-time di perangkat Anda',
            ),
            value: _pushEnabled,
            onChanged: (val) =>
                _updateSetting('push_notifications_enabled', val),
          ),
          SwitchListTile(
            title: const Text('Deteksi Gerakan'),
            subtitle: const Text('Notifikasi ketika kamera mendeteksi gerakan'),
            value: _motionEnabled,
            onChanged: (val) => _updateSetting('motion_alerts_enabled', val),
          ),
          SwitchListTile(
            title: const Text('Suara Notifikasi'),
            subtitle: const Text('Putar suara saat ada deteksi baru'),
            value: _soundEnabled,
            onChanged: (val) => _updateSetting('sound_enabled', val),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
