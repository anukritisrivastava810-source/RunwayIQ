import 'package:flutter/material.dart';
import '../../domain/models/onboarding_models.dart';
import '../../../../../widgets/custom_button.dart';

class CompanyInfoStep extends StatefulWidget {
  final OnboardingData data;
  final VoidCallback onNext;

  const CompanyInfoStep({
    super.key,
    required this.data,
    required this.onNext,
  });

  @override
  State<CompanyInfoStep> createState() => _CompanyInfoStepState();
}

class _CompanyInfoStepState extends State<CompanyInfoStep> {
  final _formKey = GlobalKey<FormState>();
  
  late String _name;
  late String _industry;
  late String _stage;
  late String _country;

  @override
  void initState() {
    super.initState();
    _name = widget.data.company?.name ?? '';
    _industry = widget.data.company?.industry ?? 'SaaS';
    _stage = widget.data.company?.stage ?? 'Seed';
    _country = widget.data.company?.country ?? 'United States';
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      
      widget.data.company = CompanyDetails(
        name: _name,
        industry: _industry,
        stage: _stage,
        country: _country,
        currency: 'USD',
        foundedDate: DateTime.now(),
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
              'Company Information',
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Tell us about your startup.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 32),
            
            TextFormField(
              initialValue: _name,
              decoration: const InputDecoration(
                labelText: 'Company Name',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.business),
              ),
              validator: (value) => value == null || value.isEmpty ? 'Required' : null,
              onSaved: (value) => _name = value!,
            ),
            const SizedBox(height: 16),
            
            DropdownButtonFormField<String>(
              initialValue: _industry,
              decoration: const InputDecoration(
                labelText: 'Industry',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.category),
              ),
              items: ['SaaS', 'Fintech', 'Healthtech', 'Edtech', 'E-commerce', 'Other']
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (value) {
                if (value != null) setState(() => _industry = value);
              },
            ),
            const SizedBox(height: 16),
            
            DropdownButtonFormField<String>(
              initialValue: _stage,
              decoration: const InputDecoration(
                labelText: 'Startup Stage',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.trending_up),
              ),
              items: ['Pre-seed', 'Seed', 'Series A', 'Series B', 'Series C+', 'Bootstrapped']
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (value) {
                if (value != null) setState(() => _stage = value);
              },
            ),
            const SizedBox(height: 16),
            
            DropdownButtonFormField<String>(
              initialValue: _country,
              decoration: const InputDecoration(
                labelText: 'Country',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.public),
              ),
              items: ['United States', 'United Kingdom', 'Canada', 'Australia', 'India', 'Other']
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (value) {
                if (value != null) setState(() => _country = value);
              },
            ),
            
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
