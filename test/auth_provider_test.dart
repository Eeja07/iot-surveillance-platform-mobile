import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:Mivion/core/di/providers.dart';
import 'package:Mivion/core/di/auth_provider.dart';
import 'package:Mivion/features/auth/domain/model/user_model.dart';
import 'package:Mivion/features/auth/presentation/auth_controller.dart';

class FakeAuthController extends ChangeNotifier implements AuthController {
  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  UserModel? get currentUser => _currentUser;

  @override
  bool get isLoading => _isLoading;

  @override
  String? get errorMessage => _errorMessage;

  void setCurrentUser(UserModel? user) {
    _currentUser = user;
    notifyListeners();
  }

  void setLoading(bool val) {
    _isLoading = val;
    notifyListeners();
  }

  void setErrorMessage(String? msg) {
    _errorMessage = msg;
    notifyListeners();
  }

  bool loginCalled = false;
  String? lastLoginEmail;
  String? lastLoginPassword;
  bool loginResult = true;

  @override
  Future<bool> login(String email, String password) async {
    loginCalled = true;
    lastLoginEmail = email;
    lastLoginPassword = password;
    return loginResult;
  }

  bool logoutCalled = false;
  bool logoutResult = true;

  @override
  Future<bool> logout() async {
    logoutCalled = true;
    return logoutResult;
  }

  @override
  void clearLocalSession() {
    _currentUser = null;
    _errorMessage = null;
    notifyListeners();
  }

  bool clearErrorCalled = false;

  @override
  Future<void> clearError() async {
    clearErrorCalled = true;
  }
}

void main() {
  late FakeAuthController fakeAuthController;

  setUp(() {
    fakeAuthController = FakeAuthController();
  });

  group('AuthProvider Tests', () {
    test('initializes state from AuthController correctly', () {
      final user = UserModel(
        id: 1,
        name: 'Alice',
        email: 'alice@example.com',
        role: 'admin',
      );
      fakeAuthController.setCurrentUser(user);
      fakeAuthController.setLoading(false);
      fakeAuthController.setErrorMessage('Some error');

      final container = ProviderContainer(
        overrides: [
          authControllerProvider.overrideWithValue(fakeAuthController),
        ],
      );
      addTearDown(container.dispose);

      final state = container.read(authProvider);
      expect(state.currentUser, user);
      expect(state.isLoading, false);
      expect(state.errorMessage, 'Some error');
      expect(state.isAuthenticated, true);
      expect(state.isAdmin, true);
    });

    test('listens and syncs updates from AuthController', () {
      final container = ProviderContainer(
        overrides: [
          authControllerProvider.overrideWithValue(fakeAuthController),
        ],
      );
      addTearDown(container.dispose);

      // Verify default state
      var state = container.read(authProvider);
      expect(state.currentUser, null);
      expect(state.isLoading, false);
      expect(state.errorMessage, null);

      // Update values and notify
      final user = UserModel(
        id: 2,
        name: 'Bob',
        email: 'bob@example.com',
        role: 'user',
      );
      fakeAuthController.setCurrentUser(user);
      fakeAuthController.setLoading(true);
      fakeAuthController.setErrorMessage('Network timeout');

      state = container.read(authProvider);
      expect(state.currentUser, user);
      expect(state.isLoading, true);
      expect(state.errorMessage, 'Network timeout');
      expect(state.isAuthenticated, true);
      expect(state.isAdmin, false);
    });

    test('delegates login to AuthController', () async {
      final container = ProviderContainer(
        overrides: [
          authControllerProvider.overrideWithValue(fakeAuthController),
        ],
      );
      addTearDown(container.dispose);

      fakeAuthController.loginResult = true;
      final success = await container
          .read(authProvider.notifier)
          .login('bob@example.com', 'password123');

      expect(success, true);
      expect(fakeAuthController.loginCalled, true);
      expect(fakeAuthController.lastLoginEmail, 'bob@example.com');
      expect(fakeAuthController.lastLoginPassword, 'password123');
    });

    test('delegates logout to AuthController', () async {
      final container = ProviderContainer(
        overrides: [
          authControllerProvider.overrideWithValue(fakeAuthController),
        ],
      );
      addTearDown(container.dispose);

      fakeAuthController.logoutResult = true;
      final success = await container.read(authProvider.notifier).logout();

      expect(success, true);
      expect(fakeAuthController.logoutCalled, true);
    });

    test('delegates clearError to AuthController', () async {
      final container = ProviderContainer(
        overrides: [
          authControllerProvider.overrideWithValue(fakeAuthController),
        ],
      );
      addTearDown(container.dispose);

      await container.read(authProvider.notifier).clearError();
      expect(fakeAuthController.clearErrorCalled, true);
    });
  });
}
