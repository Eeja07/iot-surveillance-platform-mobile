import 'package:flutter/material.dart';
import 'observability_service.dart';

class ErrorBoundary extends StatefulWidget {
  final Widget child;
  final Widget Function(BuildContext context, Object error)? fallbackBuilder;

  const ErrorBoundary({super.key, required this.child, this.fallbackBuilder});

  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  Object? _error;
  late ErrorWidgetBuilder _originalErrorBuilder;

  @override
  void initState() {
    super.initState();
    _hookErrorBuilder();
  }

  @override
  void dispose() {
    _unhookErrorBuilder();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant ErrorBoundary oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_error != null) {
      setState(() => _error = null);
    }
  }

  void reset() {
    setState(() => _error = null);
  }

  void _hookErrorBuilder() {
    _originalErrorBuilder = ErrorWidget.builder;
    ErrorWidget.builder = (FlutterErrorDetails details) {
      ObservabilityService.instance.reportError(
        details.exception,
        details.stack,
        hint: 'ErrorBoundary caught builder error',
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _error = details.exception;
          });
        }
      });
      return const SizedBox.shrink();
    };
  }

  void _unhookErrorBuilder() {
    ErrorWidget.builder = _originalErrorBuilder;
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      if (widget.fallbackBuilder != null) {
        return widget.fallbackBuilder!(context, _error!);
      }

      final hasDirectionality = Directionality.maybeOf(context) != null;

      Widget buildContent(BuildContext buildCtx) {
        Brightness? brightness;
        try {
          brightness = Theme.of(buildCtx).brightness;
        } catch (_) {
          brightness = Brightness.light;
        }
        final isDark = brightness == Brightness.dark;
        return Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, color: Colors.red[400], size: 80),
                  const SizedBox(height: 24),
                  const Text(
                    'Terjadi Kesalahan',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Terjadi kesalahan internal saat memuat bagian ini.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: reset,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Coba Lagi'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }

      if (!hasDirectionality) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          home: Builder(
            builder: (ctx) => buildContent(ctx),
          ),
        );
      }

      return buildContent(context);
    }

    return widget.child;
  }
}
