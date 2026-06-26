import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/camera_service.dart';
import '../models/camera_model.dart';
import '../utils/toast_utils.dart';
import '../core/di/injection.dart';

class AddGroupScreen extends StatefulWidget {
  const AddGroupScreen({super.key});

  @override
  _AddGroupScreenState createState() => _AddGroupScreenState();
}

class _AddGroupScreenState extends State<AddGroupScreen> {
  final TextEditingController _groupNameController = TextEditingController();
  final CameraService _cameraService = CameraService();

  List<Camera> _availableCameras = [];
  final Set<dynamic> _selectedDeviceIds = {};

  bool _isLoading = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _fetchUngroupedCameras();
  }

  Future<void> _fetchUngroupedCameras() async {
    setState(() => _isLoading = true);
    final sessionService = AppLocator.instance.sessionService;
    final token = await sessionService.getAccessToken();

    if (token != null) {
      try {
        final List<CameraGroup> groups = await _cameraService.fetchCameraGroups(
          token,
        );
        final CameraGroup? ungroupedGroup = groups.firstWhere(
          (g) => g.name == 'Tanpa Grup' || g.id == null,
          orElse: () => CameraGroup(name: 'Tanpa Grup', cameras: [], id: null),
        );

        if (mounted) {
          setState(() {
            _availableCameras = ungroupedGroup?.cameras ?? [];
            _isLoading = false;
          });
        }
      } catch (e) {
        if (mounted) setState(() => _isLoading = false);
      }
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _submit() async {
    final groupName = _groupNameController.text.trim();

    if (groupName.isEmpty) {
      ToastUtils.show(context, 'Nama grup tidak boleh kosong!', isError: true);
      return;
    }

    if (_selectedDeviceIds.isEmpty) {
      ToastUtils.show(
        context,
        'Harus memilih setidaknya satu kamera!',
        isError: true,
      );
      return;
    }

    setState(() => _isSubmitting = true);
    final sessionService = AppLocator.instance.sessionService;
    final token = await sessionService.getAccessToken();

    if (token != null) {
      final result = await _cameraService.createGroupApi(token, groupName);

      if (result['success'] == true) {
        int successCount = 0;
        int errorCount = 0;

        if (_selectedDeviceIds.isNotEmpty) {
          for (var cameraId in _selectedDeviceIds) {
            final assignRes = await _cameraService.assignCameraToGroup(
              token,
              groupName,
              cameraId is int ? cameraId : int.parse(cameraId.toString()),
            );

            if (assignRes['success'] == true)
              successCount++;
            else
              errorCount++;
          }
        }

        if (mounted) {
          setState(() => _isSubmitting = false);

          String message = 'Grup "$groupName" berhasil dibuat.';
          if (successCount > 0)
            message += ' ($successCount kamera ditambahkan)';
          if (errorCount > 0) message += '. Gagal menambah $errorCount kamera.';

          ToastUtils.show(context, message, isError: errorCount > 0);
          context.pop();
        }
      } else {
        if (mounted) {
          setState(() => _isSubmitting = false);
          ToastUtils.show(
            context,
            result['message'] ?? 'Gagal membuat grup.',
            isError: true,
          );
        }
      }
    } else {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool canCreateGroup = _availableCameras.isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: const Text('Buat Grup Baru')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _groupNameController,
                    enabled: canCreateGroup,
                    decoration: InputDecoration(
                      labelText: 'Nama Grup Baru',
                      hintText: 'Contoh: Garasi, Lantai 2',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  Text(
                    'Pilih Kamera (Tanpa Grup):',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),

                  _availableCameras.isEmpty
                      ? Container(
                          padding: const EdgeInsets.all(20),
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.red[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.red.withOpacity(0.3),
                            ),
                          ),
                          child: Column(
                            children: [
                              const Icon(
                                Icons.warning_amber_rounded,
                                color: Colors.red,
                                size: 40,
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                "Tidak ada kamera tersedia (tanpa grup).",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "Anda harus memiliki setidaknya satu kamera yang belum masuk grup untuk membuat grup baru.",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.grey[700],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _availableCameras.length,
                          itemBuilder: (context, index) {
                            final camera = _availableCameras[index];
                            final isSelected = _selectedDeviceIds.contains(
                              camera.id,
                            );

                            return CheckboxListTile(
                              title: Text(camera.name),
                              value: isSelected,
                              activeColor: Theme.of(context).primaryColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              onChanged: (bool? value) {
                                setState(() {
                                  if (value == true) {
                                    _selectedDeviceIds.add(camera.id);
                                  } else {
                                    _selectedDeviceIds.remove(camera.id);
                                  }
                                });
                              },
                            );
                          },
                        ),

                  const SizedBox(height: 30),
                  _isSubmitting
                      ? const Center(child: CircularProgressIndicator())
                      : ElevatedButton(
                          onPressed: canCreateGroup ? _submit : null,
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            backgroundColor: canCreateGroup
                                ? null
                                : Colors.grey,
                          ),
                          child: const Text('Buat Grup'),
                        ),
                ],
              ),
            ),
    );
  }
}
