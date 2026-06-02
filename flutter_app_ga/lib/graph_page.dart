import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';

// ─────────────────────────────────────────
//  Model
// ─────────────────────────────────────────
class EnergyData {
  final int hour;
  final double watt;
  final double amp;
  EnergyData({required this.hour, required this.watt, required this.amp});
}

// ─────────────────────────────────────────
//  Constants
// ─────────────────────────────────────────
class _C {
  static bool isDark = false;
  static Color get bg         => isDark ? const Color(0xFF121212) : const Color(0xFFEEEEFF);
  static Color get surface    => isDark ? const Color(0xFF1E1E1E) : const Color(0xFFFFFFFF);
  static Color get cardBorder => isDark ? const Color(0xFF333333) : const Color(0xFFE0E0F0);
  static Color get primary    => isDark ? const Color(0xFF8C88FF) : const Color(0xFF4040C0);
  static Color get primaryBg  => isDark ? const Color(0xFF2C2C3C) : const Color(0xFFEEEEFF);
  static Color get textDark   => isDark ? const Color(0xFFE0E0E0) : const Color(0xFF1A1A50);
  static Color get textMuted  => isDark ? const Color(0xFF888888) : const Color(0xFF9090B0);
  static Color get textSub    => isDark ? const Color(0xFFAAAAAA) : const Color(0xFF6060A0);
  static Color get badgeBg    => isDark ? const Color(0xFF33334D) : const Color(0xFFE8E4FF);
  static Color get badgeText  => isDark ? const Color(0xFF8C88FF) : const Color(0xFF5050B0);
  static Color get divider    => isDark ? const Color(0xFF333333) : const Color(0xFFE8E8F5);
}

// ─────────────────────────────────────────
//  Page
// ─────────────────────────────────────────
class WattDashboardPage extends StatefulWidget {
  const WattDashboardPage({Key? key}) : super(key: key);

  @override
  State<WattDashboardPage> createState() => _WattDashboardPageState();
}

class _WattDashboardPageState extends State<WattDashboardPage> {
  // ── Firebase ──────────────────────────
  final DatabaseReference _historyRef =
      FirebaseDatabase.instance.ref('history');

  // ── Local state ───────────────────────
  bool _isDark   = false;
  bool _dayView  = true;  // Day / Week tab
  int  _navIndex = 0;     // Bottom nav

  // ─────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    _C.isDark = _isDark;
    return Scaffold(
      backgroundColor: _C.bg,
      body: SafeArea(
        child: StreamBuilder(
          // Firebase: ดึง stream ทุก node ภายใต้ 'history'
          stream: _historyRef.onValue,
          builder: (context, snapshot) {

            // ── แกะข้อมูลจาก Firebase ──────────────────────
            List<FlSpot> spots = [];
            List<EnergyData> historyList = [];
            String latestWatt = '0.0';
            String latestAmp  = '0.00';

            if (snapshot.hasData &&
                snapshot.data!.snapshot.value != null) {

              final raw = snapshot.data!.snapshot.value as Map;

              raw.forEach((key, value) {
                final hour = int.tryParse(key.toString()) ?? 0;
                double w = 0, a = 0;

                if (value is Map) {
                  w = double.tryParse(value['watt'].toString()) ?? 0;
                  a = double.tryParse(value['amp'].toString())  ?? 0;
                } else {
                  w = double.tryParse(value.toString()) ?? 0;
                }
                historyList.add(EnergyData(hour: hour, watt: w, amp: a));
              });

              // เรียงตามเวลา 0→23
              historyList.sort((a, b) => a.hour.compareTo(b.hour));

              // สร้าง spots สำหรับกราฟ
              for (final item in historyList) {
                spots.add(FlSpot(item.hour.toDouble(), item.watt));
              }

              if (historyList.isNotEmpty) {
                latestWatt = historyList.last.watt.toStringAsFixed(1);
                latestAmp  = historyList.last.amp.toStringAsFixed(2);
              }

              // กลับด้านสำหรับ log list (ใหม่ → เก่า)
              historyList = historyList.reversed.toList();
            }
            // ────────────────────────────────────────────────

            return Column(
              children: [
                _buildTopBar(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(14, 0, 14, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        _buildPowerCard(latestWatt, latestAmp),
                        const SizedBox(height: 14),
                        _buildTrendSection(spots),
                        const SizedBox(height: 14),
                        _buildLogsSection(historyList),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),
                _buildBottomNav(),
              ],
            );
          },
        ),
      ),
    );
  }

