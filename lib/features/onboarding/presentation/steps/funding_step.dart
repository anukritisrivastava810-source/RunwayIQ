import 'package:flutter/material.dart';
import '../../domain/models/onboarding_models.dart';
import '../../../../../widgets/custom_button.dart';
import 'package:runway_iq/features/company/data/repositories/company_repository.dart';
import 'package:runway_iq/features/investor/data/repositories/investor_repository.dart';
import 'package:runway_iq/features/investor/domain/models/investor.dart';
import 'package:runway_iq/features/funding/data/repositories/funding_round_repository.dart';
import 'package:runway_iq/features/funding/domain/models/funding_round.dart';
import 'package:runway_iq/core/network/api_exceptions.dart';

class FundingStep extends StatefulWidget {
  final OnboardingData? data;
  final VoidCallback? onNext;
  final String? companyId;
  final String? companyCurrency;

  const FundingStep({
    super.key,
    this.data,
    this.onNext,
    this.companyId,
    this.companyCurrency,
  });

  bool get isStandalone => companyId != null || data == null;

  @override
  State<FundingStep> createState() => _FundingStepState();
}

class _FundingStepState extends State<FundingStep> {
  final _formKey = GlobalKey<FormState>();

  bool _hasRaised = false;
  String _round = 'Seed';
  String _investorName = '';
  double _amount = 0.0;
  double _equityPercentage = 0.0;
  String _currency = 'USD';
  DateTime _closedAt = DateTime.now();
  String _notes = '';
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.isStandalone) {
      _hasRaised = true;
      _currency = widget.companyCurrency ?? 'USD';
    } else if (widget.data?.funding != null) {
      _hasRaised = widget.data!.funding!.hasRaised;
      _round = widget.data!.funding!.round ?? 'Seed';
      _investorName = widget.data!.funding!.investorName ?? '';
      _amount = widget.data!.funding!.amount ?? 0.0;
      _equityPercentage = widget.data!.funding!.equityPercentage ?? 0.0;
      if (widget.data!.funding!.investmentDate != null) {
        _closedAt = widget.data!.funding!.investmentDate!;
      }
      if (widget.data!.company?.currency != null) {
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

  Future<void> _submit() async {
    if (_isSubmitting) return;

    if (!widget.isStandalone) {
      if (!_hasRaised) {
        widget.data?.funding = FundingDetails(hasRaised: false);
        widget.onNext?.call();
        return;
      }

      if (_formKey.currentState!.validate()) {
        _formKey.currentState!.save();

        widget.data?.funding = FundingDetails(
          hasRaised: true,
          round: _round,
          investorName: _investorName,
          amount: _amount,
          equityPercentage: _equityPercentage,
          investmentDate: _closedAt,
        );

        widget.onNext?.call();
      }
      return;
    }

    // Standalone flow: Persist directly to backend / PostgreSQL
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

      // 2. Resolve or create Investor record
      final investorRepo = InvestorRepository();
      final existingInvestors = await investorRepo.getInvestorsByCompany(activeCompanyId);

      String? investorId;
      final trimmedName = _investorName.trim();
      for (final inv in existingInvestors) {
        if (inv.name.trim().toLowerCase() == trimmedName.toLowerCase()) {
          investorId = inv.id;
          break;
        }
      }

      if (investorId == null || investorId.isEmpty) {
        final newInvestor = await investorRepo.createInvestor(
          Investor(
            companyId: activeCompanyId,
            name: trimmedName.isNotEmpty ? trimmedName : 'Lead Investor',
          ),
        );
        investorId = newInvestor.id;
      }

      if (investorId == null || investorId.isEmpty) {
        throw UnknownException('Failed to resolve or register investor.');
      }

      // 3. Create FundingRound
      final fundingRoundRepo = FundingRoundRepository();
      final newFundingRound = FundingRound(
        companyId: activeCompanyId,
        investorId: investorId,
        roundType: FundingRoundType.fromDisplayName(_round),
        amountRaised: _amount,
        currency: FundingCurrency.fromJson(_currency),
        equityPercent: _equityPercentage > 0
            ? (_equityPercentage > 1 ? _equityPercentage / 100 : _equityPercentage)
            : null,
        closedAt: _closedAt,
        notes: _notes.trim().isNotEmpty ? _notes.trim() : null,
      );

      await fundingRoundRepo.createFundingRound(newFundingRound);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Funding round created successfully!')),
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

  Future<void> _pickClosingDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _closedAt,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _closedAt = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final formContent = SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!widget.isStandalone) ...[
              Text(
                'Funding',
                style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Have you raised any external funding?',
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
                selected: {_hasRaised},
                onSelectionChanged: (Set<bool> newSelection) {
                  setState(() {
                    _hasRaised = newSelection.first;
                  });
                },
              ),
            ],

            if (_hasRaised) ...[
              if (!widget.isStandalone) const SizedBox(height: 32),
              DropdownButtonFormField<String>(
                initialValue: _round,
                decoration: const InputDecoration(
                  labelText: 'Round',
                  border: OutlineInputBorder(),
                ),
                items: [
                  'Pre-seed',
                  'Seed',
                  'Series A',
                  'Series B',
                  'Series C+',
                  'Bridge',
                  'Debt',
                  'Grant',
                  'IPO',
                ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                onChanged: (value) {
                  if (value != null) setState(() => _round = value);
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                initialValue: _investorName,
                decoration: const InputDecoration(
                  labelText: 'Lead Investor Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value == null || value.trim().isEmpty ? 'Investor name is required' : null,
                onSaved: (value) => _investorName = value ?? '',
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
                        labelText: 'Investment Amount',
                        border: const OutlineInputBorder(),
                        prefixText: _currencyPrefix(_currency),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) return 'Amount is required';
                        final parsed = double.tryParse(value);
                        if (parsed == null || parsed <= 0) return 'Enter a valid amount';
                        return null;
                      },
                      onSaved: (value) => _amount = double.parse(value!),
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
                initialValue: _equityPercentage > 0 ? _equityPercentage.toString() : '',
                decoration: const InputDecoration(
                  labelText: 'Equity Percentage (optional)',
                  border: OutlineInputBorder(),
                  suffixText: '%',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value != null && value.trim().isNotEmpty) {
                    final parsed = double.tryParse(value);
                    if (parsed == null || parsed < 0 || parsed > 100) {
                      return 'Enter 0 - 100%';
                    }
                  }
                  return null;
                },
                onSaved: (value) =>
                    _equityPercentage = (value != null && value.isNotEmpty) ? double.parse(value) : 0.0,
              ),
              const SizedBox(height: 16),

              InkWell(
                onTap: _pickClosingDate,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Closing Date',
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.calendar_today, size: 20),
                  ),
                  child: Text(
                    '${_closedAt.year}-${_closedAt.month.toString().padLeft(2, '0')}-${_closedAt.day.toString().padLeft(2, '0')}',
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              ),

              if (widget.isStandalone) ...[
                const SizedBox(height: 16),
                TextFormField(
                  initialValue: _notes,
                  decoration: const InputDecoration(
                    labelText: 'Notes (optional)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                  onSaved: (value) => _notes = value ?? '',
                ),
              ],
            ],

            const SizedBox(height: 48),
            CustomButton(
              text: widget.isStandalone ? 'Add Funding Round' : 'Continue',
              isLoading: _isSubmitting,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );

    if (widget.isStandalone) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Add Funding Round'),
        ),
        body: formContent,
      );
    }

    return formContent;
  }
}

