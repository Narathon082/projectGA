import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../constants/app_colors.dart';

enum ChartMode { realtime, daily, weekly }

class TrendChart extends StatelessWidget {
  final List<FlSpot> spots;
  final List<String> weekLabels;
  final List<String> realtimeLabels;
  final ChartMode chartMode;
  final ValueChanged<ChartMode> onModeChanged;

  const TrendChart({
    super.key,
    required this.spots,
    required this.weekLabels,
    required this.realtimeLabels,
    required this.chartMode,
    required this.onModeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              chartMode == ChartMode.realtime
                  ? 'Real-time Trend'
                  : 'Consumption Trend',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
            _buildModeTabs(),
          ],
        ),
        const SizedBox(height: 10),
        _buildChartCard(),
      ],
    );
  }

  Widget _buildModeTabs() {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _tab('Realtime', ChartMode.realtime),
          _tab('Day', ChartMode.daily),
          _tab('Week', ChartMode.weekly),
        ],
      ),
    );
  }

  Widget _tab(String label, ChartMode mode) {
    final active = chartMode == mode;
    return GestureDetector(
      onTap: () => onModeChanged(mode),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: active ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: active ? Colors.white : AppColors.textMuted,
          ),
        ),
      ),
    );
  }

  Widget _buildChartCard() {
    final hasData = spots.isNotEmpty;
    return Container(
      height: 220,
      padding: const EdgeInsets.fromLTRB(12, 24, 16, 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: hasData
          ? LineChart(_buildLineChartData())
          : Center(
              child: Text(
                'Waiting for data...',
                style: TextStyle(color: AppColors.textMuted, fontSize: 12),
              ),
            ),
    );
  }

  LineChartData _buildLineChartData() {
    double maxWatt = 0;
    for (var spot in spots) {
      if (spot.y > maxWatt) maxWatt = spot.y;
    }
    final maxY = maxWatt == 0 ? 10.0 : maxWatt * 1.25;

    double yInterval = maxY / 4;
    if (yInterval <= 0) {
      yInterval = 10;
    } else if (yInterval <= 20) {
      yInterval = 10;
    } else if (yInterval <= 50) {
      yInterval = 25;
    } else if (yInterval <= 100) {
      yInterval = 50;
    } else {
      yInterval = (yInterval / 100).ceil() * 100.0;
    }

    final double maxXValue = chartMode == ChartMode.realtime
        ? (spots.length > 1 ? (spots.length - 1).toDouble() : 9.0)
        : chartMode == ChartMode.daily
            ? 23
            : 6;

    return LineChartData(
      maxY: maxY,
      minY: 0,
      minX: 0,
      maxX: maxXValue,
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        drawHorizontalLine: true,
        horizontalInterval: yInterval,
        getDrawingHorizontalLine: (value) => FlLine(
          color: AppColors.divider,
          strokeWidth: 1,
          dashArray: [4, 4],
        ),
      ),
      borderData: FlBorderData(show: false),
      titlesData: FlTitlesData(
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 36,
            interval: yInterval,
            getTitlesWidget: (value, meta) {
              if (value == 0 || value >= maxY) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Text(
                  value.toStringAsFixed(1),
                  style: TextStyle(fontSize: 9, color: AppColors.textMuted, fontWeight: FontWeight.w500),
                  textAlign: TextAlign.right,
                ),
              );
            },
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: 1, 
            reservedSize: 22,
            getTitlesWidget: (v, m) {
              if (chartMode == ChartMode.realtime) {
                final idx = v.toInt();
                if (idx >= 0 && idx < realtimeLabels.length) {
                  // Show label every 4th element to prevent crowded text
                  if (idx % 4 != 0) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      realtimeLabels[idx],
                      style: TextStyle(fontSize: 8, color: AppColors.textMuted, fontWeight: FontWeight.w600),
                    ),
                  );
                }
                return const SizedBox.shrink();
              } else if (chartMode == ChartMode.daily) {
                final hour = v.toInt();
                if (hour % 4 != 0) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    '${hour.toString().padLeft(2, '0')}:00',
                    style: TextStyle(fontSize: 9, color: AppColors.textMuted, fontWeight: FontWeight.w600),
                  ),
                );
              } else {
                final idx = v.toInt();
                String label = idx >= 0 && idx < weekLabels.length ? weekLabels[idx] : '';
                if (label.length == 10) {
                  final parts = label.split('-');
                  if (parts.length == 3) {
                    label = '${parts[2]}/${parts[1]}';
                  } else {
                    label = label.substring(5);
                  }
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    label,
                    style: TextStyle(fontSize: 9, color: AppColors.textMuted, fontWeight: FontWeight.w600),
                  ),
                );
              }
            }
          ),
        ),
      ),
      lineTouchData: LineTouchData(
        handleBuiltInTouches: true,
        touchTooltipData: LineTouchTooltipData(
          getTooltipColor: (touchedSpot) => AppColors.textDark.withValues(alpha: 0.85),
          tooltipRoundedRadius: 12,
          getTooltipItems: (touchedSpots) {
            return touchedSpots.map((spot) {
              return LineTooltipItem(
                '${spot.y.toStringAsFixed(2)} W\n',
                const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                children: [
                  TextSpan(
                    text: chartMode == ChartMode.realtime
                        ? (spot.x.toInt() >= 0 && spot.x.toInt() < realtimeLabels.length ? realtimeLabels[spot.x.toInt()] : '')
                        : chartMode == ChartMode.daily
                            ? '${spot.x.toInt()}:00'
                            : (spot.x.toInt() >= 0 && spot.x.toInt() < weekLabels.length
                                ? (weekLabels[spot.x.toInt()].length == 10 ? weekLabels[spot.x.toInt()].substring(5) : weekLabels[spot.x.toInt()])
                                : ''),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 11,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ],
              );
            }).toList();
          },
        ),
      ),
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: chartMode != ChartMode.realtime, // straight lines look better for realtime ticks
          curveSmoothness: 0.35,
          gradient: const LinearGradient(
            colors: [Color(0xFF8C88FF), Color(0xFF4040C0)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          barWidth: 3.0,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: true,
            checkToShowDot: (spot, barData) => true,
            getDotPainter: (spot, percent, barData, index) {
              return FlDotCirclePainter(
                radius: 3.0,
                color: Colors.white,
                strokeWidth: 2.0,
                strokeColor: AppColors.primary,
              );
            },
          ),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.primary.withValues(alpha: 0.25),
                AppColors.primary.withValues(alpha: 0.0),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
