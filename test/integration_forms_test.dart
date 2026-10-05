import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:runway_iq/features/onboarding/presentation/steps/team_setup_step.dart';
import 'package:runway_iq/features/onboarding/presentation/steps/financial_setup_step.dart';
import 'package:runway_iq/features/onboarding/presentation/steps/treasury_step.dart';

void main() {
  group('TeamSetupStep Standalone Mode UI Tests', () {
    testWidgets('renders all expected form fields for Add Employee', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: TeamSetupStep(
            companyId: 'test-comp-1',
            companyCurrency: 'USD',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Add Employee'), findsWidgets);
      expect(find.widgetWithText(TextFormField, 'First Name'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Last Name'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Email Address'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Role / Job Title'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Annual Salary'), findsOneWidget);
    });

    testWidgets('validates required fields on Add Employee submit', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: TeamSetupStep(
            companyId: 'test-comp-1',
            companyCurrency: 'USD',
          ),
        ),
      );
      await tester.pumpAndSettle();

      final button = find.widgetWithText(ElevatedButton, 'Add Employee');
      expect(button, findsOneWidget);
      await tester.ensureVisible(button);
      await tester.tap(button);
      await tester.pumpAndSettle();

      expect(find.text('Required'), findsWidgets);
      expect(find.text('Email is required'), findsOneWidget);
      expect(find.text('Role is required'), findsOneWidget);
      expect(find.text('Salary is required'), findsOneWidget);
    });
  });

  group('FinancialSetupStep Standalone Mode UI Tests', () {
    testWidgets('renders all expected form fields for Add Expense', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: FinancialSetupStep(
            companyId: 'test-comp-1',
            companyCurrency: 'USD',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Add Expense'), findsWidgets);
      expect(find.widgetWithText(TextFormField, 'Expense Title'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Amount'), findsOneWidget);
      expect(find.text('Category'), findsOneWidget);
      expect(find.text('Recurrence'), findsOneWidget);
    });

    testWidgets('validates required fields on Add Expense submit', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: FinancialSetupStep(
            companyId: 'test-comp-1',
            companyCurrency: 'USD',
          ),
        ),
      );
      await tester.pumpAndSettle();

      final button = find.widgetWithText(ElevatedButton, 'Add Expense');
      expect(button, findsOneWidget);
      await tester.ensureVisible(button);
      await tester.tap(button);
      await tester.pumpAndSettle();

      expect(find.text('Title is required'), findsOneWidget);
      expect(find.text('Amount is required'), findsOneWidget);
    });
  });

  group('TreasuryStep Standalone Mode UI Tests', () {
    testWidgets('renders all expected form fields for Add Investment', (tester) async {
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
      expect(find.text('Asset Type'), findsOneWidget);
    });

    testWidgets('validates required fields on Add Investment submit', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: TreasuryStep(
            companyId: 'test-comp-1',
            companyCurrency: 'USD',
          ),
        ),
      );
      await tester.pumpAndSettle();

      final button = find.widgetWithText(ElevatedButton, 'Add Investment');
      expect(button, findsOneWidget);
      await tester.tap(button);
      await tester.pumpAndSettle();

      expect(find.text('Name is required'), findsOneWidget);
      expect(find.text('Amount is required'), findsOneWidget);
    });
  });
}
