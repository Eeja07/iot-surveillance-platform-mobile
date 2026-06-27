import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/camera_service.dart';
import '../models/camera_model.dart';
import '../utils/toast_utils.dart';
import '../core/di/injection.dart';

class EditCameraScreen extends StatefulWidget {
  final Camera camera;

  const EditCameraScreen({super.key, required this.camera});

  @override
  _EditCameraScreenState createState() => _EditCameraScreenState();
}

class _EditCameraScreenState extends State<EditCameraScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  final CameraService _cameraService = CameraService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.camera.name);
    _descriptionController = TextEditingController(
      text: widget.camera.description ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final sessionService = AppLocator.instance.sessionService;
    final token = await sessionService.getAccessToken();

    if (token != null) {
      final result = await _cameraService.updateCamera(
        token,
        widget.camera.id.toString(),
        _nameController.text,
        description: _descriptionController.text,
      );

      setState(() => _isLoading = false);

      if (mounted) {
        if (result['success']) {
          ToastUtils.show(context, result['message'], isError: false);
          context.pop();
        } else {
          ToastUtils.show(context, result['message'], isError: true);
        }
      }
    } else {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Kamera')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Card(
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Nama Kamera',
                          prefixIcon: Icon(Icons.videocam_outlined),
                        ),
                        validator: (v) => v!.isEmpty ? 'Nama tidak boleh kosong' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Deskripsi Kamera',
                          prefixIcon: Icon(Icons.description_outlined),
                          hintText: 'Contoh: CCTV Depan Rumah',
                        ),
                        maxLines: 3,
                        validator: (v) => null,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _submit,
                        child: const Text(
                          'Simpan Perubahan',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
