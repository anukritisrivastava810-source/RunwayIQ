import 'package:flutter/material.dart';

class StatsCard extends StatelessWidget {
  final String title;
  final String value;
  final String trend;
  final bool isPositive;
  final bool isHighlighted;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? margin;

  const StatsCard({
    super.key,
    required this.title,
    required this.value,
    this.trend = '',
    this.isPositive = true,
    this.isHighlighted = false,
    this.onTap,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    final content = Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: isHighlighted ? Colors.white70 : theme.textTheme.bodySmall?.color,
            ),
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: theme.textTheme.headlineSmall?.copyWith(
                color: isHighlighted ? Colors.white : theme.colorScheme.onSurface,
                fontWeight: FontWeight.w700,
              ),
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
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      trend,
                      maxLines: 1,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isHighlighted 
                            ? Colors.white70 
                            : (isPositive ? theme.colorScheme.primary : theme.colorScheme.error),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ]
        ],
      ),
    );

    return Card(
      margin: margin ?? EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      color: isHighlighted ? theme.colorScheme.secondary : theme.colorScheme.surface,
      child: onTap != null
          ? InkWell(
              onTap: onTap,
              child: content,
            )
          : content,
    );
  }
}
