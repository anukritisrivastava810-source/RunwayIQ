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

  const TreasuryStep({
    super.key,
    this.data,
    this.onNext,
    this.companyId,
    this.companyCurrency,
  });

  bool get isStandalone => companyId != null || data == null;

  @override
  State<TreasuryStep> createState() => _TreasuryStepState();
}

class _TreasuryStepState extends State<TreasuryStep> {
  // Onboarding mode fields
  bool _hasInvestments = false;
  final Set<String> _investmentTypes = {};

  // Standalone treasury form fields
  final _standaloneFormKey = GlobalKey<FormState>();
  String _name = '';
  AssetType _assetType = AssetType.bond;
  double _totalInvested = 0.0;
  String _currency = 'USD';
  double _interestRate = 0.0;
  DateTime _investmentDate = DateTime.now();
  DateTime? _maturityDate;
  String _notes = '';
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
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

      // 2. Create TreasuryInvestment via repository
      final treasuryRepo = TreasuryRepository();
      final newInvestment = TreasuryInvestment(
        companyId: activeCompanyId,
        assetType: _assetType,
        name: _name.trim(),
        purchasePrice: _totalInvested,
        totalInvested: _totalInvested,
        currency: TreasuryCurrency.fromJson(_currency),
        investmentDate: _investmentDate,
        maturityDate: _maturityDate,
        interestRate: _interestRate > 0
            ? (_interestRate > 1 ? _interestRate / 100 : _interestRate)
            : null,
        notes: _notes.trim().isNotEmpty ? _notes.trim() : null,
      );

      await treasuryRepo.createTreasuryInvestment(newInvestment);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Treasury investment added successfully!')),
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
          title: const Text('Add Investment'),
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
              initialValue: _name,
              decoration: const InputDecoration(
                labelText: 'Investment Name',
                hintText: 'e.g. US Treasury 6-Month Bills, Fixed Deposit',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.account_balance_outlined),
              ),
              validator: (v) => v == null || v.trim().isEmpty ? 'Name is required' : null,
              onSaved: (v) => _name = v ?? '',
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
                if (val != null) setState(() => _assetType = val);
              },
            ),
            const SizedBox(height: 16),

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: TextFormField(
                    initialValue: _totalInvested > 0 ? _totalInvested.toString() : '',
                    decoration: InputDecoration(
                      labelText: 'Total Invested',
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
                    onSaved: (v) => _totalInvested = double.parse(v!),
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

            TextFormField(
              initialValue: _interestRate > 0 ? _interestRate.toString() : '',
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
                  final parsed = double.tryParse(v);
                  if (parsed == null || parsed < 0 || parsed > 100) {
                    return 'Enter 0 - 100%';
                  }
                }
                return null;
              },
              onSaved: (v) =>
                  _interestRate = (v != null && v.isNotEmpty) ? double.parse(v) : 0.0,
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

            TextFormField(
              initialValue: _notes,
              decoration: const InputDecoration(
                labelText: 'Notes / Custodian (optional)',
                hintText: 'e.g. Goldman Sachs, Schwab, TreasuryDirect',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
              onSaved: (v) => _notes = v ?? '',
            ),
            const SizedBox(height: 40),

            CustomButton(
              text: 'Add Investment',
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
