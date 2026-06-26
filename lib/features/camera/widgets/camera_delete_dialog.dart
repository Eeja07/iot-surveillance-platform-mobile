import 'package:flutter/material.dart';

class CameraDeleteDialog extends StatelessWidget {
  final String cameraName;

  const CameraDeleteDialog({super.key, required this.cameraName});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Hapus Kamera'),
      content: Text('Apakah Anda yakin ingin menghapus kamera "$cameraName"?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Batal'),
        ),
        TextButton(
          style: TextButton.styleFrom(foregroundColor: Colors.red),
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Hapus'),
        ),
      ],
    );
  }
}
