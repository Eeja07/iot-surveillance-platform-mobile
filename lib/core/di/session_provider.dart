// lib/core/di/session_provider.dart
//
// Session Provider Facade — Phase 4 Task 2
//
// This file re-exports the canonical sessionStateProvider from
// session_state_provider.dart for convenience imports.
//
// The old FutureProvider<bool> (Task 1 placeholder) has been superseded by
// the reactive AsyncNotifierProvider<SessionStateNotifier, SessionState>
// which subscribes to SessionService.sessionEvents stream.
//
// Import this file OR session_state_provider.dart — both refer to the same
// provider. Prefer session_state_provider.dart for new code.

export 'session_state_provider.dart'
    show SessionState, SessionStateNotifier, sessionStateProvider;
