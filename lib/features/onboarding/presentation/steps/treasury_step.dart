import 'package:flutter/material.dart';
import '../../domain/models/onboarding_models.dart';
import '../../../../../widgets/custom_button.dart';

class TreasuryStep extends StatefulWidget {
  final OnboardingData data;
  final VoidCallback onNext;

  const TreasuryStep({
    super.key,
    required this.data,
    required this.onNext,
  });

  @override
  State<TreasuryStep> createState() => _TreasuryStepState();
}

class _TreasuryStepState extends State<TreasuryStep> {
  bool _hasInvestments = false;
  final Set<String> _investmentTypes = {};

  @override
  void initState() {
    super.initState();
    if (widget.data.treasury != null) {
      _hasInvestments = widget.data.treasury!.hasInvestments;
      _investmentTypes.addAll(widget.data.treasury!.investmentTypes);
    }
  }

  void _submit() {
    widget.data.treasury = TreasuryDetails(
      hasInvestments: _hasInvestments,
      investmentTypes: _hasInvestments ? _investmentTypes.toList() : [],
    );
    widget.onNext();
  }

  @override
  Widget build(BuildContext context) {
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
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}
