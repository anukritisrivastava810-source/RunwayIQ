import 'package:flutter/material.dart';
import '../../domain/models/onboarding_models.dart';
import 'package:runway_iq/widgets/custom_button.dart';
import 'package:runway_iq/core/network/api_exceptions.dart';
import 'package:runway_iq/features/company/data/repositories/company_repository.dart';
import 'package:runway_iq/features/department/data/repositories/department_repository.dart';
import 'package:runway_iq/features/department/domain/models/department.dart';
import 'package:runway_iq/features/employee/data/repositories/employee_repository.dart';
import 'package:runway_iq/features/employee/domain/models/employee.dart';

class TeamSetupStep extends StatefulWidget {
  final OnboardingData? data;
  final VoidCallback? onNext;
  final String? companyId;
  final String? companyCurrency;

  const TeamSetupStep({
    super.key,
    this.data,
    this.onNext,
    this.companyId,
    this.companyCurrency,
  });

  bool get isStandalone => companyId != null || data == null;

  @override
  State<TeamSetupStep> createState() => _TeamSetupStepState();
}

class _TeamSetupStepState extends State<TeamSetupStep> {
  // Onboarding mode state
  int _teamSize = 1;
  final Set<String> _departments = {'Engineering', 'Founders'};

  // Standalone employee form state
  final _formKey = GlobalKey<FormState>();
  String _firstName = '';
  String _lastName = '';
  String _email = '';
  String _role = '';
  String _departmentName = 'Engineering';
  double _annualSalary = 0.0;
  String _currency = 'USD';
  EmploymentStatus _status = EmploymentStatus.active;
  DateTime _joinedAt = DateTime.now();
  bool _isSubmitting = false;

