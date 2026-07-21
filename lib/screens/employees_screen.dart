import 'package:flutter/material.dart';
import '../widgets/stats_card.dart';

import '../features/onboarding/data/repositories/onboarding_repository.dart';

class EmployeesScreen extends StatelessWidget {
  const EmployeesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final repo = OnboardingRepository();
    final hasEmployees = repo.hasEmployees;
    
    if (!hasEmployees) {
      return _buildEmptyState(context);
    }

    final teamSize = repo.currentData?.team?.teamSize ?? 12;
    final payroll = repo.currentData?.financials?.payroll ?? 52000;
    final avgSalary = teamSize > 0 ? (payroll * 12 / teamSize).round() : 0;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          StatsCard(
            title: 'Monthly Payroll',
            value: '\$${payroll.toStringAsFixed(0)}',
            trend: 'Current burn',
            isPositive: false,
            isHighlighted: true,
          ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.5,
            children: [
              StatsCard(title: 'Headcount', value: teamSize.toString()),
              StatsCard(title: 'Avg. Salary', value: '\$${(avgSalary / 1000).toStringAsFixed(0)}k/yr'),
            ],
          ),
          const SizedBox(height: 24),
          Text('Directory', style: theme.textTheme.titleLarge),
          const SizedBox(height: 12),
          Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                _buildEmployeeTile(context, 'Sarah Jenkins', 'CTO • Engineering', '\$120k'),
                const Divider(height: 1),
                _buildEmployeeTile(context, 'David Chen', 'Sr. Engineer • Engineering', '\$95k'),
                const Divider(height: 1),
                _buildEmployeeTile(context, 'Elena Rodriguez', 'Marketing Lead • Growth', '\$85k'),
              ],
            ),
          ),
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
            Icon(Icons.people_outline, size: 80, color: theme.colorScheme.primary.withValues(alpha: 0.5)),
            const SizedBox(height: 24),
            Text('No Employees Yet', style: theme.textTheme.headlineSmall),
            const SizedBox(height: 16),
            Text(
              'Add your team members to track payroll and calculate runway impacts.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.add),
              label: const Text('Add Employee'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmployeeTile(BuildContext context, String name, String role, String salary) {
    final theme = Theme.of(context);
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: theme.colorScheme.primary.withValues(alpha:0.1),
        child: Text(name[0], style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold)),
      ),
      title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(role),
      trailing: Text(salary, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
    );
  }
}
