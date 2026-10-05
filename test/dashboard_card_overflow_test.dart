import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:runway_iq/theme/app_theme.dart';
import 'package:runway_iq/widgets/stats_card.dart';

void main() {
  group('StatsCard and Metrics Layout Overflow Tests', () {
    final screenSizes = [
      const Size(320, 568), // iPhone SE 1st gen / very narrow
      const Size(360, 640), // Standard Android
      const Size(375, 667), // iPhone 8 / SE 2nd gen
      const Size(390, 844), // iPhone 12 / 13 / 14
      const Size(414, 896), // iPhone 11 / XR
      const Size(768, 1024), // iPad / Tablet
    ];

    for (final size in screenSizes) {
      testWidgets('Renders metrics cards without overflow on ${size.width}x${size.height}',
          (WidgetTester tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              body: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Expanded(
                            child: StatsCard(
                              title: 'Available Cash',
                              value: '\$125.0k',
                              trend: 'Current',
                              isPositive: true,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: StatsCard(
                              title: 'Runway',
                              value: '12 mo',
                              trend: 'Based on burn',
                              isPositive: true,
                              isHighlighted: true,
                              onTap: () {},
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: const [
                          Expanded(
                            child: StatsCard(
                              title: 'Monthly Burn',
                              value: '\$10.5k',
                              trend: 'Current',
                              isPositive: false,
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: StatsCard(
                              title: 'Total Raised',
                              value: '\$1.5M',
                              trend: 'Seed',
                              isPositive: true,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Check for no overflow exceptions
        expect(tester.takeException(), isNull);

        // Verify all 4 card titles exist
        expect(find.text('Available Cash'), findsOneWidget);
        expect(find.text('Runway'), findsOneWidget);
        expect(find.text('Monthly Burn'), findsOneWidget);
        expect(find.text('Total Raised'), findsOneWidget);

        // Verify values and subtitles
        expect(find.text('\$125.0k'), findsOneWidget);
        expect(find.text('12 mo'), findsOneWidget);
        expect(find.text('\$10.5k'), findsOneWidget);
        expect(find.text('\$1.5M'), findsOneWidget);
        expect(find.text('Based on burn'), findsOneWidget);
        expect(find.text('Seed'), findsOneWidget);
      });
    }

    testWidgets('Renders with large text scale without overflow',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(1.3)),
            child: Scaffold(
              body: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Expanded(
                            child: StatsCard(
                              title: 'Available Cash',
                              value: '\$125.0k',
                              trend: 'Current',
                              isPositive: true,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: StatsCard(
                              title: 'Runway',
                              value: '12 mo',
                              trend: 'Based on burn',
                              isPositive: true,
                              isHighlighted: true,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: const [
                          Expanded(
                            child: StatsCard(
                              title: 'Monthly Burn',
                              value: '\$10.5k',
                              trend: 'Current',
                              isPositive: false,
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: StatsCard(
                              title: 'Total Raised',
                              value: '\$1.5M',
                              trend: 'Seed',
                              isPositive: true,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });
}
