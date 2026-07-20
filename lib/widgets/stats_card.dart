import 'package:flutter/material.dart';

class StatsCard extends StatelessWidget {
  final String title;
  final String value;
  final String trend;
  final bool isPositive;
  final bool isHighlighted;

  const StatsCard({
    super.key,
    required this.title,
    required this.value,
    this.trend = '',
    this.isPositive = true,
    this.isHighlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      color: isHighlighted ? theme.colorScheme.secondary : theme.colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isHighlighted ? Colors.white70 : theme.textTheme.bodySmall?.color,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: theme.textTheme.headlineSmall?.copyWith(
                color: isHighlighted ? Colors.white : theme.colorScheme.onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (trend.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    isPositive ? Icons.trending_up : Icons.trending_down,
                    size: 16,
                    color: isHighlighted 
                        ? Colors.white70 
                        : (isPositive ? theme.colorScheme.primary : theme.colorScheme.error),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    trend,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isHighlighted 
                          ? Colors.white70 
                          : (isPositive ? theme.colorScheme.primary : theme.colorScheme.error),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ]
          ],
        ),
      ),
    );
  }
}
