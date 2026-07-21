import 'package:flutter/material.dart';
import '../widgets/stats_card.dart';

import '../features/onboarding/data/repositories/onboarding_repository.dart';

class FundingScreen extends StatelessWidget {
  const FundingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final repo = OnboardingRepository();
    final hasFunding = repo.hasFunding;

    return Scaffold(
      body: hasFunding ? _buildContent(context, repo) : _buildEmptyState(context),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildContent(BuildContext context, OnboardingRepository repo) {
    final theme = Theme.of(context);
    final funding = repo.currentData?.funding;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.5,
            children: [
              StatsCard(title: 'Total Raised', value: '\$${(funding?.amount ?? 0) / 1000000}M', isHighlighted: true),
              StatsCard(title: 'Round', value: funding?.round ?? 'Unknown'),
            ],
          ),
          const SizedBox(height: 24),
          Text('Investors', style: theme.textTheme.titleLarge),
          const SizedBox(height: 12),
          Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                _buildInvestorTile(context, funding?.investorName ?? 'Lead Investor', funding?.round ?? 'Seed', '\$${(funding?.amount ?? 0) / 1000000}M', '${funding?.equityPercentage ?? 0}%', (funding?.investorName?.isNotEmpty == true) ? funding!.investorName![0] : 'I'),
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
            Icon(Icons.account_balance_wallet_outlined, size: 80, color: theme.colorScheme.primary.withValues(alpha: 0.5)),
            const SizedBox(height: 24),
            Text('No Funding Yet', style: theme.textTheme.headlineSmall),
            const SizedBox(height: 16),
            Text(
              'Keep track of your cap table, investment rounds, and investor details here.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.add),
              label: const Text('Add Funding Round'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInvestorTile(BuildContext context, String name, String details, String amount, String equity, String initial) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(initial, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
        ),
      ),
      title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(details),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(amount, style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.primary, fontSize: 16)),
          Text(equity, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}
