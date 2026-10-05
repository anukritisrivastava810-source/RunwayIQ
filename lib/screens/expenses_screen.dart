import 'package:flutter/material.dart';
import '../features/company/data/repositories/company_repository.dart';
import '../features/company/domain/models/company.dart';
import '../features/expense/data/repositories/expense_repository.dart';
import '../features/expense/domain/models/expense.dart';
import '../features/onboarding/presentation/steps/financial_setup_step.dart';
import '../widgets/stats_card.dart';
import '../core/network/api_exceptions.dart';

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  Company? _activeCompany;
  List<Expense> _expenses = [];

  @override
  void initState() {
    super.initState();
    _loadExpenseData();
  }

  Future<void> _loadExpenseData() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = '';
    });

    try {
      final companies = await CompanyRepository().getCompanies();
      if (companies.isEmpty) {
        _activeCompany = null;
        _expenses = [];
      } else {
        _activeCompany = companies.first;
        final companyId = _activeCompany!.id;
        if (companyId != null && companyId.isNotEmpty) {
          _expenses = await ExpenseRepository().getExpensesByCompany(companyId);
        } else {
          _expenses = [];
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

  Future<void> _openAddExpense() async {
    if (_activeCompany == null) {
      final companies = await CompanyRepository().getCompanies();
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
        builder: (_) => FinancialSetupStep(
          companyId: _activeCompany!.id,
          companyCurrency: _activeCompany!.currency,
        ),
      ),
    );

    if (result == true) {
      _loadExpenseData();
    }
  }

  /// Calculates monthly equivalent for each expense based on recurrence.
  double _monthlyAmount(Expense e) {
    switch (e.recurrence) {
      case ExpenseRecurrence.weekly:
        return e.amount * 52 / 12;
      case ExpenseRecurrence.monthly:
        return e.amount;
      case ExpenseRecurrence.quarterly:
        return e.amount / 3;
      case ExpenseRecurrence.yearly:
        return e.amount / 12;
      case ExpenseRecurrence.oneTime:
        return e.amount;
    }
  }

  double get _totalMonthlyBurn =>
      _expenses.fold(0.0, (sum, e) => sum + _monthlyAmount(e));

  Map<ExpenseCategory, double> get _categoryTotals {
    final map = <ExpenseCategory, double>{};
    for (final e in _expenses) {
      map[e.category] = (map[e.category] ?? 0.0) + _monthlyAmount(e);
    }
    return map;
  }

  String _formatCurrency(double amount) {
    if (amount >= 1000000) {
      return '\$${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return '\$${(amount / 1000).toStringAsFixed(1)}k';
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
              Text('Failed to load expenses', style: theme.textTheme.titleMedium),
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
                onPressed: _loadExpenseData,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_expenses.isEmpty) {
      return Scaffold(
        body: _buildEmptyState(context),
        floatingActionButton: FloatingActionButton(
          onPressed: _openAddExpense,
          backgroundColor: theme.colorScheme.primary,
          tooltip: 'Add Expense',
          child: const Icon(Icons.add),
        ),
      );
    }

    final categoryTotals = _categoryTotals;

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddExpense,
        backgroundColor: theme.colorScheme.primary,
        tooltip: 'Add Expense',
        child: const Icon(Icons.add),
      ),
      body: RefreshIndicator(
        onRefresh: _loadExpenseData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              StatsCard(
                title: 'Total Monthly Expenses',
                value: _formatCurrency(_totalMonthlyBurn),
                trend: '${_expenses.length} active recurring & one-time',
                isPositive: false,
                isHighlighted: true,
              ),
              const SizedBox(height: 24),

              Text('Category Breakdown', style: theme.textTheme.titleLarge),
              const SizedBox(height: 12),
              Card(
                clipBehavior: Clip.antiAlias,
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: categoryTotals.length,
                  separatorBuilder: (context, index) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final cat = categoryTotals.keys.elementAt(index);
                    final amt = categoryTotals[cat]!;
                    final percent = _totalMonthlyBurn > 0
                        ? ((amt / _totalMonthlyBurn) * 100).toStringAsFixed(0)
                        : '0';
                    return _buildExpenseTile(
                      context,
                      cat.displayName,
                      '$percent% of monthly operational spend',
                      '${_formatCurrency(amt)}/mo',
                      cat.icon,
                      cat.color,
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('All Expenses', style: theme.textTheme.titleLarge),
                  Text(
                    '${_expenses.length} entries',
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
                  itemCount: _expenses.length,
                  separatorBuilder: (context, index) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final exp = _expenses[index];
                    final detail = exp.vendor != null && exp.vendor!.isNotEmpty
                        ? '${exp.vendor} • ${exp.recurrence.displayName}'
                        : exp.recurrence.displayName;
                    return _buildExpenseTile(
                      context,
                      exp.title,
                      detail,
                      _formatCurrency(exp.amount),
                      exp.category.icon,
                      exp.category.color,
                    );
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
            Icon(Icons.receipt_long_outlined, size: 80, color: theme.colorScheme.primary.withValues(alpha: 0.5)),
            const SizedBox(height: 24),
            Text('No Expenses Yet', style: theme.textTheme.headlineSmall),
            const SizedBox(height: 16),
            Text(
              'Track your recurring software, rent, and operational expenses.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _openAddExpense,
              icon: const Icon(Icons.add),
              label: const Text('Add Expense'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpenseTile(
    BuildContext context,
    String title,
    String subtitle,
    String amount,
    IconData icon,
    Color color,
  ) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle),
      trailing: Text(
        amount,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
      ),
    );
  }
}
