import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/camera_model.dart';
import '../repositories/camera_config_repository.dart';
import '../features/camera/providers/camera_config_provider.dart';

class ConfigScreen extends ConsumerStatefulWidget {
  final Camera camera;
  const ConfigScreen({super.key, required this.camera});

  @override
  ConsumerState<ConfigScreen> createState() => _ConfigScreenState();
}

class _ConfigScreenState extends ConsumerState<ConfigScreen> {
  bool _initialized = false;
  bool _isSaving = false;
  bool _isCapturing = false;
  bool _isRebooting = false;

  late TextEditingController _jpegQualityController;
  late TextEditingController _captureIntervalController;
  late TextEditingController _telemetryIntervalController;
  late TextEditingController _mqttBufferController;
  String? _selectedFrameSize;
  bool _imageEnabled = true;
  bool _telemetryEnabled = true;
  bool _otaEnabled = true;

  @override
  void dispose() {
    if (_initialized) {
      _jpegQualityController.dispose();
      _captureIntervalController.dispose();
      _telemetryIntervalController.dispose();
      _mqttBufferController.dispose();
    }
    super.dispose();
  }

  void _initializeLocalValues(CameraConfig config) {
    if (_initialized) return;
    _jpegQualityController = TextEditingController(
      text: config.jpegQuality.toString(),
    );
    _captureIntervalController = TextEditingController(
      text: config.captureIntervalMs.toString(),
    );
    _telemetryIntervalController = TextEditingController(
      text: config.telemetryIntervalMs.toString(),
    );
    _mqttBufferController = TextEditingController(
      text: config.mqttBuffer.toString(),
    );
    _selectedFrameSize = config.frameSize;
    _imageEnabled = config.imageEnabled;
    _telemetryEnabled = config.telemetryEnabled;
    _otaEnabled = config.otaEnabled;
    _initialized = true;
  }

