import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/user_service.dart';
import '../config/app_colors.dart';
import '../core/di/injection.dart';
import '../core/router/app_routes.dart';
import '../features/auth/domain/model/user_model.dart';

class MeScreen extends StatefulWidget {
  final VoidCallback toggleTheme;
  final bool isDarkMode;

  const MeScreen({
    super.key,
    required this.toggleTheme,
    required this.isDarkMode,
  });

  @override
  _MeScreenState createState() => _MeScreenState();
}

class _MeScreenState extends State<MeScreen> {
  final UserService _userService = UserService();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _currentPassController = TextEditingController();
  final _newPassController = TextEditingController();
  final _confirmPassController = TextEditingController();

  bool _isLoading = false;
  bool _isDataLoaded = false;

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final sessionService = AppLocator.instance.sessionService;
    final token = await sessionService.getAccessToken();
    if (token != null) {
      final user = await _userService.getUser(token);
      if (user != null) {
        if (mounted) {
          setState(() {
            _nameController.text = user.name;
            _emailController.text = user.email;
            _isDataLoaded = true;
          });
          final currentUser = await sessionService.getCurrentUser();
          await sessionService.saveSession(
            token: token,
            user: UserModel(
              id: user.id,
              name: user.name,
              email: user.email,
              role: currentUser?.role ?? 'user',
            ),
          );
        }
        return;
      }
    }
    final user = await sessionService.getCurrentUser();
    if (user != null) {
      if (mounted) {
        setState(() {
          _nameController.text = user.name;
          _emailController.text = user.email;
          _isDataLoaded = true;
        });
      }
    }
  }

  void _logout() async {
    final authController = AppLocator.instance.authController;

    await authController.logout();

    if (mounted) {
      context.go(AppRoutes.login);
    }
  }

  void _showEditDialog(String title, TextEditingController controller) {
    final editController = TextEditingController(text: controller.text);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Ubah $title'),
        content: TextField(
          controller: editController,
          decoration: InputDecoration(
            labelText: '$title Baru',
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              context.pop();
              await _updateProfile(
                title == 'Nama' ? editController.text : _nameController.text,
                title == 'Email' ? editController.text : _emailController.text,
              );
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateProfile(String name, String email) async {
    setState(() => _isLoading = true);
    final sessionService = AppLocator.instance.sessionService;
    final token = await sessionService.getAccessToken();
    if (token != null) {
      final success = await _userService.updateUser(token, name, email);
      if (success) {
        setState(() {
          _nameController.text = name;
          _emailController.text = email;
        });
        final currentUser = await sessionService.getCurrentUser();
        if (currentUser != null) {
          await sessionService.saveSession(
            token: token,
            user: UserModel(
              id: currentUser.id,
              name: name,
              email: email,
              role: currentUser.role,
            ),
          );
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profil berhasil diperbarui')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal memperbarui profil'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
    setState(() => _isLoading = false);
  }

  Future<void> _changePassword() async {
    if (_newPassController.text.isEmpty ||
        _currentPassController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Semua kolom password harus diisi'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    if (_newPassController.text != _confirmPassController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Konfirmasi password baru tidak cocok!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    setState(() => _isLoading = true);
    final sessionService = AppLocator.instance.sessionService;
    final token = await sessionService.getAccessToken();
    if (token != null) {
      final result = await _userService.changePassword(
        token,
        _currentPassController.text,
        _newPassController.text,
        _confirmPassController.text,
      );
      setState(() => _isLoading = false);
      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: Colors.green,
          ),
        );
        await Future.delayed(const Duration(seconds: 2));
        _logout();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil Saya'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: Icon(
              isDark ? Icons.wb_sunny_outlined : Icons.nightlight_round,
            ),
            onPressed: widget.toggleTheme,
            tooltip: isDark ? 'Mode Terang' : 'Mode Gelap',
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: AppColors.danger),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: !_isDataLoaded
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle('Informasi Akun'),
                      const SizedBox(height: 16),

                      _buildReadOnlyField(
                        label: 'Nama Lengkap',
                        controller: _nameController,
                        icon: Icons.person_outline,
                        onTap: () => _showEditDialog('Nama', _nameController),
                      ),
                      const SizedBox(height: 16),

                      _buildReadOnlyField(
                        label: 'Email',
                        controller: _emailController,
                        icon: Icons.email_outlined,
                        onTap: null,
                      ),

                      const SizedBox(height: 32),
                      const Divider(thickness: 1),
                      const SizedBox(height: 16),
                      _buildSectionTitle('Ganti Password'),
                      const SizedBox(height: 16),
                      _buildPasswordField(
                        label: 'Password Saat Ini',
                        controller: _currentPassController,
                        obscureText: _obscureCurrent,
                        onToggle: () =>
                            setState(() => _obscureCurrent = !_obscureCurrent),
                      ),
                      const SizedBox(height: 16),
                      _buildPasswordField(
                        label: 'Password Baru',
                        controller: _newPassController,
                        obscureText: _obscureNew,
                        onToggle: () =>
                            setState(() => _obscureNew = !_obscureNew),
                      ),
                      const SizedBox(height: 16),
                      _buildPasswordField(
                        label: 'Konfirmasi Password Baru',
                        controller: _confirmPassController,
                        obscureText: _obscureConfirm,
                        onToggle: () =>
                            setState(() => _obscureConfirm = !_obscureConfirm),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _changePassword,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Simpan Password Baru',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 32),
                      const Divider(thickness: 1),
                      const SizedBox(height: 10),
                      _buildSectionTitle('Lainnya'),
                      const SizedBox(height: 10),

                      ListTile(
                        leading: const Icon(Icons.help_outline),
                        title: const Text('Bantuan & Panduan'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          context.go(AppRoutes.help);
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.info_outline),
                        title: const Text('Tentang Aplikasi'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          context.go(AppRoutes.about);
                        },
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
                if (_isLoading)
                  Container(
                    color: Colors.black.withOpacity(0.3),
                    child: const Center(child: CircularProgressIndicator()),
                  ),
              ],
            ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Theme.of(context).primaryColor,
      ),
    );
  }

  Widget _buildReadOnlyField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    VoidCallback? onTap,
  }) {
    return TextField(
      controller: controller,
      readOnly: true,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),

        suffixIcon: onTap != null
            ? IconButton(
                icon: const Icon(Icons.edit, color: Colors.blueGrey),
                onPressed: onTap,
              )
            : null,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Theme.of(context).cardColor,
      ),
    );
  }

  Widget _buildPasswordField({
    required String label,
    required TextEditingController controller,
    required bool obscureText,
    required VoidCallback onToggle,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.lock_outline),
        suffixIcon: IconButton(
          icon: Icon(obscureText ? Icons.visibility_off : Icons.visibility),
          onPressed: onToggle,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
