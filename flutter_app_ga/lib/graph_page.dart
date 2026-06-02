import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';

import 'models/energy_data.dart';
import 'constants/app_colors.dart';
import 'widgets/top_bar.dart';
import 'widgets/power_card.dart';
import 'widgets/trend_chart.dart';
import 'widgets/activity_logs.dart';
import 'widgets/history_list.dart';
import 'widgets/bottom_nav.dart';

class WattDashboardPage extends StatefulWidget {
  const WattDashboardPage({Key? key}) : super(key: key);

  @override
  State<WattDashboardPage> createState() => _WattDashboardPageState();
}

class _WattDashboardPageState extends State<WattDashboardPage> {
  final DatabaseReference _historyRef = FirebaseDatabase.instance.ref('history');

  bool _isDark   = false;
  bool _dayView  = true;  
  int  _navIndex = 0;     
  String? _selectedDate;

  @override
  Widget build(BuildContext context) {
    AppColors.isDark = _isDark;
    return Scaffold(
      backgroundColor: AppColors.bg,
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
              
              availableDates = raw.keys.map((e) => e.toString()).toList();
              availableDates.sort((a, b) => b.compareTo(a));

              if (_selectedDate != null && availableDates.contains(_selectedDate)) {
                displayDate = _selectedDate!;
              } else if (availableDates.isNotEmpty) {
                displayDate = availableDates.first;
              }

              if (_dayView) {
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
                final last7 = availableDates.take(7).toList().reversed.toList();
                for (int i = 0; i < last7.length; i++) {
                  final dRaw = raw[last7[i]] as Map? ?? {};
                  weekLabels.add(last7[i]); // YYYY-MM-DD
                  
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
                TopBar(
                  isDark: _isDark,
                  onToggleTheme: () => setState(() => _isDark = !_isDark),
                ),
                Expanded(
                  child: _navIndex == 0
                    ? _buildDashboard(spots, historyList, latestWatt, latestAmp, displayDate, weekLabels)
                    : HistoryList(
                        dates: availableDates,
                        selectedDate: _selectedDate,
                        onDateSelected: (date) {
                          setState(() {
                            _selectedDate = date;
                            _dayView = true;
                            _navIndex = 0; 
                          });
                        },
                      ),
                ),
                BottomNav(
                  navIndex: _navIndex,
                  onNavChanged: (index) => setState(() => _navIndex = index),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildDashboard(List<FlSpot> spots, List<EnergyData> historyList, String watt, String amp, String displayDate, List<String> weekLabels) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          PowerCard(
            watt: watt,
            amp: amp,
            dateStr: displayDate,
            dayView: _dayView,
          ),
          const SizedBox(height: 14),
          TrendChart(
            spots: spots,
            weekLabels: weekLabels,
            dayView: _dayView,
            onToggleView: (isDay) => setState(() => _dayView = isDay),
          ),
          const SizedBox(height: 14),
          ActivityLogs(
            list: historyList,
            weekLabels: weekLabels,
            dayView: _dayView,
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}