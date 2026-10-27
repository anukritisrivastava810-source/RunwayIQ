import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:runway_iq/core/network/api_client.dart';
import 'package:runway_iq/core/network/api_exceptions.dart';
import 'package:runway_iq/features/company/data/repositories/company_repository.dart';
import 'package:runway_iq/features/scenario/data/repositories/scenario_repository.dart';
import 'package:runway_iq/screens/runway_screen.dart';
import 'package:runway_iq/theme/app_theme.dart';

// ── Mock API client ────────────────────────────────────────────────────────────

class MockRunwayApiClient extends ApiClient {
  final Map<String, dynamic> getResponses = {};
  final Map<String, ApiException> getErrors = {};
  final Map<String, dynamic> postResponses = {};
  final Map<String, ApiException> postErrors = {};
  final Map<String, dynamic> putResponses = {};
  final Map<String, ApiException> putErrors = {};
  final Map<String, dynamic> deleteResponses = {};
  final Map<String, ApiException> deleteErrors = {};

  @override
  Future<dynamic> get(String path,
      {Map<String, dynamic>? queryParameters}) async {
    if (getErrors.containsKey(path)) throw getErrors[path]!;
    if (getResponses.containsKey(path)) return getResponses[path];
    return {'data': []};
  }

  @override
  Future<dynamic> post(String path,
      {dynamic data, Map<String, dynamic>? queryParameters}) async {
    if (postErrors.containsKey(path)) throw postErrors[path]!;
    if (postResponses.containsKey(path)) return postResponses[path];
    return {'data': null};
  }

  @override
  Future<dynamic> put(String path,
      {dynamic data, Map<String, dynamic>? queryParameters}) async {
    if (putErrors.containsKey(path)) throw putErrors[path]!;
    if (putResponses.containsKey(path)) return putResponses[path];
    return {'data': null};
  }

  @override
  Future<dynamic> delete(String path,
      {dynamic data, Map<String, dynamic>? queryParameters}) async {
    if (deleteErrors.containsKey(path)) throw deleteErrors[path]!;
    if (deleteResponses.containsKey(path)) return deleteResponses[path];
    return {'data': null, 'message': 'Deleted'};
  }
}

// ── Test helpers ──────────────────────────────────────────────────────────────

MockRunwayApiClient _setupWithCompany({
  String companyId = 'co-1',
  String companyName = 'Acme AI',
  double? simulatedRunway = 10.0,
  double baseCash = 300000.0,
  double baseBurn = 30000.0,
  List<Map<String, dynamic>> scenarios = const [],
}) {
  final client = MockRunwayApiClient();

  client.getResponses['/company'] = [
    {'id': companyId, 'name': companyName, 'stage': 'SEED', 'currency': 'USD'}
  ];

  client.getResponses['/scenarios/company/$companyId'] = {'data': scenarios};

  client.postResponses['/scenarios/simulate'] = {
    'data': {
      'companyId': companyId,
      'scenarioId': null,
      'scenarioName': null,
      'baseline': {
        'cash': baseCash,
        'burn': baseBurn,
        'runway': simulatedRunway,
      },
      'simulated': {
        'cash': baseCash,
        'burn': baseBurn,
        'runway': simulatedRunway,
      },
      'adjustments': {
        'additionalBurn': 0.0,
        'additionalRevenue': 0.0,
        'additionalCash': 0.0,
      },
    }
  };

  return client;
}

