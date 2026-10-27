import 'package:flutter/material.dart';
import '../../domain/models/onboarding_models.dart';
import 'package:runway_iq/widgets/custom_button.dart';
import 'package:runway_iq/core/network/api_exceptions.dart';
import 'package:runway_iq/features/company/data/repositories/company_repository.dart';
import 'package:runway_iq/features/treasury/data/repositories/treasury_repository.dart';
import 'package:runway_iq/features/treasury/domain/models/treasury_investment.dart';

class TreasuryStep extends StatefulWidget {
  final OnboardingData? data;
  final VoidCallback? onNext;
  final String? companyId;
  final String? companyCurrency;
  final TreasuryInvestment? initialInvestment;

  const TreasuryStep({
    super.key,
    this.data,
    this.onNext,
    this.companyId,
    this.companyCurrency,
    this.initialInvestment,
  });

  bool get isStandalone => companyId != null || data == null || initialInvestment != null;
  bool get isEditing => initialInvestment != null;

  @override
  State<TreasuryStep> createState() => _TreasuryStepState();
}

class _TreasuryStepState extends State<TreasuryStep> {
  // Onboarding mode fields
  bool _hasInvestments = false;
  final Set<String> _investmentTypes = {};

  // Standalone treasury form fields
  final _standaloneFormKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _tickerController = TextEditingController();
  final _unitsController = TextEditingController();
  final _purchasePriceController = TextEditingController();
  final _totalInvestedController = TextEditingController();
  final _interestRateController = TextEditingController();
  final _notesController = TextEditingController();

  AssetType _assetType = AssetType.bond;
  double _totalInvested = 0.0;
  String _currency = 'USD';
  DateTime _investmentDate = DateTime.now();
  DateTime? _maturityDate;
  bool _isSubmitting = false;

  bool get _isMarketPriced =>
      _assetType == AssetType.stock ||
      _assetType == AssetType.etf ||
      _assetType == AssetType.crypto ||
      _assetType == AssetType.mutualFund;

  @override
  void initState() {
    super.initState();

    if (widget.initialInvestment != null) {
      final inv = widget.initialInvestment!;
      _assetType = inv.assetType;
      _currency = inv.currency.value;
      _totalInvested = inv.totalInvested;
      _investmentDate = inv.investmentDate;
      _maturityDate = inv.maturityDate;

      _nameController.text = inv.name;
      _tickerController.text = inv.ticker ?? '';
      _unitsController.text = inv.units != null ? inv.units.toString() : '';
      _purchasePriceController.text = inv.purchasePrice > 0 ? inv.purchasePrice.toString() : '';
      _totalInvestedController.text = inv.totalInvested > 0 ? inv.totalInvested.toStringAsFixed(2) : '';
      _interestRateController.text = inv.interestRate != null ? (inv.interestRate! * 100).toString() : '';
      _notesController.text = inv.notes ?? '';
    } else {
      if (widget.isStandalone) {
        _currency = widget.companyCurrency ?? 'USD';
      } else if (widget.data?.treasury != null) {
        _hasInvestments = widget.data!.treasury!.hasInvestments;
        _investmentTypes.addAll(widget.data!.treasury!.investmentTypes);
        if (widget.data?.company?.currency != null) {
          _currency = widget.data!.company!.currency;
        }
      }
    }

    _unitsController.addListener(_onMarketInputsChanged);
    _purchasePriceController.addListener(_onMarketInputsChanged);
  }