  final List<String> _departmentOptions = [
    'Engineering',
    'Product',
    'Design',
    'Marketing',
    'Sales',
    'Operations',
    'HR',
    'Founders',
    'Finance',
    'Legal',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.isStandalone) {
      _currency = widget.companyCurrency ?? 'USD';
    } else if (widget.data?.team != null) {
      _teamSize = widget.data!.team!.teamSize;
      _departments.clear();
      _departments.addAll(widget.data!.team!.departments);
    }
  }

  String _currencyPrefix(String curr) {
    switch (curr.toUpperCase()) {
      case 'INR':
        return '₹ ';
      case 'EUR':
        return '€ ';
      case 'GBP':
        return '£ ';
      case 'SGD':
        return 'S\$ ';
      case 'AED':
        return 'AED ';
      case 'USD':
      default:
        return '\$ ';
    }
  }

  void _submitOnboarding() {
    widget.data?.team = TeamSetup(
      teamSize: _teamSize,
      departments: _departments.toList(),
    );
    widget.onNext?.call();
  }

  Future<void> _submitStandalone() async {
    if (_isSubmitting) return;
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() {
      _isSubmitting = true;
    });

    try {
      // 1. Resolve active Company ID
      String? activeCompanyId = widget.companyId;
      if (activeCompanyId == null || activeCompanyId.isEmpty) {
        final companies = await CompanyRepository().getCompanies();
        if (companies.isNotEmpty) {
          activeCompanyId = companies.first.id;
        }
      }

      if (activeCompanyId == null || activeCompanyId.isEmpty) {
        throw UnknownException('Active company not found. Please complete onboarding first.');
      }

      // 2. Resolve or create Department
      final departmentRepo = DepartmentRepository();
      final existingDepts = await departmentRepo.getDepartmentsByCompany(activeCompanyId);
      String? departmentId;
      final trimmedDept = _departmentName.trim();
      for (final d in existingDepts) {
        if (d.name.trim().toLowerCase() == trimmedDept.toLowerCase()) {
          departmentId = d.id;
          break;
        }
      }

      if (departmentId == null || departmentId.isEmpty) {
        final newDept = await departmentRepo.createDepartment(
          Department(
            companyId: activeCompanyId,
            name: trimmedDept.isNotEmpty ? trimmedDept : 'General',
          ),
        );
        departmentId = newDept.id;
      }

      if (departmentId == null || departmentId.isEmpty) {
        throw UnknownException('Failed to resolve or register department.');
      }

      // 3. Create Employee
      final employeeRepo = EmployeeRepository();
      final newEmployee = Employee(
        companyId: activeCompanyId,
        departmentId: departmentId,
        firstName: _firstName.trim(),
        lastName: _lastName.trim(),
        email: _email.trim(),
        role: _role.trim(),
        annualSalary: _annualSalary,
        currency: EmployeeCurrency.fromJson(_currency),
        status: _status,
        joinedAt: _joinedAt,
      );

      await employeeRepo.createEmployee(newEmployee);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Employee added successfully!')),
        );
        Navigator.of(context).pop(true);
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('An unexpected error occurred: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<void> _pickJoinedDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _joinedAt,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _joinedAt = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isStandalone) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Add Employee'),
        ),
        body: _buildStandaloneForm(context),
      );
    }
    return _buildOnboardingContent(context);
  }

  Widget _buildStandaloneForm(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: _firstName,
                    decoration: const InputDecoration(
                      labelText: 'First Name',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                    onSaved: (v) => _firstName = v ?? '',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    initialValue: _lastName,
                    decoration: const InputDecoration(
                      labelText: 'Last Name',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                    onSaved: (v) => _lastName = v ?? '',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            TextFormField(
              initialValue: _email,
              decoration: const InputDecoration(
                labelText: 'Email Address',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email_outlined),
              ),
              keyboardType: TextInputType.emailAddress,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Email is required';
                if (!v.contains('@') || !v.contains('.')) return 'Enter a valid email';
                return null;
              },
              onSaved: (v) => _email = v ?? '',
            ),
            const SizedBox(height: 16),

            TextFormField(
              initialValue: _role,
              decoration: const InputDecoration(
                labelText: 'Role / Job Title',
                hintText: 'e.g. Senior Software Engineer',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.badge_outlined),
              ),
              validator: (v) => v == null || v.trim().isEmpty ? 'Role is required' : null,
              onSaved: (v) => _role = v ?? '',
            ),
            const SizedBox(height: 16),

            DropdownButtonFormField<String>(
              initialValue: _departmentName,
              decoration: const InputDecoration(
                labelText: 'Department',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.corporate_fare_outlined),
              ),
              items: _departmentOptions
                  .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                  .toList(),
              onChanged: (val) {
                if (val != null) setState(() => _departmentName = val);
              },
            ),
            const SizedBox(height: 16),

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: TextFormField(
                    initialValue: _annualSalary > 0 ? _annualSalary.toString() : '',
                    decoration: InputDecoration(
                      labelText: 'Annual Salary',
                      border: const OutlineInputBorder(),
                      prefixText: _currencyPrefix(_currency),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Salary is required';
                      final parsed = double.tryParse(v);
                      if (parsed == null || parsed <= 0) return 'Enter a valid salary';
                      return null;
                    },
                    onSaved: (v) => _annualSalary = double.parse(v!),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<String>(
                    initialValue: _currency,
                    decoration: const InputDecoration(
                      labelText: 'Currency',
                      border: OutlineInputBorder(),
                    ),
                    items: ['USD', 'INR', 'EUR', 'GBP', 'SGD', 'AED']
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _currency = val);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            DropdownButtonFormField<EmploymentStatus>(
              initialValue: _status,
              decoration: const InputDecoration(
                labelText: 'Employment Status',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: EmploymentStatus.active, child: Text('Active')),
                DropdownMenuItem(value: EmploymentStatus.probation, child: Text('Probation')),
                DropdownMenuItem(value: EmploymentStatus.noticePeriod, child: Text('Notice Period')),
                DropdownMenuItem(value: EmploymentStatus.resigned, child: Text('Resigned')),
                DropdownMenuItem(value: EmploymentStatus.terminated, child: Text('Terminated')),
              ],
              onChanged: (val) {
                if (val != null) setState(() => _status = val);
              },
            ),
            const SizedBox(height: 16),

            InkWell(
              onTap: _pickJoinedDate,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Joined Date',
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.calendar_today, size: 20),
                ),
                child: Text(
                  '${_joinedAt.year}-${_joinedAt.month.toString().padLeft(2, '0')}-${_joinedAt.day.toString().padLeft(2, '0')}',
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            ),
            const SizedBox(height: 40),

            CustomButton(
              text: 'Add Employee',
              isLoading: _isSubmitting,
              onPressed: _submitStandalone,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOnboardingContent(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Team Setup',
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'How big is your current team?',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 32),

          Text(
            'Team Size: $_teamSize',
            style: theme.textTheme.titleMedium,
          ),
          Slider(
            value: _teamSize.toDouble(),
            min: 1,
            max: 100,
            divisions: 99,
            activeColor: theme.colorScheme.primary,
            label: _teamSize.toString(),
            onChanged: (value) {
              setState(() {
                _teamSize = value.toInt();
              });
            },
          ),

          const SizedBox(height: 32),
          Text(
            'Departments',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 16),

          Wrap(
            spacing: 8.0,
            runSpacing: 8.0,
            children: [
              'Founders',
              'Engineering',
              'Product',
              'Design',
              'Marketing',
              'Sales',
              'HR',
              'Operations',
            ].map((dept) {
              final isSelected = _departments.contains(dept);
              return FilterChip(
                label: Text(dept),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _departments.add(dept);
                    } else {
                      _departments.remove(dept);
                    }
                  });
                },
                selectedColor: theme.colorScheme.primary.withValues(alpha: 0.2),
                checkmarkColor: theme.colorScheme.primary,
              );
            }).toList(),
          ),

          const SizedBox(height: 48),
          CustomButton(
            text: 'Continue',
            onPressed: _submitOnboarding,
          ),
        ],
      ),
    );
  }
}
