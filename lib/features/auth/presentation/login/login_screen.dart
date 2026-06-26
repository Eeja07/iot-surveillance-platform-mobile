import 'package:flutter/material.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../auth_controller.dart';
import 'login_form.dart';

class LoginScreen extends StatefulWidget {
  final VoidCallback toggleTheme;
  final bool isDarkMode;
  final VoidCallback? onSuccess;

  const LoginScreen({
    super.key,
    required this.toggleTheme,
    required this.isDarkMode,
    this.onSuccess,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late final AuthController _authController;

  @override
  void initState() {
    super.initState();
    _authController = AppLocator.instance.authController;
    _authController.addListener(_onStateChanged);
  }

  @override
  void dispose() {
    _authController.removeListener(_onStateChanged);
    super.dispose();
  }

  void _onStateChanged() {
    if (_authController.currentUser != null) {
      if (widget.onSuccess != null) {
        widget.onSuccess!();
      }
    }
  }

  Future<void> _handleLogin(String email, String password) async {
    await _authController.login(email, password);
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final isLandscape = mediaQuery.orientation == Orientation.landscape;
    final isTablet = mediaQuery.size.shortestSide >= 600;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Masuk'),
        actions: [
          IconButton(
            icon: Icon(widget.isDarkMode ? Icons.light_mode : Icons.dark_mode),
            onPressed: widget.toggleTheme,
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: _authController,
        builder: (context, _) {
          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: AutofillGroup(
                child: Container(
                  constraints: BoxConstraints(maxWidth: isTablet ? 500 : 400),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (!isLandscape) ...[
                        const Icon(
                          Icons.security_outlined,
                          size: 80,
                          color: AppColors.success,
                        ),
                        AppSpacing.vXl,
                      ],
                      Text(
                        'MiotVision',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      AppSpacing.vSm,
                      Text(
                        'Sistem Pemantauan Kamera CCTV Terintegrasi',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? AppColors.darkTextSecondary
                              : AppColors.textSecondary,
                        ),
                      ),
                      AppSpacing.vXxl,
                      LoginForm(
                        onSubmit: _handleLogin,
                        isLoading: _authController.isLoading,
                        errorMessage: _authController.errorMessage,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
