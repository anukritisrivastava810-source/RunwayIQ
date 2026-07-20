import 'package:flutter/material.dart';
import '../widgets/stats_card.dart';

class EmployeesScreen extends StatelessWidget {
  const EmployeesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const StatsCard(
            title: 'Monthly Payroll',
            value: '\$52,000',
            trend: '65% of total burn',
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
            children: const [
              StatsCard(title: 'Headcount', value: '12'),
              StatsCard(title: 'Avg. Salary', value: '\$52k/yr'),
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
