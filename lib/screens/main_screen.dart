import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/observability/observability_service.dart';
import '../core/realtime/last_detection_provider.dart';
import '../core/router/app_routes.dart';
import '../utils/toast_utils.dart';

class MainScreen extends ConsumerStatefulWidget {
  final VoidCallback toggleTheme;
  final bool isDarkMode;
  final Widget child;

  const MainScreen({
    super.key,
    required this.toggleTheme,
    required this.isDarkMode,
    required this.child,
  });

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  // Dedup: cache the last detection id shown as a toast so we never show the
  // same event twice (e.g. on rebuild or rapid re-subscription).
  int? _lastShownDetectionId;

  int get _selectedIndex {
    final String location = GoRouterState.of(context).uri.path;
    if (location.startsWith(AppRoutes.me)) {
      return 1;
    }
    return 0;
  }

  void _onItemTapped(int index) {
    if (index == 0) {
      context.go(AppRoutes.dashboard);
    } else {
      context.go(AppRoutes.me);
    }
  }

  void _showAddDeviceMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext bc) {
        return Material(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          clipBehavior: Clip.antiAlias,
          child: Wrap(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.qr_code_scanner),
                title: const Text('Scan QR Code'),
                onTap: () {
                  context.pop();
                  context.go(AppRoutes.qrScanner);
                },
              ),
              ListTile(
                leading: const Icon(Icons.add_box_outlined),
                title: const Text('Add Device Manually'),
                onTap: () {
                  context.pop();
                  context.go(AppRoutes.addDeviceManual);
                },
              ),
              ListTile(
                leading: const Icon(Icons.folder_copy_outlined),
                title: const Text('Add Group'),
                onTap: () {
                  context.pop();
                  context.go(AppRoutes.addGroup);
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Listen for new detection events and show an in-app toast safely.
    ref.listen<Map<String, dynamic>?>(lastDetectionEventProvider, (_, payload) {
      if (payload == null) return;

      // Parse the detection id for dedup.
      final id = int.tryParse(payload['id']?.toString() ?? '') ?? payload.hashCode;

      // Skip if we already showed a toast for this exact detection event.
      if (_lastShownDetectionId == id) return;
      _lastShownDetectionId = id;

      final cameraName = payload['camera_name']?.toString() ?? 'Kamera';
      final confidence = payload['confidence']?.toString() ?? '';
      final message =
          'Person detected on $cameraName${confidence.isNotEmpty ? ' ($confidence)' : ''}';

      // Defer until after the current frame so the Overlay is guaranteed to
      // exist and the widget is fully mounted.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final overlay = Overlay.maybeOf(context);
        if (overlay == null) return;

        ObservabilityService.instance.info('[UI] toast shown');
        ToastUtils.show(context, '[Human Detected] $message', isError: false);
      });
    });

    final bool isKeyboardVisible =
        MediaQuery.of(context).viewInsets.bottom != 0;

    return Scaffold(
      body: widget.child,
      floatingActionButton: isKeyboardVisible
          ? null
          : FloatingActionButton(
              onPressed: () => _showAddDeviceMenu(context),
              elevation: 4.0,
              child: const Icon(Icons.add),
            ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: isKeyboardVisible
          ? null
          : BottomAppBar(
              shape: const CircularNotchedRectangle(),
              notchMargin: 8.0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: <Widget>[
                  _buildBottomNavItem(
                    icon: Icons.home,
                    label: 'Home',
                    index: 0,
                  ),
                  const SizedBox(width: 40),
                  _buildBottomNavItem(
                    icon: Icons.person_outline,
                    label: 'Me',
                    index: 1,
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildBottomNavItem({
    required IconData icon,
    required String label,
    required int index,
  }) {
    final isSelected = _selectedIndex == index;
    final color = isSelected
        ? Theme.of(context).primaryColor
        : Theme.of(context).textTheme.bodyMedium?.color;

    return InkWell(
      onTap: () => _onItemTapped(index),
      borderRadius: BorderRadius.circular(30),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(fontSize: 12, color: color)),
          ],
        ),
      ),
    );
  }
}
