import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import 'dart:async';

import 'models/energy_data.dart';
import 'constants/app_colors.dart';
import 'widgets/top_bar.dart';
import 'widgets/power_card.dart';
import 'widgets/in_out_card.dart';
import 'widgets/trend_chart.dart';
import 'widgets/activity_logs.dart';
import 'widgets/history_list.dart';
import 'widgets/bottom_nav.dart';
import 'in_out_page.dart';

class WattDashboardPage extends StatefulWidget {
  const WattDashboardPage({Key? key}) : super(key: key);

  @override
  State<WattDashboardPage> createState() => _WattDashboardPageState();
}

class _WattDashboardPageState extends State<WattDashboardPage> {
  final DatabaseReference _historyRef = FirebaseDatabase.instance.ref('history');
  
  // Real-time Database references and local state
  StreamSubscription? _realtimeSub;

  double vin = 0.0;
  double iin = 0.0;
  double pin = 0.0;
  double vout = 0.0;
  double iout = 0.0;
  double pout = 0.0;

  final List<FlSpot> _realtimeSpots = [];
  final List<String> _realtimeLabels = [];
  final int _maxRealtimePoints = 12;

  double? _latestHistoryWatt;
  ChartMode _chartMode = ChartMode.realtime;

  bool _isDark   = false;
  int  _navIndex = 0;     
  String? _selectedDate;

  Map<String, dynamic> _convertToMap(dynamic val) {
    if (val == null) return {};
    if (val is Map) {
      return val.map((k, v) => MapEntry(k.toString(), v));
    }
    if (val is List) {
      final Map<String, dynamic> map = {};
      for (int i = 0; i < val.length; i++) {
        if (val[i] != null) {
          map[i.toString()] = val[i];
        }
      }
      return map;
    }
    return {};
  }

  @override
  void initState() {
    super.initState();
    _setupRealtimeData();
  }

  @override
  void dispose() {
    _realtimeSub?.cancel();
    super.dispose();
  }

  void _addRealtimePoint(double wattValue) {
    _realtimeSpots.add(FlSpot(_realtimeSpots.length.toDouble(), wattValue));
    final nowStr = DateFormat('HH:mm:ss').format(DateTime.now());
    _realtimeLabels.add(nowStr);
    if (_realtimeSpots.length > _maxRealtimePoints) {
      _realtimeSpots.removeAt(0);
      _realtimeLabels.removeAt(0);
      // Re-index x coordinates to keep them sequential
      for (int i = 0; i < _realtimeSpots.length; i++) {
        _realtimeSpots[i] = FlSpot(i.toDouble(), _realtimeSpots[i].y);
      }
    }
  }

  void _setupRealtimeData() {
    // Subscribe to Firebase Realtime Database at 'realtime' node
    final DatabaseReference realtimeRef = FirebaseDatabase.instance.ref('realtime');
    _realtimeSub = realtimeRef.onValue.listen((event) {
      final data = event.snapshot.value;
      if (data != null && data is Map) {
        setState(() {
          vin = double.tryParse(data['vin'].toString()) ?? 0.0;
          iin = double.tryParse(data['iin'].toString()) ?? 0.0;
          pin = double.tryParse(data['pin'].toString()) ?? 0.0;
          vout = double.tryParse(data['vout'].toString()) ?? 0.0;
          iout = double.tryParse(data['iout'].toString()) ?? 0.0;
          pout = double.tryParse(data['pout'].toString()) ?? 0.0;
          _addRealtimePoint(pout);
        });
      }
    });
  }

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
            String latestWatt = '0.00';
            String latestAmp  = '0.00';
            
            String displayDate = DateFormat('yyyy-MM-dd').format(DateTime.now());

            if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
              final raw = _convertToMap(snapshot.data!.snapshot.value);
              
              availableDates = raw.keys.toList();
              availableDates.sort((a, b) => b.compareTo(a));

              if (_selectedDate != null && availableDates.contains(_selectedDate)) {
                displayDate = _selectedDate!;
              } else if (availableDates.isNotEmpty) {
                displayDate = availableDates.first;
              }

              if (_chartMode == ChartMode.daily || _chartMode == ChartMode.realtime) {
                final dayRaw = _convertToMap(raw[displayDate]);
                dayRaw.forEach((key, value) {
                  final hour = int.tryParse(key) ?? 0;
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
                  latestWatt = historyList.last.watt.toStringAsFixed(2);
                  latestAmp  = historyList.last.amp.toStringAsFixed(2);
                  _latestHistoryWatt = historyList.last.watt;
                  historyList = historyList.reversed.toList();
                }
              } else {
                final last7 = availableDates.take(7).toList().reversed.toList();
                for (int i = 0; i < last7.length; i++) {
                  final dRaw = _convertToMap(raw[last7[i]]);
                  weekLabels.add(last7[i]); // YYYY-MM-DD
                  
                  double maxW = 0, maxA = 0;
                  dRaw.forEach((k, v) {
                    double w = 0, a = 0;
                    if (v is Map) {
                      w = double.tryParse(v['watt'].toString()) ?? 0;
                      a = double.tryParse(v['amp'].toString()) ?? 0;
                    } else {
                      double? parsedVal = double.tryParse(v.toString());
                      if (parsedVal != null) {
                        w = parsedVal;
                      } else if (v is Map) {
                        w = double.tryParse(v['watt'].toString()) ?? 0;
                        a = double.tryParse(v['amp'].toString()) ?? 0;
                      }
                    }
                    if (w > maxW) maxW = w;
                    if (a > maxA) maxA = a;
                  });
                  spots.add(FlSpot(i.toDouble(), maxW));
                  historyList.add(EnergyData(hour: i, watt: maxW, amp: maxA));
                }
                
                if (historyList.isNotEmpty) {
                  latestWatt = historyList.last.watt.toStringAsFixed(2);
                  latestAmp  = historyList.last.amp.toStringAsFixed(2);
                  _latestHistoryWatt = historyList.last.watt;
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
                    : _navIndex == 1
                      ? HistoryList(
                          dates: availableDates,
                          selectedDate: _selectedDate,
                          onDateSelected: (date) {
                            setState(() {
                              _selectedDate = date;
                              _chartMode = ChartMode.daily;
                              _navIndex = 0; 
                            });
                          },
                        )
                      : InOutPage(
                          vin: vin,
                          iin: iin,
                          pin: pin,
                          vout: vout,
                          iout: iout,
                          pout: pout,
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
            dayView: _chartMode != ChartMode.weekly,
          ),
          const SizedBox(height: 14),
          InOutCard(
            vin: vin,
            iin: iin,
            pin: pin,
            vout: vout,
            iout: iout,
            pout: pout,
          ),
          const SizedBox(height: 14),
          TrendChart(
            spots: _chartMode == ChartMode.realtime ? _realtimeSpots : spots,
            weekLabels: weekLabels,
            realtimeLabels: _realtimeLabels,
            chartMode: _chartMode,
            onModeChanged: (mode) => setState(() => _chartMode = mode),
          ),
          const SizedBox(height: 14),
          ActivityLogs(
            list: historyList,
            weekLabels: weekLabels,
            dayView: _chartMode != ChartMode.weekly,
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}