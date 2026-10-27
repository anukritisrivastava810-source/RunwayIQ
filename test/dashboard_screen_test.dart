import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:runway_iq/core/network/api_client.dart';
import 'package:runway_iq/features/company/data/repositories/company_repository.dart';
import 'package:runway_iq/features/employee/data/repositories/employee_repository.dart';
import 'package:runway_iq/features/expense/data/repositories/expense_repository.dart';
import 'package:runway_iq/features/funding/data/repositories/funding_round_repository.dart';
import 'package:runway_iq/features/treasury/data/repositories/treasury_repository.dart';
import 'package:runway_iq/features/dashboard/data/repositories/dashboard_repository.dart';
import 'package:runway_iq/core/network/api_exceptions.dart';
import 'package:runway_iq/screens/dashboard_screen.dart';
import 'package:runway_iq/screens/main_layout.dart';
import 'package:runway_iq/theme/app_theme.dart';

class MockTestApiClient extends ApiClient {
  final Map<String, dynamic> responses = {};
  final Map<String, ApiException> errors = {};

  @override
  Future<dynamic> get(String path, {Map<String, dynamic>? queryParameters}) async {
    if (errors.containsKey(path)) {
      throw errors[path]!;
    }
    if (responses.containsKey(path)) {
      return responses[path];
    }
    return {'data': []};
  }
}

