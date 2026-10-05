import 'package:flutter/material.dart';
import '../widgets/stats_card.dart';

import '../features/company/data/repositories/company_repository.dart';
import '../features/company/domain/models/company.dart';
import '../features/funding/data/repositories/funding_round_repository.dart';
import '../features/funding/domain/models/funding_round.dart';
import '../features/onboarding/presentation/steps/funding_step.dart';
import '../core/network/api_exceptions.dart';

class FundingScreen extends StatefulWidget {
  const FundingScreen({super.key});

  @override
  State<FundingScreen> createState() => _FundingScreenState();
}

class _FundingScreenState extends State<FundingScreen> {
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  Company? _activeCompany;
  List<FundingRound> _fundingRounds = [];

  @override
  void initState() {
    super.initState();
    _loadFundingData();
  }

  Future<void> _loadFundingData() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = '';
    });

    try {
      // Resolve active company using the same pattern as DashboardScreen.
      final companies = await CompanyRepository().getCompanies();
      if (companies.isEmpty) {
        _activeCompany = null;
        _fundingRounds = [];
      } else {
        _activeCompany = companies.first;
        final companyId = _activeCompany!.id;
        if (companyId != null && companyId.isNotEmpty) {
          _fundingRounds = await FundingRoundRepository()
              .getFundingRoundsByCompany(companyId);
        } else {
          _fundingRounds = [];
        }
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

  Future<void> _openAddFundingRound() async {
    // Ensure active company exists
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
        builder: (_) => FundingStep(
          companyId: _activeCompany!.id,
          companyCurrency: _activeCompany!.currency,
        ),
      ),
    );

    if (result == true) {
      _loadFundingData();
    }
  }

  /// Sum of [amountRaised] across all funding rounds.
  double get _totalRaised =>
      _fundingRounds.fold(0.0, (sum, r) => sum + r.amountRaised);

  /// Most recent round by [closedAt].
  FundingRound? get _latestRound {
    if (_fundingRounds.isEmpty) return null;
    final sorted = List<FundingRound>.from(_fundingRounds)
      ..sort((a, b) => b.closedAt.compareTo(a.closedAt));
    return sorted.first;
  }

  /// Format an amount to a human-readable string (M / k / raw).
  String _formatAmount(double amount, FundingCurrency currency) {
    final prefix = currency == FundingCurrency.inr ? '₹' : '\$';
    if (amount >= 1000000) {
      return '$prefix${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return '$prefix${(amount / 1000).toStringAsFixed(1)}k';
    }
    return '$prefix${amount.toStringAsFixed(0)}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: _buildBody(context, theme),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddFundingRound,
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBody(BuildContext context, ThemeData theme) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_hasError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline,
                  color: theme.colorScheme.error, size: 48),
              const SizedBox(height: 16),
              Text(_errorMessage,
                  style: theme.textTheme.titleMedium,
                  textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _loadFundingData,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_fundingRounds.isEmpty) {
      return _buildEmptyState(context, theme);
    }

    return _buildContent(context, theme);
  }

  Widget _buildContent(BuildContext context, ThemeData theme) {
    final latest = _latestRound!;

    return RefreshIndicator(
      onRefresh: _loadFundingData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Summary stats
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.5,
              children: [
                StatsCard(
                  title: 'Total Raised',
                  value: _formatAmount(_totalRaised, latest.currency),
                  isHighlighted: true,
                ),
                StatsCard(
                  title: 'Latest Round',
                  value: latest.roundType.displayName,
                  trend: _formatDate(latest.closedAt),
                  isPositive: true,
                ),
              ],
            ),

            const SizedBox(height: 24),
            Text('Funding Rounds', style: theme.textTheme.titleLarge),
            const SizedBox(height: 12),

            // Funding round list — sorted most recent first.
            Card(
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  for (int i = 0; i < _fundingRounds.length; i++) ...[
                    if (i > 0) const Divider(height: 1),
                    _buildRoundTile(context, theme, _fundingRounds[i]),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoundTile(
      BuildContext context, ThemeData theme, FundingRound round) {
    final label = round.roundType.displayName;
    final initial = label.isNotEmpty ? label[0] : 'R';
    final equityLabel = round.equityPercent != null
        ? '${(round.equityPercent! * 100).toStringAsFixed(1)}% equity'
        : '';

    return ListTile(
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            initial,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
        ),
      ),
      title: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(
        equityLabel.isNotEmpty
            ? '$equityLabel · ${_formatDate(round.closedAt)}'
            : _formatDate(round.closedAt),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            _formatAmount(round.amountRaised, round.currency),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
              fontSize: 16,
            ),
          ),
          Text(
            round.currency.toJson(),
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, ThemeData theme) {
    return RefreshIndicator(
      onRefresh: _loadFundingData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.7,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.account_balance_wallet_outlined,
                    size: 80,
                    color: theme.colorScheme.primary.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 24),
                  Text('\$0 Raised', style: theme.textTheme.headlineSmall),
                  const SizedBox(height: 8),
                  Text(
                    'No funding rounds recorded yet.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Keep track of your cap table, investment rounds, and investor details here.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    onPressed: _openAddFundingRound,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Funding Round'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.year}';
  }
}
