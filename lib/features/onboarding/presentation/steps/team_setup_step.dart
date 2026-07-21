import 'package:flutter/material.dart';
import '../../domain/models/onboarding_models.dart';
import '../../../../../widgets/custom_button.dart';

class TeamSetupStep extends StatefulWidget {
  final OnboardingData data;
  final VoidCallback onNext;

  const TeamSetupStep({
    super.key,
    required this.data,
    required this.onNext,
  });

  @override
  State<TeamSetupStep> createState() => _TeamSetupStepState();
}

class _TeamSetupStepState extends State<TeamSetupStep> {
  int _teamSize = 1;
  final Set<String> _departments = {'Engineering', 'Founders'};

  @override
  void initState() {
    super.initState();
    if (widget.data.team != null) {
      _teamSize = widget.data.team!.teamSize;
      _departments.clear();
      _departments.addAll(widget.data.team!.departments);
    }
  }

  void _submit() {
    widget.data.team = TeamSetup(
      teamSize: _teamSize,
      departments: _departments.toList(),
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
            'Team Setup',
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'How big is your current team?',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 32),
          
          Text(
            'Team Size: $_teamSize',
            style: theme.textTheme.titleMedium,
          ),
          Slider(
            value: _teamSize.toDouble(),
            min: 1,
            max: 100,
            divisions: 99,
            activeColor: theme.colorScheme.primary,
            label: _teamSize.toString(),
            onChanged: (value) {
              setState(() {
                _teamSize = value.toInt();
              });
            },
          ),
          
          const SizedBox(height: 32),
          Text(
            'Departments',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          
          Wrap(
            spacing: 8.0,
            runSpacing: 8.0,
            children: [
              'Founders',
              'Engineering',
              'Product',
              'Design',
              'Marketing',
              'Sales',
              'HR',
              'Operations'
            ].map((dept) {
              final isSelected = _departments.contains(dept);
              return FilterChip(
                label: Text(dept),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _departments.add(dept);
                    } else {
                      _departments.remove(dept);
                    }
                  });
                },
                selectedColor: theme.colorScheme.primary.withValues(alpha: 0.2),
                checkmarkColor: theme.colorScheme.primary,
              );
            }).toList(),
          ),
          
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
