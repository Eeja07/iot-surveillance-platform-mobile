import 'package:flutter/material.dart';

class DashboardSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final bool autofocus;
  final ValueChanged<String>? onChanged;

  const DashboardSearchBar({
    super.key,
    required this.controller,
    this.autofocus = true,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return TextField(
      controller: controller,
      autofocus: autofocus,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: 'Cari kamera atau grup...',
        border: InputBorder.none,
        hintStyle: TextStyle(
          color: isDark ? Colors.grey[400] : Colors.grey[600],
        ),
      ),
      style: TextStyle(color: isDark ? Colors.white : Colors.black),
    );
  }
}