void main() {
  late MockTestApiClient mockApiClient;
  late CompanyRepository companyRepo;
  late FundingRoundRepository fundingRepo;
  late ExpenseRepository expenseRepo;
  late EmployeeRepository employeeRepo;
  late TreasuryRepository treasuryRepo;
  late DashboardRepository dashboardRepo;

  setUp(() {
    mockApiClient = MockTestApiClient();
    companyRepo = CompanyRepository(apiClient: mockApiClient);
    fundingRepo = FundingRoundRepository(apiClient: mockApiClient);
    expenseRepo = ExpenseRepository(apiClient: mockApiClient);
    employeeRepo = EmployeeRepository(apiClient: mockApiClient);
    treasuryRepo = TreasuryRepository(apiClient: mockApiClient);
    dashboardRepo = DashboardRepository(apiClient: mockApiClient);
  });

  testWidgets('Dashboard renders live company metrics and zero-burn empty state',
      (WidgetTester tester) async {
    mockApiClient.responses['/company'] = [
      {
        'id': 'co-1',
        'name': 'Acme AI',
        'stage': 'SEED',
        'currency': 'USD',
      }
    ];

    mockApiClient.responses['/funding/company/co-1'] = [
      {
        'id': 'f-1',
        'companyId': 'co-1',
        'roundType': 'SEED',
        'amountRaised': 3000000.0,
        'currency': 'USD',
        'closedAt': '2026-06-15T10:00:00.000Z',
      }
    ];

    mockApiClient.responses['/expenses/company/co-1'] = [];
    mockApiClient.responses['/employees/company/co-1'] = [];
    mockApiClient.responses['/treasury/company/co-1'] = [];

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: DashboardScreen(
            companyRepository: companyRepo,
            fundingRoundRepository: fundingRepo,
            expenseRepository: expenseRepo,
            employeeRepository: employeeRepo,
            treasuryRepository: treasuryRepo,
            dashboardRepository: dashboardRepo,
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify company name
    expect(find.text('Acme AI Insight'), findsOneWidget);

    // Verify metrics
    // Total Raised: $3.0M
    expect(find.text('\$3.0M'), findsNWidgets(2)); // Total Raised and Available Cash
    expect(find.text('Available Cash'), findsOneWidget);
    expect(find.text('Runway'), findsOneWidget);
    expect(find.text('Monthly Burn'), findsOneWidget);
    expect(find.text('Total Raised'), findsOneWidget);

    // Runway should be empty state '—' with 'No burn data' because burn is 0
    expect(find.text('—'), findsOneWidget);
    expect(find.text('No burn data'), findsOneWidget);

    // Monthly burn should be $0
    expect(find.text('\$0'), findsOneWidget);
    expect(find.text('No expenses'), findsOneWidget);

    // Latest round label
    expect(find.text('Seed · Jun 2026'), findsOneWidget);
  });

  testWidgets('Dashboard calculates burn, runway, and cash accurately with expenses and employees',
      (WidgetTester tester) async {
    mockApiClient.responses['/company'] = [
      {
        'id': 'co-2',
        'name': 'Beta Tech',
        'stage': 'SERIES_A',
        'currency': 'USD',
      }
    ];

    // Funding: $2,000,000
    mockApiClient.responses['/funding/company/co-2'] = [
      {
        'id': 'f-2',
        'companyId': 'co-2',
        'roundType': 'SERIES_A',
        'amountRaised': 2000000.0,
        'currency': 'USD',
        'closedAt': '2026-01-10T10:00:00.000Z',
      }
    ];

    // Expenses: $20,000 monthly
    mockApiClient.responses['/expenses/company/co-2'] = [
      {
        'id': 'e-1',
        'companyId': 'co-2',
        'title': 'GCP Hosting',
        'amount': 20000.0,
        'category': 'CLOUD',
        'recurrence': 'MONTHLY',
        'expenseDate': '2026-02-01T00:00:00.000Z',
      }
    ];

    // Employees: $120,000 annual = $10,000 monthly payroll
    mockApiClient.responses['/employees/company/co-2'] = [
      {
        'id': 'emp-1',
        'companyId': 'co-2',
        'departmentId': 'd-1',
        'firstName': 'John',
        'lastName': 'Doe',
        'email': 'john@beta.com',
        'role': 'Engineer',
        'annualSalary': 120000.0,
        'currency': 'USD',
        'status': 'ACTIVE',
        'joinedAt': '2025-01-01T00:00:00.000Z',
      }
    ];
    mockApiClient.responses['/treasury/company/co-2'] = [];

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: DashboardScreen(
            companyRepository: companyRepo,
            fundingRoundRepository: fundingRepo,
            expenseRepository: expenseRepo,
            employeeRepository: employeeRepo,
            treasuryRepository: treasuryRepo,
            dashboardRepository: dashboardRepo,
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Cash = 2,000,000 - 20,000 = 1,980,000 -> $2.0M
    expect(find.text('\$2.0M'), findsNWidgets(2)); // Cash & Total Raised

    // Monthly Burn = 20,000 (cloud) + 10,000 (payroll) = 30,000 -> $30.0k
    expect(find.text('\$30.0k'), findsOneWidget);

    // Runway = 1,980,000 / 30,000 = 66 months
    expect(find.text('66 mo'), findsOneWidget);

    // Recent activity should display real entries
    expect(find.text('GCP Hosting'), findsOneWidget);
    expect(find.text('Series A Round'), findsOneWidget);
  });

  testWidgets('Dashboard reactively updates payroll burn, runway, and team count when employee data changes',
      (WidgetTester tester) async {
    mockApiClient.responses['/company'] = [
      {
        'id': 'co-sync',
        'name': 'Gamma AI',
        'stage': 'SEED',
        'currency': 'USD',
      }
    ];

    // Funding: $1,200,000
    mockApiClient.responses['/funding/company/co-sync'] = [
      {
        'id': 'f-sync',
        'companyId': 'co-sync',
        'roundType': 'SEED',
        'amountRaised': 1200000.0,
        'currency': 'USD',
        'closedAt': '2026-01-01T00:00:00.000Z',
      }
    ];

    mockApiClient.responses['/expenses/company/co-sync'] = [];
    mockApiClient.responses['/treasury/company/co-sync'] = [];

    // Initial 1 employee: $120,000 annual = $10,000/mo
    mockApiClient.responses['/employees/company/co-sync'] = [
      {
        'id': 'emp-1',
        'companyId': 'co-sync',
        'departmentId': 'd-1',
        'firstName': 'Dev',
        'lastName': 'One',
        'email': 'dev1@gamma.com',
        'role': 'Engineer',
        'annualSalary': 120000.0,
        'currency': 'USD',
        'status': 'ACTIVE',
        'joinedAt': '2026-01-01T00:00:00.000Z',
      }
    ];

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: DashboardScreen(
            companyRepository: companyRepo,
            fundingRoundRepository: fundingRepo,
            expenseRepository: expenseRepo,
            employeeRepository: employeeRepo,
            treasuryRepository: treasuryRepo,
            dashboardRepository: dashboardRepo,
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // 1 employee: burn = $10.0k, runway = 1,200,000 / 10,000 = 120 mo
    expect(find.text('\$10.0k'), findsOneWidget);
    expect(find.text('120 mo'), findsOneWidget);
    expect(find.textContaining('with a team of 1'), findsOneWidget);

    // Simulate adding second employee: $240,000 annual = $20,000/mo
    mockApiClient.responses['/employees/company/co-sync'] = [
      {
        'id': 'emp-1',
        'companyId': 'co-sync',
        'departmentId': 'd-1',
        'firstName': 'Dev',
        'lastName': 'One',
        'email': 'dev1@gamma.com',
        'role': 'Engineer',
        'annualSalary': 120000.0,
        'currency': 'USD',
        'status': 'ACTIVE',
        'joinedAt': '2026-01-01T00:00:00.000Z',
      },
      {
        'id': 'emp-2',
        'companyId': 'co-sync',
        'departmentId': 'd-1',
        'firstName': 'Staff',
        'lastName': 'Lead',
        'email': 'staff@gamma.com',
        'role': 'Staff Engineer',
        'annualSalary': 240000.0,
        'currency': 'USD',
        'status': 'ACTIVE',
        'joinedAt': '2026-02-01T00:00:00.000Z',
      }
    ];

    // Trigger reactive notification
    DashboardScreen.notifyDataChanged();
    await tester.pumpAndSettle();

    // 2 employees: total payroll = 10,000 + 20,000 = $30.0k
    // runway = 1,200,000 / 30,000 = 40 mo
    expect(find.text('\$30.0k'), findsOneWidget);
    expect(find.text('40 mo'), findsOneWidget);
    expect(find.textContaining('with a team of 2'), findsOneWidget);

    // Simulate marking second employee INACTIVE (resigned/departed)
    mockApiClient.responses['/employees/company/co-sync'] = [
      {
        'id': 'emp-1',
        'companyId': 'co-sync',
        'departmentId': 'd-1',
        'firstName': 'Dev',
        'lastName': 'One',
        'email': 'dev1@gamma.com',
        'role': 'Engineer',
        'annualSalary': 120000.0,
        'currency': 'USD',
        'status': 'ACTIVE',
        'joinedAt': '2026-01-01T00:00:00.000Z',
      },
      {
        'id': 'emp-2',
        'companyId': 'co-sync',
        'departmentId': 'd-1',
        'firstName': 'Staff',
        'lastName': 'Lead',
        'email': 'staff@gamma.com',
        'role': 'Staff Engineer',
        'annualSalary': 240000.0,
        'currency': 'USD',
        'status': 'INACTIVE',
        'joinedAt': '2026-02-01T00:00:00.000Z',
      }
    ];

    DashboardScreen.notifyDataChanged();
    await tester.pumpAndSettle();

    // Only active employee counted: burn = $10.0k, runway = 120 mo, team of 1
    expect(find.text('\$10.0k'), findsOneWidget);
    expect(find.text('120 mo'), findsOneWidget);
    expect(find.textContaining('with a team of 1'), findsOneWidget);
  });

  testWidgets('MainLayout navigates across all tabs with unique Hero tags and no collisions',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: const MainLayout(),
      ),
    );

    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    expect(find.text('Dashboard'), findsWidgets);

    // Navigate to Funding tab
    await tester.tap(find.byIcon(Icons.account_balance_wallet_outlined));
    await tester.pumpAndSettle();
    expect(find.text('Funding'), findsWidgets);

    // Navigate to Employees tab
    await tester.tap(find.byIcon(Icons.people_outline));
    await tester.pumpAndSettle();
    expect(find.text('Employees'), findsWidgets);

    // Navigate to Expenses tab
    await tester.tap(find.byIcon(Icons.receipt_long_outlined));
    await tester.pumpAndSettle();
    expect(find.text('Expenses'), findsWidgets);

    // Navigate to Treasury tab
    await tester.tap(find.byIcon(Icons.show_chart));
    await tester.pumpAndSettle();
    expect(find.text('Treasury'), findsWidgets);

    // Navigate back to Dashboard
    await tester.tap(find.byIcon(Icons.home_outlined));
    await tester.pumpAndSettle();
    expect(find.text('Dashboard'), findsWidgets);

    // Check no exceptions thrown
    expect(tester.takeException(), isNull);
  });

  testWidgets('Dashboard renders loading spinner while fetching initial data',
      (WidgetTester tester) async {
    mockApiClient.responses['/company'] = [
      {
        'id': 'co-load',
        'name': 'Loading Corp',
        'stage': 'SEED',
        'currency': 'USD',
      }
    ];

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: DashboardScreen(
            companyRepository: companyRepo,
            fundingRoundRepository: fundingRepo,
            expenseRepository: expenseRepo,
            employeeRepository: employeeRepo,
            treasuryRepository: treasuryRepo,
            dashboardRepository: dashboardRepo,
          ),
        ),
      ),
    );

    // Initial frame shows loading indicator
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pumpAndSettle();
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('Loading Corp Insight'), findsOneWidget);
  });

  testWidgets('Dashboard handles error state and retry button successfully',
      (WidgetTester tester) async {
    mockApiClient.errors['/company'] =
        ServerException('Database connection failure');

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: DashboardScreen(
            companyRepository: companyRepo,
            fundingRoundRepository: fundingRepo,
            expenseRepository: expenseRepo,
            employeeRepository: employeeRepo,
            treasuryRepository: treasuryRepo,
            dashboardRepository: dashboardRepo,
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Database connection failure'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);

    // Resolve error and retry
    mockApiClient.errors.remove('/company');
    mockApiClient.responses['/company'] = [
      {
        'id': 'co-retry',
        'name': 'Recovered Corp',
        'stage': 'SEED',
        'currency': 'USD',
      }
    ];

    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(find.text('Recovered Corp Insight'), findsOneWidget);
  });

  testWidgets('Dashboard renders empty state when no company exists',
      (WidgetTester tester) async {
    mockApiClient.responses['/company'] = [];

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: DashboardScreen(
            companyRepository: companyRepo,
            fundingRoundRepository: fundingRepo,
            expenseRepository: expenseRepo,
            employeeRepository: employeeRepo,
            treasuryRepository: treasuryRepo,
            dashboardRepository: dashboardRepo,
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('No company data found'), findsOneWidget);
    expect(find.text('Please complete onboarding to view your dashboard.'),
        findsOneWidget);
  });

  testWidgets(
      'Dashboard displays real employee hire in Recent Activity and updates on pull-to-refresh',
      (WidgetTester tester) async {
    mockApiClient.responses['/company'] = [
      {
        'id': 'co-act',
        'name': 'Activity Tech',
        'stage': 'SEED',
        'currency': 'USD',
      }
    ];
    mockApiClient.responses['/funding/company/co-act'] = [];
    mockApiClient.responses['/expenses/company/co-act'] = [];
    mockApiClient.responses['/treasury/company/co-act'] = [];
    mockApiClient.responses['/employees/company/co-act'] = [
      {
        'id': 'emp-hire',
        'companyId': 'co-act',
        'departmentId': 'd-act',
        'firstName': 'Sarah',
        'lastName': 'Connor',
        'email': 'sarah@activity.com',
        'role': 'Lead Architect',
        'annualSalary': 180000.0,
        'currency': 'USD',
        'status': 'ACTIVE',
        'joinedAt': '2026-03-15T00:00:00.000Z',
      }
    ];

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: DashboardScreen(
            companyRepository: companyRepo,
            fundingRoundRepository: fundingRepo,
            expenseRepository: expenseRepo,
            employeeRepository: employeeRepo,
            treasuryRepository: treasuryRepo,
            dashboardRepository: dashboardRepo,
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify employee in recent activity
    expect(find.text('Sarah Connor (Lead Architect)'), findsOneWidget);
    expect(find.text('Mar 15'), findsOneWidget);
    expect(find.text('-\$15.0k'), findsOneWidget);

    // Trigger pull-to-refresh
    await tester.fling(
        find.byType(RefreshIndicator), const Offset(0.0, 300.0), 1000.0);
    await tester.pumpAndSettle();

    expect(find.text('Sarah Connor (Lead Architect)'), findsOneWidget);
  });

  testWidgets(
      'Dashboard displays real BurnRateChart with LineChart when historical burn trend data exists',
      (WidgetTester tester) async {
    mockApiClient.responses['/company'] = [
      {
        'id': 'co-trend',
        'name': 'Trend Tech',
        'stage': 'SEED',
        'currency': 'USD',
      }
    ];
    mockApiClient.responses['/funding/company/co-trend'] = [];
    mockApiClient.responses['/expenses/company/co-trend'] = [];
    mockApiClient.responses['/treasury/company/co-trend'] = [];
    mockApiClient.responses['/employees/company/co-trend'] = [];
    mockApiClient.responses['/dashboard/company/co-trend/burn-trend'] = {
      'statusCode': 200,
      'data': {
        'companyId': 'co-trend',
        'currency': 'USD',
        'data': [
          {
            'month': '2026-06',
            'expenseBurn': 5000.0,
            'payrollBurn': 15000.0,
            'totalBurn': 20000.0,
          },
          {
            'month': '2026-07',
            'expenseBurn': 8000.0,
            'payrollBurn': 15000.0,
            'totalBurn': 23000.0,
          },
        ]
      }
    };

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: DashboardScreen(
            companyRepository: companyRepo,
            fundingRoundRepository: fundingRepo,
            expenseRepository: expenseRepo,
            employeeRepository: employeeRepo,
            treasuryRepository: treasuryRepo,
            dashboardRepository: dashboardRepo,
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify Burn Rate Trend header
    expect(find.text('Burn Rate Trend'), findsOneWidget);

    // Verify Legend items
    expect(find.text('Total Burn'), findsOneWidget);
    expect(find.text('Payroll'), findsOneWidget);
    expect(find.text('Expenses'), findsOneWidget);

    // Verify LineChart is rendered
    expect(find.byType(LineChart), findsOneWidget);
  });
}
