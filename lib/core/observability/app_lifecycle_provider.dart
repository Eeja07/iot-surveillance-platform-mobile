// lib/core/observability/app_lifecycle_provider.dart
//
// Exposes the current [AppLifecycleState] as a Riverpod provider so any
// service layer (e.g. DashboardSync) can check whether the app is in the
// foreground without touching a BuildContext.
//
// The provider is updated by [LifecycleObserver] (which already registers a
// WidgetsBindingObserver) — see lifecycle_observer.dart.

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The current [AppLifecycleState] of the application.
///
/// Defaults to [AppLifecycleState.resumed] so that on a cold start (before any
/// lifecycle callback fires) the app is treated as being in the foreground.
///
/// Updated by [LifecycleObserver] via `ref.read(appLifecycleProvider.notifier)`.
final appLifecycleProvider = StateProvider<AppLifecycleState>(
  (ref) => AppLifecycleState.resumed,
  name: 'appLifecycleProvider',
);
