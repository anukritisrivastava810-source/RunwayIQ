import 'package:flutter/material.dart';
import '../../domain/models/onboarding_models.dart';
import '../../../../../widgets/custom_button.dart';

class FinancialSetupStep extends StatefulWidget {
  final OnboardingData data;
  final VoidCallback onNext;

  const FinancialSetupStep({
    super.key,
    required this.data,
    required this.onNext,
  });

  @override
  State<FinancialSetupStep> createState() => _FinancialSetupStepState();
}

class _FinancialSetupStepState extends State<FinancialSetupStep> {
  final _formKey = GlobalKey<FormState>();
  
  late double _currentCash;
  late double _monthlyRevenue;
  late double _monthlyExpenses;
  late double _payroll;

  @override
  void initState() {
    super.initState();
    _currentCash = widget.data.financials?.currentCash ?? 0.0;
    _monthlyRevenue = widget.data.financials?.monthlyRevenue ?? 0.0;
    _monthlyExpenses = widget.data.financials?.monthlyExpenses ?? 0.0;
    _payroll = widget.data.financials?.payroll ?? 0.0;
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      
      widget.data.financials = FinancialSetup(
        currentCash: _currentCash,
        monthlyRevenue: _monthlyRevenue,
        monthlyExpenses: _monthlyExpenses,
        payroll: _payroll,
        burnFrequency: 'Monthly',
        currency: 'USD',
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
              'Financial Setup',
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Enter your current financial numbers to calculate runway.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 32),
            
            _buildNumberField('Current Cash in Bank', (v) => _currentCash = v, _currentCash),
            const SizedBox(height: 16),
            _buildNumberField('Monthly Revenue (MRR)', (v) => _monthlyRevenue = v, _monthlyRevenue),
            const SizedBox(height: 16),
            _buildNumberField('Total Monthly Expenses', (v) => _monthlyExpenses = v, _monthlyExpenses),
            const SizedBox(height: 16),
            _buildNumberField('Current Monthly Payroll', (v) => _payroll = v, _payroll),
            
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

  Widget _buildNumberField(String label, Function(double) onSaved, double initial) {
    return TextFormField(
      initialValue: initial > 0 ? initial.toString() : '',
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        prefixText: '\$ ',
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      validator: (value) {
        if (value == null || value.isEmpty) return 'Required';
        if (double.tryParse(value) == null) return 'Must be a valid number';
        return null;
      },
      onSaved: (value) => onSaved(double.parse(value!)),
    );
  }
}
