import 'package:flutter/material.dart';
import '../widgets/stats_card.dart';
import 'dashboard_screen.dart';
import '../features/company/data/repositories/company_repository.dart';
import '../features/company/domain/models/company.dart';
import '../features/employee/data/repositories/employee_repository.dart';
import '../features/employee/domain/models/employee.dart';
import '../features/onboarding/presentation/steps/team_setup_step.dart';
import '../core/network/api_exceptions.dart';

class EmployeesScreen extends StatefulWidget {
  final CompanyRepository? companyRepository;
  final EmployeeRepository? employeeRepository;

  const EmployeesScreen({
    super.key,
    this.companyRepository,
    this.employeeRepository,
  });

  @override
  State<EmployeesScreen> createState() => _EmployeesScreenState();
}

class _EmployeesScreenState extends State<EmployeesScreen> {
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  Company? _activeCompany;
  List<Employee> _employees = [];

  CompanyRepository get _companyRepository =>
      widget.companyRepository ?? CompanyRepository();
  EmployeeRepository get _employeeRepository =>
      widget.employeeRepository ?? EmployeeRepository();

  @override
  void initState() {
    super.initState();
    DashboardScreen.refreshNotifier.addListener(_onDataChanged);
    _loadEmployeeData();
  }

  @override
  void dispose() {
    DashboardScreen.refreshNotifier.removeListener(_onDataChanged);
    super.dispose();
  }

  void _onDataChanged() {
    if (mounted) {
      _loadEmployeeData();
    }
  }

  Future<void> _loadEmployeeData() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = '';
    });

    try {
      final companies = await _companyRepository.getCompanies();
      if (companies.isEmpty) {
        _activeCompany = null;
        _employees = [];
      } else {
        _activeCompany = companies.first;
        final companyId = _activeCompany!.id;
        if (companyId != null && companyId.isNotEmpty) {
          _employees = await _employeeRepository.getEmployeesByCompany(companyId);
        } else {
          _employees = [];
        }
      }
    } on ApiException catch (e) {
      _hasError = true;
      _errorMessage = e.message;
    } catch (e) {
      _hasError = true;
      _errorMessage = 'An unexpected error occurred: $e';
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _openAddEmployee() async {
    if (_activeCompany == null) {
      final companies = await _companyRepository.getCompanies();
      if (companies.isNotEmpty) {
        _activeCompany = companies.first;
      }
    }

    if (_activeCompany == null || _activeCompany!.id == null || _activeCompany!.id!.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No active company found. Please complete onboarding first.')),
        );
      }
      return;
    }

    if (!mounted) return;

    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => TeamSetupStep(
          companyId: _activeCompany!.id,
          companyCurrency: _activeCompany!.currency,
          companyRepository: _companyRepository,
          employeeRepository: _employeeRepository,
        ),
      ),
    );

    if (result == true) {
      _loadEmployeeData();
      DashboardScreen.notifyDataChanged();
    }
  }

  Future<void> _openEditEmployee(Employee employee) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => TeamSetupStep(
          companyId: _activeCompany?.id,
          companyCurrency: _activeCompany?.currency,
          employee: employee,
          companyRepository: _companyRepository,
          employeeRepository: _employeeRepository,
        ),
      ),
    );

    if (result == true) {
      _loadEmployeeData();
      DashboardScreen.notifyDataChanged();
    }
  }

  Future<void> _confirmDeleteEmployee(Employee employee) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Employee'),
        content: Text('Are you sure you want to remove ${employee.fullName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && employee.id != null) {
      setState(() {
        _isLoading = true;
      });
      try {
        await _employeeRepository.deleteEmployee(employee.id!);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${employee.fullName} removed successfully')),
          );
        }
        _loadEmployeeData();
        DashboardScreen.notifyDataChanged();
      } on ApiException catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.message),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
          setState(() {
            _isLoading = false;
          });
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete employee: $e'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  double get _totalPayrollMonthly =>
      _employees.fold(0.0, (sum, e) => sum + (e.annualSalary / 12));

  double get _totalPayrollAnnual =>
      _employees.fold(0.0, (sum, e) => sum + e.annualSalary);

  double get _avgSalary =>
      _employees.isNotEmpty ? _totalPayrollAnnual / _employees.length : 0.0;

  String _formatCurrency(double amount) {
    if (amount >= 1000000) {
      return '\$${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return '\$${(amount / 1000).toStringAsFixed(0)}k';
    }
    return '\$${amount.toStringAsFixed(0)}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_hasError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: theme.colorScheme.error),
              const SizedBox(height: 16),
              Text('Failed to load employees', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(
                _errorMessage,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _loadEmployeeData,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_employees.isEmpty) {
      return Scaffold(
        body: _buildEmptyState(context),
        floatingActionButton: FloatingActionButton(
          heroTag: 'employees_fab_empty',
          onPressed: _openAddEmployee,
          backgroundColor: theme.colorScheme.primary,
          tooltip: 'Add Employee',
          child: const Icon(Icons.add),
        ),
      );
    }

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        heroTag: 'employees_fab',
        onPressed: _openAddEmployee,
        backgroundColor: theme.colorScheme.primary,
        tooltip: 'Add Employee',
        child: const Icon(Icons.add),
      ),
      body: RefreshIndicator(
        onRefresh: _loadEmployeeData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              StatsCard(
                title: 'Monthly Payroll',
                value: _formatCurrency(_totalPayrollMonthly),
                trend: 'Current burn',
                isPositive: false,
                isHighlighted: true,
              ),
              const SizedBox(height: 12),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.5,
                children: [
                  StatsCard(
                    title: 'Headcount',
                    value: _employees.length.toString(),
                  ),
                  StatsCard(
                    title: 'Avg. Salary',
                    value: '${_formatCurrency(_avgSalary)}/yr',
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Directory', style: theme.textTheme.titleLarge),
                  Text(
                    '${_employees.length} ${_employees.length == 1 ? 'member' : 'members'}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Card(
                clipBehavior: Clip.antiAlias,
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _employees.length,
                  separatorBuilder: (context, index) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final emp = _employees[index];
                    return _buildEmployeeTile(context, emp);
                  },
                ),
              ),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 80, color: theme.colorScheme.primary.withValues(alpha: 0.5)),
            const SizedBox(height: 24),
            Text('No Employees Yet', style: theme.textTheme.headlineSmall),
            const SizedBox(height: 16),
            Text(
              'Add your team members to track payroll and calculate runway impacts.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _openAddEmployee,
              icon: const Icon(Icons.add),
              label: const Text('Add Employee'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmployeeTile(BuildContext context, Employee emp) {
    final theme = Theme.of(context);
    final initial = emp.firstName.isNotEmpty ? emp.firstName[0].toUpperCase() : '?';
    final deptSubtitle = emp.departmentName.isNotEmpty
        ? '${emp.role} • ${emp.departmentName}'
        : emp.role;
    final salaryText = '${_formatCurrency(emp.annualSalary)}/yr';

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
        child: Text(
          initial,
          style: TextStyle(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      title: Text(emp.fullName, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(deptSubtitle),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            salaryText,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, size: 20),
            onSelected: (value) {
              if (value == 'edit') {
                _openEditEmployee(emp);
              } else if (value == 'delete') {
                _confirmDeleteEmployee(emp);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit_outlined, size: 18),
                    SizedBox(width: 8),
                    Text('Edit'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline, size: 18, color: theme.colorScheme.error),
                    const SizedBox(width: 8),
                    Text('Delete', style: TextStyle(color: theme.colorScheme.error)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      onTap: () => _openEditEmployee(emp),
    );
  }
}
