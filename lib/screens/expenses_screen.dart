import 'package:flutter/material.dart';

class ExpensesScreen extends StatelessWidget {
  const ExpensesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
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
