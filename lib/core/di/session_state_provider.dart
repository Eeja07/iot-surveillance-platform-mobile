// lib/core/di/session_state_provider.dart
//
// SessionProvider Migration — Phase 4 Task 2
//
// Provides a reactive [SessionState] that tracks authentication state
// by listening to [SessionService.sessionEvents] stream.
//
// Design contract:
// - SessionService is NOT modified here (zero changes to session_service.dart)
// - GoRouter remains the source of truth for navigation
// - RouterRedirect remains the authority for redirect logic
// - This provider only EXPOSES state — it does not navigate
// - UI uses: ref.watch(sessionStateProvider) -> AsyncValue<SessionState>

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../storage/session_event.dart';
import '../storage/session_service.dart';
import 'providers.dart';

// ---------------------------------------------------------------------------
// SessionState — immutable value object
// ---------------------------------------------------------------------------

/// Immutable snapshot of the current session.
///
/// [isLoggedIn] reflects whether a valid token exists.
/// [isExpired]  is true when the session was terminated by the server.
/// [user]       is non-null when the cache is available (may lag one event).
class SessionState {
  final bool isLoggedIn;
  final bool isExpired;

  const SessionState({required this.isLoggedIn, this.isExpired = false});

  /// Initial unauthenticated state before the first async check completes.
  static const unauthenticated = SessionState(isLoggedIn: false);

  /// Authenticated state after a successful login event.
  static const authenticated = SessionState(isLoggedIn: true);

  /// Session expired state (e.g. server forced logout / token invalidated).
  static const expired = SessionState(isLoggedIn: false, isExpired: true);

  @override
  String toString() =>
      'SessionState(isLoggedIn: $isLoggedIn, isExpired: $isExpired)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SessionState &&
          other.isLoggedIn == isLoggedIn &&
          other.isExpired == isExpired;

  @override
  int get hashCode => Object.hash(isLoggedIn, isExpired);
}

// ---------------------------------------------------------------------------
// SessionStateNotifier — reactive AsyncNotifier
// ---------------------------------------------------------------------------

/// Listens to [SessionService.sessionEvents] and translates each [SessionEvent]
/// into an updated [SessionState].
///
/// Lifecycle:
///   build()   → reads isLoggedIn() from storage as initial state
///   _listen() → subscribes to sessionEvents broadcast stream
///   dispose   → StreamSubscription is cancelled automatically by ref.onDispose
class SessionStateNotifier extends AsyncNotifier<SessionState> {
  StreamSubscription<SessionEvent>? _eventSub;

  @override
  Future<SessionState> build() async {
    final sessionService = ref.watch(sessionServiceProvider);

    // Cancel any existing subscription before rebuilding
    ref.onDispose(() => _eventSub?.cancel());

    // Subscribe to the broadcast stream from SessionService
    _eventSub = sessionService.sessionEvents.listen(
      (event) => _onSessionEvent(event),
    );

    // Resolve initial state from storage (async)
    final loggedIn = await sessionService.isLoggedIn();
    return loggedIn ? SessionState.authenticated : SessionState.unauthenticated;
  }

  // --------------------------------------------------------------------------
  // Private — event handler
  // --------------------------------------------------------------------------

  void _onSessionEvent(SessionEvent event) {
    switch (event) {
      case SessionEvent.loggedIn:
        state = const AsyncData(SessionState.authenticated);
      case SessionEvent.loggedOut:
        state = const AsyncData(SessionState.unauthenticated);
      case SessionEvent.sessionExpired:
        state = const AsyncData(SessionState.expired);
      case SessionEvent.tokenRefreshed:
        // Token refresh does not change isLoggedIn — keep current state.
        // Re-read from storage in case state was stale.
        _refreshFromStorage();
    }
  }

  Future<void> _refreshFromStorage() async {
    final sessionService = ref.read(sessionServiceProvider);
    final loggedIn = await sessionService.isLoggedIn();
    state = AsyncData(
      loggedIn ? SessionState.authenticated : SessionState.unauthenticated,
    );
  }
}

// ---------------------------------------------------------------------------
// Public provider
// ---------------------------------------------------------------------------

/// Watch this provider to reactively react to authentication state changes.
///
/// ```dart
/// // In a ConsumerWidget:
/// final sessionAsync = ref.watch(sessionStateProvider);
/// sessionAsync.when(
///   data: (s) => s.isLoggedIn ? HomeWidget() : LoginWidget(),
///   loading: () => SplashWidget(),
///   error: (e, _) => ErrorWidget(),
/// );
/// ```
///
/// GoRouter / RouterRedirect are NOT affected by this provider.
final sessionStateProvider =
    AsyncNotifierProvider<SessionStateNotifier, SessionState>(
      SessionStateNotifier.new,
      name: 'sessionStateProvider',
    );
