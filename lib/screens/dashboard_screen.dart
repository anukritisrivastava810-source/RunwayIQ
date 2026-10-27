import 'package:flutter/material.dart';
import '../widgets/stats_card.dart';
import '../widgets/dashboard_card.dart';
import '../widgets/burn_rate_chart.dart';
import 'ai_advisor_screen.dart';
import 'runway_screen.dart';

import '../features/company/data/repositories/company_repository.dart';
import '../features/company/domain/models/company.dart';
import '../features/funding/data/repositories/funding_round_repository.dart';
import '../features/funding/domain/models/funding_round.dart';
import '../features/expense/data/repositories/expense_repository.dart';
import '../features/expense/domain/models/expense.dart';
import '../features/employee/data/repositories/employee_repository.dart';
import '../features/employee/domain/models/employee.dart';
import '../features/treasury/data/repositories/treasury_repository.dart';
import '../features/treasury/domain/models/treasury_investment.dart';
import '../features/dashboard/data/repositories/dashboard_repository.dart';
import '../features/dashboard/domain/models/burn_trend.dart';
import '../core/network/api_exceptions.dart';

class DashboardScreen extends StatefulWidget {
  final CompanyRepository? companyRepository;
  final FundingRoundRepository? fundingRoundRepository;
  final ExpenseRepository? expenseRepository;
  final EmployeeRepository? employeeRepository;
  final TreasuryRepository? treasuryRepository;
  final DashboardRepository? dashboardRepository;

  const DashboardScreen({
    super.key,
    this.companyRepository,
    this.fundingRoundRepository,
    this.expenseRepository,
    this.employeeRepository,
    this.treasuryRepository,
    this.dashboardRepository,
  });

  /// Global notification trigger when financial data is modified elsewhere in the app.
  static final ValueNotifier<int> refreshNotifier = ValueNotifier<int>(0);

  /// Call this whenever a funding round, expense, employee, or treasury item is created/modified.
  static void notifyDataChanged() {
    refreshNotifier.value++;
  }

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  Company? _company;
  List<FundingRound> _fundingRounds = [];
  List<Expense> _expenses = [];
  List<Employee> _employees = [];
  List<TreasuryInvestment> _treasuryInvestments = [];
  BurnTrendResponse? _burnTrend;
  bool _isChartLoading = false;
  bool _hasChartError = false;
  String _chartErrorMessage = '';

  CompanyRepository get _companyRepository =>
      widget.companyRepository ?? CompanyRepository();
  FundingRoundRepository get _fundingRoundRepository =>
      widget.fundingRoundRepository ?? FundingRoundRepository();
  ExpenseRepository get _expenseRepository =>
      widget.expenseRepository ?? ExpenseRepository();
  EmployeeRepository get _employeeRepository =>
      widget.employeeRepository ?? EmployeeRepository();
  TreasuryRepository get _treasuryRepository =>
      widget.treasuryRepository ?? TreasuryRepository();
  DashboardRepository get _dashboardRepository =>
      widget.dashboardRepository ?? DashboardRepository();

  @override
  void initState() {
    super.initState();
    DashboardScreen.refreshNotifier.addListener(_onDataChanged);
    loadDashboardData();
  }

  @override
  void dispose() {
    DashboardScreen.refreshNotifier.removeListener(_onDataChanged);
    super.dispose();
  }

  void _onDataChanged() {
    if (mounted) {
      loadDashboardData();
    }
  }

