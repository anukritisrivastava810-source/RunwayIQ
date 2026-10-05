import 'package:flutter/material.dart';
import '../features/company/data/repositories/company_repository.dart';
import '../features/company/domain/models/company.dart';
import '../features/treasury/data/repositories/treasury_repository.dart';
import '../features/treasury/domain/models/treasury_investment.dart';
import '../features/onboarding/presentation/steps/treasury_step.dart';
import '../widgets/stats_card.dart';
import '../core/network/api_exceptions.dart';

class TreasuryScreen extends StatefulWidget {
  const TreasuryScreen({super.key});

  @override
  State<TreasuryScreen> createState() => _TreasuryScreenState();
}

class _TreasuryScreenState extends State<TreasuryScreen> {
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  Company? _activeCompany;
  List<TreasuryInvestment> _investments = [];

  @override
  void initState() {
    super.initState();
    _loadTreasuryData();
  }

  Future<void> _loadTreasuryData() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = '';
    });

    try {
      final companies = await CompanyRepository().getCompanies();
      if (companies.isEmpty) {
        _activeCompany = null;
        _investments = [];
      } else {
        _activeCompany = companies.first;
        final companyId = _activeCompany!.id;
        if (companyId != null && companyId.isNotEmpty) {
          _investments = await TreasuryRepository().getTreasuryInvestmentsByCompany(companyId);
        } else {
          _investments = [];
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

  Future<void> _openAddInvestment() async {
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
        builder: (_) => TreasuryStep(
          companyId: _activeCompany!.id,
          companyCurrency: _activeCompany!.currency,
        ),
      ),
    );

    if (result == true) {
      _loadTreasuryData();
    }
  }

  double get _totalInvested =>
      _investments.fold(0.0, (sum, i) => sum + i.totalInvested);

  /// Average or weighted yield rate
  double get _weightedYield {
    if (_totalInvested <= 0) return 0.0;
    double weightedSum = 0.0;
    for (final inv in _investments) {
      if (inv.interestRate != null) {
        weightedSum += (inv.interestRate! * 100) * inv.totalInvested;
      }
    }
    return weightedSum / _totalInvested;
  }

  Map<AssetType, double> get _allocationByType {
    final map = <AssetType, double>{};
    for (final inv in _investments) {
      map[inv.assetType] = (map[inv.assetType] ?? 0.0) + inv.totalInvested;
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
              Text('Failed to load treasury portfolio', style: theme.textTheme.titleMedium),
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
                onPressed: _loadTreasuryData,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_investments.isEmpty) {
      return Scaffold(
        body: _buildEmptyState(context),
        floatingActionButton: FloatingActionButton(
          onPressed: _openAddInvestment,
          backgroundColor: theme.colorScheme.primary,
          tooltip: 'Add Investment',
          child: const Icon(Icons.add),
        ),
      );
    }

    final allocation = _allocationByType;

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddInvestment,
        backgroundColor: theme.colorScheme.primary,
        tooltip: 'Add Investment',
        child: const Icon(Icons.add),
      ),
      body: RefreshIndicator(
        onRefresh: _loadTreasuryData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              StatsCard(
                title: 'Total Treasury Holdings',
                value: _formatCurrency(_totalInvested),
                trend: _weightedYield > 0
                    ? '+${_weightedYield.toStringAsFixed(2)}% APY Avg'
                    : '${_investments.length} Active Holdings',
                isPositive: true,
                isHighlighted: true,
              ),
              const SizedBox(height: 24),

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Portfolio Allocation', style: theme.textTheme.titleLarge),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: theme.colorScheme.primary,
                                width: 16,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                '${_investments.length}',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 24),
                          Expanded(
                            child: Column(
                              children: allocation.entries.map((entry) {
                                final percent = _totalInvested > 0
                                    ? ((entry.value / _totalInvested) * 100).round()
                                    : 0;
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 8.0),
                                  child: _buildLegend(
                                    theme,
                                    entry.key.displayName,
                                    '$percent%',
                                    entry.key.color,
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Holdings', style: theme.textTheme.titleLarge),
                  Text(
                    '${_investments.length} investments',
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
                  itemCount: _investments.length,
                  separatorBuilder: (context, index) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final inv = _investments[index];
                    final yieldText = inv.interestRate != null
                        ? '${(inv.interestRate! * 100).toStringAsFixed(2)}% APY'
                        : inv.assetType.displayName;
                    final notesText = inv.notes != null && inv.notes!.isNotEmpty
                        ? ' • ${inv.notes}'
                        : '';
                    return ListTile(
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: inv.assetType.color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(inv.assetType.icon, color: inv.assetType.color),
                      ),
                      title: Text(inv.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('$yieldText$notesText'),
                      trailing: Text(
                        _formatCurrency(inv.totalInvested),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
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
            Icon(Icons.show_chart, size: 80, color: theme.colorScheme.primary.withValues(alpha: 0.5)),
            const SizedBox(height: 24),
            Text('No Treasury Investments', style: theme.textTheme.headlineSmall),
            const SizedBox(height: 16),
            Text(
              'Manage your idle cash and track yields from investments like Bonds and Fixed Deposits.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _openAddInvestment,
              icon: const Icon(Icons.add),
              label: const Text('Add Investment'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegend(ThemeData theme, String label, String percentage, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
            const SizedBox(width: 8),
            Text(label, style: theme.textTheme.bodyMedium),
          ],
        ),
        Text(percentage, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }
}
