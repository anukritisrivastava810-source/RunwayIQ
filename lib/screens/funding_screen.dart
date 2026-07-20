import 'package:flutter/material.dart';
import '../widgets/stats_card.dart';

class FundingScreen extends StatelessWidget {
  const FundingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      body: SingleChildScrollView(
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
              children: const [
                StatsCard(title: 'Total Raised', value: '\$3.5M', isHighlighted: true),
                StatsCard(title: 'Post-Money Val.', value: '\$15.0M'),
              ],
            ),
            const SizedBox(height: 24),
            Text('Investors', style: theme.textTheme.titleLarge),
            const SizedBox(height: 12),
            Card(
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  _buildInvestorTile(context, 'Sequoia Surge', 'Seed Round • Jan 2024', '\$2.0M', '13.3%', 'S'),
                  const Divider(height: 1),
                  _buildInvestorTile(context, 'Y Combinator', 'Pre-Seed • Jun 2023', '\$500k', '7.0%', 'Y'),
                  const Divider(height: 1),
                  _buildInvestorTile(context, 'Angel Syndicate', 'Pre-Seed • Jun 2023', '\$1.0M', '5.0%', 'A'),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
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
