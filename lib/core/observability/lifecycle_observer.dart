import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app_lifecycle_provider.dart';
import 'observability_service.dart';

/// Wraps a child widget and listens to [AppLifecycleState] changes.
///
/// On every change it:
///   1. Updates [appLifecycleProvider] so service-layer code (e.g. DashboardSync)
///      can decide whether the app is in the foreground.
///   2. Calls the optional [onResumed] callback.
class LifecycleObserver extends ConsumerStatefulWidget {
  final Widget child;
  final VoidCallback? onResumed;

  const LifecycleObserver({super.key, required this.child, this.onResumed});

  @override
  ConsumerState<LifecycleObserver> createState() => _LifecycleObserverState();
}

class _LifecycleObserverState extends ConsumerState<LifecycleObserver>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    ObservabilityService.instance.info('LifecycleObserver initialized');
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    ObservabilityService.instance.info('LifecycleObserver disposed');
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    ObservabilityService.instance.info(
      'App Lifecycle State changed to: ${state.name}',
    );

    // Update the shared provider so services can read it without a context.
    ref.read(appLifecycleProvider.notifier).state = state;

    if (state == AppLifecycleState.resumed) {
      widget.onResumed?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
