import 'package:flutter/material.dart';

import '../features/onboarding/data/repositories/onboarding_repository.dart';

class ExpensesScreen extends StatelessWidget {
  const ExpensesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final repo = OnboardingRepository();
    final hasExpenses = repo.hasExpenses;
    
    if (!hasExpenses) {
      return _buildEmptyState(context);
    }
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Chart Placeholder
          Card(
            child: Container(
              height: 200,
              padding: const EdgeInsets.all(16),
              child: Center(
                child: Text(
                  '[ Expense Bar Chart Placeholder ]',
                  style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.primary),
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          Text('Breakdown (excluding payroll)', style: theme.textTheme.titleLarge),
          const SizedBox(height: 12),
          
          Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                _buildExpenseTile(context, 'Total Monthly Expenses', 'Calculated from Onboarding', '\$${repo.currentData?.financials?.monthlyExpenses ?? 0}', Icons.account_balance, Colors.blue),
                const Divider(height: 1),
                _buildExpenseTile(context, 'Cloud Services', 'AWS, Vercel', '\$12,500', Icons.cloud, Colors.blue),
                const Divider(height: 1),
                _buildExpenseTile(context, 'Marketing', 'Meta Ads, Google', '\$8,200', Icons.campaign, Colors.orange),
                const Divider(height: 1),
                _buildExpenseTile(context, 'Office Rent', 'WeWork', '\$5,000', Icons.business, Colors.purple),
                const Divider(height: 1),
                _buildExpenseTile(context, 'Software Licenses', 'Github, Linear, Figma', '\$1,800', Icons.code, Colors.teal),
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
            Icon(Icons.receipt_long_outlined, size: 80, color: theme.colorScheme.primary.withValues(alpha: 0.5)),
            const SizedBox(height: 24),
            Text('No Expenses Yet', style: theme.textTheme.headlineSmall),
            const SizedBox(height: 16),
            Text(
              'Track your recurring software, rent, and operational expenses.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.add),
              label: const Text('Add Expense'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpenseTile(BuildContext context, String category, String details, String amount, IconData icon, Color color) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color.withValues(alpha:0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color),
      ),
      title: Text(category, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(details),
      trailing: Text(amount, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
    );
  }
}
