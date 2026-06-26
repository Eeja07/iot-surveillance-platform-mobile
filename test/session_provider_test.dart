import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:MiotVision/core/di/providers.dart';
import 'package:MiotVision/core/di/session_state_provider.dart';
import 'package:MiotVision/core/storage/session_service.dart';
import 'package:MiotVision/core/storage/session_event.dart';
import 'package:MiotVision/features/auth/domain/model/user_model.dart';

class FakeSessionService implements SessionService {
  final _eventController = StreamController<SessionEvent>.broadcast();
  bool _isLoggedInVal = false;
  String? _tokenVal;

  void triggerEvent(SessionEvent event) {
    _eventController.add(event);
  }

  void setLoggedIn(bool value) {
    _isLoggedInVal = value;
    _tokenVal = value ? 'dummy_token' : null;
  }

  @override
  Stream<SessionEvent> get sessionEvents => _eventController.stream;

  @override
  Future<bool> isLoggedIn() async => _isLoggedInVal;

  @override
  Future<String?> getAccessToken() async => _tokenVal;

  @override
  Future<void> saveSession({
    required String token,
    required UserModel user,
  }) async {
    _isLoggedInVal = true;
    _tokenVal = token;
    _eventController.add(SessionEvent.loggedIn);
  }

  @override
  Future<void> clearSession() async {
    _isLoggedInVal = false;
    _tokenVal = null;
    _eventController.add(SessionEvent.loggedOut);
  }

  @override
  Future<void> expireSession() async {
    _isLoggedInVal = false;
    _tokenVal = null;
    _eventController.add(SessionEvent.sessionExpired);
  }

  @override
  Future<void> notifyTokenRefreshed() async {
    _eventController.add(SessionEvent.tokenRefreshed);
  }

  @override
  Future<UserModel?> getCurrentUser() async => null;

  @override
  Future<Map<String, dynamic>?> getUserCache() async => null;

  @override
  void dispose() {
    _eventController.close();
  }
}

void main() {
  late FakeSessionService fakeSessionService;

  setUp(() {
    fakeSessionService = FakeSessionService();
  });

  tearDown(() {
    fakeSessionService.dispose();
  });

  group('SessionStateProvider Tests', () {
    test('initial state handles unauthenticated correctly', () async {
      fakeSessionService.setLoggedIn(false);

      final container = ProviderContainer(
        overrides: [
          sessionServiceProvider.overrideWithValue(fakeSessionService),
        ],
      );
      addTearDown(container.dispose);

      // Verify initially loading state
      expect(
        container.read(sessionStateProvider),
        const AsyncLoading<SessionState>(),
      );

      // Await build completion
      final state = await container.read(sessionStateProvider.future);
      expect(state.isLoggedIn, false);
      expect(state.isExpired, false);
    });

    test('initial state handles authenticated correctly', () async {
      fakeSessionService.setLoggedIn(true);

      final container = ProviderContainer(
        overrides: [
          sessionServiceProvider.overrideWithValue(fakeSessionService),
        ],
      );
      addTearDown(container.dispose);

      final state = await container.read(sessionStateProvider.future);
      expect(state.isLoggedIn, true);
      expect(state.isExpired, false);
    });

    test('handles SessionEvent.loggedIn transition', () async {
      fakeSessionService.setLoggedIn(false);

      final container = ProviderContainer(
        overrides: [
          sessionServiceProvider.overrideWithValue(fakeSessionService),
        ],
      );
      addTearDown(container.dispose);

      // Wait for initial unauthenticated state
      var state = await container.read(sessionStateProvider.future);
      expect(state.isLoggedIn, false);

      // Trigger log in
      fakeSessionService.setLoggedIn(true);
      fakeSessionService.triggerEvent(SessionEvent.loggedIn);

      // Wait for next frame / microtask queue to process stream event
      await Future.delayed(Duration.zero);

      final updatedState = container.read(sessionStateProvider).value;
      expect(updatedState?.isLoggedIn, true);
      expect(updatedState?.isExpired, false);
    });

    test('handles SessionEvent.loggedOut transition', () async {
      fakeSessionService.setLoggedIn(true);

      final container = ProviderContainer(
        overrides: [
          sessionServiceProvider.overrideWithValue(fakeSessionService),
        ],
      );
      addTearDown(container.dispose);

      var state = await container.read(sessionStateProvider.future);
      expect(state.isLoggedIn, true);

      fakeSessionService.setLoggedIn(false);
      fakeSessionService.triggerEvent(SessionEvent.loggedOut);

      await Future.delayed(Duration.zero);

      final updatedState = container.read(sessionStateProvider).value;
      expect(updatedState?.isLoggedIn, false);
      expect(updatedState?.isExpired, false);
    });

    test('handles SessionEvent.sessionExpired transition', () async {
      fakeSessionService.setLoggedIn(true);

      final container = ProviderContainer(
        overrides: [
          sessionServiceProvider.overrideWithValue(fakeSessionService),
        ],
      );
      addTearDown(container.dispose);

      var state = await container.read(sessionStateProvider.future);
      expect(state.isLoggedIn, true);

      fakeSessionService.setLoggedIn(false);
      fakeSessionService.triggerEvent(SessionEvent.sessionExpired);

      await Future.delayed(Duration.zero);

      final updatedState = container.read(sessionStateProvider).value;
      expect(updatedState?.isLoggedIn, false);
      expect(updatedState?.isExpired, true);
    });
  });
}
