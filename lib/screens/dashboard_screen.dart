import 'package:flutter/material.dart';
import '../widgets/stats_card.dart';
import '../widgets/dashboard_card.dart';
import 'ai_advisor_screen.dart';
import 'runway_screen.dart';

import '../features/onboarding/data/repositories/onboarding_repository.dart';
import '../features/company/data/repositories/company_repository.dart';
import '../features/company/domain/models/company.dart';
import '../features/funding/data/repositories/funding_round_repository.dart';
import '../features/funding/domain/models/funding_round.dart';
import '../core/network/api_exceptions.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  Company? _company;
  List<FundingRound> _fundingRounds = [];

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = '';
    });

    try {
      // 1. Fetch the active company.
      final companies = await CompanyRepository().getCompanies();
      if (companies.isNotEmpty) {
        _company = companies.first;

        // 2. Fetch real funding rounds for this company.
        final companyId = _company!.id;
        if (companyId != null && companyId.isNotEmpty) {
          _fundingRounds = await FundingRoundRepository()
              .getFundingRoundsByCompany(companyId);
        } else {
          _fundingRounds = [];
        }
      } else {
        _company = null;
        _fundingRounds = [];
      }
    } on ApiException catch (e) {
      _hasError = true;
      _errorMessage = e.message;
    } catch (e) {
      _hasError = true;
      _errorMessage = 'An unexpected error occurred';
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
              onPressed: _loadDashboardData,
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

    // Financial data still sourced from onboarding in-memory store for
    // cash / burn figures (financial-setup module not yet on backend).
    final repo = OnboardingRepository();
    final cash = repo.currentData?.financials?.currentCash ?? 0.0;
    final burn = repo.currentData?.financials?.monthlyExpenses ?? 0.0;

    int runwayMonths = 0;
    if (burn > 0) {
      runwayMonths = (cash / burn).round();
    }

    // Funding data: real backend totals.
    final totalRaised = _totalRaised;
    final latest = _latestRound;
    final latestRoundLabel = latest != null
        ? latest.roundType.displayName
        : _company!.stage;

    return RefreshIndicator(
      onRefresh: _loadDashboardData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // AI Insight Card
            DashboardCard(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AiAdvisorScreen()),
                );
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
                          'At your current burn rate, ${_company!.name} has $runwayMonths months of runway remaining.',
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
                      value: '\$${(cash / 1000).toStringAsFixed(1)}k',
                      trend: 'Current',
                      isPositive: true,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: StatsCard(
                      title: 'Runway',
                      value: '$runwayMonths mo',
                      trend: 'Based on burn',
                      isPositive: runwayMonths > 6,
                      isHighlighted: true,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const RunwayScreen()),
                        );
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
                      value: '\$${(burn / 1000).toStringAsFixed(1)}k',
                      trend: 'Current',
                      isPositive: false,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: StatsCard(
                      title: 'Total Raised',
                      value: totalRaised >= 1000000
                          ? '\$${(totalRaised / 1000000).toStringAsFixed(1)}M'
                          : totalRaised >= 1000
                              ? '\$${(totalRaised / 1000).toStringAsFixed(1)}k'
                              : '\$${totalRaised.toStringAsFixed(0)}',
                      trend: latestRoundLabel,
                      isPositive: true,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Chart Placeholder
            Text('Burn Rate Trend', style: theme.textTheme.titleLarge),
            const SizedBox(height: 12),
            DashboardCard(
              padding: const EdgeInsets.all(0),
              child: Container(
                height: 200,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      theme.colorScheme.primary.withValues(alpha: 0.2),
                      theme.colorScheme.primary.withValues(alpha: 0.0),
                    ],
                  ),
                ),
                child: Center(
                  child: Text(
                    '[ Line Chart Placeholder ]',
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: theme.colorScheme.primary),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Recent Activity
            Text('Recent Activity', style: theme.textTheme.titleLarge),
            const SizedBox(height: 12),
            DashboardCard(
              padding: EdgeInsets.zero,
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 3,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: theme.colorScheme.surface,
                      child: Icon(
                        index == 0 ? Icons.arrow_downward : Icons.arrow_upward,
                        color: index == 0
                            ? theme.colorScheme.error
                            : theme.colorScheme.primary,
                        size: 20,
                      ),
                    ),
                    title: Text(
                        ['AWS Web Services', 'Subscription Revenue', 'Stripe Payout'][index]),
                    subtitle: Text(['Oct 14', 'Oct 12', 'Oct 10'][index]),
                    trailing: Text(
                      ['-\$2,400', '+\$14,500', '+\$12,000'][index],
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: index == 0
                            ? theme.colorScheme.error
                            : theme.colorScheme.primary,
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
