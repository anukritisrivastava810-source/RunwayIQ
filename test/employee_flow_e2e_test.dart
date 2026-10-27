import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:runway_iq/core/network/api_exceptions.dart';
import 'package:runway_iq/features/company/data/repositories/company_repository.dart';
import 'package:runway_iq/features/company/domain/models/company.dart';
import 'package:runway_iq/features/department/data/repositories/department_repository.dart';
import 'package:runway_iq/features/department/domain/models/department.dart';
import 'package:runway_iq/features/employee/data/repositories/employee_repository.dart';
import 'package:runway_iq/features/employee/domain/models/employee.dart';
import 'package:runway_iq/features/funding/data/repositories/funding_round_repository.dart';
import 'package:runway_iq/features/funding/domain/models/funding_round.dart';
import 'package:runway_iq/features/expense/data/repositories/expense_repository.dart';
import 'package:runway_iq/features/expense/domain/models/expense.dart';
import 'package:runway_iq/features/treasury/data/repositories/treasury_repository.dart';
import 'package:runway_iq/features/treasury/domain/models/treasury_investment.dart';
import 'package:runway_iq/features/onboarding/presentation/steps/team_setup_step.dart';
import 'package:runway_iq/screens/dashboard_screen.dart';
import 'package:runway_iq/screens/employees_screen.dart';
import 'package:runway_iq/theme/app_theme.dart';

class MockE2EEmployeeRepository extends EmployeeRepository {
  final List<Employee> _db = [];
  int createCalls = 0;
  Exception? error;

  List<Employee> get employees => List.unmodifiable(_db);

  void seed(List<Employee> employees) {
    _db.clear();
    _db.addAll(employees);
  }

  @override
  Future<Employee> createEmployee(Employee employee) async {
    createCalls++;
    if (error != null) throw error!;
    final created = employee.copyWith(
      id: 'emp-${DateTime.now().millisecondsSinceEpoch}-${_db.length + 1}',
    );
    _db.add(created);
    return created;
  }

  @override
  Future<List<Employee>> getEmployeesByCompany(String companyId) async {
    if (error != null) throw error!;
    return _db.where((e) => e.companyId == companyId).toList();
  }

  @override
  Future<Employee> updateEmployee(String id, Employee employee) async {
    if (error != null) throw error!;
    final index = _db.indexWhere((e) => e.id == id);
    if (index == -1) throw NotFoundException('Employee not found');
    final updated = employee.copyWith(id: id);
    _db[index] = updated;
    return updated;
  }

  @override
  Future<void> deleteEmployee(String id) async {
    if (error != null) throw error!;
    final index = _db.indexWhere((e) => e.id == id);
    if (index == -1) throw NotFoundException('Employee not found');
    _db.removeAt(index);
  }
}

class MockE2ECompanyRepository extends CompanyRepository {
  List<Company> companies = [];
  Exception? error;

  @override
  Future<List<Company>> getCompanies() async {
    if (error != null) throw error!;
    return companies;
  }
}

class MockE2EDepartmentRepository extends DepartmentRepository {
  final List<Department> _depts = [];

  void seed(List<Department> departments) {
    _depts.clear();
    _depts.addAll(departments);
  }

  @override
  Future<List<Department>> getDepartmentsByCompany(String companyId) async {
    return _depts.where((d) => d.companyId == companyId).toList();
  }

  @override
  Future<Department> createDepartment(Department department) async {
    final created = Department(
      id: 'dept-${DateTime.now().millisecondsSinceEpoch}-${_depts.length + 1}',
      companyId: department.companyId,
      name: department.name,
    );
    _depts.add(created);
    return created;
  }
}

class MockE2EFundingRepository extends FundingRoundRepository {
  final List<FundingRound> rounds = [];

  @override
  Future<List<FundingRound>> getFundingRoundsByCompany(String companyId) async {
    return rounds.where((r) => r.companyId == companyId).toList();
  }
}

class MockE2EExpenseRepository extends ExpenseRepository {
  final List<Expense> expenses = [];

