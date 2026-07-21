import 'package:flutter/material.dart';
import '../widgets/stats_card.dart';

import '../features/onboarding/data/repositories/onboarding_repository.dart';

class TreasuryScreen extends StatelessWidget {
  const TreasuryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final repo = OnboardingRepository();
    final hasTreasury = repo.hasTreasury;
    
    if (!hasTreasury) {
      return _buildEmptyState(context);
    }
    
    final types = repo.currentData?.treasury?.investmentTypes ?? [];
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const StatsCard(
            title: 'Total Yield YTD',
            value: '+\$42,500',
            trend: '4.2% APY Average',
            isPositive: true,
            isHighlighted: true,
          ),
          const SizedBox(height: 24),
          
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Portfolio Allocation', style: theme.textTheme.titleLarge),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      // Doughnut placeholder
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: theme.colorScheme.primary, width: 20),
                        ),
                        child: Center(
                          child: Text('100%', style: theme.textTheme.titleMedium),
                        ),
                      ),
                      const SizedBox(width: 32),
                      Expanded(
                        child: Column(
                          children: [
                            if (types.isNotEmpty) ...types.map((t) => Padding(
                              padding: const EdgeInsets.only(bottom: 12.0),
                              child: _buildLegend(theme, t, '${(100/types.length).round()}%', Colors.blue),
                            )),
                            if (types.isEmpty) ...[
                              _buildLegend(theme, 'Cash (Checking)', '20%', theme.colorScheme.primary),
                              const SizedBox(height: 12),
                              _buildLegend(theme, 'US Treasuries', '50%', Colors.blue),
                              const SizedBox(height: 12),
                              _buildLegend(theme, 'Fixed Deposits', '30%', Colors.orange),
                            ]
                          ],
                        ),
                      )
                    ],
                  ),
                ],
              ),
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
            Icon(Icons.show_chart, size: 80, color: theme.colorScheme.primary.withValues(alpha: 0.5)),
            const SizedBox(height: 24),
            Text('No Treasury Investments', style: theme.textTheme.headlineSmall),
            const SizedBox(height: 16),
            Text(
              'Manage your idle cash and track yields from investments like Bonds and Fixed Deposits.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.add),
              label: const Text('Add Investment'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegend(ThemeData theme, String label, String percentage, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
            const SizedBox(width: 8),
            Text(label, style: theme.textTheme.bodyMedium),
          ],
        ),
        Text(percentage, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }
}
