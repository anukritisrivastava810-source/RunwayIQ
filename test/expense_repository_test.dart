import 'package:flutter_test/flutter_test.dart';
import 'package:runway_iq/core/network/api_client.dart';
import 'package:runway_iq/core/network/api_exceptions.dart';
import 'package:runway_iq/features/expense/data/repositories/expense_repository.dart';
import 'package:runway_iq/features/expense/domain/models/expense.dart';

class MockApiClient extends ApiClient {
  dynamic getResponse;
  dynamic postResponse;
  dynamic putResponse;
  dynamic deleteResponse;

  Exception? errorToThrow;

  String? lastPath;
  dynamic lastData;
  Map<String, dynamic>? lastQueryParams;

  @override
  Future<dynamic> get(String path, {Map<String, dynamic>? queryParameters}) async {
    lastPath = path;
    lastQueryParams = queryParameters;
    if (errorToThrow != null) throw errorToThrow!;
    return getResponse;
  }

  @override
  Future<dynamic> post(String path, {dynamic data, Map<String, dynamic>? queryParameters}) async {
    lastPath = path;
    lastData = data;
    lastQueryParams = queryParameters;
    if (errorToThrow != null) throw errorToThrow!;
    return postResponse;
  }

  @override
  Future<dynamic> put(String path, {dynamic data, Map<String, dynamic>? queryParameters}) async {
    lastPath = path;
    lastData = data;
    lastQueryParams = queryParameters;
    if (errorToThrow != null) throw errorToThrow!;
    return putResponse;
  }

  @override
  Future<dynamic> delete(String path, {dynamic data, Map<String, dynamic>? queryParameters}) async {
    lastPath = path;
    lastData = data;
    lastQueryParams = queryParameters;
    if (errorToThrow != null) throw errorToThrow!;
    return deleteResponse;
  }
}

void main() {
  group('Expense Model & Repository Tests', () {
    test('Expense fromJson and toJson round-trip', () {
      final json = {
        'id': 'exp-1',
        'companyId': 'comp-1',
        'title': 'AWS Cloud Hosting',
        'category': 'CLOUD',
        'amount': 2500.0,
        'currency': 'USD',
        'recurrence': 'MONTHLY',
        'expenseDate': '2026-03-01T00:00:00.000Z',
        'vendor': 'Amazon Web Services',
        'description': 'Production clusters',
        'isPaid': true,
      };

      final exp = Expense.fromJson(json);
      expect(exp.id, 'exp-1');
      expect(exp.title, 'AWS Cloud Hosting');
      expect(exp.category, ExpenseCategory.cloud);
      expect(exp.amount, 2500.0);
      expect(exp.currency, ExpenseCurrency.usd);
      expect(exp.recurrence, ExpenseRecurrence.monthly);
      expect(exp.vendor, 'Amazon Web Services');
      expect(exp.isPaid, true);

      final outJson = exp.toJson();
      expect(outJson['title'], 'AWS Cloud Hosting');
      expect(outJson['category'], 'CLOUD');
      expect(outJson['amount'], 2500.0);
      expect(outJson['recurrence'], 'MONTHLY');
      expect(outJson['vendor'], 'Amazon Web Services');
    });

    test('ExpenseRepository creates expense via POST /expenses', () async {
      final mockClient = MockApiClient();
      final repo = ExpenseRepository(apiClient: mockClient);

      mockClient.postResponse = {
        'data': {
          'id': 'exp-new',
          'companyId': 'comp-1',
          'title': 'WeWork Rent',
          'category': 'OFFICE_RENT',
          'amount': 4500.0,
          'currency': 'USD',
          'recurrence': 'MONTHLY',
          'expenseDate': '2026-03-01T00:00:00.000Z',
        }
      };

      final created = await repo.createExpense(
        Expense(
          companyId: 'comp-1',
          title: 'WeWork Rent',
          category: ExpenseCategory.officeRent,
          amount: 4500.0,
          expenseDate: DateTime(2026, 3, 1),
        ),
      );

      expect(created.id, 'exp-new');
      expect(mockClient.lastPath, '/expenses');
      expect(mockClient.lastData['category'], 'OFFICE_RENT');
    });

    test('ExpenseRepository retrieves expenses by company', () async {
      final mockClient = MockApiClient();
      final repo = ExpenseRepository(apiClient: mockClient);

      mockClient.getResponse = {
        'data': [
          {
            'id': 'exp-1',
            'companyId': 'comp-1',
            'title': 'Google Workspace',
            'category': 'SOFTWARE',
            'amount': 300.0,
            'currency': 'USD',
            'recurrence': 'MONTHLY',
            'expenseDate': '2026-03-01T00:00:00.000Z',
          }
        ]
      };

      final list = await repo.getExpensesByCompany('comp-1');
      expect(list.length, 1);
      expect(list.first.title, 'Google Workspace');
      expect(mockClient.lastPath, '/expenses/company/comp-1');
    });

    test('ExpenseRepository handles ServerException properly', () async {
      final mockClient = MockApiClient();
      final repo = ExpenseRepository(apiClient: mockClient);

      mockClient.errorToThrow = ServerException('Database unavailable');

      expect(
        () => repo.getExpensesByCompany('comp-1'),
        throwsA(isA<ServerException>()),
      );
    });
  });
}
