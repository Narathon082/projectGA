import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../constants/app_colors.dart';

class TrendChart extends StatelessWidget {
  final List<FlSpot> spots;
  final List<String> weekLabels;
  final bool dayView;
  final ValueChanged<bool> onToggleView;

  const TrendChart({
    Key? key,
    required this.spots,
    required this.weekLabels,
    required this.dayView,
    required this.onToggleView,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Consumption Trend',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
            _buildDayWeekTabs(),
          ],
        ),
        const SizedBox(height: 10),
        _buildChartCard(),
      ],
    );
  }

  Widget _buildDayWeekTabs() {
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
          _tab('Day', true),
          _tab('Week', false),
        ],
      ),
    );
  }

  Widget _tab(String label, bool isDay) {
    final active = dayView == isDay;
    return GestureDetector(
      onTap: () => onToggleView(isDay),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
        decoration: BoxDecoration(
          color: active ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
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
            color: AppColors.primary.withOpacity(0.04),
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
    final maxY = maxWatt == 0 ? 100.0 : maxWatt * 1.25;

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

    return LineChartData(
      maxY: maxY,
      minY: 0,
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
                  value.toInt().toString(),
                  style: TextStyle(fontSize: 10, color: AppColors.textMuted, fontWeight: FontWeight.w500),
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
              if (dayView) {
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    '${v.toInt()}:00',
                    style: TextStyle(fontSize: 10, color: AppColors.textMuted, fontWeight: FontWeight.w600),
                  ),
                );
              } else {
                final idx = v.toInt();
                String label = idx >= 0 && idx < weekLabels.length ? weekLabels[idx] : '';
                if (label.length == 10) {
                  label = label.substring(5);
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    label,
                    style: TextStyle(fontSize: 10, color: AppColors.textMuted, fontWeight: FontWeight.w600),
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
          getTooltipColor: (touchedSpot) => AppColors.textDark.withOpacity(0.85),
          tooltipRoundedRadius: 12,
          getTooltipItems: (touchedSpots) {
            return touchedSpots.map((spot) {
              return LineTooltipItem(
                '${spot.y.toStringAsFixed(1)} W\n',
                TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                children: [
                  TextSpan(
                    text: dayView 
                      ? '${spot.x.toInt()}:00' 
                      : (spot.x.toInt() >= 0 && spot.x.toInt() < weekLabels.length ? (weekLabels[spot.x.toInt()].length == 10 ? weekLabels[spot.x.toInt()].substring(5) : weekLabels[spot.x.toInt()]) : ''),
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
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
          isCurved: true,
          curveSmoothness: 0.35,
          gradient: LinearGradient(
            colors: [Color(0xFF8C88FF), AppColors.primary],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          barWidth: 3.5,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: true,
            checkToShowDot: (spot, barData) => true,
            getDotPainter: (spot, percent, barData, index) {
              return FlDotCirclePainter(
                radius: 4.5,
                color: AppColors.surface,
                strokeWidth: 2.5,
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
                AppColors.primary.withOpacity(0.35),
                AppColors.primary.withOpacity(0.0),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
