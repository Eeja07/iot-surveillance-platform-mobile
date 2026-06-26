import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/camera_service.dart';
import '../utils/toast_utils.dart';

class AddDeviceManualScreen extends StatefulWidget {
  final String? deviceIdFromQR;

  const AddDeviceManualScreen({super.key, this.deviceIdFromQR});

  @override
  _AddDeviceManualScreenState createState() => _AddDeviceManualScreenState();
}

class _AddDeviceManualScreenState extends State<AddDeviceManualScreen> {
  late final TextEditingController _deviceIdController;
  final TextEditingController _descriptionController = TextEditingController();
  final CameraService _cameraService = CameraService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _deviceIdController = TextEditingController(text: widget.deviceIdFromQR);
  }

  @override
  void dispose() {
    _deviceIdController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _submit() async {
    final deviceId = _deviceIdController.text.trim();
    final description = _descriptionController.text.trim();

    if (deviceId.isEmpty) {
      ToastUtils.show(context, 'Device ID tidak boleh kosong!', isError: true);
      return;
    }

    if (description.isEmpty) {
      ToastUtils.show(context, 'Deskripsi kamera harus diisi!', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token != null) {
      final result = await _cameraService.addCamera(
        token,
        deviceId,
        description: description
      );

      setState(() => _isLoading = false);

      if (mounted) {
        if (result['success']) {
          ToastUtils.show(context, result['message'], isError: false);
          Navigator.pop(context, true);
        } else {
          ToastUtils.show(context, result['message'], isError: true);
        }
      }
    } else {
      setState(() => _isLoading = false);
      ToastUtils.show(context, 'Sesi habis, silakan login ulang.', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tambah Device Manual'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _deviceIdController,
              decoration: InputDecoration(
                labelText: 'Device ID',
                hintText: 'Contoh: 56bbe22e-...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () => _deviceIdController.clear(),
                ),
              ),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: 'Deskripsi Kamera',
                hintText: 'Contoh: Kamera Garasi Depan',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Icons.description),
              ),
              maxLines: 2,
            ),

            const SizedBox(height: 24),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Hubungkan Kamera'),
                  ),
          ],
        ),
      ),
    );
  }
}