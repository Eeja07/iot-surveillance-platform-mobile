import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'me_screen.dart';
import 'add_device_manual_screen.dart';
import 'add_group_screen.dart';
import 'qr_scanner_screen.dart';

class MainScreen extends StatefulWidget {
  final VoidCallback toggleTheme;
  final bool isDarkMode;

  const MainScreen({
    super.key,
    required this.toggleTheme,
    required this.isDarkMode,
  });

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  final ValueNotifier<bool> _refreshHomeNotifier = ValueNotifier(false);

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _showAddDeviceMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext bc) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
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
                onTap: () async {
                  Navigator.pop(context);
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const QrScannerScreen(),
                    ),
                  );
                  if (result == true) _triggerHomeRefresh();
                },
              ),
              ListTile(
                leading: const Icon(Icons.add_box_outlined),
                title: const Text('Add Device Manually'),
                onTap: () async {
                  Navigator.pop(context);
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AddDeviceManualScreen(),
                    ),
                  );
                  if (result == true) _triggerHomeRefresh();
                },
              ),
              ListTile(
                leading: const Icon(Icons.folder_copy_outlined),
                title: const Text('Add Group'),
                onTap: () async {
                  Navigator.pop(context);
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AddGroupScreen(),
                    ),
                  );
                  if (result == true) _triggerHomeRefresh();
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  void _triggerHomeRefresh() {
    _refreshHomeNotifier.value = !_refreshHomeNotifier.value;
  }

  @override
  Widget build(BuildContext context) {
    final bool isKeyboardVisible =
        MediaQuery.of(context).viewInsets.bottom != 0;

    final List<Widget> pages = [
      HomeScreen(
        toggleTheme: widget.toggleTheme,
        isDarkMode: widget.isDarkMode,
        refreshNotifier: _refreshHomeNotifier,
      ),
      MeScreen(toggleTheme: widget.toggleTheme, isDarkMode: widget.isDarkMode),
    ];

    return Scaffold(
      body: pages[_selectedIndex],

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
