import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../features/dashboard/domain/models/burn_trend.dart';
import 'dashboard_card.dart';

class BurnRateChart extends StatelessWidget {
  final BurnTrendResponse? burnTrend;
  final bool isLoading;
  final bool hasError;
  final String errorMessage;
  final VoidCallback? onRetry;

  const BurnRateChart({
    super.key,
    this.burnTrend,
    this.isLoading = false,
    this.hasError = false,
    this.errorMessage = '',
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DashboardCard(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header / Legend
          _buildLegend(context),
          const SizedBox(height: 16),

          // Content: Loading / Error / Empty / Chart
          SizedBox(
            height: 220,
            child: _buildBody(context, theme),
          ),
        ],
      ),
    );
  }

  Widget _buildLegend(BuildContext context) {
    final theme = Theme.of(context);
    final totalColor = theme.colorScheme.primary;
    const payrollColor = Color(0xFF0D9488); // Teal 600
    const expenseColor = Color(0xFFD97706); // Amber 600

    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 12,
      runSpacing: 8,
      children: [
        _buildLegendItem(label: 'Total Burn', color: totalColor, isPrimary: true),
        _buildLegendItem(label: 'Payroll', color: payrollColor),
        _buildLegendItem(label: 'Expenses', color: expenseColor),
      ],
    );
  }

  Widget _buildLegendItem({
    required String label,
    required Color color,
    bool isPrimary = false,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: isPrimary ? 16 : 10,
          height: isPrimary ? 4 : 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: isPrimary ? BorderRadius.circular(2) : null,
            shape: isPrimary ? BoxShape.rectangle : BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isPrimary ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildBody(BuildContext context, ThemeData theme) {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (hasError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, color: theme.colorScheme.error, size: 36),
              const SizedBox(height: 8),
              Text(
                errorMessage.isNotEmpty
                    ? errorMessage
                    : 'Failed to load burn rate trend',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.error,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (onRetry != null) ...[
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Retry'),
                  style: ElevatedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    final data = burnTrend;
    if (data == null || data.points.isEmpty || !data.hasBurnData) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.show_chart_rounded,
              size: 40,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 10),
            Text(
              'No historical burn data recorded',
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Add expenses or active employees to see monthly trends.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return _buildLineChart(context, data);
  }

  Widget _buildLineChart(BuildContext context, BurnTrendResponse trend) {
    final theme = Theme.of(context);
    final points = trend.points;
    final currencySymbol = trend.currencySymbol;

    final totalColor = theme.colorScheme.primary;
    const payrollColor = Color(0xFF0D9488);
    const expenseColor = Color(0xFFD97706);

    double maxVal = 0.0;
    final totalSpots = <FlSpot>[];
    final payrollSpots = <FlSpot>[];
    final expenseSpots = <FlSpot>[];

    for (int i = 0; i < points.length; i++) {
      final p = points[i];
      final x = i.toDouble();
      totalSpots.add(FlSpot(x, p.totalBurn));
      payrollSpots.add(FlSpot(x, p.payrollBurn));
      expenseSpots.add(FlSpot(x, p.expenseBurn));

      maxVal = max(maxVal, p.totalBurn);
      maxVal = max(maxVal, p.payrollBurn);
      maxVal = max(maxVal, p.expenseBurn);
    }

    final maxY = maxVal > 0 ? (maxVal * 1.25) : 1000.0;
    final intervalY = _calculateInterval(maxY);

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: (points.length - 1).toDouble(),
        minY: 0,
        maxY: maxY,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: intervalY,
          getDrawingHorizontalLine: (value) => FlLine(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.35),
            strokeWidth: 1,
            dashArray: [4, 4],
          ),
        ),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 52,
              interval: intervalY,
              getTitlesWidget: (value, meta) {
                if (value == 0) {
                  return SideTitleWidget(
                    meta: meta,
                    child: Text(
                      '${currencySymbol}0',
                      style: TextStyle(
                        fontSize: 10,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  );
                }
                return SideTitleWidget(
                  meta: meta,
                  child: Text(
                    _formatShortAmount(value, currencySymbol),
                    style: TextStyle(
                      fontSize: 10,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              interval: 1,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= points.length) {
                  return const SizedBox.shrink();
                }
                return SideTitleWidget(
                  meta: meta,
                  child: Text(
                    points[index].displayMonth,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineTouchData: LineTouchData(
          enabled: true,
          touchTooltipData: LineTouchTooltipData(
            fitInsideHorizontally: true,
            fitInsideVertically: true,
            getTooltipColor: (_) => theme.colorScheme.surfaceContainerHighest,
            tooltipBorderRadius: BorderRadius.circular(8),
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((barSpot) {
                final index = barSpot.x.toInt();
                final p = (index >= 0 && index < points.length)
                    ? points[index]
                    : null;
                final monthName = p?.displayMonth ?? '';

                String seriesName = 'Burn';
                Color textColor = totalColor;
                if (barSpot.barIndex == 0) {
                  seriesName = 'Total';
                  textColor = totalColor;
                } else if (barSpot.barIndex == 1) {
                  seriesName = 'Payroll';
                  textColor = payrollColor;
                } else if (barSpot.barIndex == 2) {
                  seriesName = 'Expenses';
                  textColor = expenseColor;
                }

                final amountStr = _formatFullAmount(barSpot.y, currencySymbol);

                return LineTooltipItem(
                  barSpot.barIndex == 0
                      ? '$monthName\n$seriesName: $amountStr'
                      : '$seriesName: $amountStr',
                  TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                );
              }).toList();
            },
          ),
        ),
        lineBarsData: [
          // 1. Total Burn (Primary line with area gradient)
          LineChartBarData(
            spots: totalSpots,
            isCurved: true,
            curveSmoothness: 0.3,
            color: totalColor,
            barWidth: 3.0,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, i) =>
                  FlDotCirclePainter(
                radius: 3.5,
                color: totalColor,
                strokeWidth: 2,
                strokeColor: theme.colorScheme.surface,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  totalColor.withValues(alpha: 0.22),
                  totalColor.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),

          // 2. Payroll Burn
          LineChartBarData(
            spots: payrollSpots,
            isCurved: true,
            curveSmoothness: 0.3,
            color: payrollColor,
            barWidth: 2.0,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, i) =>
                  FlDotCirclePainter(
                radius: 2.5,
                color: payrollColor,
                strokeWidth: 1.5,
                strokeColor: theme.colorScheme.surface,
              ),
            ),
          ),

          // 3. Expense Burn
          LineChartBarData(
            spots: expenseSpots,
            isCurved: true,
            curveSmoothness: 0.3,
            color: expenseColor,
            barWidth: 2.0,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, i) =>
                  FlDotCirclePainter(
                radius: 2.5,
                color: expenseColor,
                strokeWidth: 1.5,
                strokeColor: theme.colorScheme.surface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  double _calculateInterval(double maxY) {
    if (maxY <= 0) return 100;
    if (maxY <= 1000) return 250;
    if (maxY <= 10000) return 2500;
    if (maxY <= 50000) return 10000;
    if (maxY <= 200000) return 50000;
    if (maxY <= 1000000) return 250000;
    return maxY / 4;
  }

  String _formatShortAmount(double amount, String symbol) {
    if (amount >= 1000000) {
      return '$symbol${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return '$symbol${(amount / 1000).toStringAsFixed(0)}k';
    }
    return '$symbol${amount.toInt()}';
  }

  String _formatFullAmount(double amount, String symbol) {
    if (amount >= 1000000) {
      return '$symbol${(amount / 1000000).toStringAsFixed(2)}M';
    } else if (amount >= 1000) {
      return '$symbol${(amount / 1000).toStringAsFixed(1)}k';
    }
    return '$symbol${amount.toStringAsFixed(0)}';
  }
}
