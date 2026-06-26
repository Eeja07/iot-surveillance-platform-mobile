import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/auth_service.dart';
import '../core/router/app_routes.dart';

class NewPasswordScreen extends StatefulWidget {
  final String email;
  final String otp;

  const NewPasswordScreen({super.key, required this.email, required this.otp});

  @override
  _NewPasswordScreenState createState() => _NewPasswordScreenState();
}

class _NewPasswordScreenState extends State<NewPasswordScreen> {
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmNewPasswordController =
      TextEditingController();
  final AuthService _authService = AuthService();
  final _formKey = GlobalKey<FormState>();

  bool _obscureText = true;
  bool _isLoading = false;

  void _resetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final result = await _authService.resetPassword(
      widget.email,
      widget.otp,
      _newPasswordController.text,
      _confirmNewPasswordController.text,
    );

    setState(() => _isLoading = false);

    if (mounted) {
      if (result['success']) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 60),
                const SizedBox(height: 16),
                const Text(
                  'Sukses!',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Password Anda berhasil diperbarui.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      context.pop();
                      context.go(AppRoutes.login);
                    },
                    child: const Text('Login Sekarang'),
                  ),
                ),
              ],
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Buat Password Baru')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                const Icon(
                  Icons.lock_open_rounded,
                  size: 80,
                  color: Colors.green,
                ),
                const SizedBox(height: 20),
                const Text(
                  'Password Baru',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Silakan buat password baru untuk akun Anda.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 40),

                TextFormField(
                  controller: _newPasswordController,
                  decoration: InputDecoration(
                    labelText: 'Password Baru',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureText ? Icons.visibility_off : Icons.visibility,
                      ),
                      onPressed: () =>
                          setState(() => _obscureText = !_obscureText),
                    ),
                  ),
                  obscureText: _obscureText,
                  validator: (val) => val != null && val.length < 6
                      ? 'Minimal 6 karakter'
                      : null,
                ),
                const SizedBox(height: 20),

                TextFormField(
                  controller: _confirmNewPasswordController,
                  decoration: InputDecoration(
                    labelText: 'Konfirmasi Password',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.check_circle_outline),
                  ),
                  obscureText: _obscureText,
                  validator: (val) {
                    if (val == null || val.isEmpty)
                      return 'Konfirmasi password wajib diisi';
                    if (val != _newPasswordController.text)
                      return 'Password tidak cocok';
                    return null;
                  },
                ),

                const SizedBox(height: 30),

                _isLoading
                    ? const CircularProgressIndicator()
                    : SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _resetPassword,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text(
                            'Simpan Password',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
