import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../models/camera_model.dart';

class DashboardDialogs {
  static void showGroupMenu({
    required BuildContext context,
    required CameraGroup group,
    required VoidCallback onEdit,
    required VoidCallback onDelete,
  }) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext bc) {
        return Wrap(
          children: <Widget>[
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Edit Grup'),
              onTap: () {
                context.pop();
                onEdit();
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text(
                'Hapus Grup',
                style: TextStyle(color: Colors.red),
              ),
              onTap: () {
                context.pop();
                onDelete();
              },
            ),
          ],
        );
      },
    );
  }

  static void showDeleteGroupConfirmation({
    required BuildContext context,
    required CameraGroup group,
    required VoidCallback onConfirm,
  }) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Hapus Grup'),
          content: Text(
            'Hapus grup "${group.name}"?\n'
            'Kamera akan dipindahkan ke "Tanpa Grup".',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Batal'),
              onPressed: () => context.pop(),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              onPressed: () {
                context.pop();
                onConfirm();
              },
              child: const Text('Hapus'),
            ),
          ],
        );
      },
    );
  }

  static void showCameraOptions({
    required BuildContext context,
    required Camera camera,
    required VoidCallback onEdit,
    required VoidCallback onDelete,
  }) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.edit, color: Colors.blue),
              title: const Text('Edit Kamera'),
              onTap: () {
                context.pop();
                onEdit();
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text(
                'Hapus Kamera',
                style: TextStyle(color: Colors.red),
              ),
              onTap: () {
                context.pop();
                onDelete();
              },
            ),
          ],
        );
      },
    );
  }

  static void showDeleteCameraConfirmation({
    required BuildContext context,
    required Camera camera,
    required VoidCallback onConfirm,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Kamera'),
        content: Text('Hapus kamera "${camera.name}"?'),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: const Text('Batal'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () {
              context.pop();
              onConfirm();
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }
}
