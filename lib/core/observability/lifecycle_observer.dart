import 'package:flutter/material.dart';
import 'observability_service.dart';

class LifecycleObserver extends StatefulWidget {
  final Widget child;
  final VoidCallback? onResumed;

  const LifecycleObserver({super.key, required this.child, this.onResumed});

  @override
  State<LifecycleObserver> createState() => _LifecycleObserverState();
}

class _LifecycleObserverState extends State<LifecycleObserver>
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
    if (state == AppLifecycleState.resumed) {
      widget.onResumed?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
