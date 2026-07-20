import 'package:flutter/material.dart';
import '../widgets/stats_card.dart';
import '../widgets/dashboard_card.dart';
import 'ai_advisor_screen.dart';
import 'runway_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // AI Insight Card
          DashboardCard(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AiAdvisorScreen()),
              );
            },
            child: Row(
              children: [
                Icon(Icons.auto_awesome, color: theme.colorScheme.primary),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AI Insight',
                        style: theme.textTheme.titleSmall?.copyWith(color: theme.colorScheme.primary),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'At your current burn rate, you have 14 months of runway remaining.',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios, size: 16, color: theme.colorScheme.primary),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Metrics Grid
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.5,
            children: [
              const StatsCard(
                title: 'Available Cash',
                value: '\$1.2M',
                trend: '-\$85k',
                isPositive: false,
              ),
              GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const RunwayScreen()),
                  );
                },
                child: const StatsCard(
                  title: 'Runway',
                  value: '14 mo',
                  trend: '+2 mo',
                  isPositive: true,
                  isHighlighted: true, 
                ),
              ),
              const StatsCard(
                title: 'Monthly Burn',
                value: '\$85k',
                trend: '+5%',
                isPositive: false,
              ),
              const StatsCard(
                title: 'Total Raised',
                value: '\$3.5M',
                trend: 'Seed Round',
                isPositive: true,
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Chart Placeholder
          Text('Burn Rate Trend', style: theme.textTheme.titleLarge),
          const SizedBox(height: 12),
          DashboardCard(
            padding: const EdgeInsets.all(0),
            child: Container(
              height: 200,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    theme.colorScheme.primary.withValues(alpha: 0.2),
                    theme.colorScheme.primary.withValues(alpha: 0.0),
                  ],
                ),
              ),
              child: Center(
                child: Text(
                  '[ Line Chart Placeholder ]',
                  style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.primary),
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Recent Activity
          Text('Recent Activity', style: theme.textTheme.titleLarge),
          const SizedBox(height: 12),
          DashboardCard(
            padding: EdgeInsets.zero,
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 3,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: theme.colorScheme.surface,
                    child: Icon(
                      index == 0 ? Icons.arrow_downward : Icons.arrow_upward,
                      color: index == 0 ? theme.colorScheme.error : theme.colorScheme.primary,
                      size: 20,
                    ),
                  ),
                  title: Text(['AWS Web Services', 'Subscription Revenue', 'Stripe Payout'][index]),
                  subtitle: Text(['Oct 14', 'Oct 12', 'Oct 10'][index]),
                  trailing: Text(
                    ['-\$2,400', '+\$14,500', '+\$12,000'][index],
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: index == 0 ? theme.colorScheme.error : theme.colorScheme.primary,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
