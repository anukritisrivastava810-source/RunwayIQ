import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:runway_iq/features/funding/domain/models/funding_round.dart';
import 'package:runway_iq/features/onboarding/presentation/steps/funding_step.dart';
import 'package:runway_iq/screens/funding_screen.dart';
import 'package:runway_iq/theme/app_theme.dart';

void main() {
  group('FundingRoundType.fromDisplayName tests', () {
    test('parses common round display names correctly', () {
      expect(FundingRoundType.fromDisplayName('Pre-seed'), FundingRoundType.preSeed);
      expect(FundingRoundType.fromDisplayName('Pre-Seed'), FundingRoundType.preSeed);
      expect(FundingRoundType.fromDisplayName('Seed'), FundingRoundType.seed);
      expect(FundingRoundType.fromDisplayName('Series A'), FundingRoundType.seriesA);
      expect(FundingRoundType.fromDisplayName('Series B'), FundingRoundType.seriesB);
      expect(FundingRoundType.fromDisplayName('Series C'), FundingRoundType.seriesC);
      expect(FundingRoundType.fromDisplayName('Series C+'), FundingRoundType.seriesC);
      expect(FundingRoundType.fromDisplayName('Bridge'), FundingRoundType.bridge);
      expect(FundingRoundType.fromDisplayName('Debt'), FundingRoundType.debt);
      expect(FundingRoundType.fromDisplayName('Grant'), FundingRoundType.grant);
      expect(FundingRoundType.fromDisplayName('IPO'), FundingRoundType.ipo);
      expect(FundingRoundType.fromDisplayName(null), FundingRoundType.seed);
      expect(FundingRoundType.fromDisplayName('unknown'), FundingRoundType.seed);
    });
  });

  group('FundingStep Standalone UI Tests', () {
    testWidgets('renders all expected form fields in standalone mode', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const FundingStep(
            companyId: 'test-company-id',
            companyCurrency: 'USD',
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify AppBar
      expect(find.text('Add Funding Round'), findsNWidgets(2)); // AppBar title + button

      // Verify Form Fields
      expect(find.text('Round'), findsOneWidget);
      expect(find.text('Lead Investor Name'), findsOneWidget);
      expect(find.text('Investment Amount'), findsOneWidget);
      expect(find.text('Currency'), findsOneWidget);
      expect(find.text('Equity Percentage (optional)'), findsOneWidget);
      expect(find.text('Closing Date'), findsOneWidget);
      expect(find.text('Notes (optional)'), findsOneWidget);

      // Verify submit button
      expect(find.widgetWithText(ElevatedButton, 'Add Funding Round'), findsOneWidget);
    });

    testWidgets('validates required fields on submit', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const FundingStep(
            companyId: 'test-company-id',
            companyCurrency: 'USD',
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap submit with empty required fields
      await tester.tap(find.widgetWithText(ElevatedButton, 'Add Funding Round'));
      await tester.pumpAndSettle();

      // Check validation error messages
      expect(find.text('Investor name is required'), findsOneWidget);
      expect(find.text('Amount is required'), findsOneWidget);
    });
  });

  group('FundingScreen FAB Tests', () {
    testWidgets('has floating action button with add icon', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const FundingScreen(),
        ),
      );

      // Fast-forward past network timeouts from initState
      await tester.pump(const Duration(seconds: 16));
      await tester.pumpAndSettle();

      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);
    });
  });
}
