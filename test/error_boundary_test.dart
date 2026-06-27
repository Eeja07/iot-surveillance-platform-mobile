import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:Mivion/core/observability/error_boundary.dart';

void main() {
  group('ErrorBoundary Tests', () {
    testWidgets('Renders child when no error occurs', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ErrorBoundary(child: Container(key: const Key('child_widget'))),
        ),
      );

      expect(find.byKey(const Key('child_widget')), findsOneWidget);
      expect(find.text('Terjadi Kesalahan'), findsNothing);
    });

    testWidgets(
      'Catches error and displays fallback UI even when outside MaterialApp',
      (WidgetTester tester) async {
        final boundaryKey = GlobalKey();

        // We render ErrorBoundary WITHOUT MaterialApp to test fallback resilience
        await tester.pumpWidget(
          ErrorBoundary(
            key: boundaryKey,
            child: Builder(
              builder: (context) {
                // Trigger a build error
                throw Exception('Test build error');
              },
            ),
          ),
        );

        // Consume the exception thrown during build
        expect(tester.takeException(), isNotNull);

        // Pump to trigger the post-frame callback that sets the error state
        await tester.pump();
        // Pump transition frame for MaterialApp fallback
        await tester.pump();

        // Should render the fallback UI with custom error title/text
        expect(find.text('Terjadi Kesalahan'), findsOneWidget);
        expect(
          find.text('Terjadi kesalahan internal saat memuat bagian ini.'),
          findsOneWidget,
        );
        expect(find.byIcon(Icons.error_outline), findsOneWidget);
      },
    );
  });
}
