// lib/core/di/auth_provider.dart
//
// AuthProvider Introduction — Phase 4 Task 3
//
// Adapter layer between AuthController (ChangeNotifier) and Riverpod.
//
// Design contract:
// - AuthController is NOT modified (zero changes to auth_controller.dart)
// - All actions are delegated to AuthController — no business logic here
// - AuthNotifier listens to AuthController's ChangeNotifier to sync state
// - UI uses: ref.watch(authProvider)         → AuthState
//            ref.read(authProvider.notifier)  → AuthNotifier (for actions)
// - SessionProvider / GoRouter are NOT affected

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/domain/model/user_model.dart';
import 'providers.dart';

// ---------------------------------------------------------------------------
// AuthState — immutable value object
// ---------------------------------------------------------------------------

/// Immutable snapshot of the current auth UI state.
///
/// Mirrors the three public getters of [AuthController]:
///   [currentUser], [isLoading], [errorMessage]
///
/// Keeps Presentation layer free of direct ChangeNotifier dependency.
class AuthState {
  final UserModel? currentUser;
  final bool isLoading;
  final String? errorMessage;

  const AuthState({
    this.currentUser,
    this.isLoading = false,
    this.errorMessage,
  });

  /// Convenience: true when a user object is present.
  bool get isAuthenticated => currentUser != null;

  /// Convenience: true when current user has admin role.
  bool get isAdmin => currentUser?.isAdmin ?? false;

  /// Returns a copy with the specified fields overridden.
  AuthState copyWith({
    UserModel? currentUser,
    bool clearUser = false,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AuthState(
      currentUser: clearUser ? null : (currentUser ?? this.currentUser),
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  String toString() =>
      'AuthState('
      'user: ${currentUser?.email}, '
      'isLoading: $isLoading, '
      'error: $errorMessage)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthState &&
          other.currentUser == currentUser &&
          other.isLoading == isLoading &&
          other.errorMessage == errorMessage;

  @override
  int get hashCode => Object.hash(currentUser, isLoading, errorMessage);
}

// ---------------------------------------------------------------------------
// AuthNotifier — adapter Notifier
// ---------------------------------------------------------------------------

/// Adapter between [AuthController] (ChangeNotifier) and Riverpod.
///
/// Subscribes to [AuthController] change notifications and mirrors its state
/// into the immutable [AuthState] managed by Riverpod.
///
/// All write operations are delegated to [AuthController] — no logic lives
/// in this class beyond translating return values to state updates.
class AuthNotifier extends Notifier<AuthState> {
  VoidCallback? _listener;

  @override
  AuthState build() {
    final controller = ref.watch(authControllerProvider);

    // Remove old listener before re-registering (in case of rebuild)
    ref.onDispose(() {
      if (_listener != null) {
        controller.removeListener(_listener!);
      }
    });

    // Sync Riverpod state whenever AuthController notifies
    _listener = () {
      state = _fromController(controller);
    };
    controller.addListener(_listener!);

    // Capture initial state immediately (AuthController may have loaded from
    // cache before this notifier was first built)
    return _fromController(controller);
  }

  // --------------------------------------------------------------------------
  // Actions — all delegated to AuthController
  // --------------------------------------------------------------------------

  /// Delegates to [AuthController.login].
  ///
  /// Returns true on success; on failure [state.errorMessage] is populated.
  Future<bool> login(String email, String password) {
    final controller = ref.read(authControllerProvider);
    return controller.login(email, password);
  }

  /// Delegates to [AuthController.logout].
  ///
  /// Returns true on success.
  Future<bool> logout() {
    final controller = ref.read(authControllerProvider);
    return controller.logout();
  }

  /// Delegates to [AuthController.clearError].
  Future<void> clearError() {
    final controller = ref.read(authControllerProvider);
    return controller.clearError();
  }

  // --------------------------------------------------------------------------
  // Private helpers
  // --------------------------------------------------------------------------

  /// Converts [AuthController] getters to an immutable [AuthState] snapshot.
  AuthState _fromController(controller) {
    return AuthState(
      currentUser: controller.currentUser,
      isLoading: controller.isLoading,
      errorMessage: controller.errorMessage,
    );
  }
}

// ---------------------------------------------------------------------------
// Public provider
// ---------------------------------------------------------------------------

/// Watch this provider to reactively respond to auth state changes.
///
/// ```dart
/// // Read state in ConsumerWidget:
/// final auth = ref.watch(authProvider);
/// if (auth.isLoading) return CircularProgressIndicator();
/// if (auth.errorMessage != null) return Text(auth.errorMessage!);
///
/// // Trigger actions (does NOT trigger rebuild by itself):
/// await ref.read(authProvider.notifier).login(email, password);
/// await ref.read(authProvider.notifier).logout();
/// ```
///
/// AuthController, SessionService, and GoRouter are NOT affected.
final authProvider = NotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
  name: 'authProvider',
);
