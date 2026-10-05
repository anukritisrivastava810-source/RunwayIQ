import 'package:flutter_test/flutter_test.dart';
import 'package:runway_iq/core/network/api_client.dart';
import 'package:runway_iq/core/network/api_exceptions.dart';
import 'package:runway_iq/features/department/data/repositories/department_repository.dart';
import 'package:runway_iq/features/department/domain/models/department.dart';
import 'package:runway_iq/features/employee/data/repositories/employee_repository.dart';
import 'package:runway_iq/features/employee/domain/models/employee.dart';

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
  group('Department Model & Repository Tests', () {
    test('Department fromJson and toJson round-trip', () {
      final json = {
        'id': 'dept-123',
        'companyId': 'comp-456',
        'name': 'Engineering',
        'headCount': 5,
      };

      final dept = Department.fromJson(json);
      expect(dept.id, 'dept-123');
      expect(dept.companyId, 'comp-456');
      expect(dept.name, 'Engineering');
      expect(dept.headCount, 5);

      final outJson = dept.toJson();
      expect(outJson['name'], 'Engineering');
      expect(outJson['headCount'], 5);
    });

    test('DepartmentRepository creates and retrieves departments', () async {
      final mockClient = MockApiClient();
      final repo = DepartmentRepository(apiClient: mockClient);

      mockClient.postResponse = {
        'data': {
          'id': 'dept-new',
          'companyId': 'comp-456',
          'name': 'Design',
          'headCount': 0,
        }
      };

      final created = await repo.createDepartment(
        const Department(companyId: 'comp-456', name: 'Design'),
      );
      expect(created.id, 'dept-new');
      expect(mockClient.lastPath, '/departments');
      expect(mockClient.lastData['name'], 'Design');

      mockClient.getResponse = {
        'data': [
          {'id': 'dept-1', 'companyId': 'comp-456', 'name': 'Engineering'},
          {'id': 'dept-2', 'companyId': 'comp-456', 'name': 'Design'},
        ]
      };

      final list = await repo.getDepartmentsByCompany('comp-456');
      expect(list.length, 2);
      expect(mockClient.lastPath, '/departments/company/comp-456');
    });
  });

  group('Employee Model & Repository Tests', () {
    test('Employee fromJson and toJson round-trip', () {
      final json = {
        'id': 'emp-123',
        'companyId': 'comp-456',
        'departmentId': 'dept-789',
        'firstName': 'Jane',
        'lastName': 'Doe',
        'email': 'jane@example.com',
        'role': 'Senior Engineer',
        'annualSalary': 120000.0,
        'currency': 'USD',
        'status': 'ACTIVE',
        'joinedAt': '2026-01-15T00:00:00.000Z',
        'department': {
          'id': 'dept-789',
          'companyId': 'comp-456',
          'name': 'Engineering',
        }
      };

      final emp = Employee.fromJson(json);
      expect(emp.id, 'emp-123');
      expect(emp.fullName, 'Jane Doe');
      expect(emp.role, 'Senior Engineer');
      expect(emp.annualSalary, 120000.0);
      expect(emp.currency, EmployeeCurrency.usd);
      expect(emp.status, EmploymentStatus.active);
      expect(emp.departmentName, 'Engineering');

      final outJson = emp.toJson();
      expect(outJson['firstName'], 'Jane');
      expect(outJson['lastName'], 'Doe');
      expect(outJson['email'], 'jane@example.com');
      expect(outJson['annualSalary'], 120000.0);
      expect(outJson['currency'], 'USD');
    });

    test('EmployeeRepository creates employee via POST /employees', () async {
      final mockClient = MockApiClient();
      final repo = EmployeeRepository(apiClient: mockClient);

      mockClient.postResponse = {
        'data': {
          'id': 'emp-created',
          'companyId': 'comp-1',
          'departmentId': 'dept-1',
          'firstName': 'Alex',
          'lastName': 'Smith',
          'email': 'alex@example.com',
          'role': 'Product Lead',
          'annualSalary': 110000.0,
          'currency': 'USD',
          'status': 'ACTIVE',
          'joinedAt': '2026-02-01T00:00:00.000Z',
        }
      };

      final created = await repo.createEmployee(
        Employee(
          companyId: 'comp-1',
          departmentId: 'dept-1',
          firstName: 'Alex',
          lastName: 'Smith',
          email: 'alex@example.com',
          role: 'Product Lead',
          annualSalary: 110000.0,
          joinedAt: DateTime(2026, 2, 1),
        ),
      );

      expect(created.id, 'emp-created');
      expect(mockClient.lastPath, '/employees');
      expect(mockClient.lastData['email'], 'alex@example.com');
    });

    test('EmployeeRepository retrieves employees by company', () async {
      final mockClient = MockApiClient();
      final repo = EmployeeRepository(apiClient: mockClient);

      mockClient.getResponse = {
        'data': [
          {
            'id': 'emp-1',
            'companyId': 'comp-1',
            'departmentId': 'dept-1',
            'firstName': 'Alex',
            'lastName': 'Smith',
            'email': 'alex@example.com',
            'role': 'Product Lead',
            'annualSalary': 110000.0,
            'joinedAt': '2026-02-01T00:00:00.000Z',
          }
        ]
      };

      final list = await repo.getEmployeesByCompany('comp-1');
      expect(list.length, 1);
      expect(list.first.firstName, 'Alex');
      expect(mockClient.lastPath, '/employees/company/comp-1');
    });

    test('EmployeeRepository handles ApiException properly', () async {
      final mockClient = MockApiClient();
      final repo = EmployeeRepository(apiClient: mockClient);

      mockClient.errorToThrow = ValidationException('Email already in use');

      expect(
        () => repo.createEmployee(
          Employee(
            companyId: 'comp-1',
            departmentId: 'dept-1',
            firstName: 'A',
            lastName: 'B',
            email: 'a@b.com',
            role: 'Dev',
            annualSalary: 80000,
            joinedAt: DateTime.now(),
          ),
        ),
        throwsA(isA<ValidationException>()),
      );
    });
  });
}
