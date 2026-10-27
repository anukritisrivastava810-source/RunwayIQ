import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:runway_iq/core/network/api_client.dart';
import 'package:runway_iq/core/network/api_exceptions.dart';
import 'package:runway_iq/features/dashboard/data/repositories/dashboard_repository.dart';
import 'package:runway_iq/features/dashboard/domain/models/burn_trend.dart';
import 'package:runway_iq/theme/app_theme.dart';
import 'package:runway_iq/widgets/burn_rate_chart.dart';

class MockChartApiClient extends ApiClient {
  dynamic responseData;
  ApiException? errorToThrow;

  @override
  Future<dynamic> get(String path, {Map<String, dynamic>? queryParameters}) async {
    if (errorToThrow != null) {
      throw errorToThrow!;
    }
    return responseData;
  }
}

void main() {
  group('BurnTrend Models Unit Tests', () {
    test('BurnTrendPoint parses int, double, and string values safely', () {
      final point = BurnTrendPoint.fromJson({
        'month': '2026-05',
        'expenseBurn': 12000, // int
        'payrollBurn': '35000.50', // string
        'totalBurn': 47000.50, // double
      });

      expect(point.month, '2026-05');
      expect(point.expenseBurn, 12000.0);
      expect(point.payrollBurn, 35000.50);
      expect(point.totalBurn, 47000.50);
      expect(point.displayMonth, 'May');
    });

    test('BurnTrendPoint handles null values safely with zeros', () {
      final point = BurnTrendPoint.fromJson({
        'month': null,
        'expenseBurn': null,
        'payrollBurn': null,
        'totalBurn': null,
      });

      expect(point.month, '');
      expect(point.expenseBurn, 0.0);
      expect(point.payrollBurn, 0.0);
      expect(point.totalBurn, 0.0);
      expect(point.displayMonth, '');
    });

    test('BurnTrendResponse parses wrapper map and calculates currency symbol', () {
      final response = BurnTrendResponse.fromJson({
        'data': {
          'companyId': 'co-100',
          'currency': 'EUR',
          'data': [
            {
              'month': '2026-01',
              'expenseBurn': 5000,
              'payrollBurn': 15000,
              'totalBurn': 20000,
            },
            {
              'month': '2026-02',
              'expenseBurn': 6000,
              'payrollBurn': 15000,
              'totalBurn': 21000,
            }
          ]
        }
      });

      expect(response.companyId, 'co-100');
      expect(response.currency, 'EUR');
      expect(response.currencySymbol, '€');
      expect(response.points.length, 2);
      expect(response.hasBurnData, isTrue);
      expect(response.points[0].displayMonth, 'Jan');
      expect(response.points[1].displayMonth, 'Feb');
    });

    test('BurnTrendResponse hasBurnData returns false when all values are zero', () {
      final response = BurnTrendResponse.fromJson({
        'companyId': 'co-zero',
        'currency': 'USD',
        'data': [
          {
            'month': '2026-07',
            'expenseBurn': 0,
            'payrollBurn': 0,
            'totalBurn': 0,
          },
          {
            'month': '2026-08',
            'expenseBurn': 0,
            'payrollBurn': 0,
            'totalBurn': 0,
          }
        ]
      });

      expect(response.hasBurnData, isFalse);
      expect(response.currencySymbol, '\$');
    });
  });

  group('DashboardRepository Unit Tests', () {
    test('getBurnTrend calls endpoint and returns parsed BurnTrendResponse', () async {
      final mockApi = MockChartApiClient();
      mockApi.responseData = {
        'statusCode': 200,
        'data': {
          'companyId': 'co-1',
          'currency': 'USD',
          'data': [
            {
              'month': '2026-08',
              'expenseBurn': 2000,
              'payrollBurn': 10000,
              'totalBurn': 12000,
            }
          ]
        }
      };

      final repo = DashboardRepository(apiClient: mockApi);
      final result = await repo.getBurnTrend('co-1', months: 6);

      expect(result.companyId, 'co-1');
      expect(result.currency, 'USD');
      expect(result.points.length, 1);
      expect(result.points.first.totalBurn, 12000.0);
    });

    test('getBurnTrend rethrows ApiException properly', () async {
      final mockApi = MockChartApiClient();
      mockApi.errorToThrow = ServerException('Backend failure');

      final repo = DashboardRepository(apiClient: mockApi);
      expect(
        () => repo.getBurnTrend('co-1'),
        throwsA(isA<ServerException>()),
      );
    });
  });

  group('BurnRateChart Widget Tests', () {
    testWidgets('renders loading spinner when isLoading is true', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: BurnRateChart(
              isLoading: true,
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Total Burn'), findsOneWidget);
      expect(find.text('Payroll'), findsOneWidget);
      expect(find.text('Expenses'), findsOneWidget);
    });

    testWidgets('renders error message and triggers onRetry when button pressed', (tester) async {
      bool retried = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: BurnRateChart(
              hasError: true,
              errorMessage: 'Network timeout loading burn trend',
              onRetry: () => retried = true,
            ),
          ),
        ),
      );

      expect(find.text('Network timeout loading burn trend'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);

      await tester.tap(find.text('Retry'));
      await tester.pump();

      expect(retried, isTrue);
    });

    testWidgets('renders clean empty state when no historical burn data exists', (tester) async {
      final emptyTrend = BurnTrendResponse(
        companyId: 'co-empty',
        currency: 'USD',
        points: [
          const BurnTrendPoint(month: '2026-08', expenseBurn: 0, payrollBurn: 0, totalBurn: 0),
          const BurnTrendPoint(month: '2026-09', expenseBurn: 0, payrollBurn: 0, totalBurn: 0),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: BurnRateChart(
              burnTrend: emptyTrend,
            ),
          ),
        ),
      );

      expect(find.text('No historical burn data recorded'), findsOneWidget);
      expect(
        find.text('Add expenses or active employees to see monthly trends.'),
        findsOneWidget,
      );
      expect(find.byType(LineChart), findsNothing);
    });

    testWidgets('renders LineChart with real data and legend', (tester) async {
      final realTrend = BurnTrendResponse(
        companyId: 'co-active',
        currency: 'USD',
        points: [
          const BurnTrendPoint(
            month: '2026-06',
            expenseBurn: 5000,
            payrollBurn: 20000,
            totalBurn: 25000,
          ),
          const BurnTrendPoint(
            month: '2026-07',
            expenseBurn: 7000,
            payrollBurn: 20000,
            totalBurn: 27000,
          ),
          const BurnTrendPoint(
            month: '2026-08',
            expenseBurn: 10000,
            payrollBurn: 20000,
            totalBurn: 30000,
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: BurnRateChart(
              burnTrend: realTrend,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Legend items
      expect(find.text('Total Burn'), findsOneWidget);
      expect(find.text('Payroll'), findsOneWidget);
      expect(find.text('Expenses'), findsOneWidget);

      // LineChart widget is present
      expect(find.byType(LineChart), findsOneWidget);

      // Month axis titles
      expect(find.text('Jun'), findsOneWidget);
      expect(find.text('Jul'), findsOneWidget);
      expect(find.text('Aug'), findsOneWidget);
    });
  });
}