  // ─────────────────────────────────────
  //  Top bar
  // ─────────────────────────────────────
  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(Icons.bolt_rounded, color: _C.primary, size: 18),
              SizedBox(width: 6),
              Text(
                'Energy Monitor',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: _C.primary,
                ),
              ),
            ],
          ),
          GestureDetector(
            onTap: () => setState(() => _isDark = !_isDark),
            child: Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                color: _C.primaryBg,
                shape: BoxShape.circle,
              ),
              child: Icon(
                _isDark ? Icons.wb_sunny_outlined : Icons.dark_mode_outlined,
                size: 16,
                color: _C.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────
  //  Power card
  // ─────────────────────────────────────
  Widget _buildPowerCard(String watt, String amp) {
    final dateStr = DateFormat('EEEE, d MMMM').format(DateTime.now());
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _C.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _C.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'CURRENT POWER',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              color: _C.textMuted,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            dateStr,
            style: TextStyle(fontSize: 11, color: _C.textMuted),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    watt,
                    style: TextStyle(
                      fontSize: 38,
                      fontWeight: FontWeight.w800,
                      color: _C.textDark,
                      letterSpacing: -1,
                      height: 1,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Padding(
                    padding: EdgeInsets.only(bottom: 4),
                    child: Text(
                      'Watt',
                      style: TextStyle(fontSize: 16, color: _C.textSub),
                    ),
                  ),
                ],
              ),
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  color: _C.primaryBg,
                  shape: BoxShape.circle,
                  border: Border.all(color: _C.cardBorder, width: 1.5),
                ),
                child: Icon(Icons.bolt_rounded, color: _C.textSub, size: 24),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────
  //  Trend section
  // ─────────────────────────────────────
  Widget _buildTrendSection(List<FlSpot> spots) {
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
                color: _C.textDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _buildChartCard(spots),
      ],
    );
  }

  Widget _buildChartCard(List<FlSpot> spots) {
    final hasData = spots.isNotEmpty;
    return Container(
      height: 220,
      padding: const EdgeInsets.fromLTRB(12, 24, 16, 12),
      decoration: BoxDecoration(
        color: _C.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _C.cardBorder),
        boxShadow: [
          BoxShadow(
            color: _C.primary.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: hasData
          ? LineChart(_buildLineChartData(spots))
          : Center(
              child: Text(
                'Waiting for data...',
                style: TextStyle(color: _C.textMuted, fontSize: 12),
              ),
            ),
    );
  }

  LineChartData _buildLineChartData(List<FlSpot> spots) {
    double maxWatt = 0;
    for (var spot in spots) {
      if (spot.y > maxWatt) maxWatt = spot.y;
    }
    final maxY = maxWatt == 0 ? 100.0 : maxWatt * 1.25;

    // คำนวณช่วงห่างของสเกลแกน Y ให้เป็นเลขกลมๆ สวยๆ
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
          color: _C.divider,
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
                  style: TextStyle(fontSize: 10, color: _C.textMuted, fontWeight: FontWeight.w500),
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
            getTitlesWidget: (v, m) => Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                '${v.toInt()}:00',
                style: TextStyle(fontSize: 10, color: _C.textMuted, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ),
      ),
      lineTouchData: LineTouchData(
        handleBuiltInTouches: true,
        touchTooltipData: LineTouchTooltipData(
          getTooltipColor: (touchedSpot) => _C.textDark.withOpacity(0.85),
          tooltipRoundedRadius: 12,
          getTooltipItems: (touchedSpots) {
            return touchedSpots.map((spot) {
              return LineTooltipItem(
                '${spot.y.toStringAsFixed(1)} W\n',
                TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                children: [
                  TextSpan(
                    text: '${spot.x.toInt()}:00',
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
            colors: [Color(0xFF8C88FF), _C.primary],
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
                color: _C.surface,
                strokeWidth: 2.5,
                strokeColor: _C.primary,
              );
            },
          ),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                _C.primary.withOpacity(0.35),
                _C.primary.withOpacity(0.0),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────
  //  Activity logs
  // ─────────────────────────────────────
  Widget _buildLogsSection(List<EnergyData> list) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Activity Logs',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: _C.textDark,
          ),
        ),
        const SizedBox(height: 10),
        if (list.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _C.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _C.cardBorder),
            ),
            child: Text(
              'Waiting for data...',
              style: TextStyle(color: _C.textMuted, fontSize: 12),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: list.length,
            itemBuilder: (context, i) =>
                _buildLogItem(list[i], isLatest: i == 0),
          ),
      ],
    );
  }

  Widget _buildLogItem(EnergyData data, {required bool isLatest}) {
    final timeStr = '${data.hour.toString().padLeft(2, '0')}:00';
    final dateStr = DateFormat('dd MMM yyyy').format(DateTime.now());
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _C.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _C.divider),
      ),
      child: Row(
        children: [
          // ── Icon ──
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              color: _C.primaryBg,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.history_rounded,
                color: _C.textSub, size: 16),
          ),
          const SizedBox(width: 10),

          // ── Label ──
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '${data.watt.toStringAsFixed(1)} W',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _C.textDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '$timeStr | $dateStr',
                  style: TextStyle(
                      fontSize: 11, color: _C.textMuted),
                ),
              ],
            ),
          ),

          // ── Amp ──
          Text(
            '${data.amp.toStringAsFixed(2)} A',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: _C.textDark,
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────
  //  Bottom nav
  // ─────────────────────────────────────
  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: _C.surface,
        border: Border(top: BorderSide(color: _C.divider, width: 0.5)),
      ),
      child: Row(
        children: [
          _navItem(0, Icons.home_outlined, 'หน้าหลัก'),
          _navItem(1, Icons.history_rounded, 'ประวัติ'),
        ],
      ),
    );
  }

  Widget _navItem(int index, IconData icon, String label) {
    final active = _navIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _navIndex = index),
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon,
                  size: 22,
                  color: active ? _C.primary : _C.textMuted),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: active ? _C.primary : _C.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}