  @override
  void dispose() {
    _unitsController.removeListener(_onMarketInputsChanged);
    _purchasePriceController.removeListener(_onMarketInputsChanged);

    _nameController.dispose();
    _tickerController.dispose();
    _unitsController.dispose();
    _purchasePriceController.dispose();
    _totalInvestedController.dispose();
    _interestRateController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _onMarketInputsChanged() {
    if (!_isMarketPriced) return;
    final units = double.tryParse(_unitsController.text.trim());
    final price = double.tryParse(_purchasePriceController.text.trim());

    if (units != null && units > 0 && price != null && price >= 0) {
      final total = double.parse((units * price).toStringAsFixed(2));
      _totalInvested = total;
      _totalInvestedController.text = total.toStringAsFixed(2);
    } else {
      _totalInvested = 0.0;
      _totalInvestedController.text = '';
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
    widget.data?.treasury = TreasuryDetails(
      hasInvestments: _hasInvestments,
      investmentTypes: _hasInvestments ? _investmentTypes.toList() : [],
    );
    widget.onNext?.call();
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
      String? activeCompanyId = widget.companyId ?? widget.initialInvestment?.companyId;
      if (activeCompanyId == null || activeCompanyId.isEmpty) {
        final companies = await CompanyRepository().getCompanies();
        if (companies.isNotEmpty) {
          activeCompanyId = companies.first.id;
        }
      }

      if (activeCompanyId == null || activeCompanyId.isEmpty) {
        throw UnknownException('Active company not found. Please complete onboarding first.');
      }

      // 2. Prepare investment model
      final units = _isMarketPriced
          ? double.tryParse(_unitsController.text.trim())
          : null;
      final purchasePrice = _isMarketPriced
          ? (double.tryParse(_purchasePriceController.text.trim()) ?? 0.0)
          : (double.tryParse(_totalInvestedController.text.trim()) ?? _totalInvested);
      final totalInvested = _isMarketPriced
          ? _totalInvested
          : (double.tryParse(_totalInvestedController.text.trim()) ?? _totalInvested);

      final interestRateText = _interestRateController.text.trim();
      final parsedInterestRate = (!_isMarketPriced && interestRateText.isNotEmpty)
          ? double.tryParse(interestRateText)
          : null;

      final investment = TreasuryInvestment(
        id: widget.initialInvestment?.id,
        companyId: activeCompanyId,
        assetType: _assetType,
        name: _nameController.text.trim(),
        ticker: _isMarketPriced ? _tickerController.text.trim().toUpperCase() : null,
        units: units,
        purchasePrice: purchasePrice,
        currentPrice: widget.initialInvestment?.currentPrice, // Never populated from purchasePrice!
        totalInvested: totalInvested,
        currentValue: widget.initialInvestment?.currentValue,
        currency: TreasuryCurrency.fromJson(_currency),
        investmentDate: _investmentDate,
        maturityDate: _isMarketPriced ? null : _maturityDate,
        interestRate: parsedInterestRate != null
            ? (parsedInterestRate > 1 ? parsedInterestRate / 100 : parsedInterestRate)
            : null,
        notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
      );

      final treasuryRepo = TreasuryRepository();
      if (widget.isEditing && widget.initialInvestment?.id != null) {
        await treasuryRepo.updateTreasuryInvestment(widget.initialInvestment!.id!, investment);
      } else {
        await treasuryRepo.createTreasuryInvestment(investment);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.isEditing
                  ? 'Treasury investment updated successfully!'
                  : 'Treasury investment added successfully!',
            ),
          ),
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

  Future<void> _pickInvestmentDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _investmentDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _investmentDate = picked;
      });
    }
  }

  Future<void> _pickMaturityDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _maturityDate ?? _investmentDate.add(const Duration(days: 180)),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _maturityDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isStandalone) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.isEditing ? 'Edit Investment' : 'Add Investment'),
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
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Investment Name',
                hintText: 'e.g. Apple Inc, S&P 500 ETF, US Treasury 6M Bill',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.account_balance_outlined),
              ),
              validator: (v) => v == null || v.trim().isEmpty ? 'Name is required' : null,
            ),
            const SizedBox(height: 16),

            DropdownButtonFormField<AssetType>(
              initialValue: _assetType,
              decoration: const InputDecoration(
                labelText: 'Asset Type',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.pie_chart_outline),
              ),
              items: AssetType.values.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Row(
                    children: [
                      Icon(type.icon, size: 18, color: type.color),
                      const SizedBox(width: 8),
                      Text(type.displayName),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    _assetType = val;
                    if (_isMarketPriced) {
                      _onMarketInputsChanged();
                    }
                  });
                }
              },
            ),
            const SizedBox(height: 16),

            // Market-Priced Assets: Ticker, Quantity, Purchase Price
            if (_isMarketPriced) ...[
              TextFormField(
                controller: _tickerController,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  labelText: 'Ticker Symbol',
                  hintText: 'e.g. AAPL, SPY, BTC/USD, MSFT',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.tag),
                  helperText: 'Required for real-time market data quotes',
                ),
                validator: (v) {
                  if (_isMarketPriced) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Ticker symbol is required for market-priced assets';
                    }
                    if (!RegExp(r'^[A-Za-z0-9.\-:/]{1,20}$').hasMatch(v.trim())) {
                      return 'Invalid ticker format (e.g. AAPL, BTC/USD)';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _unitsController,
                      decoration: const InputDecoration(
                        labelText: 'Quantity / Units',
                        hintText: 'e.g. 50',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.format_list_numbered),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (v) {
                        if (_isMarketPriced) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Quantity is required';
                          }
                          final parsed = double.tryParse(v.trim());
                          if (parsed == null || parsed <= 0) {
                            return 'Must be > 0';
                          }
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _purchasePriceController,
                      decoration: InputDecoration(
                        labelText: 'Purchase Price/Unit',
                        hintText: 'e.g. 150.00',
                        border: const OutlineInputBorder(),
                        prefixText: _currencyPrefix(_currency),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (v) {
                        if (_isMarketPriced) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Price is required';
                          }
                          final parsed = double.tryParse(v.trim());
                          if (parsed == null || parsed < 0) {
                            return 'Must be ≥ 0';
                          }
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],

            // Total Invested & Currency Row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: TextFormField(
                    controller: _totalInvestedController,
                    readOnly: _isMarketPriced,
                    decoration: InputDecoration(
                      labelText: 'Total Invested',
                      border: const OutlineInputBorder(),
                      prefixText: _currencyPrefix(_currency),
                      helperText: _isMarketPriced
                          ? 'Calculated: Quantity × Purchase Price'
                          : 'Amount invested in holding',
                      filled: _isMarketPriced,
                      fillColor: _isMarketPriced
                          ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3)
                          : null,
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Amount is required';
                      final parsed = double.tryParse(v.trim());
                      if (parsed == null || parsed <= 0) return 'Enter a valid amount';
                      return null;
                    },
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

            // Yield & Maturity (Non-market assets only)
            if (!_isMarketPriced) ...[
              TextFormField(
                controller: _interestRateController,
                decoration: const InputDecoration(
                  labelText: 'Expected APY / Yield (optional)',
                  hintText: 'e.g. 5.25',
                  border: OutlineInputBorder(),
                  suffixText: '%',
                  prefixIcon: Icon(Icons.percent),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (v) {
                  if (v != null && v.trim().isNotEmpty) {
                    final parsed = double.tryParse(v.trim());
                    if (parsed == null || parsed < 0 || parsed > 100) {
                      return 'Enter 0 - 100%';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: _pickInvestmentDate,
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Investment Date',
                          border: OutlineInputBorder(),
                          suffixIcon: Icon(Icons.calendar_today, size: 18),
                        ),
                        child: Text(
                          '${_investmentDate.year}-${_investmentDate.month.toString().padLeft(2, '0')}-${_investmentDate.day.toString().padLeft(2, '0')}',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      onTap: _pickMaturityDate,
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Maturity (opt)',
                          border: const OutlineInputBorder(),
                          suffixIcon: _maturityDate != null
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 16),
                                  onPressed: () => setState(() => _maturityDate = null),
                                )
                              : const Icon(Icons.event, size: 18),
                        ),
                        child: Text(
                          _maturityDate != null
                              ? '${_maturityDate!.year}-${_maturityDate!.month.toString().padLeft(2, '0')}-${_maturityDate!.day.toString().padLeft(2, '0')}'
                              : 'None',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ] else ...[
              // Market-priced assets only need investment date
              InkWell(
                onTap: _pickInvestmentDate,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Investment Date',
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.calendar_today, size: 18),
                  ),
                  child: Text(
                    '${_investmentDate.year}-${_investmentDate.month.toString().padLeft(2, '0')}-${_investmentDate.day.toString().padLeft(2, '0')}',
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes / Custodian (optional)',
                hintText: 'e.g. Goldman Sachs, Schwab, Robinhood, Zerodha',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 36),

            CustomButton(
              text: widget.isEditing ? 'Save Changes' : 'Add Investment',
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
            'Treasury Management',
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Do you have any treasury investments or idle cash yielding interest?',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 32),

          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: true, label: Text('Yes')),
              ButtonSegment(value: false, label: Text('No')),
            ],
            selected: {_hasInvestments},
            onSelectionChanged: (Set<bool> newSelection) {
              setState(() {
                _hasInvestments = newSelection.first;
              });
            },
          ),

          if (_hasInvestments) ...[
            const SizedBox(height: 32),
            Text(
              'Select Investment Types',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 16),

            Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              children: [
                'Stocks',
                'Mutual Funds',
                'ETF',
                'Fixed Deposit',
                'Cash Reserve',
                'Treasury Bills',
                'Bonds'
              ].map((type) {
                final isSelected = _investmentTypes.contains(type);
                return FilterChip(
                  label: Text(type),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _investmentTypes.add(type);
                      } else {
                        _investmentTypes.remove(type);
                      }
                    });
                  },
                  selectedColor: theme.colorScheme.primary.withValues(alpha: 0.2),
                  checkmarkColor: theme.colorScheme.primary,
                );
              }).toList(),
            ),
          ],

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
