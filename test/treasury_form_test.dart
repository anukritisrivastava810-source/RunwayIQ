import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:runway_iq/features/onboarding/presentation/steps/treasury_step.dart';
import 'package:runway_iq/features/treasury/domain/models/treasury_investment.dart';

void main() {
  group('TreasuryStep Form & Market-Price Integration Tests', () {
    testWidgets('renders non-market form fields by default (BOND)', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: TreasuryStep(
            companyId: 'test-comp-1',
            companyCurrency: 'USD',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Add Investment'), findsWidgets);
      expect(find.widgetWithText(TextFormField, 'Investment Name'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Total Invested'), findsOneWidget);
      expect(find.text('Expected APY / Yield (optional)'), findsOneWidget);

      // Ticker and Quantity are NOT shown for BOND
      expect(find.text('Ticker Symbol'), findsNothing);
      expect(find.text('Quantity / Units'), findsNothing);
      expect(find.text('Purchase Price/Unit'), findsNothing);
    });

    testWidgets('switching to STOCK reveals Ticker, Quantity, and Purchase Price fields', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: TreasuryStep(
            companyId: 'test-comp-1',
            companyCurrency: 'USD',
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Asset Type dropdown and select Stocks
      final dropdown = find.byType(DropdownButtonFormField<AssetType>);
      expect(dropdown, findsOneWidget);
      await tester.tap(dropdown);
      await tester.pumpAndSettle();

      final stockOption = find.text('Stocks').last;
      await tester.tap(stockOption);
      await tester.pumpAndSettle();

      // Now Ticker, Quantity, and Purchase Price fields must be visible
      expect(find.widgetWithText(TextFormField, 'Ticker Symbol'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Quantity / Units'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Purchase Price/Unit'), findsOneWidget);

      // APY/Yield should be hidden for stocks
      expect(find.text('Expected APY / Yield (optional)'), findsNothing);
    });

    testWidgets('auto-calculates Total Invested as Quantity × Purchase Price', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: TreasuryStep(
            companyId: 'test-comp-1',
            companyCurrency: 'USD',
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Select Stocks
      await tester.tap(find.byType(DropdownButtonFormField<AssetType>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Stocks').last);
      await tester.pumpAndSettle();

      // Enter Quantity = 50
      final unitsField = find.widgetWithText(TextFormField, 'Quantity / Units');
      await tester.enterText(unitsField, '50');
      await tester.pumpAndSettle();

      // With only units entered, Total Invested is not calculated yet
      final totalFieldFinder = find.widgetWithText(TextFormField, 'Total Invested');
      TextFormField totalField = tester.widget(totalFieldFinder);
      expect(totalField.controller?.text, isEmpty);

      // Enter Purchase Price = 120.50
      final priceField = find.widgetWithText(TextFormField, 'Purchase Price/Unit');
      await tester.enterText(priceField, '120.50');
      await tester.pumpAndSettle();

      // Now Total Invested must be auto-calculated to 6025.00 (50 * 120.50)
      totalField = tester.widget(totalFieldFinder);
      expect(totalField.controller?.text, '6025.00');
    });

    testWidgets('avoids calculating Total Invested from invalid or incomplete inputs', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: TreasuryStep(
            companyId: 'test-comp-1',
            companyCurrency: 'USD',
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Select Stocks
      await tester.tap(find.byType(DropdownButtonFormField<AssetType>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Stocks').last);
      await tester.pumpAndSettle();

      // Enter non-numeric quantity
      await tester.enterText(find.widgetWithText(TextFormField, 'Quantity / Units'), 'abc');
      await tester.enterText(find.widgetWithText(TextFormField, 'Purchase Price/Unit'), '100');
      await tester.pumpAndSettle();

      TextFormField totalField = tester.widget(find.widgetWithText(TextFormField, 'Total Invested'));
      expect(totalField.controller?.text, isEmpty);
    });

    testWidgets('validates required Ticker and Quantity for market-priced assets on submit', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: TreasuryStep(
            companyId: 'test-comp-1',
            companyCurrency: 'USD',
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Fill in Name
      await tester.enterText(find.widgetWithText(TextFormField, 'Investment Name'), 'Apple Inc.');

      // Select Stocks
      await tester.tap(find.byType(DropdownButtonFormField<AssetType>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Stocks').last);
      await tester.pumpAndSettle();

      // Submit without entering Ticker or Quantity
      final submitButton = find.widgetWithText(ElevatedButton, 'Add Investment');
      await tester.ensureVisible(submitButton);
      await tester.tap(submitButton);
      await tester.pumpAndSettle();

      expect(find.text('Ticker symbol is required for market-priced assets'), findsOneWidget);
      expect(find.text('Quantity is required'), findsOneWidget);
      expect(find.text('Price is required'), findsOneWidget);
    });

    testWidgets('validates positive quantity and non-negative purchase price', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: TreasuryStep(
            companyId: 'test-comp-1',
            companyCurrency: 'USD',
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.widgetWithText(TextFormField, 'Investment Name'), 'Apple Inc.');

      // Select Stocks
      await tester.tap(find.byType(DropdownButtonFormField<AssetType>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Stocks').last);
      await tester.pumpAndSettle();

      await tester.enterText(find.widgetWithText(TextFormField, 'Ticker Symbol'), 'AAPL');
      await tester.enterText(find.widgetWithText(TextFormField, 'Quantity / Units'), '-5');
      await tester.enterText(find.widgetWithText(TextFormField, 'Purchase Price/Unit'), '-10');

      final submitButton = find.widgetWithText(ElevatedButton, 'Add Investment');
      await tester.ensureVisible(submitButton);
      await tester.tap(submitButton);
      await tester.pumpAndSettle();

      expect(find.text('Must be > 0'), findsOneWidget);
      expect(find.text('Must be ≥ 0'), findsOneWidget);
    });

    testWidgets('pre-populates existing market investment in edit mode', (tester) async {
      final existingStock = TreasuryInvestment(
        id: 'stock-edit-1',
        companyId: 'test-comp-1',
        assetType: AssetType.stock,
        name: 'Apple Growth Holding',
        ticker: 'AAPL',
        units: 100.0,
        purchasePrice: 175.50,
        totalInvested: 17550.0,
        currency: TreasuryCurrency.usd,
        investmentDate: DateTime(2026, 2, 1),
        notes: 'Held in Charles Schwab',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: TreasuryStep(
            companyId: 'test-comp-1',
            companyCurrency: 'USD',
            initialInvestment: existingStock,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Edit Investment'), findsWidgets);
      expect(find.widgetWithText(ElevatedButton, 'Save Changes'), findsOneWidget);

      final nameField = tester.widget<TextFormField>(find.widgetWithText(TextFormField, 'Investment Name'));
      expect(nameField.controller?.text, 'Apple Growth Holding');

      final tickerField = tester.widget<TextFormField>(find.widgetWithText(TextFormField, 'Ticker Symbol'));
      expect(tickerField.controller?.text, 'AAPL');

      final unitsField = tester.widget<TextFormField>(find.widgetWithText(TextFormField, 'Quantity / Units'));
      expect(unitsField.controller?.text, '100.0');

      final priceField = tester.widget<TextFormField>(find.widgetWithText(TextFormField, 'Purchase Price/Unit'));
      expect(priceField.controller?.text, '175.5');

      final totalField = tester.widget<TextFormField>(find.widgetWithText(TextFormField, 'Total Invested'));
      expect(totalField.controller?.text, '17550.00');

      final notesField = tester.widget<TextFormField>(find.widgetWithText(TextFormField, 'Notes / Custodian (optional)'));
      expect(notesField.controller?.text, 'Held in Charles Schwab');
    });
  });
}
