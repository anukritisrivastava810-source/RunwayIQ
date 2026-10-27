import 'package:flutter/material.dart';
import 'dashboard_screen.dart';
import '../features/company/data/repositories/company_repository.dart';
import '../features/company/domain/models/company.dart';
import '../features/treasury/data/repositories/treasury_repository.dart';
import '../features/treasury/domain/models/treasury_investment.dart';
import '../features/treasury/domain/models/market_quote.dart';
import '../features/onboarding/presentation/steps/treasury_step.dart';
import '../widgets/stats_card.dart';
import '../core/network/api_exceptions.dart';

class TreasuryScreen extends StatefulWidget {
  final TreasuryRepository? treasuryRepository;
  final CompanyRepository? companyRepository;

  const TreasuryScreen({
    super.key,
    this.treasuryRepository,
    this.companyRepository,
  });

  @override
  State<TreasuryScreen> createState() => _TreasuryScreenState();
}

class _TreasuryScreenState extends State<TreasuryScreen> {
  late final TreasuryRepository _treasuryRepo;
  late final CompanyRepository _companyRepo;
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  Company? _activeCompany;
  List<TreasuryInvestment> _investments = [];

  // Market quotes state
  final Map<String, MarketQuote> _quotes = {};
  final Map<String, bool> _quoteLoading = {};
  final Map<String, String> _quoteErrors = {};

  @override
  void initState() {
    super.initState();
    _treasuryRepo = widget.treasuryRepository ?? TreasuryRepository();
    _companyRepo = widget.companyRepository ?? CompanyRepository();
    _loadTreasuryData();
  }

