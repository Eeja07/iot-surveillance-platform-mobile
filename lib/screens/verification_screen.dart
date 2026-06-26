import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import 'new_password_screen.dart';
import 'login_screen.dart';
import 'main_screen.dart';
import 'admin_home_screen.dart';

enum VerificationPurpose { activation, passwordReset }

class VerificationScreen extends StatefulWidget {
  final String email;
  final VerificationPurpose purpose;

  const VerificationScreen({
    super.key,
    required this.email,
    required this.purpose,
  });

  @override
  _VerificationScreenState createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  final List<TextEditingController> _controllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  final AuthService _authService = AuthService();
  bool _isLoading = false;

  void _verifyOtp() async {
    String inputOtp = _controllers.map((c) => c.text).join().trim();

    if (inputOtp.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Harap lengkapi 6 digit kode OTP'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    Map<String, dynamic> result;

    if (widget.purpose == VerificationPurpose.activation) {
      result = await _authService.verifyRegistrationOtp(widget.email, inputOtp);
    } else {
      result = await _authService.verifyPasswordOtp(widget.email, inputOtp);
    }

    setState(() => _isLoading = false);

    if (mounted) {
      if (result['success']) {
        if (widget.purpose == VerificationPurpose.activation) {
          String role = result['role'] ?? 'user';
          String? token = result['token'];

          if (token != null) {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('token', token);
            await prefs.setString('role', role);

            await prefs.setString('saved_email', widget.email);
          }

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Verifikasi Berhasil! Sedang masuk...'),
              backgroundColor: Colors.green,
            ),
          );

          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (context) => role == 'admin'
                  ? AdminHomeScreen(toggleTheme: () {}, isDarkMode: false)
                  : MainScreen(toggleTheme: () {}, isDarkMode: false),
            ),
            (route) => false,
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Kode OTP Valid! Silakan buat password baru.'),
              backgroundColor: Colors.green,
            ),
          );

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  NewPasswordScreen(email: widget.email, otp: inputOtp),
            ),
          );
        }
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
  void dispose() {
    for (var c in _controllers) c.dispose();
    for (var f in _focusNodes) f.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String title = widget.purpose == VerificationPurpose.activation
        ? 'Aktivasi Akun'
        : 'Reset Password';

    String desc = widget.purpose == VerificationPurpose.activation
        ? 'Kode aktivasi akun telah dikirim ke:\n${widget.email}'
        : 'Kode reset password telah dikirim ke:\n${widget.email}';

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const SizedBox(height: 40),
            Icon(
              widget.purpose == VerificationPurpose.activation
                  ? Icons.mark_email_read
                  : Icons.lock_reset,
              size: 80,
              color: Colors.orange,
            ),
            const SizedBox(height: 24),
            const Text(
              'Masukkan Kode OTP',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              desc,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey, height: 1.5),
            ),
            const SizedBox(height: 40),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(6, (index) {
                return SizedBox(
                  width: 45,
                  height: 55,
                  child: TextField(
                    controller: _controllers[index],
                    focusNode: _focusNodes[index],
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLength: 1,
                    decoration: InputDecoration(
                      counterText: "",
                      contentPadding: EdgeInsets.zero,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                          color: Colors.orange,
                          width: 2,
                        ),
                      ),
                    ),
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (value) {
                      if (value.isNotEmpty) {
                        if (index < 5) {
                          FocusScope.of(
                            context,
                          ).requestFocus(_focusNodes[index + 1]);
                        } else {
                          FocusScope.of(context).unfocus();
                        }
                      } else {
                        if (index > 0) {
                          FocusScope.of(
                            context,
                          ).requestFocus(_focusNodes[index - 1]);
                        }
                      }
                    },
                  ),
                );
              }),
            ),

            const SizedBox(height: 40),

            _isLoading
                ? const CircularProgressIndicator()
                : SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _verifyOtp,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        backgroundColor:
                            widget.purpose == VerificationPurpose.activation
                            ? Colors.blue
                            : Colors.orange,
                        foregroundColor: Colors.white,
                      ),
                      child: Text(
                        widget.purpose == VerificationPurpose.activation
                            ? 'Verifikasi & Masuk'
                            : 'Lanjut Reset Password',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
