import 'package:flutter/material.dart';
import '../../domain/models/onboarding_models.dart';
import '../../../../../widgets/custom_button.dart';

class FundingStep extends StatefulWidget {
  final OnboardingData data;
  final VoidCallback onNext;

  const FundingStep({
    super.key,
    required this.data,
    required this.onNext,
  });

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

  @override
  void initState() {
    super.initState();
    if (widget.data.funding != null) {
      _hasRaised = widget.data.funding!.hasRaised;
      _round = widget.data.funding!.round ?? 'Seed';
      _investorName = widget.data.funding!.investorName ?? '';
      _amount = widget.data.funding!.amount ?? 0.0;
      _equityPercentage = widget.data.funding!.equityPercentage ?? 0.0;
    }
  }

  void _submit() {
    if (!_hasRaised) {
      widget.data.funding = FundingDetails(hasRaised: false);
      widget.onNext();
      return;
    }

    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      
      widget.data.funding = FundingDetails(
        hasRaised: true,
        round: _round,
        investorName: _investorName,
        amount: _amount,
        equityPercentage: _equityPercentage,
        investmentDate: DateTime.now(),
      );
      
      widget.onNext();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
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
            
            if (_hasRaised) ...[
              const SizedBox(height: 32),
              DropdownButtonFormField<String>(
                initialValue: _round,
                decoration: const InputDecoration(
                  labelText: 'Round',
                  border: OutlineInputBorder(),
                ),
                items: ['Pre-seed', 'Seed', 'Series A', 'Series B', 'Series C+']
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
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
                validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                onSaved: (value) => _investorName = value!,
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                initialValue: _amount > 0 ? _amount.toString() : '',
                decoration: const InputDecoration(
                  labelText: 'Investment Amount',
                  border: OutlineInputBorder(),
                  prefixText: '\$ ',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Required';
                  if (double.tryParse(value) == null) return 'Invalid number';
                  return null;
                },
                onSaved: (value) => _amount = double.parse(value!),
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                initialValue: _equityPercentage > 0 ? _equityPercentage.toString() : '',
                decoration: const InputDecoration(
                  labelText: 'Equity Percentage',
                  border: OutlineInputBorder(),
                  suffixText: '%',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Required';
                  if (double.tryParse(value) == null) return 'Invalid number';
                  return null;
                },
                onSaved: (value) => _equityPercentage = double.parse(value!),
              ),
            ],
            
            const SizedBox(height: 48),
            CustomButton(
              text: 'Continue',
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}
