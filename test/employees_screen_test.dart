import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:runway_iq/core/network/api_exceptions.dart';
import 'package:runway_iq/features/company/data/repositories/company_repository.dart';
import 'package:runway_iq/features/company/domain/models/company.dart';
import 'package:runway_iq/features/department/domain/models/department.dart';
import 'package:runway_iq/features/employee/data/repositories/employee_repository.dart';
import 'package:runway_iq/features/employee/domain/models/employee.dart';
import 'package:runway_iq/screens/employees_screen.dart';
import 'package:runway_iq/theme/app_theme.dart';

class MockCompanyRepo extends CompanyRepository {
  List<Company> mockCompanies = [];
  Exception? error;

  @override
  Future<List<Company>> getCompanies() async {
    if (error != null) throw error!;
    return mockCompanies;
  }
}

class MockEmployeeRepo extends EmployeeRepository {
  List<Employee> mockEmployees = [];
  Exception? error;
  String? lastDeletedId;

  @override
  Future<List<Employee>> getEmployeesByCompany(String companyId) async {
    if (error != null) throw error!;
    return mockEmployees;
  }

  @override
  Future<void> deleteEmployee(String id) async {
    if (error != null) throw error!;
    lastDeletedId = id;
    mockEmployees.removeWhere((e) => e.id == id);
  }
}

void main() {
  final testCompany = Company(
    id: 'comp-101',
    name: 'Acme Technologies',
    currency: 'USD',
  );

  final testEmployees = [
    Employee(
      id: 'emp-1',
      companyId: 'comp-101',
      departmentId: 'dept-eng',
      firstName: 'Sarah',
      lastName: 'Connor',
      email: 'sarah@acme.com',
      role: 'Staff Engineer',
      annualSalary: 180000.0,
      currency: EmployeeCurrency.usd,
      status: EmploymentStatus.active,
      joinedAt: DateTime(2025, 1, 15),
      department: const Department(
        id: 'dept-eng',
        companyId: 'comp-101',
        name: 'Engineering',
      ),
    ),
    Employee(
      id: 'emp-2',
      companyId: 'comp-101',
      departmentId: 'dept-des',
      firstName: 'John',
      lastName: 'Doe',
      email: 'john@acme.com',
      role: 'Lead Designer',
      annualSalary: 120000.0,
      currency: EmployeeCurrency.usd,
      status: EmploymentStatus.active,
      joinedAt: DateTime(2025, 3, 1),
      department: const Department(
        id: 'dept-des',
        companyId: 'comp-101',
        name: 'Design',
      ),
    ),
  ];

  group('EmployeesScreen Widget Tests', () {
    testWidgets('renders empty state when no employees exist', (tester) async {
      final mockCompany = MockCompanyRepo()..mockCompanies = [testCompany];
      final mockEmployee = MockEmployeeRepo()..mockEmployees = [];

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: EmployeesScreen(
            companyRepository: mockCompany,
            employeeRepository: mockEmployee,
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('No Employees Yet'), findsOneWidget);
      expect(
        find.text('Add your team members to track payroll and calculate runway impacts.'),
        findsOneWidget,
      );
      expect(find.widgetWithText(ElevatedButton, 'Add Employee'), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    testWidgets('renders populated employee list with metrics correctly', (tester) async {
      final mockCompany = MockCompanyRepo()..mockCompanies = [testCompany];
      final mockEmployee = MockEmployeeRepo()..mockEmployees = List.of(testEmployees);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: EmployeesScreen(
            companyRepository: mockCompany,
            employeeRepository: mockEmployee,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Metrics
      expect(find.text('Monthly Payroll'), findsOneWidget);
      expect(find.text('Headcount'), findsOneWidget);
      expect(find.text('Avg. Salary'), findsOneWidget);
      expect(find.text('2'), findsOneWidget); // 2 members count

      // Directory header
      expect(find.text('Directory'), findsOneWidget);
      expect(find.text('2 members'), findsOneWidget);

      // Employees listed
      expect(find.text('Sarah Connor'), findsOneWidget);
      expect(find.text('Staff Engineer • Engineering'), findsOneWidget);
      expect(find.text('\$180k/yr'), findsOneWidget);

      expect(find.text('John Doe'), findsOneWidget);
      expect(find.text('Lead Designer • Design'), findsOneWidget);
      expect(find.text('\$120k/yr'), findsOneWidget);
    });

    testWidgets('shows delete confirmation dialog and cancels without deletion', (tester) async {
      final mockCompany = MockCompanyRepo()..mockCompanies = [testCompany];
      final mockEmployee = MockEmployeeRepo()..mockEmployees = List.of(testEmployees);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: EmployeesScreen(
            companyRepository: mockCompany,
            employeeRepository: mockEmployee,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find more_vert popup button for first employee
      final popupMenuButtons = find.byType(PopupMenuButton<String>);
      expect(popupMenuButtons, findsNWidgets(2));

      await tester.tap(popupMenuButtons.first);
      await tester.pumpAndSettle();

      expect(find.text('Delete'), findsOneWidget);
      expect(find.text('Edit'), findsOneWidget);

      // Tap Delete menu item
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      // Confirmation dialog should be shown
      expect(find.text('Delete Employee'), findsOneWidget);
      expect(find.text('Are you sure you want to remove Sarah Connor?'), findsOneWidget);

      // Cancel deletion
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.text('Delete Employee'), findsNothing);
      expect(mockEmployee.lastDeletedId, isNull);
      expect(find.text('Sarah Connor'), findsOneWidget);
    });

    testWidgets('confirms delete employee and removes from list', (tester) async {
      final mockCompany = MockCompanyRepo()..mockCompanies = [testCompany];
      final mockEmployee = MockEmployeeRepo()..mockEmployees = List.of(testEmployees);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: EmployeesScreen(
            companyRepository: mockCompany,
            employeeRepository: mockEmployee,
          ),
        ),
      );

      await tester.pumpAndSettle();

      final popupMenuButtons = find.byType(PopupMenuButton<String>);
      await tester.tap(popupMenuButtons.first);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      // Tap Delete in dialog
      final dialogDeleteButton = find.widgetWithText(TextButton, 'Delete');
      await tester.tap(dialogDeleteButton);
      await tester.pumpAndSettle();

      expect(mockEmployee.lastDeletedId, 'emp-1');
      expect(find.text('Sarah Connor removed successfully'), findsOneWidget);
      expect(find.text('Sarah Connor'), findsNothing);
      expect(find.text('John Doe'), findsOneWidget);
    });

    testWidgets('renders error state and retries successfully', (tester) async {
      final mockCompany = MockCompanyRepo()..mockCompanies = [testCompany];
      final mockEmployee = MockEmployeeRepo()..error = ServerException('Database unavailable');

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: EmployeesScreen(
            companyRepository: mockCompany,
            employeeRepository: mockEmployee,
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Failed to load employees'), findsOneWidget);
      expect(find.text('Database unavailable'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Retry'), findsOneWidget);

      // Fix error and tap retry
      mockEmployee.error = null;
      mockEmployee.mockEmployees = List.of(testEmployees);

      await tester.tap(find.widgetWithText(ElevatedButton, 'Retry'));
      await tester.pumpAndSettle();

      expect(find.text('Sarah Connor'), findsOneWidget);
    });
  });
}
