import 'package:flutter/material.dart';
import '../widgets/stats_card.dart';

class RunwayScreen extends StatefulWidget {
  const RunwayScreen({super.key});

  @override
  State<RunwayScreen> createState() => _RunwayScreenState();
}

class _RunwayScreenState extends State<RunwayScreen> {
  double _runwayMonths = 14.0;
  double _projectedBurn = 85.0; // in thousands

  void _applySimulation(double burnChange, double runwayChange) {
    setState(() {
      _projectedBurn += burnChange;
      _runwayMonths += runwayChange;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(title: const Text('Runway Analysis')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Text('Simulate scenarios to see impact on survival.'),
            const SizedBox(height: 32),
            
            // Circular Progress
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 200,
                  height: 200,
                  child: CircularProgressIndicator(
                    value: _runwayMonths / 24.0, // Assuming 24 months is 100%
                    strokeWidth: 12,
                    backgroundColor: theme.colorScheme.surface,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _runwayMonths < 6 ? theme.colorScheme.error : theme.colorScheme.primary,
                    ),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _runwayMonths.toStringAsFixed(1),
                      style: theme.textTheme.displayLarge?.copyWith(
                        color: _runwayMonths < 6 ? theme.colorScheme.error : theme.colorScheme.primary,
                      ),
                    ),
                    Text('Months', style: theme.textTheme.titleMedium),
                  ],
                ),
              ],
            ),
            
            const SizedBox(height: 32),
            
            Row(
              children: [
                Expanded(child: StatsCard(title: 'Cash Available', value: '\$1.2M')),
                const SizedBox(width: 12),
                Expanded(child: StatsCard(title: 'Projected Burn', value: '\$${_projectedBurn}k')),
              ],
            ),
            
            const SizedBox(height: 32),
            Align(
              alignment: Alignment.centerLeft,
              child: Text('Simulations', style: theme.textTheme.titleLarge),
            ),
            const SizedBox(height: 12),
            
            _buildSimCard('What if I hire 2 engineers?', '+\$15k / mo burn', 15, -2.5),
            _buildSimCard('What if expenses increase by 15%?', '+\$12k / mo burn', 12, -2.0),
            _buildSimCard('What if we raise ₹50L?', '+\$60k to cash', -0, 0.7),
          ],
        ),
      ),
    );
  }

  Widget _buildSimCard(String title, String subtitle, double burnChange, double runwayChange) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: CheckboxListTile(
        title: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        value: false,
        onChanged: (bool? value) {
          // This is a dummy toggle. In a real app, track state per card.
          _applySimulation(value == true ? burnChange : -burnChange, value == true ? runwayChange : -runwayChange);
        },
      ),
    );
  }
}