  Future<void> _loadBurnTrend(String companyId) async {
    if (mounted) {
      setState(() {
        _isChartLoading = true;
        _hasChartError = false;
        _chartErrorMessage = '';
      });
    } else {
      _isChartLoading = true;
      _hasChartError = false;
      _chartErrorMessage = '';
    }

    try {
      final trend = await _dashboardRepository.getBurnTrend(companyId);
      if (mounted) {
        setState(() {
          _burnTrend = trend;
          _isChartLoading = false;
        });
      } else {
        _burnTrend = trend;
        _isChartLoading = false;
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _hasChartError = true;
          _chartErrorMessage = e.message;
          _isChartLoading = false;
        });
      } else {
        _hasChartError = true;
        _chartErrorMessage = e.message;
        _isChartLoading = false;
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasChartError = true;
          _chartErrorMessage = 'Failed to load chart data: $e';
          _isChartLoading = false;
        });
      } else {
        _hasChartError = true;
        _chartErrorMessage = 'Failed to load chart data: $e';
        _isChartLoading = false;
      }
    }
  }

  /// Fetches fresh data from PostgreSQL through existing backend APIs.
  Future<void> loadDashboardData() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _hasError = false;
        _errorMessage = '';
      });
    } else {
      _isLoading = true;
      _hasError = false;
      _errorMessage = '';
    }

    try {
      // 1. Fetch active company using project's existing logic.
      final companies = await _companyRepository.getCompanies();
      if (companies.isNotEmpty) {
        _company = companies.first;

        final companyId = _company!.id;
        if (companyId != null && companyId.isNotEmpty) {
          // 2. Concurrently fetch all real records from PostgreSQL including burn trend
          final results = await Future.wait([
            _fundingRoundRepository.getFundingRoundsByCompany(companyId),
            _expenseRepository.getExpensesByCompany(companyId),
            _employeeRepository.getEmployeesByCompany(companyId),
            _treasuryRepository.getTreasuryInvestmentsByCompany(companyId),
            _loadBurnTrend(companyId),
          ]);

          _fundingRounds = results[0] as List<FundingRound>;
          _expenses = results[1] as List<Expense>;
          _employees = results[2] as List<Employee>;
          _treasuryInvestments = results[3] as List<TreasuryInvestment>;
        } else {
          _fundingRounds = [];
          _expenses = [];
          _employees = [];
          _treasuryInvestments = [];
          _burnTrend = null;
        }
      } else {
        _company = null;
        _fundingRounds = [];
        _expenses = [];
        _employees = [];
        _treasuryInvestments = [];
        _burnTrend = null;
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

  /// Sum of [amountRaised] across all fetched funding rounds.
  double get _totalRaised =>
      _fundingRounds.fold(0.0, (sum, r) => sum + r.amountRaised);

  /// The most-recently-closed funding round, or null if none exist.
  FundingRound? get _latestRound {
    if (_fundingRounds.isEmpty) return null;
    final sorted = List<FundingRound>.from(_fundingRounds)
      ..sort((a, b) => b.closedAt.compareTo(a.closedAt));
    return sorted.first;
  }

  String get _latestRoundLabel {
    final latest = _latestRound;
    if (latest != null) {
      return '${latest.roundType.displayName} · ${_formatMonthYear(latest.closedAt)}';
    }
    return _company?.stage ?? 'No rounds';
  }

  /// Total expenses in dollars.
  double get _totalExpenses =>
      _expenses.fold(0.0, (sum, e) => sum + e.amount);

  /// Available cash: defined by project architecture (Total Funding - Total Expenses).
  double get _availableCash => _totalRaised - _totalExpenses;

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

  /// Monthly operational spend from expenses.
  double get _monthlyExpenseBurn =>
      _expenses.fold(0.0, (sum, e) => sum + _monthlyAmount(e));

  /// Monthly payroll from all active employees (annualSalary / 12) matching AnalyticsService.
  double get _monthlyPayrollBurn =>
      _employees
          .where((e) => e.status == EmploymentStatus.active)
          .fold(0.0, (sum, e) => sum + (e.annualSalary / 12));

  /// Total monthly burn rate (payroll + expenses) matching AnalyticsService formula.
  double get _monthlyBurn => _monthlyExpenseBurn + _monthlyPayrollBurn;

  /// Number of active employees.
  int get _activeEmployeeCount =>
      _employees.where((e) => e.status == EmploymentStatus.active).length;

  /// Runway in months, or null if no burn recorded to calculate from.
  int? get _runwayMonths {
    if (_monthlyBurn <= 0) return null;
    if (_availableCash <= 0) return 0;
    return (_availableCash / _monthlyBurn).round();
  }

  /// Recent activities compiled from actual FundingRound, Expense, and Employee records.
  List<_ActivityItem> get _recentActivities {
    final items = <_ActivityItem>[];

    for (final round in _fundingRounds) {
      items.add(_ActivityItem(
        title: '${round.roundType.displayName} Round',
        subtitle: _formatDateShort(round.closedAt),
        trailing: '+${_formatAmount(round.amountRaised)}',
        isPositive: true,
        date: round.closedAt,
      ));
    }

    for (final exp in _expenses) {
      items.add(_ActivityItem(
        title: exp.title,
        subtitle: _formatDateShort(exp.expenseDate),
        trailing: '-${_formatAmount(exp.amount)}',
        isPositive: false,
        date: exp.expenseDate,
      ));
    }

    for (final emp in _employees) {
      final name =
          emp.fullName.trim().isEmpty ? 'Employee' : emp.fullName.trim();
      final rolePart =
          emp.role.trim().isNotEmpty ? ' (${emp.role.trim()})' : '';
      items.add(_ActivityItem(
        title: '$name$rolePart',
        subtitle: _formatDateShort(emp.joinedAt),
        trailing: '-${_formatAmount(emp.annualSalary / 12)}',
        isPositive: false,
        date: emp.joinedAt,
      ));
    }

    for (final inv in _treasuryInvestments) {
      items.add(_ActivityItem(
        title: inv.name,
        subtitle: _formatDateShort(inv.investmentDate),
        trailing: '-${_formatAmount(inv.totalInvested)}',
        isPositive: false,
        date: inv.investmentDate,
      ));
    }

    items.sort((a, b) => b.date.compareTo(a.date));
    return items.take(5).toList();
  }

  String _formatAmount(double amount) {
    final isNegative = amount < 0;
    final absAmount = amount.abs();
    final prefix = isNegative ? '-\$' : '\$';
    if (absAmount >= 1000000) {
      return '$prefix${(absAmount / 1000000).toStringAsFixed(1)}M';
    } else if (absAmount >= 1000) {
      return '$prefix${(absAmount / 1000).toStringAsFixed(1)}k';
    }
    return '$prefix${absAmount.toStringAsFixed(0)}';
  }

  String _formatMonthYear(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  String _formatDateShort(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: theme.colorScheme.error, size: 48),
            const SizedBox(height: 16),
            Text(_errorMessage, style: theme.textTheme.titleMedium),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: loadDashboardData,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_company == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.business_outlined, color: theme.colorScheme.primary, size: 48),
            const SizedBox(height: 16),
            Text('No company data found', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              'Please complete onboarding to view your dashboard.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    final runway = _runwayMonths;
    final totalRaised = _totalRaised;
    final availableCash = _availableCash;
    final monthlyBurn = _monthlyBurn;
    final activities = _recentActivities;

    // Build intelligent dynamic AI insight
    String insightText;
    if (runway != null) {
      final teamCount = _activeEmployeeCount;
      final teamSuffix = teamCount > 0 ? ' with a team of $teamCount' : '';
      insightText =
          'At your current burn rate, ${_company!.name}$teamSuffix has $runway months of runway remaining.';
    } else if (availableCash > 0) {
      insightText =
          '${_company!.name} has ${_formatAmount(availableCash)} in available cash with no active burn.';
    } else {
      insightText =
          'Record your expenses and funding rounds to see live runway insights.';
    }

    return RefreshIndicator(
      onRefresh: loadDashboardData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // AI Insight Card
            DashboardCard(
              onTap: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AiAdvisorScreen()),
                );
                if (mounted) loadDashboardData();
              },
              child: Row(
                children: [
                  Icon(Icons.auto_awesome, color: theme.colorScheme.primary),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${_company!.name} Insight',
                          style: theme.textTheme.titleSmall?.copyWith(
                              color: theme.colorScheme.primary),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          insightText,
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios,
                      size: 16, color: theme.colorScheme.primary),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Metrics Cards
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: StatsCard(
                      title: 'Available Cash',
                      value: _formatAmount(availableCash),
                      trend: availableCash >= 0 ? 'Current' : 'Deficit',
                      isPositive: availableCash >= 0,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: StatsCard(
                      title: 'Runway',
                      value: runway != null ? '$runway mo' : '—',
                      trend: runway != null ? 'Based on burn' : 'No burn data',
                      isPositive: runway != null ? runway > 6 : true,
                      isHighlighted: true,
                      onTap: () async {
                        await Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const RunwayScreen()),
                        );
                        if (mounted) loadDashboardData();
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: StatsCard(
                      title: 'Monthly Burn',
                      value: _formatAmount(monthlyBurn),
                      trend: monthlyBurn > 0 ? 'Current' : 'No expenses',
                      isPositive: false,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: StatsCard(
                      title: 'Total Raised',
                      value: _formatAmount(totalRaised),
                      trend: _latestRoundLabel,
                      isPositive: true,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Real Burn Rate Trend Chart
            Text('Burn Rate Trend', style: theme.textTheme.titleLarge),
            const SizedBox(height: 12),
            BurnRateChart(
              burnTrend: _burnTrend,
              isLoading: _isChartLoading,
              hasError: _hasChartError,
              errorMessage: _chartErrorMessage,
              onRetry: _company?.id != null
                  ? () => _loadBurnTrend(_company!.id!)
                  : null,
            ),

            const SizedBox(height: 24),

            // Recent Activity
            Text('Recent Activity', style: theme.textTheme.titleLarge),
            const SizedBox(height: 12),
            DashboardCard(
              padding: EdgeInsets.zero,
              child: activities.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 32.0, horizontal: 16.0),
                      child: Center(
                        child: Text(
                          'No recent activity recorded.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.6),
                          ),
                        ),
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: activities.length,
                      separatorBuilder: (context, index) =>
                          const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final item = activities[index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: theme.colorScheme.surface,
                            child: Icon(
                              item.isPositive
                                  ? Icons.arrow_upward
                                  : Icons.arrow_downward,
                              color: item.isPositive
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.error,
                              size: 20,
                            ),
                          ),
                          title: Text(item.title),
                          subtitle: Text(item.subtitle),
                          trailing: Text(
                            item.trailing,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: item.isPositive
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.error,
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActivityItem {
  final String title;
  final String subtitle;
  final String trailing;
  final bool isPositive;
  final DateTime date;

  _ActivityItem({
    required this.title,
    required this.subtitle,
    required this.trailing,
    required this.isPositive,
    required this.date,
  });
}

