import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import '../core/router/app_routes.dart';
import 'verification_screen.dart';

class LoginScreen extends StatefulWidget {
  final VoidCallback toggleTheme;
  final bool isDarkMode;

  const LoginScreen({
    super.key,
    required this.toggleTheme,
    required this.isDarkMode,
  });

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _obscureText = true;
  bool _isLoading = false;
  final AuthService _authService = AuthService();

  void _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email dan Password wajib diisi')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final result = await _authService.login(email, password);

    setState(() => _isLoading = false);

    if (mounted) {
      if (result['success']) {
        final prefs = await SharedPreferences.getInstance();
        final String token = result['token'];
        final String role = result['role'];

        await prefs.setString('token', token);
        await prefs.setString('role', role);
        await prefs.setString('saved_email', email);

        context.go(AppRoutes.dashboard);
      } else {
        String errorMessage = result['message'].toString();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
        );

        if (errorMessage.toLowerCase().contains('belum diverifikasi') ||
            errorMessage.toLowerCase().contains('verify your email') ||
            errorMessage.toLowerCase().contains('not verified')) {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text("Akun Belum Aktif"),
              content: Text(
                "Email $email belum diverifikasi. Apakah Anda ingin memasukkan kode OTP sekarang?",
              ),
              actions: [
                TextButton(
                  onPressed: () => context.pop(),
                  child: const Text("Batal"),
                ),
                TextButton(
                  onPressed: () {
                    context.pop();
                    context.go(
                      '/verification',
                      extra: {
                        'email': email,
                        'purpose': VerificationPurpose.activation,
                      },
                    );
                  },
                  child: const Text("Ya, Verifikasi"),
                ),
              ],
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  SizedBox(
                    width: 140,
                    height: 140,
                    child: Image.asset(
                      'assets/logomivion.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 20),

                  const Text(
                    'Selamat Datang',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 40),
                  TextField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      prefixIcon: const Icon(Icons.email),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _passwordController,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureText
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () =>
                            setState(() => _obscureText = !_obscureText),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    obscureText: _obscureText,
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => context.go('/forgot-password'),
                      child: const Text('Lupa Password?'),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _isLoading
                      ? const CircularProgressIndicator()
                      : ElevatedButton(
                          onPressed: _handleLogin,
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Login'),
                        ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Belum punya akun?'),
                      TextButton(
                        onPressed: () => context.go('/register'),
                        child: const Text('Daftar'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          Positioned(
            top: 40,
            right: 16,
            child: IconButton(
              icon: Icon(
                widget.isDarkMode
                    ? Icons.wb_sunny_outlined
                    : Icons.nightlight_round,
                size: 28,
              ),
              onPressed: widget.toggleTheme,
              tooltip: widget.isDarkMode ? 'Mode Terang' : 'Mode Gelap',
            ),
          ),
        ],
      ),
    );
  }
}