  Future<void> _applyConfig() async {
    final quality = int.tryParse(_jpegQualityController.text) ?? 80;
    final captureInterval =
        int.tryParse(_captureIntervalController.text) ?? 5000;
    final telemetryInterval =
        int.tryParse(_telemetryIntervalController.text) ?? 10000;
    final buffer = int.tryParse(_mqttBufferController.text) ?? 10;

    final newConfig = CameraConfig(
      jpegQuality: quality,
      frameSize: _selectedFrameSize ?? 'QVGA',
      captureIntervalMs: captureInterval,
      telemetryIntervalMs: telemetryInterval,
      mqttBuffer: buffer,
      imageEnabled: _imageEnabled,
      telemetryEnabled: _telemetryEnabled,
      otaEnabled: _otaEnabled,
    );

    try {
      setState(() => _isSaving = true);
      await ref
          .read(cameraConfigProvider(widget.camera.id).notifier)
          .updateConfig(newConfig);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Konfigurasi berhasil disimpan'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menyimpan konfigurasi: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _captureNow() async {
    try {
      setState(() => _isCapturing = true);
      await ref
          .read(cameraConfigProvider(widget.camera.id).notifier)
          .captureFrame();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Perintah capture berhasil dikirim'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mengirim perintah capture: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isCapturing = false);
    }
  }

  Future<void> _rebootCamera() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reboot Kamera'),
        content: const Text(
          'Apakah Anda yakin ingin menyalakan ulang kamera ini?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reboot'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      setState(() => _isRebooting = true);
      await ref
          .read(cameraConfigProvider(widget.camera.id).notifier)
          .rebootCamera();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kamera berhasil di-reboot'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal me-reboot kamera: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isRebooting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final configAsync = ref.watch(cameraConfigProvider(widget.camera.id));

    return Scaffold(
      appBar: AppBar(
        title: Text('Konfigurasi ${widget.camera.name}'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: configAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'Gagal memuat konfigurasi: $err',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () =>
                      ref.refresh(cameraConfigProvider(widget.camera.id)),
                  child: const Text('Coba Lagi'),
                ),
              ],
            ),
          ),
        ),
        data: (config) {
          _initializeLocalValues(config);

          final frameSizes = [
            'QQVGA',
            'QVGA',
            'VGA',
            'SVGA',
            'XGA',
            'SXGA',
            'UXGA',
          ];
          if (_selectedFrameSize != null &&
              !frameSizes.contains(_selectedFrameSize)) {
            frameSizes.add(_selectedFrameSize!);
          }

          final isBusy = _isSaving || _isCapturing || _isRebooting;

          return Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Pengaturan Gambar',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            DropdownButtonFormField<String>(
                              value: _selectedFrameSize,
                              decoration: const InputDecoration(
                                labelText: 'Frame Size',
                                border: OutlineInputBorder(),
                              ),
                              items: frameSizes
                                  .map(
                                    (size) => DropdownMenuItem(
                                      value: size,
                                      child: Text(size),
                                    ),
                                  )
                                  .toList(),
                              onChanged: isBusy
                                  ? null
                                  : (val) => setState(
                                      () => _selectedFrameSize = val,
                                    ),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _jpegQualityController,
                              keyboardType: TextInputType.number,
                              enabled: !isBusy,
                              decoration: const InputDecoration(
                                labelText: 'JPEG Quality (1 - 100)',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Pengaturan Interval & Buffer',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _captureIntervalController,
                              keyboardType: TextInputType.number,
                              enabled: !isBusy,
                              decoration: const InputDecoration(
                                labelText: 'Interval Capture (ms)',
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _telemetryIntervalController,
                              keyboardType: TextInputType.number,
                              enabled: !isBusy,
                              decoration: const InputDecoration(
                                labelText: 'Interval Telemetry (ms)',
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _mqttBufferController,
                              keyboardType: TextInputType.number,
                              enabled: !isBusy,
                              decoration: const InputDecoration(
                                labelText: 'MQTT Buffer Count',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Fitur Aktif',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            SwitchListTile(
                              title: const Text('Capture Gambar Aktif'),
                              value: _imageEnabled,
                              onChanged: isBusy
                                  ? null
                                  : (val) =>
                                        setState(() => _imageEnabled = val),
                            ),
                            SwitchListTile(
                              title: const Text('Telemetry Aktif'),
                              value: _telemetryEnabled,
                              onChanged: isBusy
                                  ? null
                                  : (val) =>
                                        setState(() => _telemetryEnabled = val),
                            ),
                            SwitchListTile(
                              title: const Text('Update OTA Aktif'),
                              value: _otaEnabled,
                              onChanged: isBusy
                                  ? null
                                  : (val) => setState(() => _otaEnabled = val),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: isBusy ? null : _applyConfig,
                        icon: const Icon(Icons.save),
                        label: const Text(
                          'Simpan Konfigurasi',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 50,
                            child: OutlinedButton.icon(
                              onPressed: isBusy ? null : _captureNow,
                              icon: const Icon(Icons.camera_alt),
                              label: const Text('Capture Now'),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Colors.blue),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: SizedBox(
                            height: 50,
                            child: OutlinedButton.icon(
                              onPressed: isBusy ? null : _rebootCamera,
                              icon: const Icon(
                                Icons.restart_alt,
                                color: Colors.red,
                              ),
                              label: const Text(
                                'Reboot',
                                style: TextStyle(color: Colors.red),
                              ),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Colors.red),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
              if (isBusy)
                Container(
                  color: Colors.black.withOpacity(0.3),
                  child: Center(
                    child: Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24.0,
                          vertical: 16.0,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const CircularProgressIndicator(),
                            const SizedBox(width: 16),
                            Text(
                              _isSaving
                                  ? 'Menyimpan...'
                                  : _isCapturing
                                  ? 'Capturing...'
                                  : 'Rebooting...',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
