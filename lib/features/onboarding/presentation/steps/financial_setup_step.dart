import 'package:flutter/material.dart';
import '../../domain/models/onboarding_models.dart';
import 'package:runway_iq/widgets/custom_button.dart';
import 'package:runway_iq/core/network/api_exceptions.dart';
import 'package:runway_iq/features/company/data/repositories/company_repository.dart';
import 'package:runway_iq/features/expense/data/repositories/expense_repository.dart';
import 'package:runway_iq/features/expense/domain/models/expense.dart';

class FinancialSetupStep extends StatefulWidget {
  final OnboardingData? data;
  final VoidCallback? onNext;
  final String? companyId;
  final String? companyCurrency;

  const FinancialSetupStep({
    super.key,
    this.data,
    this.onNext,
    this.companyId,
    this.companyCurrency,
  });

  bool get isStandalone => companyId != null || data == null;

  @override
  State<FinancialSetupStep> createState() => _FinancialSetupStepState();
}

class _FinancialSetupStepState extends State<FinancialSetupStep> {
  // Onboarding mode fields
  final _onboardingFormKey = GlobalKey<FormState>();
  late double _currentCash;
  late double _monthlyRevenue;
  late double _monthlyExpenses;
  late double _payroll;

  // Standalone expense form fields
  final _standaloneFormKey = GlobalKey<FormState>();
  String _title = '';
  ExpenseCategory _category = ExpenseCategory.cloud;
  double _amount = 0.0;
  String _currency = 'USD';
  ExpenseRecurrence _recurrence = ExpenseRecurrence.monthly;
  DateTime _expenseDate = DateTime.now();
  String _vendor = '';
  String _description = '';
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.isStandalone) {
      _currency = widget.companyCurrency ?? 'USD';
    } else {
      _currentCash = widget.data?.financials?.currentCash ?? 0.0;
      _monthlyRevenue = widget.data?.financials?.monthlyRevenue ?? 0.0;
      _monthlyExpenses = widget.data?.financials?.monthlyExpenses ?? 0.0;
      _payroll = widget.data?.financials?.payroll ?? 0.0;
      if (widget.data?.company?.currency != null) {
        _currency = widget.data!.company!.currency;
      }
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
    if (_onboardingFormKey.currentState!.validate()) {
      _onboardingFormKey.currentState!.save();

      widget.data?.financials = FinancialSetup(
        currentCash: _currentCash,
        monthlyRevenue: _monthlyRevenue,
        monthlyExpenses: _monthlyExpenses,
        payroll: _payroll,
        burnFrequency: 'Monthly',
        currency: 'USD',
      );

      widget.onNext?.call();
    }
  }

  Future<void> _submitStandalone() async {
    if (_isSubmitting) return;
    if (!_standaloneFormKey.currentState!.validate()) return;
    _standaloneFormKey.currentState!.save();

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

      // 2. Create Expense via repository
      final expenseRepo = ExpenseRepository();
      final newExpense = Expense(
        companyId: activeCompanyId,
        title: _title.trim(),
        category: _category,
        amount: _amount,
        currency: ExpenseCurrency.fromJson(_currency),
        recurrence: _recurrence,
        expenseDate: _expenseDate,
        vendor: _vendor.trim().isNotEmpty ? _vendor.trim() : null,
        description: _description.trim().isNotEmpty ? _description.trim() : null,
      );

      await expenseRepo.createExpense(newExpense);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Expense added successfully!')),
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

  Future<void> _pickExpenseDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _expenseDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _expenseDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isStandalone) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Add Expense'),
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
        key: _standaloneFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              initialValue: _title,
              decoration: const InputDecoration(
                labelText: 'Expense Title',
                hintText: 'e.g. AWS Cloud Hosting, Office Rent',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description_outlined),
              ),
              validator: (v) => v == null || v.trim().isEmpty ? 'Title is required' : null,
              onSaved: (v) => _title = v ?? '',
            ),
            const SizedBox(height: 16),

            DropdownButtonFormField<ExpenseCategory>(
              initialValue: _category,
              decoration: const InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.category_outlined),
              ),
              items: ExpenseCategory.values.map((cat) {
                return DropdownMenuItem(
                  value: cat,
                  child: Row(
                    children: [
                      Icon(cat.icon, size: 18, color: cat.color),
                      const SizedBox(width: 8),
                      Text(cat.displayName),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _category = val);
              },
            ),
            const SizedBox(height: 16),

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: TextFormField(
                    initialValue: _amount > 0 ? _amount.toString() : '',
                    decoration: InputDecoration(
                      labelText: 'Amount',
                      border: const OutlineInputBorder(),
                      prefixText: _currencyPrefix(_currency),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Amount is required';
                      final parsed = double.tryParse(v);
                      if (parsed == null || parsed <= 0) return 'Enter a valid amount';
                      return null;
                    },
                    onSaved: (v) => _amount = double.parse(v!),
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

            DropdownButtonFormField<ExpenseRecurrence>(
              initialValue: _recurrence,
              decoration: const InputDecoration(
                labelText: 'Recurrence',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.repeat),
              ),
              items: ExpenseRecurrence.values.map((rec) {
                return DropdownMenuItem(
                  value: rec,
                  child: Text(rec.displayName),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _recurrence = val);
              },
            ),
            const SizedBox(height: 16),

            TextFormField(
              initialValue: _vendor,
              decoration: const InputDecoration(
                labelText: 'Vendor / Provider (optional)',
                hintText: 'e.g. Amazon Web Services, Google, WeWork',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.storefront_outlined),
              ),
              onSaved: (v) => _vendor = v ?? '',
            ),
            const SizedBox(height: 16),

            InkWell(
              onTap: _pickExpenseDate,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Expense Date',
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.calendar_today, size: 20),
                ),
                child: Text(
                  '${_expenseDate.year}-${_expenseDate.month.toString().padLeft(2, '0')}-${_expenseDate.day.toString().padLeft(2, '0')}',
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            ),
            const SizedBox(height: 16),

            TextFormField(
              initialValue: _description,
              decoration: const InputDecoration(
                labelText: 'Notes / Description (optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
              onSaved: (v) => _description = v ?? '',
            ),
            const SizedBox(height: 40),

            CustomButton(
              text: 'Add Expense',
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
      child: Form(
        key: _onboardingFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Financial Setup',
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Enter your current financial numbers to calculate runway.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 32),

            _buildNumberField('Current Cash in Bank', (v) => _currentCash = v, _currentCash),
            const SizedBox(height: 16),
            _buildNumberField('Monthly Revenue (MRR)', (v) => _monthlyRevenue = v, _monthlyRevenue),
            const SizedBox(height: 16),
            _buildNumberField('Total Monthly Expenses', (v) => _monthlyExpenses = v, _monthlyExpenses),
            const SizedBox(height: 16),
            _buildNumberField('Current Monthly Payroll', (v) => _payroll = v, _payroll),

            const SizedBox(height: 48),
            CustomButton(
              text: 'Continue',
              onPressed: _submitOnboarding,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNumberField(String label, Function(double) onSaved, double initial) {
    return TextFormField(
      initialValue: initial > 0 ? initial.toString() : '',
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        prefixText: '\$ ',
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      validator: (value) {
        if (value == null || value.isEmpty) return 'Required';
        if (double.tryParse(value) == null) return 'Must be a valid number';
        return null;
      },
      onSaved: (value) => onSaved(double.parse(value!)),
    );
  }
}
