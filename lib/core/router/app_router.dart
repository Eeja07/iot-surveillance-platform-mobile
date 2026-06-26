import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../di/injection.dart';
import 'app_routes.dart';
import 'router_redirect.dart';
import 'router_observer.dart';
import '../../screens/splash_screen.dart';
import '../../features/auth/presentation/login/login_screen.dart';
import '../../screens/main_screen.dart';
import '../../screens/admin_home_screen.dart';
import '../../screens/help_screen.dart';
import '../../screens/about_screen.dart';
import '../../screens/home_screen.dart';
import '../../screens/me_screen.dart';
import '../../screens/edit_group_screen.dart';
import '../../screens/edit_camera_screen.dart';
import '../../screens/camera_detail_screen.dart';
import '../../screens/qr_scanner_screen.dart';
import '../../screens/add_device_manual_screen.dart';
import '../../screens/add_group_screen.dart';
import '../../screens/new_password_screen.dart';
import '../../screens/image_viewer_screen.dart';
import '../../screens/forgot_password_screen.dart';
import '../../screens/verification_screen.dart';
import '../../screens/register_screen.dart';
import '../../models/camera_model.dart';

class AppRouter {
  static late final GoRouter router;
  static late final GlobalKey<NavigatorState> rootNavigatorKey;
  static late VoidCallback _toggleTheme;
  static late bool Function() _isDarkMode;

  static void init({
    required VoidCallback toggleTheme,
    required bool Function() isDarkMode,
    required GlobalKey<NavigatorState> navigatorKey,
  }) {
    _toggleTheme = toggleTheme;
    _isDarkMode = isDarkMode;
    rootNavigatorKey = navigatorKey;

    final sessionService = AppLocator.instance.sessionService;
    final redirector = RouterRedirect(sessionService);
    final shellNavigatorKey = GlobalKey<NavigatorState>();

    router = GoRouter(
      navigatorKey: navigatorKey,
      initialLocation: AppRoutes.splash,
      observers: [AppRouterObserver()],
      refreshListenable: AppLocator.instance.authController,
      redirect: (context, state) => redirector.redirect(context, state),
      routes: [
        GoRoute(
          path: AppRoutes.splash,
          builder: (context, state) => SplashScreen(
            toggleTheme: _toggleTheme,
            isDarkMode: _isDarkMode(),
          ),
        ),
        GoRoute(
          path: AppRoutes.login,
          builder: (context, state) =>
              LoginScreen(toggleTheme: _toggleTheme, isDarkMode: _isDarkMode()),
        ),
        GoRoute(
          path: '/new-password',
          builder: (context, state) {
            final extra = state.extra as Map<String, dynamic>;
            return NewPasswordScreen(
              email: extra['email'] as String,
              otp: extra['otp'] as String,
            );
          },
        ),
        GoRoute(
          path: '/forgot-password',
          builder: (context, state) => const ForgotPasswordScreen(),
        ),
        GoRoute(
          path: '/register',
          builder: (context, state) => const RegisterScreen(),
        ),
        GoRoute(
          path: '/verification',
          builder: (context, state) {
            final extra = state.extra as Map<String, dynamic>;
            return VerificationScreen(
              email: extra['email'] as String,
              purpose: extra['purpose'] as VerificationPurpose,
            );
          },
        ),
        ShellRoute(
          navigatorKey: shellNavigatorKey,
          builder: (context, state, child) {
            return MainScreen(
              toggleTheme: _toggleTheme,
              isDarkMode: _isDarkMode(),
              child: child,
            );
          },
          routes: [
            GoRoute(
              path: AppRoutes.dashboard,
              builder: (context, state) => HomeScreen(
                toggleTheme: _toggleTheme,
                isDarkMode: _isDarkMode(),
              ),
              routes: [
                GoRoute(
                  path: 'help',
                  parentNavigatorKey: rootNavigatorKey,
                  builder: (context, state) => const HelpScreen(),
                ),
                GoRoute(
                  path: 'about',
                  parentNavigatorKey: rootNavigatorKey,
                  builder: (context, state) => const AboutScreen(),
                ),
                GoRoute(
                  path: 'edit-group',
                  parentNavigatorKey: rootNavigatorKey,
                  builder: (context, state) {
                    final extra = state.extra as Map<String, dynamic>;
                    return EditGroupScreen(
                      group: extra['group'] as CameraGroup,
                      onSave: extra['onSave'] as Function(bool),
                    );
                  },
                ),
                GoRoute(
                  path: 'edit-camera',
                  parentNavigatorKey: rootNavigatorKey,
                  builder: (context, state) {
                    final extra = state.extra as Map<String, dynamic>;
                    return EditCameraScreen(camera: extra['camera'] as Camera);
                  },
                ),
                GoRoute(
                  path: 'camera-detail',
                  parentNavigatorKey: rootNavigatorKey,
                  builder: (context, state) {
                    final extra = state.extra as Map<String, dynamic>;
                    return CameraDetailScreen(
                      camera: extra['camera'] as Camera,
                    );
                  },
                ),
                GoRoute(
                  path: 'qr-scanner',
                  parentNavigatorKey: rootNavigatorKey,
                  builder: (context, state) => const QrScannerScreen(),
                ),
                GoRoute(
                  path: 'add-device-manual',
                  parentNavigatorKey: rootNavigatorKey,
                  builder: (context, state) {
                    final extra = state.extra as Map<String, dynamic>? ?? {};
                    return AddDeviceManualScreen(
                      deviceIdFromQR: extra['deviceId'] as String?,
                    );
                  },
                ),
                GoRoute(
                  path: 'add-group',
                  parentNavigatorKey: rootNavigatorKey,
                  builder: (context, state) => const AddGroupScreen(),
                ),
              ],
            ),
            GoRoute(
              path: AppRoutes.me,
              builder: (context, state) => MeScreen(
                toggleTheme: _toggleTheme,
                isDarkMode: _isDarkMode(),
              ),
            ),
          ],
        ),
        GoRoute(
          path: AppRoutes.admin,
          builder: (context, state) => AdminHomeScreen(
            toggleTheme: _toggleTheme,
            isDarkMode: _isDarkMode(),
          ),
        ),
        GoRoute(
          path: '/image-viewer',
          parentNavigatorKey: rootNavigatorKey,
          builder: (context, state) {
            final extra = state.extra as Map<String, dynamic>;
            return ImageViewerScreen(
              imageUrls: List<String>.from(extra['imageUrls'] as List),
              initialIndex: extra['initialIndex'] as int,
              title: extra['title'] as String,
              cameraName: extra['cameraName'] as String,
            );
          },
        ),
      ],
    );
  }
}