Future<void> _pumpRunwayScreen(
    WidgetTester tester, MockRunwayApiClient client) async {
  tester.view.physicalSize = const Size(1200, 2000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final companyRepo = CompanyRepository(apiClient: client);
  final scenarioRepo = ScenarioRepository(apiClient: client);
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.lightTheme,
      home: Scaffold(
        body: RunwayScreen(
          companyRepository: companyRepo,
          scenarioRepository: scenarioRepo,
        ),
      ),
    ),
  );
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  group('RunwayScreen Widget Tests', () {
    testWidgets('shows loading indicator while fetching initial data',
        (WidgetTester tester) async {
      final client = _setupWithCompany();
      await _pumpRunwayScreen(tester, client);

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.pumpAndSettle();
    });

    testWidgets('displays baseline financial metrics from backend response',
        (WidgetTester tester) async {
      final client = _setupWithCompany(
        baseCash: 300000.0,
        baseBurn: 30000.0,
      );
      await _pumpRunwayScreen(tester, client);
      await tester.pumpAndSettle();

      expect(find.text('\$300.0k'), findsOneWidget);
      expect(find.text('\$30.0k'), findsOneWidget);
      expect(find.text('Cash Available'), findsOneWidget);
      expect(find.text('Monthly Burn'), findsOneWidget);
    });

    testWidgets('displays finite runway in circular indicator',
        (WidgetTester tester) async {
      final client = _setupWithCompany(simulatedRunway: 10.0);
      await _pumpRunwayScreen(tester, client);
      await tester.pumpAndSettle();

      expect(find.text('10.0'), findsOneWidget);
      expect(find.text('Months'), findsOneWidget);
    });

    testWidgets('displays Unlimited text when runway is null (burn <= 0)',
        (WidgetTester tester) async {
      final client = _setupWithCompany(simulatedRunway: null);
      await _pumpRunwayScreen(tester, client);
      await tester.pumpAndSettle();

      expect(find.text('∞'), findsOneWidget);
      expect(find.text('Unlimited'), findsOneWidget);
    });

    testWidgets('displays depleted state when runway is 0.0 (cash <= 0)',
        (WidgetTester tester) async {
      final client = _setupWithCompany(simulatedRunway: 0.0);
      await _pumpRunwayScreen(tester, client);
      await tester.pumpAndSettle();

      expect(find.text('0'), findsOneWidget);
      expect(find.text('Depleted'), findsOneWidget);
    });

    testWidgets('shows empty state when company has no saved scenarios',
        (WidgetTester tester) async {
      final client = _setupWithCompany(scenarios: []);
      await _pumpRunwayScreen(tester, client);
      await tester.pumpAndSettle();

      expect(find.text('No saved scenarios yet.'), findsOneWidget);
      expect(find.text('Adjust the inputs above and tap Save.'), findsOneWidget);
    });

    testWidgets('displays list of saved scenarios',
        (WidgetTester tester) async {
      final client = _setupWithCompany(scenarios: [
        {
          'id': 's-1',
          'companyId': 'co-1',
          'name': 'Hire 2 Engineers',
          'baseCash': 300000.0,
          'baseMonthlyBurn': 30000.0,
          'additionalBurn': 15000.0,
          'additionalRevenue': 0.0,
          'additionalCash': 0.0,
          'currency': 'USD',
          'isActive': true,
        }
      ]);
      await _pumpRunwayScreen(tester, client);
      await tester.pumpAndSettle();

      expect(find.text('Hire 2 Engineers'), findsOneWidget);
      expect(find.text('+15000 burn'), findsOneWidget);
    });

    testWidgets('simulates new adjustments on button tap and displays results',
        (WidgetTester tester) async {
      final client = _setupWithCompany();
      client.postResponses['/scenarios/simulate'] = {
        'data': {
          'companyId': 'co-1',
          'scenarioId': null,
          'baseline': {'cash': 300000.0, 'burn': 30000.0, 'runway': 10.0},
          'simulated': {'cash': 300000.0, 'burn': 45000.0, 'runway': 6.7},
          'adjustments': {
            'additionalBurn': 15000.0,
            'additionalRevenue': 0.0,
            'additionalCash': 0.0
          },
        }
      };

      await _pumpRunwayScreen(tester, client);
      await tester.pumpAndSettle();

      // Enter additional burn
      final burnField = find.widgetWithText(TextField, 'Additional Monthly Burn');
      await tester.ensureVisible(burnField);
      await tester.enterText(burnField, '15000');

      // Tap Simulate
      final simBtn = find.text('Simulate');
      await tester.ensureVisible(simBtn);
      await tester.tap(simBtn);
      await tester.pumpAndSettle();

      // Simulation Results card should appear
      expect(find.text('Simulation Results'), findsOneWidget);
      expect(find.text('+Burn'), findsOneWidget);
      expect(find.text('\$45.0k'), findsWidgets);
    });

    testWidgets('creates and saves new scenario via dialog',
        (WidgetTester tester) async {
      final client = _setupWithCompany();
      client.postResponses['/scenarios'] = {
        'data': {
          'id': 's-new',
          'companyId': 'co-1',
          'name': 'Hiring Freeze',
          'baseCash': 300000.0,
          'baseMonthlyBurn': 30000.0,
          'additionalBurn': 0.0,
          'additionalRevenue': 0.0,
          'additionalCash': 0.0,
          'currency': 'USD',
          'isActive': true,
        }
      };
      client.getResponses['/scenarios/company/co-1'] = {
        'data': [
          {
            'id': 's-new',
            'companyId': 'co-1',
            'name': 'Hiring Freeze',
            'baseCash': 300000.0,
            'baseMonthlyBurn': 30000.0,
            'additionalBurn': 0.0,
            'additionalRevenue': 0.0,
            'additionalCash': 0.0,
            'currency': 'USD',
            'isActive': true,
          }
        ]
      };

      await _pumpRunwayScreen(tester, client);
      await tester.pumpAndSettle();

      // Tap Save button
      final saveBtn = find.text('Save');
      await tester.ensureVisible(saveBtn);
      await tester.tap(saveBtn);
      await tester.pumpAndSettle();

      // Dialog opens
      expect(find.text('Save Scenario'), findsOneWidget);

      // Enter scenario name
      final nameField = find.widgetWithText(TextField, 'Scenario Name');
      await tester.enterText(nameField, 'Hiring Freeze');

      // Submit dialog
      final dialogSaveBtn = find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Save'),
      );
      await tester.tap(dialogSaveBtn);
      await tester.pumpAndSettle();

      expect(find.text('Hiring Freeze'), findsOneWidget);
      expect(find.text('Scenario saved successfully'), findsOneWidget);
    });

    testWidgets('deletes a scenario with confirmation dialog',
        (WidgetTester tester) async {
      final client = _setupWithCompany(scenarios: [
        {
          'id': 's-del',
          'companyId': 'co-1',
          'name': 'Scenario To Delete',
          'baseCash': 300000.0,
          'baseMonthlyBurn': 30000.0,
          'additionalBurn': 5000.0,
          'additionalRevenue': 0.0,
          'additionalCash': 0.0,
          'currency': 'USD',
          'isActive': true,
        }
      ]);
      client.deleteResponses['/scenarios/s-del'] = {'data': null};

      await _pumpRunwayScreen(tester, client);
      await tester.pumpAndSettle();

      expect(find.text('Scenario To Delete'), findsOneWidget);

      // Tap delete icon
      final deleteIcon = find.byIcon(Icons.delete_outline);
      await tester.ensureVisible(deleteIcon);
      await tester.tap(deleteIcon);
      await tester.pumpAndSettle();

      // Confirmation dialog opens
      expect(find.text('Delete Scenario'), findsOneWidget);
      expect(find.text('Delete "Scenario To Delete"? This cannot be undone.'),
          findsOneWidget);

      // Update response before confirming
      client.getResponses['/scenarios/company/co-1'] = {'data': []};

      // Confirm delete
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      expect(find.text('No saved scenarios yet.'), findsOneWidget);
      expect(find.text('Scenario deleted'), findsOneWidget);
    });

    testWidgets('shows error and Retry button when company request fails',
        (WidgetTester tester) async {
      final client = MockRunwayApiClient();
      client.getErrors['/company'] = ServerException('Failed to load companies');
      await _pumpRunwayScreen(tester, client);
      await tester.pumpAndSettle();

      expect(find.text('Failed to load companies'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);

      // Resolving error and clicking Retry
      client.getErrors.remove('/company');
      client.getResponses['/company'] = [
        {'id': 'co-retried', 'name': 'Retried Inc', 'currency': 'USD'}
      ];
      client.getResponses['/scenarios/company/co-retried'] = {'data': []};
      client.postResponses['/scenarios/simulate'] = {
        'data': {
          'companyId': 'co-retried',
          'baseline': {'cash': 500000.0, 'burn': 50000.0, 'runway': 10.0},
          'simulated': {'cash': 500000.0, 'burn': 50000.0, 'runway': 10.0},
          'adjustments': {
            'additionalBurn': 0.0,
            'additionalRevenue': 0.0,
            'additionalCash': 0.0
          },
        }
      };

      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      expect(find.text('Runway Analysis'), findsOneWidget);
      expect(find.text('\$500.0k'), findsOneWidget);
    });

    testWidgets('shows empty state when company list is empty',
        (WidgetTester tester) async {
      final client = MockRunwayApiClient();
      client.getResponses['/company'] = [];
      await _pumpRunwayScreen(tester, client);
      await tester.pumpAndSettle();

      expect(
        find.text('No company found. Please complete onboarding.'),
        findsOneWidget,
      );
    });

    testWidgets('handles UnauthorizedException gracefully without infinite retries',
        (WidgetTester tester) async {
      final client = MockRunwayApiClient();
      client.getErrors['/company'] = UnauthorizedException('Session expired');
      await _pumpRunwayScreen(tester, client);
      await tester.pumpAndSettle();

      expect(find.text('Session expired'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });
  });
}
