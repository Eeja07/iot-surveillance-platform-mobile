import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/di/auth_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/router/app_routes.dart';
import 'login_form.dart';

class LoginScreen extends ConsumerStatefulWidget {
  final VoidCallback toggleTheme;
  final bool isDarkMode;

  const LoginScreen({
    super.key,
    required this.toggleTheme,
    required this.isDarkMode,
  });

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  Future<void> _handleLogin(String email, String password) async {
    await ref.read(authProvider.notifier).login(email, password);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authProvider, (previous, next) {
      if (next.currentUser != null) {
        context.go(AppRoutes.dashboard);
      }
    });

    final authState = ref.watch(authProvider);
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
      body: Center(
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
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
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
                    isLoading: authState.isLoading,
                    errorMessage: authState.errorMessage,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
