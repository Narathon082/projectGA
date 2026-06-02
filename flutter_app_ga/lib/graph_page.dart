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
  final DatabaseReference _historyRef = FirebaseDatabase.instance.ref('history');

  // ── Local state ───────────────────────
  bool _isDark   = false;
  bool _dayView  = true;  
  int  _navIndex = 0;     
  String? _selectedDate;

  // ─────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    _C.isDark = _isDark;
    return Scaffold(
      backgroundColor: _C.bg,
      body: SafeArea(
        child: StreamBuilder(
          stream: _historyRef.onValue,
          builder: (context, snapshot) {

            List<String> availableDates = [];
            List<FlSpot> spots = [];
            List<EnergyData> historyList = [];
            List<String> weekLabels = [];
            String latestWatt = '0.0';
            String latestAmp  = '0.00';
            
            String displayDate = DateFormat('yyyy-MM-dd').format(DateTime.now());

            if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
              final raw = snapshot.data!.snapshot.value as Map;
              
              // ดึงวันที่ทั้งหมดออกมาและเรียงจากใหม่สุดไปเก่าสุด
              availableDates = raw.keys.map((e) => e.toString()).toList();
              availableDates.sort((a, b) => b.compareTo(a));

              if (_selectedDate != null && availableDates.contains(_selectedDate)) {
                displayDate = _selectedDate!;
              } else if (availableDates.isNotEmpty) {
                displayDate = availableDates.first;
              }

              if (_dayView) {
                // ── แบบรายวัน (Day View) ──
                final dayRaw = raw[displayDate] as Map? ?? {};
                dayRaw.forEach((key, value) {
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

                historyList.sort((a, b) => a.hour.compareTo(b.hour));
                for (final item in historyList) {
                  spots.add(FlSpot(item.hour.toDouble(), item.watt));
                }

                if (historyList.isNotEmpty) {
                  latestWatt = historyList.last.watt.toStringAsFixed(1);
                  latestAmp  = historyList.last.amp.toStringAsFixed(2);
                  historyList = historyList.reversed.toList();
                }
              } else {
                // ── แบบรายสัปดาห์ (Week View) ──
                final last7 = availableDates.take(7).toList().reversed.toList();
                for (int i = 0; i < last7.length; i++) {
                  final dRaw = raw[last7[i]] as Map? ?? {};
                  weekLabels.add(last7[i]); // เก็บป้ายชื่อ "YYYY-MM-DD"
                  
                  double maxW = 0, maxA = 0;
                  dRaw.forEach((k, v) {
                    double w = 0, a = 0;
                    if (v is Map) {
                      w = double.tryParse(v['watt'].toString()) ?? 0;
                      a = double.tryParse(v['amp'].toString()) ?? 0;
                    } else {
                      w = double.tryParse(v.toString()) ?? 0;
                    }
                    if (w > maxW) maxW = w;
                    if (a > maxA) maxA = a;
                  });
                  spots.add(FlSpot(i.toDouble(), maxW));
                  // ใส่ hour เป็น index ไปก่อนเพื่อให้จับคู่กับ weekLabels ได้
                  historyList.add(EnergyData(hour: i, watt: maxW, amp: maxA));
                }
                
                if (historyList.isNotEmpty) {
                  latestWatt = historyList.last.watt.toStringAsFixed(1);
                  latestAmp  = historyList.last.amp.toStringAsFixed(2);
                  historyList = historyList.reversed.toList();
                }
              }
            }

            return Column(
              children: [
                _buildTopBar(),
                Expanded(
                  child: _navIndex == 0
                    ? _buildDashboard(spots, historyList, latestWatt, latestAmp, displayDate, weekLabels)
                    : _buildHistoryList(availableDates),
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
  //  Dashboard Tab (หน้าหลัก)
  // ─────────────────────────────────────
  Widget _buildDashboard(List<FlSpot> spots, List<EnergyData> historyList, String watt, String amp, String displayDate, List<String> weekLabels) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          _buildPowerCard(watt, amp, displayDate),
          const SizedBox(height: 14),
          _buildTrendSection(spots, weekLabels),
          const SizedBox(height: 14),
          _buildLogsSection(historyList, weekLabels),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  // ─────────────────────────────────────
  //  History List Tab (หน้าประวัติ)
  // ─────────────────────────────────────
  Widget _buildHistoryList(List<String> dates) {
    if (dates.isEmpty) {
       return Center(child: Text("No history data", style: TextStyle(color: _C.textMuted)));
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      itemCount: dates.length,
      itemBuilder: (context, i) {
        final date = dates[i];
        final isSelected = date == (_selectedDate ?? (dates.isNotEmpty ? dates.first : ''));
        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedDate = date;
              _dayView = true;
              _navIndex = 0; // กลับไปหน้า Dashboard ของวันนั้น
            });
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isSelected ? _C.primaryBg : _C.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isSelected ? _C.primary : _C.divider),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.calendar_month_rounded, color: isSelected ? _C.primary : _C.textSub, size: 20),
                    const SizedBox(width: 12),
                    Text(
                      date, 
                      style: TextStyle(
                        fontSize: 15, 
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w600, 
                        color: isSelected ? _C.primary : _C.textDark
                      )
                    ),
                  ],
                ),
                Icon(Icons.chevron_right, color: isSelected ? _C.primary : _C.textMuted),
              ]
            )
          )
        );
      }
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
              const SizedBox(width: 6),
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
  Widget _buildPowerCard(String watt, String amp, String dateStr) {
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
            _dayView ? 'MAX/CURRENT POWER' : 'WEEK MAX POWER',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              color: _C.textMuted,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            _dayView ? dateStr : 'Last 7 Days',
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
                    padding: const EdgeInsets.only(bottom: 4),
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
  Widget _buildTrendSection(List<FlSpot> spots, List<String> weekLabels) {
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
            _buildDayWeekTabs(),
          ],
        ),
        const SizedBox(height: 10),
        _buildChartCard(spots, weekLabels),
      ],
    );
  }

  Widget _buildDayWeekTabs() {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: _C.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _C.cardBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _tab('Day',  true),
          _tab('Week', false),
        ],
      ),
    );
  }

  Widget _tab(String label, bool isDay) {
    final active = _dayView == isDay;
    return GestureDetector(
      onTap: () => setState(() => _dayView = isDay),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
        decoration: BoxDecoration(
          color: active ? _C.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: active ? Colors.white : _C.textMuted,
          ),
        ),
      ),
    );
  }

  Widget _buildChartCard(List<FlSpot> spots, List<String> weekLabels) {
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
          ? LineChart(_buildLineChartData(spots, weekLabels))
          : Center(
              child: Text(
                'Waiting for data...',
                style: TextStyle(color: _C.textMuted, fontSize: 12),
              ),
            ),
    );
  }

  LineChartData _buildLineChartData(List<FlSpot> spots, List<String> weekLabels) {
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
            getTitlesWidget: (v, m) {
              if (_dayView) {
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    '${v.toInt()}:00',
                    style: TextStyle(fontSize: 10, color: _C.textMuted, fontWeight: FontWeight.w600),
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
                    style: TextStyle(fontSize: 10, color: _C.textMuted, fontWeight: FontWeight.w600),
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
          getTooltipColor: (touchedSpot) => _C.textDark.withOpacity(0.85),
          tooltipRoundedRadius: 12,
          getTooltipItems: (touchedSpots) {
            return touchedSpots.map((spot) {
              return LineTooltipItem(
                '${spot.y.toStringAsFixed(1)} W\n',
                TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                children: [
                  TextSpan(
                    text: _dayView 
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
  Widget _buildLogsSection(List<EnergyData> list, List<String> weekLabels) {
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
                _buildLogItem(list[i], weekLabels),
          ),
      ],
    );
  }

  Widget _buildLogItem(EnergyData data, List<String> weekLabels) {
    String subStr = '';
    
    if (_dayView) {
      subStr = '${data.hour.toString().padLeft(2, '0')}:00';
    } else {
      final idx = data.hour;
      if (idx >= 0 && idx < weekLabels.length) {
        final parts = weekLabels[idx].split('-');
        subStr = parts.length == 3 ? '${parts[2]}/${parts[1]}/${parts[0]}' : weekLabels[idx];
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: _C.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _C.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left: Icon + Time/Date
          Row(
            children: [
              Container(
                width: 38, height: 38,
                decoration: BoxDecoration(
                  color: _C.primaryBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _dayView ? Icons.access_time_filled_rounded : Icons.calendar_today_rounded,
                  color: _C.primary, 
                  size: 18,
                ),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    subStr,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: _C.textDark,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _dayView ? 'Hourly Update' : 'Daily Max',
                    style: TextStyle(
                      fontSize: 11, 
                      color: _C.textMuted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
          
          // Right: Watt & Amp
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    data.watt.toStringAsFixed(1),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: _C.textDark,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(width: 3),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 1.5),
                    child: Text(
                      'W',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: _C.textSub,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _C.badgeBg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${data.amp.toStringAsFixed(2)} A',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: _C.badgeText,
                  ),
                ),
              ),
            ],
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