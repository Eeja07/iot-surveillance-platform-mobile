import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/camera_service.dart';
import '../models/camera_model.dart';
import '../utils/toast_utils.dart';

class EditGroupScreen extends StatefulWidget {
  final CameraGroup group;
  final Function(bool) onSave;

  const EditGroupScreen({super.key, required this.group, required this.onSave});

  @override
  _EditGroupScreenState createState() => _EditGroupScreenState();
}

class _EditGroupScreenState extends State<EditGroupScreen> {
  late final TextEditingController _groupNameController;
  final CameraService _cameraService = CameraService();

  List<Camera> _availableCameras = [];
  final Set<dynamic> _selectedDeviceIds = {};

  bool _isLoading = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _groupNameController = TextEditingController(text: widget.group.name);
    for (var cam in widget.group.cameras) {
      _selectedDeviceIds.add(cam.id);
    }
    _fetchAndFilterCameras();
  }

  @override
  void dispose() {
    _groupNameController.dispose();
    super.dispose();
  }

  Future<void> _fetchAndFilterCameras() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token != null) {
      try {
        final List<CameraGroup> groups = await _cameraService.fetchCameraGroups(
          token,
        );
        final CameraGroup currentGroupRef = groups.firstWhere(
          (g) => g.id == widget.group.id,
          orElse: () =>
              CameraGroup(name: 'Current', cameras: [], id: widget.group.id),
        );
        final CameraGroup ungroupedRef = groups.firstWhere(
          (g) => g.name == 'Tanpa Grup' || g.id == null,
          orElse: () => CameraGroup(name: 'Tanpa Grup', cameras: [], id: null),
        );

        final List<Camera> combinedCameras = [
          ...currentGroupRef.cameras,
          ...ungroupedRef.cameras,
        ];

        if (mounted) {
          setState(() {
            _availableCameras = combinedCameras;
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
    final newGroupName = _groupNameController.text.trim();
    if (newGroupName.isEmpty) {
      ToastUtils.show(context, 'Nama grup tidak boleh kosong!', isError: true);
      return;
    }

    setState(() => _isSubmitting = true);
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token != null) {
      if (widget.group.name != newGroupName) {
        final result = await _cameraService.updateGroupApi(
          token,
          widget.group.name,
          newGroupName,
        );

        if (result['success'] != true) {
          setState(() => _isSubmitting = false);
          ToastUtils.show(
            context,
            result['message'] ?? 'Gagal mengganti nama grup.',
            isError: true,
          );
          return;
        }
      }

      int successCount = 0;
      int errorCount = 0;

      for (var cameraId in _selectedDeviceIds) {
        bool wasInGroup = widget.group.cameras.any((c) => c.id == cameraId);
        if (!wasInGroup) {
          final res = await _cameraService.assignCameraToGroup(
            token,
            newGroupName,
            cameraId is int ? cameraId : int.parse(cameraId.toString()),
          );
          if (res['success'] == true)
            successCount++;
          else
            errorCount++;
        }
      }

      final originalIds = widget.group.cameras.map((c) => c.id).toSet();
      final removedIds = originalIds.difference(_selectedDeviceIds);

      for (var removedId in removedIds) {
        final res = await _cameraService.removeCameraFromGroup(
          token,
          removedId is int ? removedId : int.parse(removedId.toString()),
        );
        if (res['success'] == true)
          successCount++;
        else
          errorCount++;
      }

      if (mounted) {
        setState(() => _isSubmitting = false);

        String message = 'Grup berhasil diperbarui.';
        if (errorCount > 0) message += ' ($errorCount operasi gagal)';

        ToastUtils.show(context, message, isError: errorCount > 0);
        Navigator.pop(context);
        widget.onSave(true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.group.name == 'Tanpa Grup' && widget.group.id == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Edit Grup')),
        body: const Center(child: Text("Grup default tidak dapat diedit.")),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Grup')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  TextField(
                    controller: _groupNameController,
                    decoration: InputDecoration(
                      labelText: 'Nama Grup',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  Text(
                    'Anggota Grup:',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),

                  if (_availableCameras.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text("Tidak ada kamera lain yang tersedia."),
                    ),

                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _availableCameras.length,
                    itemBuilder: (context, index) {
                      final camera = _availableCameras[index];
                      final isSelected = _selectedDeviceIds.contains(camera.id);

                      String subtitle = "";
                      if (camera.groupName == 'Tanpa Grup') {
                        subtitle = "Belum memiliki grup";
                      } else if (camera.id != null &&
                          widget.group.cameras.any((c) => c.id == camera.id)) {
                        subtitle = "Anggota saat ini";
                      }

                      return CheckboxListTile(
                        title: Text(camera.name),
                        subtitle: subtitle.isNotEmpty
                            ? Text(
                                subtitle,
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey,
                                ),
                              )
                            : null,
                        value: isSelected,
                        activeColor: Theme.of(context).primaryColor,
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
                  const SizedBox(height: 20),
                  _isSubmitting
                      ? const Center(child: CircularProgressIndicator())
                      : ElevatedButton(
                          onPressed: _submit,
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Simpan Perubahan'),
                        ),
                ],
              ),
            ),
    );
  }
}