  @override
  Future<List<Expense>> getExpensesByCompany(String companyId) async {
    return expenses.where((e) => e.companyId == companyId).toList();
  }
}

class MockE2ETreasuryRepository extends TreasuryRepository {
  final List<TreasuryInvestment> investments = [];

  @override
  Future<List<TreasuryInvestment>> getTreasuryInvestmentsByCompany(String companyId) async {
    return investments.where((i) => i.companyId == companyId).toList();
  }
}

void main() {
  late MockE2ECompanyRepository companyRepo;
  late MockE2EEmployeeRepository employeeRepo;
  late MockE2EDepartmentRepository departmentRepo;
  late MockE2EFundingRepository fundingRepo;
  late MockE2EExpenseRepository expenseRepo;
  late MockE2ETreasuryRepository treasuryRepo;

  final activeCompany = Company(
    id: 'comp-e2e-1',
    name: 'Quantum Intelligence',
    stage: 'SEED',
    currency: 'USD',
  );

  setUp(() {
    companyRepo = MockE2ECompanyRepository()..companies = [activeCompany];
    employeeRepo = MockE2EEmployeeRepository();
    departmentRepo = MockE2EDepartmentRepository();
    fundingRepo = MockE2EFundingRepository();
    expenseRepo = MockE2EExpenseRepository();
    treasuryRepo = MockE2ETreasuryRepository();
  });

  group('Phase 5 — Step 6: Employee End-to-End Testing', () {
    testWidgets('1. Complete Flow & CRUD Operations: Create, Read, Update, Delete with Company Association',
        (WidgetTester tester) async {
      // 1.1 Render EmployeesScreen with zero employees -> Empty state
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: EmployeesScreen(
            companyRepository: companyRepo,
            employeeRepository: employeeRepo,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No Employees Yet'), findsOneWidget);

      // 1.2 Open Add Employee form
      final addFab = find.byType(FloatingActionButton);
      expect(addFab, findsOneWidget);
      await tester.tap(addFab);
      await tester.pumpAndSettle();

      // Form is displayed
      expect(find.text('Add Employee'), findsWidgets);

      // 1.3 Fill in new Employee details using TextField indices
      final textFields = find.byType(TextField);
      expect(textFields, findsNWidgets(5));

      await tester.enterText(textFields.at(0), 'Grace');
      await tester.enterText(textFields.at(1), 'Hopper');
      await tester.enterText(textFields.at(2), 'grace@quantum.io');
      await tester.enterText(textFields.at(3), 'Lead Compiler Engineer');
      await tester.enterText(textFields.at(4), '180000');

      // 1.4 Submit form
      final submitBtn = find.widgetWithText(ElevatedButton, 'Add Employee');
      await tester.ensureVisible(submitBtn);
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      // 1.5 Verify creation in repository with proper companyId
      expect(employeeRepo.employees.length, 1);
      final created = employeeRepo.employees.first;
      expect(created.firstName, 'Grace');
      expect(created.lastName, 'Hopper');
      expect(created.email, 'grace@quantum.io');
      expect(created.companyId, 'comp-e2e-1');
      expect(created.role, 'Lead Compiler Engineer');
      expect(created.annualSalary, 180000.0);

      // 1.6 Verify Read on Employees Screen
      expect(find.text('Grace Hopper'), findsOneWidget);
      expect(find.text('Lead Compiler Engineer • Engineering'), findsOneWidget);
      expect(find.text('\$180k/yr'), findsNWidgets(2)); // Avg salary stat & tile
      expect(find.text('\$15k'), findsOneWidget); // Monthly payroll: 180k / 12
      expect(find.text('1'), findsNWidgets(2)); // Headcount and directory member count

      // 1.7 Update Employee: Tap popup menu -> Edit
      final popupMenu = find.byType(PopupMenuButton<String>);
      await tester.tap(popupMenu);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();

      expect(find.text('Edit Employee'), findsOneWidget);
      expect(find.text('Grace'), findsOneWidget);

      // Update Salary to 240000 and Role to 'VP of Engineering'
      final editFields = find.byType(TextField);
      await tester.enterText(editFields.at(3), 'VP of Engineering');
      await tester.enterText(editFields.at(4), '240000');

      final updateBtn = find.widgetWithText(ElevatedButton, 'Update Employee');
      await tester.ensureVisible(updateBtn);
      await tester.tap(updateBtn);
      await tester.pumpAndSettle();

      // Verify Update in database
      expect(employeeRepo.employees.length, 1);
      final updated = employeeRepo.employees.first;
      expect(updated.role, 'VP of Engineering');
      expect(updated.annualSalary, 240000.0);

      // Verify Read on Employees Screen with updated values
      expect(find.text('VP of Engineering • Engineering'), findsOneWidget);
      expect(find.text('\$240k/yr'), findsNWidgets(2)); // Avg salary stat & tile
      expect(find.text('\$20k'), findsOneWidget); // 240k / 12

      // 1.8 Delete Employee: Tap popup menu -> Delete -> Cancel
      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      expect(find.text('Delete Employee'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(employeeRepo.employees.length, 1);
      expect(find.text('Grace Hopper'), findsOneWidget);

      // Tap Delete -> Confirm
      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      final confirmDelete = find.widgetWithText(TextButton, 'Delete');
      await tester.tap(confirmDelete);
      await tester.pumpAndSettle();

      // Verify Deleted from repository
      expect(employeeRepo.employees.isEmpty, isTrue);
      expect(find.text('No Employees Yet'), findsOneWidget);
    });

    testWidgets('2. UI States: Loading, Error, Retry, and Duplicate Submission Prevention',
        (WidgetTester tester) async {
      // 2.1 Duplicate Submission Prevention
      // Mount standalone TeamSetupStep directly
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: TeamSetupStep(
              companyId: 'comp-e2e-1',
              companyCurrency: 'USD',
              companyRepository: companyRepo,
              employeeRepository: employeeRepo,
              departmentRepository: departmentRepo,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final textFields = find.byType(TextField);
      await tester.enterText(textFields.at(0), 'Alan');
      await tester.enterText(textFields.at(1), 'Turing');
      await tester.enterText(textFields.at(2), 'alan@quantum.io');
      await tester.enterText(textFields.at(3), 'Cryptography Lead');
      await tester.enterText(textFields.at(4), '150000');

      final submitBtn = find.widgetWithText(ElevatedButton, 'Add Employee');
      await tester.ensureVisible(submitBtn);

      // Simulate rapid double tap
      await tester.tap(submitBtn);
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      // Confirm only 1 employee record created (no duplicate)
      expect(employeeRepo.createCalls, 1);
      expect(employeeRepo.employees.length, 1);

      // 2.2 Error State and Retry on EmployeesScreen
      employeeRepo.error = ServerException('Backend service temporarily unavailable');

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: EmployeesScreen(
            companyRepository: companyRepo,
            employeeRepository: employeeRepo,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Failed to load employees'), findsOneWidget);
      expect(find.text('Backend service temporarily unavailable'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Retry'), findsOneWidget);

      // Clear error and retry
      employeeRepo.error = null;
      await tester.tap(find.widgetWithText(ElevatedButton, 'Retry'));
      await tester.pumpAndSettle();

      // Screen recovers and renders Alan Turing
      expect(find.text('Alan Turing'), findsOneWidget);
    });

    testWidgets('3. Persistence: Re-opening screen preserves real employee record',
        (WidgetTester tester) async {
      // Seed employee record
      employeeRepo.seed([
        Employee(
          id: 'emp-persisted-1',
          companyId: 'comp-e2e-1',
          departmentId: 'dept-1',
          firstName: 'Katherine',
          lastName: 'Johnson',
          email: 'katherine@quantum.io',
          role: 'Flight Dynamics Lead',
          annualSalary: 192000.0,
          currency: EmployeeCurrency.usd,
          status: EmploymentStatus.active,
          joinedAt: DateTime(2025, 4, 1),
          department: const Department(
            id: 'dept-1',
            companyId: 'comp-e2e-1',
            name: 'Aerospace',
          ),
        ),
      ]);

      // Mount screen (Session 1)
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: EmployeesScreen(
            companyRepository: companyRepo,
            employeeRepository: employeeRepo,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Katherine Johnson'), findsOneWidget);
      expect(find.text('\$192k/yr'), findsNWidgets(2));

      // Simulate App Restart / Complete Widget Tree Rebuild (Session 2)
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: EmployeesScreen(
            companyRepository: companyRepo,
            employeeRepository: employeeRepo,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Data is immediately restored from database
      expect(find.text('Katherine Johnson'), findsOneWidget);
      expect(find.text('\$16k'), findsOneWidget); // 192k / 12
    });

    testWidgets('4. Regression: Dashboard accurately reflects employee operations without affecting other modules',
        (WidgetTester tester) async {
      // Seed company funding and expenses
      fundingRepo.rounds.add(
        FundingRound(
          id: 'f-reg-1',
          companyId: 'comp-e2e-1',
          investorId: 'inv-1',
          roundType: FundingRoundType.seed,
          amountRaised: 2400000.0,
          currency: FundingCurrency.usd,
          closedAt: DateTime(2026, 1, 1),
        ),
      );

      expenseRepo.expenses.add(
        Expense(
          id: 'exp-reg-1',
          companyId: 'comp-e2e-1',
          title: 'Infrastructure Cloud',
          amount: 10000.0,
          category: ExpenseCategory.cloud,
          recurrence: ExpenseRecurrence.monthly,
          expenseDate: DateTime(2026, 2, 1),
        ),
      );

      // Zero employees initially:
      // Available Cash = 2.4M - 10k = 2.39M -> $2.4M
      // Monthly Burn = 10k (no payroll)
      // Runway = 2,390,000 / 10,000 = 239 mo
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
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('\$2.4M'), findsNWidgets(2)); // Cash and Total Raised
      expect(find.text('\$10.0k'), findsOneWidget); // Monthly Burn
      expect(find.text('239 mo'), findsOneWidget); // Runway

      // Add employee: $120,000 annual = $10,000/mo payroll
      employeeRepo.seed([
        Employee(
          id: 'emp-reg-1',
          companyId: 'comp-e2e-1',
          departmentId: 'dept-1',
          firstName: 'Linus',
          lastName: 'Torvalds',
          email: 'linus@quantum.io',
          role: 'Kernel Specialist',
          annualSalary: 120000.0,
          currency: EmployeeCurrency.usd,
          status: EmploymentStatus.active,
          joinedAt: DateTime(2026, 3, 1),
        ),
      ]);

      // Notify Dashboard of employee creation
      DashboardScreen.notifyDataChanged();
      await tester.pumpAndSettle();

      // New Monthly Burn = 10,000 (cloud) + 10,000 (payroll) = $20.0k
      // New Runway = 2,390,000 / 20,000 = 120 mo
      expect(find.text('\$20.0k'), findsOneWidget);
      expect(find.text('120 mo'), findsOneWidget);
      expect(find.textContaining('with a team of 1'), findsOneWidget);
      expect(find.text('Linus Torvalds (Kernel Specialist)'), findsOneWidget);

      // Funding & expense modules unaffected
      expect(find.text('Seed Round'), findsOneWidget);
      expect(find.text('Infrastructure Cloud'), findsOneWidget);

      // Remove employee
      employeeRepo.seed([]);
      DashboardScreen.notifyDataChanged();
      await tester.pumpAndSettle();

      // Returns to initial non-payroll metrics
      expect(find.text('\$10.0k'), findsOneWidget);
      expect(find.text('239 mo'), findsOneWidget);
      expect(find.text('Linus Torvalds (Kernel Specialist)'), findsNothing);
    });
  });
}