  Future<void> _loadTreasuryData() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = '';
    });

    try {
      final companies = await _companyRepo.getCompanies();
      if (companies.isEmpty) {
        _activeCompany = null;
        _investments = [];
      } else {
        _activeCompany = companies.first;
        final companyId = _activeCompany!.id;
        if (companyId != null && companyId.isNotEmpty) {
          _investments = await _treasuryRepo.getTreasuryInvestmentsByCompany(companyId);
        } else {
          _investments = [];
        }
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }

      // Automatically fetch quotes for market-priced investments
      _fetchQuotesForMarketInvestments();
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = e.message;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = 'An unexpected error occurred: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _fetchQuotesForMarketInvestments({bool forceRefresh = false}) async {
    final marketInvestments = _investments.where((inv) =>
        inv.assetType.isMarketPriced &&
        inv.id != null &&
        inv.ticker != null &&
        inv.ticker!.trim().isNotEmpty &&
        inv.units != null &&
        inv.units! > 0);

    for (final inv in marketInvestments) {
      _fetchQuoteForInvestment(inv.id!, forceRefresh: forceRefresh);
    }
  }

  Future<void> _fetchQuoteForInvestment(String investmentId, {bool forceRefresh = false}) async {
    if (_quoteLoading[investmentId] == true) return;

    if (mounted) {
      setState(() {
        _quoteLoading[investmentId] = true;
        _quoteErrors.remove(investmentId);
      });
    }

    try {
      final quote = await _treasuryRepo.getInvestmentQuote(
        investmentId,
        forceRefresh: forceRefresh,
      );
      if (mounted) {
        setState(() {
          _quotes[investmentId] = quote;
          _quoteLoading[investmentId] = false;
        });
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _quoteErrors[investmentId] = e.message;
          _quoteLoading[investmentId] = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _quoteErrors[investmentId] = 'Quote unavailable';
          _quoteLoading[investmentId] = false;
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
      DashboardScreen.notifyDataChanged();
    }
  }

  Future<void> _openEditInvestment(TreasuryInvestment investment) async {
    if (_activeCompany == null || _activeCompany!.id == null || _activeCompany!.id!.isEmpty) {
      return;
    }

    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => TreasuryStep(
          companyId: _activeCompany!.id,
          companyCurrency: _activeCompany!.currency,
          initialInvestment: investment,
        ),
      ),
    );

    if (result == true) {
      _loadTreasuryData();
      DashboardScreen.notifyDataChanged();
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

  // ---------------------------------------------------------------------------
  // Currency-Scoped Market Portfolio Calculations
  // Only aggregates investments in the company's base currency to prevent distortion
  // ---------------------------------------------------------------------------
  String get _companyCurrency => _activeCompany?.currency.toUpperCase() ?? 'USD';

  List<TreasuryInvestment> get _companyCurrencyMarketInvestments =>
      _investments.where((inv) =>
          inv.assetType.isMarketPriced &&
          inv.currency.value.toUpperCase() == _companyCurrency).toList();

  List<TreasuryInvestment> get _foreignCurrencyMarketInvestments =>
      _investments.where((inv) =>
          inv.assetType.isMarketPriced &&
          inv.currency.value.toUpperCase() != _companyCurrency).toList();

  double get _marketTotalInvested =>
      _companyCurrencyMarketInvestments.fold(0.0, (sum, inv) => sum + inv.totalInvested);

  double? get _marketCurrentValue {
    final list = _companyCurrencyMarketInvestments;
    if (list.isEmpty) return null;

    double sum = 0.0;
    bool hasValuation = false;

    for (final inv in list) {
      final quote = inv.id != null ? _quotes[inv.id] : null;
      if (quote != null && quote.currentValue != null) {
        sum += quote.currentValue!;
        hasValuation = true;
      } else if (inv.currentValue != null) {
        sum += inv.currentValue!;
        hasValuation = true;
      } else {
        sum += inv.totalInvested;
      }
    }

    return hasValuation ? sum : null;
  }

  double? get _marketUnrealizedGainLoss {
    final val = _marketCurrentValue;
    if (val == null || _marketTotalInvested <= 0) return null;
    return val - _marketTotalInvested;
  }

  double? get _marketUnrealizedGainLossPercent {
    final gl = _marketUnrealizedGainLoss;
    if (gl == null || _marketTotalInvested <= 0) return null;
    return (gl / _marketTotalInvested) * 100;
  }

  String _currencyPrefix(String curr) {
    switch (curr.toUpperCase()) {
      case 'INR':
        return '₹';
      case 'EUR':
        return '€';
      case 'GBP':
        return '£';
      case 'SGD':
        return 'S\$';
      case 'AED':
        return 'AED ';
      case 'USD':
      default:
        return '\$';
    }
  }

  String _formatCurrency(double amount) {
    if (amount >= 1000000) {
      return '\$${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return '\$${(amount / 1000).toStringAsFixed(1)}k';
    }
    return '\$${amount.toStringAsFixed(0)}';
  }

  String _formatAmount(double amount, String currency, {bool showSign = false, int decimals = 2}) {
    final prefix = _currencyPrefix(currency);
    final sign = showSign && amount > 0 ? '+' : (amount < 0 ? '-' : '');
    final absVal = amount.abs().toStringAsFixed(decimals);
    return '$sign$prefix$absVal';
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
          heroTag: 'treasury_fab_empty',
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
        heroTag: 'treasury_fab',
        onPressed: _openAddInvestment,
        backgroundColor: theme.colorScheme.primary,
        tooltip: 'Add Investment',
        child: const Icon(Icons.add),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _loadTreasuryData();
          await _fetchQuotesForMarketInvestments(forceRefresh: true);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Overall Total Treasury Holdings Card
              StatsCard(
                title: 'Total Treasury Holdings',
                value: _formatCurrency(_totalInvested),
                trend: _weightedYield > 0
                    ? '+${_weightedYield.toStringAsFixed(2)}% APY Avg'
                    : '${_investments.length} Active Holdings',
                isPositive: true,
                isHighlighted: true,
              ),
              const SizedBox(height: 16),

              // 2. Market Portfolio Summary Card (if market-priced assets exist)
              if (_companyCurrencyMarketInvestments.isNotEmpty) ...[
                _buildMarketValuationCard(theme),
                const SizedBox(height: 16),
              ],

              // 3. Portfolio Allocation Card
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

              // 4. Holdings Section
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
                    return _buildHoldingItem(context, inv, theme);
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

  // ---------------------------------------------------------------------------
  // Market Portfolio Summary Card Widget
  // ---------------------------------------------------------------------------
  Widget _buildMarketValuationCard(ThemeData theme) {
    final currentValue = _marketCurrentValue ?? _marketTotalInvested;
    final totalInvested = _marketTotalInvested;
    final gainLoss = _marketUnrealizedGainLoss ?? 0.0;
    final gainLossPercent = _marketUnrealizedGainLossPercent ?? 0.0;
    final isGain = gainLoss >= 0;
    final gainColor = isGain ? Colors.green.shade700 : Colors.red.shade700;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.show_chart, color: theme.colorScheme.primary, size: 22),
                    const SizedBox(width: 8),
                    Text(
                      'Market Assets Valuation',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '15m delay',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Current Market Value',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatAmount(currentValue, _companyCurrency),
                      style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Unrealized P/L',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isGain ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                          color: gainColor,
                          size: 24,
                        ),
                        Text(
                          '${_formatAmount(gainLoss, _companyCurrency, showSign: true)} (${gainLossPercent.toStringAsFixed(2)}%)',
                          style: TextStyle(
                            color: gainColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),

            Divider(color: theme.dividerColor.withValues(alpha: 0.4)),
            const SizedBox(height: 6),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Cost Basis: ${_formatAmount(totalInvested, _companyCurrency)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
                Text(
                  '${_companyCurrencyMarketInvestments.length} market holdings ($_companyCurrency)',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),

            if (_foreignCurrencyMarketInvestments.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                '* ${_foreignCurrencyMarketInvestments.length} foreign-currency holding(s) listed below are excluded from aggregate totals to avoid currency conversion distortion.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.orange.shade800,
                  fontSize: 11,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Individual Holding Item (Market vs Non-Market)
  // ---------------------------------------------------------------------------
  Widget _buildHoldingItem(BuildContext context, TreasuryInvestment inv, ThemeData theme) {
    if (!inv.assetType.isMarketPriced) {
      // Non-market investment (BOND, FIXED_DEPOSIT, CASH)
      return _buildNonMarketHolding(context, inv, theme);
    }
    // Market-priced investment (STOCK, ETF, CRYPTO, MUTUAL_FUND)
    return _buildMarketHolding(context, inv, theme);
  }

  Widget _buildNonMarketHolding(BuildContext context, TreasuryInvestment inv, ThemeData theme) {
    final yieldText = inv.interestRate != null
        ? '${(inv.interestRate! * 100).toStringAsFixed(2)}% APY'
        : inv.assetType.displayName;
    final notesText = inv.notes != null && inv.notes!.isNotEmpty ? ' • ${inv.notes}' : '';

    return ListTile(
      onTap: () => _openEditInvestment(inv),
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
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _formatAmount(inv.totalInvested, inv.currency.value),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          const SizedBox(width: 8),
          Icon(Icons.chevron_right, size: 18, color: theme.colorScheme.onSurface.withValues(alpha: 0.4)),
        ],
      ),
    );
  }

  Widget _buildMarketHolding(BuildContext context, TreasuryInvestment inv, ThemeData theme) {
    final quote = inv.id != null ? _quotes[inv.id] : null;
    final isLoading = inv.id != null && _quoteLoading[inv.id] == true;
    final errorMessage = inv.id != null ? _quoteErrors[inv.id] : null;
    final ticker = inv.ticker ?? '';
    final units = inv.units;
    final currency = inv.currency.value;

    // Check currency mismatch between quote and investment
    final hasCurrencyMismatch = quote != null &&
        quote.currency.toUpperCase() != currency.toUpperCase();

    // Calculate valuation and unrealized gain/loss
    double? currentValue;
    double? gainLoss;
    double? gainLossPercent;

    if (quote != null && !hasCurrencyMismatch && units != null && units > 0) {
      currentValue = quote.currentValue ?? (quote.price * units);
      if (inv.totalInvested > 0) {
        gainLoss = currentValue - inv.totalInvested;
        gainLossPercent = (gainLoss / inv.totalInvested) * 100;
      }
    } else if (inv.currentValue != null && inv.totalInvested > 0) {
      currentValue = inv.currentValue;
      gainLoss = inv.currentValue! - inv.totalInvested;
      gainLossPercent = (gainLoss / inv.totalInvested) * 100;
    }

    final isGain = (gainLoss ?? 0.0) >= 0;
    final gainColor = isGain ? Colors.green.shade700 : Colors.red.shade700;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row: Icon, Name, Ticker pill, Refresh Button, Edit Chevron
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: inv.assetType.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(inv.assetType.icon, color: inv.assetType.color, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            inv.name,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (ticker.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              ticker,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    // Quantity and Purchase price
                    Text(
                      units != null
                          ? '$units units @ ${_formatAmount(inv.purchasePrice, currency)} • Cost: ${_formatAmount(inv.totalInvested, currency)}'
                          : 'Cost: ${_formatAmount(inv.totalInvested, currency)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),

              // Action buttons: Refresh quote + Edit holding
              if (isLoading)
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: Padding(
                    padding: EdgeInsets.all(4.0),
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              else if (inv.id != null && ticker.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.refresh, size: 18),
                  tooltip: 'Refresh quote',
                  visualDensity: VisualDensity.compact,
                  onPressed: () => _fetchQuoteForInvestment(inv.id!, forceRefresh: true),
                ),
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 18),
                tooltip: 'Edit holding',
                visualDensity: VisualDensity.compact,
                onPressed: () => _openEditInvestment(inv),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Market Quote Status & Valuation Row
          if (ticker.isEmpty) ...[
            Padding(
              padding: const EdgeInsets.only(left: 46.0),
              child: Text(
                'Missing ticker symbol. Edit investment to enable live quotes.',
                style: TextStyle(color: Colors.orange.shade800, fontSize: 12),
              ),
            ),
          ] else if (units == null || units <= 0) ...[
            Padding(
              padding: const EdgeInsets.only(left: 46.0),
              child: Text(
                quote != null
                    ? 'Market Price: ${_formatAmount(quote.price, quote.currency)} (Quantity missing for valuation)'
                    : 'Quantity missing. Edit investment to enable valuation.',
                style: TextStyle(color: Colors.orange.shade800, fontSize: 12),
              ),
            ),
          ] else if (isLoading && quote == null) ...[
            Padding(
              padding: const EdgeInsets.only(left: 46.0, top: 4.0),
              child: Row(
                children: [
                  const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 1.5)),
                  const SizedBox(width: 8),
                  Text(
                    'Fetching market quote for $ticker...',
                    style: theme.textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            ),
          ] else if (errorMessage != null) ...[
            Padding(
              padding: const EdgeInsets.only(left: 46.0),
              child: Row(
                children: [
                  Icon(Icons.error_outline, size: 14, color: theme.colorScheme.error),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      errorMessage,
                      style: TextStyle(color: theme.colorScheme.error, fontSize: 12),
                    ),
                  ),
                  TextButton(
                    onPressed: () => _fetchQuoteForInvestment(inv.id!, forceRefresh: true),
                    style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                    child: const Text('Retry', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            ),
          ] else if (hasCurrencyMismatch) ...[
            Padding(
              padding: const EdgeInsets.only(left: 46.0),
              child: Text(
                'Currency mismatch: Quote is in ${quote.currency}, but holding is in $currency.',
                style: TextStyle(color: theme.colorScheme.error, fontSize: 12),
              ),
            ),
          ] else if (quote != null || currentValue != null) ...[
            Padding(
              padding: const EdgeInsets.only(left: 46.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      // Market Price & Current Value
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 4,
                        children: [
                          if (quote != null) ...[
                            Text(
                              'Market: ${_formatAmount(quote.price, quote.currency)}',
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                            ),
                            const Text('•'),
                          ],
                          if (currentValue != null)
                            Text(
                              'Value: ${_formatAmount(currentValue, currency)}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                        ],
                      ),

                      // Unrealized P/L chip
                      if (gainLoss != null && gainLossPercent != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: gainColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isGain ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                                color: gainColor,
                                size: 18,
                              ),
                              Text(
                                '${_formatAmount(gainLoss, currency, showSign: true)} (${gainLossPercent.toStringAsFixed(2)}%)',
                                style: TextStyle(
                                  color: gainColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  // Cache / Freshness Pill
                  if (quote != null) ...[
                    Row(
                      children: [
                        if (quote.isStale) ...[
                          Icon(Icons.warning_amber_rounded, size: 12, color: Colors.orange.shade800),
                          const SizedBox(width: 4),
                          Text(
                            'Stale Quote (Provider Error)',
                            style: TextStyle(color: Colors.orange.shade800, fontSize: 11),
                          ),
                        ] else ...[
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: quote.cached ? Colors.blue.shade600 : Colors.green.shade600,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            quote.cached
                                ? 'Cached (${quote.ageSeconds}s ago • 15m delay)'
                                : 'Updated (${quote.ageSeconds}s ago • 15m delay)',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontSize: 11,
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
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
              'Manage your idle cash, track yields from Bonds, and monitor market-priced assets like Stocks and ETFs.',
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
