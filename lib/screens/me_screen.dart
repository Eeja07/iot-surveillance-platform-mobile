import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/user_service.dart';
import '../config/app_colors.dart';
import '../core/di/providers.dart';
import '../core/di/auth_provider.dart';
import '../core/router/app_routes.dart';
import '../features/auth/domain/model/user_model.dart';

class MeScreen extends ConsumerStatefulWidget {
  final VoidCallback toggleTheme;
  final bool isDarkMode;

  const MeScreen({
    super.key,
    required this.toggleTheme,
    required this.isDarkMode,
  });

  @override
  ConsumerState<MeScreen> createState() => _MeScreenState();
}

class _MeScreenState extends ConsumerState<MeScreen> {
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

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _currentPassController.dispose();
    _newPassController.dispose();
    _confirmPassController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final sessionService = ref.read(sessionServiceProvider);
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
    await ref.read(authProvider.notifier).logout();
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: TextField(
          controller: editController,
          autofocus: true,
          decoration: InputDecoration(
            labelText: '$title Baru',
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
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(88, 36),
            ),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateProfile(String name, String email) async {
    setState(() => _isLoading = true);
    final sessionService = ref.read(sessionServiceProvider);
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
    final sessionService = ref.read(sessionServiceProvider);
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
        _currentPassController.clear();
        _newPassController.clear();
        _confirmPassController.clear();
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

  void _showChangePasswordBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            return Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: EdgeInsets.only(
                top: 24,
                left: 24,
                right: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Ganti Password',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => context.pop(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _currentPassController,
                      obscureText: _obscureCurrent,
                      decoration: InputDecoration(
                        labelText: 'Password Saat Ini',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureCurrent
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: () => setModalState(
                              () => _obscureCurrent = !_obscureCurrent),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _newPassController,
                      obscureText: _obscureNew,
                      decoration: InputDecoration(
                        labelText: 'Password Baru',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureNew
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: () => setModalState(
                              () => _obscureNew = !_obscureNew),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _confirmPassController,
                      obscureText: _obscureConfirm,
                      decoration: InputDecoration(
                        labelText: 'Konfirmasi Password Baru',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirm
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: () => setModalState(
                              () => _obscureConfirm = !_obscureConfirm),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () {
                          context.pop();
                          _changePassword();
                        },
                        child: const Text('Simpan Password Baru'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengaturan'),
        automaticallyImplyLeading: false,
      ),
      body: !_isDataLoaded
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // User Profile Header Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E293B) : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 32,
                              backgroundColor: primaryColor.withValues(alpha: 0.1),
                              child: Text(
                                _nameController.text.isNotEmpty
                                    ? _nameController.text[0].toUpperCase()
                                    : 'U',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: primaryColor,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _nameController.text,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _emailController.text,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: isDark
                                          ? AppColors.darkTextSecondary
                                          : AppColors.textSecondary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, size: 20),
                              onPressed: () => _showEditDialog('Nama', _nameController),
                              tooltip: 'Edit Nama',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      _buildSectionHeader('Akun & Keamanan'),
                      Card(
                        child: Column(
                          children: [
                            ListTile(
                              leading: const Icon(Icons.lock_outline_rounded),
                              title: const Text('Ganti Password'),
                              subtitle: const Text('Perbarui kredensial login Anda'),
                              trailing: const Icon(Icons.chevron_right_rounded, size: 20),
                              onTap: _showChangePasswordBottomSheet,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      _buildSectionHeader('Preferensi'),
                      Card(
                        child: Column(
                          children: [
                            SwitchListTile(
                              secondary: Icon(
                                isDark
                                    ? Icons.dark_mode_outlined
                                    : Icons.light_mode_outlined,
                              ),
                              title: const Text('Mode Gelap'),
                              subtitle: Text(isDark ? 'Tema gelap aktif' : 'Tema terang aktif'),
                              value: isDark,
                              onChanged: (_) => widget.toggleTheme(),
                            ),
                            const Divider(height: 1, indent: 56),
                            ListTile(
                              leading: const Icon(Icons.notifications_none_rounded),
                              title: const Text('Notifikasi CCTV'),
                              subtitle: const Text('Lihat & atur riwayat notifikasi'),
                              trailing: const Icon(Icons.chevron_right_rounded, size: 20),
                              onTap: () => context.go(AppRoutes.notifications),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      _buildSectionHeader('Lainnya'),
                      Card(
                        child: Column(
                          children: [
                            ListTile(
                              leading: const Icon(Icons.help_outline_rounded),
                              title: const Text('Bantuan & Panduan'),
                              trailing: const Icon(Icons.chevron_right_rounded, size: 20),
                              onTap: () => context.go(AppRoutes.help),
                            ),
                            const Divider(height: 1, indent: 56),
                            ListTile(
                              leading: const Icon(Icons.info_outline_rounded),
                              title: const Text('Tentang Aplikasi'),
                              trailing: const Icon(Icons.chevron_right_rounded, size: 20),
                              onTap: () => context.go(AppRoutes.about),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Logout Button
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: OutlinedButton.icon(
                          onPressed: _logout,
                          icon: const Icon(Icons.logout_rounded, color: AppColors.danger),
                          label: const Text(
                            'Keluar dari Akun',
                            style: TextStyle(
                              color: AppColors.danger,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.danger, width: 1.5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
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

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4.0, bottom: 8.0),
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Colors.grey,
        letterSpacing: 0.5,
      ),
      child: Text(title.toUpperCase()),
    );
  }
}
