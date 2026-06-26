import 'package:flutter/material.dart';

class CameraLoading extends StatelessWidget {
  const CameraLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}
