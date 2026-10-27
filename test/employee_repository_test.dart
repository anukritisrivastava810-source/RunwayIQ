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

  group('Employee Model Unit Tests', () {
    test('Employee fromJson and toJson round-trip with all fields', () {
      final json = {
        'id': 'emp-123',
        'companyId': 'comp-456',
        'departmentId': 'dept-789',
        'firstName': 'Jane',
        'lastName': 'Doe',
        'email': 'jane@example.com',
        'role': 'Senior Engineer',
        'annualSalary': '120000.00', // Decimal string from Prisma
        'currency': 'USD',
        'status': 'ACTIVE',
        'joinedAt': '2026-01-15T00:00:00.000Z',
        'exitedAt': '2026-09-01T00:00:00.000Z',
        'avatarUrl': 'https://example.com/avatar.png',
        'createdAt': '2026-01-15T12:00:00.000Z',
        'updatedAt': '2026-01-15T12:00:00.000Z',
        'department': {
          'id': 'dept-789',
          'companyId': 'comp-456',
          'name': 'Engineering',
        }
      };

      final emp = Employee.fromJson(json);
      expect(emp.id, 'emp-123');
      expect(emp.companyId, 'comp-456');
      expect(emp.departmentId, 'dept-789');
      expect(emp.firstName, 'Jane');
      expect(emp.lastName, 'Doe');
      expect(emp.fullName, 'Jane Doe');
      expect(emp.email, 'jane@example.com');
      expect(emp.role, 'Senior Engineer');
      expect(emp.annualSalary, 120000.0);
      expect(emp.currency, EmployeeCurrency.usd);
      expect(emp.status, EmploymentStatus.active);
      expect(emp.joinedAt, DateTime.parse('2026-01-15T00:00:00.000Z'));
      expect(emp.exitedAt, DateTime.parse('2026-09-01T00:00:00.000Z'));
      expect(emp.avatarUrl, 'https://example.com/avatar.png');
      expect(emp.departmentName, 'Engineering');
      expect(emp.department?.id, 'dept-789');

      final outJson = emp.toJson();
      expect(outJson['id'], 'emp-123');
      expect(outJson['companyId'], 'comp-456');
      expect(outJson['departmentId'], 'dept-789');
      expect(outJson['firstName'], 'Jane');
      expect(outJson['lastName'], 'Doe');
      expect(outJson['email'], 'jane@example.com');
      expect(outJson['role'], 'Senior Engineer');
      expect(outJson['annualSalary'], 120000.0);
      expect(outJson['currency'], 'USD');
      expect(outJson['status'], 'ACTIVE');
      expect(outJson['joinedAt'], '2026-01-15T00:00:00.000Z');
      expect(outJson['exitedAt'], '2026-09-01T00:00:00.000Z');
      expect(outJson['avatarUrl'], 'https://example.com/avatar.png');
    });

    test('Parses annualSalary as num or string Decimal accurately', () {
      final jsonNum = {
        'companyId': 'c1',
        'departmentId': 'd1',
        'firstName': 'A',
        'lastName': 'B',
        'email': 'a@b.com',
        'role': 'Dev',
        'annualSalary': 95000,
        'joinedAt': '2026-01-01T00:00:00.000Z',
      };
      final empFromNum = Employee.fromJson(jsonNum);
      expect(empFromNum.annualSalary, 95000.0);

      final jsonStr = {
        'companyId': 'c1',
        'departmentId': 'd1',
        'firstName': 'A',
        'lastName': 'B',
        'email': 'a@b.com',
        'role': 'Dev',
        'annualSalary': '145000.50',
        'joinedAt': '2026-01-01T00:00:00.000Z',
      };
      final empFromStr = Employee.fromJson(jsonStr);
      expect(empFromStr.annualSalary, 145000.50);
    });

    test('EmploymentStatus enum correctly serializes and parses Prisma values and UI aliases', () {
      expect(EmploymentStatus.active.toJson(), 'ACTIVE');
      expect(EmploymentStatus.inactive.toJson(), 'INACTIVE');
      expect(EmploymentStatus.notice.toJson(), 'NOTICE');
      expect(EmploymentStatus.resigned.toJson(), 'RESIGNED');
      expect(EmploymentStatus.probation.toJson(), 'INACTIVE');
      expect(EmploymentStatus.noticePeriod.toJson(), 'NOTICE');
      expect(EmploymentStatus.terminated.toJson(), 'INACTIVE');

      expect(EmploymentStatus.fromJson('ACTIVE'), EmploymentStatus.active);
      expect(EmploymentStatus.fromJson('INACTIVE'), EmploymentStatus.inactive);
      expect(EmploymentStatus.fromJson('NOTICE'), EmploymentStatus.notice);
      expect(EmploymentStatus.fromJson('RESIGNED'), EmploymentStatus.resigned);
      expect(EmploymentStatus.fromJson('PROBATION'), EmploymentStatus.probation);
      expect(EmploymentStatus.fromJson('NOTICE_PERIOD'), EmploymentStatus.noticePeriod);
      expect(EmploymentStatus.fromJson('TERMINATED'), EmploymentStatus.terminated);
      expect(EmploymentStatus.fromJson(null), EmploymentStatus.active);
      expect(EmploymentStatus.fromJson('UNKNOWN'), EmploymentStatus.active);

      expect(EmploymentStatus.active.displayName, 'Active');
      expect(EmploymentStatus.inactive.displayName, 'Inactive');
      expect(EmploymentStatus.notice.displayName, 'Notice Period');
      expect(EmploymentStatus.resigned.displayName, 'Resigned');
    });

    test('EmployeeCurrency enum supports currencies', () {
      expect(EmployeeCurrency.usd.toJson(), 'USD');
      expect(EmployeeCurrency.inr.toJson(), 'INR');
      expect(EmployeeCurrency.eur.toJson(), 'EUR');
      expect(EmployeeCurrency.fromJson('USD'), EmployeeCurrency.usd);
      expect(EmployeeCurrency.fromJson('INR'), EmployeeCurrency.inr);
      expect(EmployeeCurrency.fromJson(null), EmployeeCurrency.usd);
    });

    test('Employee copyWith, equality and toString work correctly', () {
      final emp1 = Employee(
        id: '1',
        companyId: 'c1',
        departmentId: 'd1',
        firstName: 'John',
        lastName: 'Doe',
        email: 'john@example.com',
        role: 'Engineer',
        annualSalary: 100000,
        joinedAt: DateTime.parse('2026-01-01T00:00:00.000Z'),
      );

      final emp2 = emp1.copyWith(role: 'Staff Engineer', annualSalary: 130000);
      expect(emp2.role, 'Staff Engineer');
      expect(emp2.annualSalary, 130000.0);
      expect(emp2.firstName, 'John');

      final emp1Duplicate = Employee(
        id: '1',
        companyId: 'c1',
        departmentId: 'd1',
        firstName: 'John',
        lastName: 'Doe',
        email: 'john@example.com',
        role: 'Engineer',
        annualSalary: 100000,
        joinedAt: DateTime.parse('2026-01-01T00:00:00.000Z'),
      );
      expect(emp1 == emp1Duplicate, isTrue);
      expect(emp1.hashCode, emp1Duplicate.hashCode);
      expect(emp1.toString(), contains('John Doe'));
    });
  });

  group('EmployeeRepository CRUD Operations', () {
    late MockApiClient mockClient;
    late EmployeeRepository repo;

    setUp(() {
      mockClient = MockApiClient();
      repo = EmployeeRepository(apiClient: mockClient);
    });

    test('createEmployee sends POST to /employees with bare JSON response', () async {
      mockClient.postResponse = {
        'id': 'emp-created',
        'companyId': 'comp-1',
        'departmentId': 'dept-1',
        'firstName': 'Alex',
        'lastName': 'Smith',
        'email': 'alex@example.com',
        'role': 'Product Lead',
        'annualSalary': '110000.00',
        'currency': 'USD',
        'status': 'ACTIVE',
        'joinedAt': '2026-02-01T00:00:00.000Z',
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
          joinedAt: DateTime.parse('2026-02-01T00:00:00.000Z'),
        ),
      );

      expect(created.id, 'emp-created');
      expect(created.fullName, 'Alex Smith');
      expect(mockClient.lastPath, '/employees');
      expect(mockClient.lastData['email'], 'alex@example.com');
      expect(mockClient.lastData['companyId'], 'comp-1');
    });

    test('getAllEmployees sends GET to /employees and handles bare list response', () async {
      mockClient.getResponse = [
        {
          'id': 'emp-1',
          'companyId': 'comp-1',
          'departmentId': 'dept-1',
          'firstName': 'Alice',
          'lastName': 'Dev',
          'email': 'alice@example.com',
          'role': 'Backend Dev',
          'annualSalary': '120000',
          'joinedAt': '2026-01-01T00:00:00.000Z',
        },
        {
          'id': 'emp-2',
          'companyId': 'comp-1',
          'departmentId': 'dept-2',
          'firstName': 'Bob',
          'lastName': 'Design',
          'email': 'bob@example.com',
          'role': 'Product Designer',
          'annualSalary': '95000',
          'joinedAt': '2026-01-01T00:00:00.000Z',
        },
      ];

      final employees = await repo.getAllEmployees();

      expect(mockClient.lastPath, '/employees');
      expect(employees.length, 2);
      expect(employees[0].firstName, 'Alice');
      expect(employees[1].firstName, 'Bob');
    });

    test('getEmployeeById sends GET to /employees/:id and returns Employee', () async {
      mockClient.getResponse = {
        'id': 'emp-xyz',
        'companyId': 'comp-1',
        'departmentId': 'dept-1',
        'firstName': 'Charlie',
        'lastName': 'Brown',
        'email': 'charlie@example.com',
        'role': 'QA Lead',
        'annualSalary': '85000',
        'joinedAt': '2026-03-01T00:00:00.000Z',
      };

      final employee = await repo.getEmployeeById('emp-xyz');

      expect(mockClient.lastPath, '/employees/emp-xyz');
      expect(employee.id, 'emp-xyz');
      expect(employee.firstName, 'Charlie');
      expect(employee.role, 'QA Lead');
    });

    test('getEmployeesByCompany sends GET to /employees/company/:companyId and handles wrapped list', () async {
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

    test('updateEmployee sends PUT to /employees/:id with data and returns updated Employee', () async {
      mockClient.putResponse = {
        'id': 'emp-1',
        'companyId': 'comp-1',
        'departmentId': 'dept-1',
        'firstName': 'Alex',
        'lastName': 'Smith',
        'email': 'alex.smith@example.com',
        'role': 'VP Product',
        'annualSalary': '150000',
        'joinedAt': '2026-02-01T00:00:00.000Z',
      };

      final updated = await repo.updateEmployee(
        'emp-1',
        Employee(
          id: 'emp-1',
          companyId: 'comp-1',
          departmentId: 'dept-1',
          firstName: 'Alex',
          lastName: 'Smith',
          email: 'alex.smith@example.com',
          role: 'VP Product',
          annualSalary: 150000.0,
          joinedAt: DateTime.parse('2026-02-01T00:00:00.000Z'),
        ),
      );

      expect(mockClient.lastPath, '/employees/emp-1');
      expect(mockClient.lastData['role'], 'VP Product');
      expect(updated.role, 'VP Product');
      expect(updated.annualSalary, 150000.0);
    });

    test('deleteEmployee sends DELETE to /employees/:id successfully', () async {
      mockClient.deleteResponse = {'success': true, 'message': 'Employee deleted successfully'};

      await repo.deleteEmployee('emp-1');

      expect(mockClient.lastPath, '/employees/emp-1');
    });

    test('handles NotFoundException properly', () async {
      mockClient.errorToThrow = NotFoundException('Employee not found');

      expect(
        () => repo.getEmployeeById('missing-emp'),
        throwsA(isA<NotFoundException>()),
      );
    });

    test('handles ValidationException properly', () async {
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

    test('wraps unknown exceptions in UnknownException', () async {
      mockClient.errorToThrow = const FormatException('Unexpected character');

      expect(
        () => repo.getEmployeeById('bad-format'),
        throwsA(isA<UnknownException>()),
      );
    });
  });
}

