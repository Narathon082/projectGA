import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';

// สร้าง Class เพื่อเก็บข้อมูลคู่กัน
class EnergyData {
  final int hour;
  final double watt;
  final double amp;

  EnergyData({required this.hour, required this.watt, required this.amp});
}

class WattDashboardPage extends StatefulWidget {
  const WattDashboardPage({Key? key}) : super(key: key);

  @override
  State<WattDashboardPage> createState() => _WattDashboardPageState();
}

class _WattDashboardPageState extends State<WattDashboardPage> {
  final DatabaseReference _historyRef = FirebaseDatabase.instance.ref('history');

  @override
  Widget build(BuildContext context) {
    const Color purpleBg = Color(0xFFE6E0F8); 
    const Color chartLineColor = Color(0xFF1A1A1A);
    const Color scaffoldBg = Color(0xFFFDFDFD);
    const Color accentColor = Color(0xFF6366F1);

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        title: const Text("Energy Monitor",
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: scaffoldBg,
        elevation: 0,
        centerTitle: true,
      ),
      body: StreamBuilder(
        stream: _historyRef.onValue,
        builder: (context, snapshot) {
          List<FlSpot> spots = [];
          List<EnergyData> historyList = []; // ใช้ Class ใหม่เก็บข้อมูล
          String latestWatt = "0.0";

          if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
            Map<dynamic, dynamic> data = snapshot.data!.snapshot.value as Map;
            
            data.forEach((key, value) {
              int hour = int.parse(key.toString());
              double w = 0.0;
              double a = 0.0;

              // เช็กว่าข้อมูลเป็น Map (เก็บหลายค่า) หรือเป็นตัวเลข (เก็บค่าเดียวแบบเก่า)
              if (value is Map) {
                w = double.tryParse(value['watt'].toString()) ?? 0.0;
                a = double.tryParse(value['amp'].toString()) ?? 0.0;
              } else {
                w = double.tryParse(value.toString()) ?? 0.0;
              }

              historyList.add(EnergyData(hour: hour, watt: w, amp: a));
            });

            // เรียงลำดับเวลาสำหรับกราฟ (น้อยไปมาก)
            historyList.sort((a, b) => a.hour.compareTo(b.hour));
            for (var item in historyList) {
              spots.add(FlSpot(item.hour.toDouble(), item.watt));
            }

            // ดึงค่าล่าสุดมาแสดงตัวใหญ่
            if (historyList.isNotEmpty) {
              latestWatt = historyList.last.watt.toStringAsFixed(1);
            }

            // กลับด้านรายการสำหรับ Log (ใหม่ไปเก่า)
            historyList = historyList.reversed.toList();
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- 1. ส่วนกราฟ (โชว์เฉพาะ Watt) ---
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: purpleBg,
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [
                      BoxShadow(color: Colors.purple.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, 10))
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("Current Power",
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black54)),
                              Text(DateFormat('EEEE, d MMMM').format(DateTime.now()),
                                  style: const TextStyle(fontSize: 12, color: Colors.black38)),
                            ],
                          ),
                          const Icon(Icons.bolt_rounded, color: Colors.black, size: 24),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                        child: Text("$latestWatt Watt",
                            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.black)),
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        height: 140,
                        child: LineChart(
                          LineChartData(
                            gridData: FlGridData(show: true, drawVerticalLine: false, horizontalInterval: 100),
                            borderData: FlBorderData(show: false),
                            titlesData: FlTitlesData(
                              bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, interval: 1, getTitlesWidget: (v, m) => Text("${v.toInt()}:00", style: const TextStyle(color: Colors.black38, fontSize: 9)))),
                              leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40, getTitlesWidget: (v, m) => Text("${v.toInt()}W", style: const TextStyle(color: Colors.black38, fontSize: 9)))),
                              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            ),
                            lineBarsData: [
                              LineChartBarData(
                                spots: spots,
                                isCurved: true,
                                color: chartLineColor, 
                                barWidth: 3.5,
                                dotData: FlDotData(show: true),
                                belowBarData: BarAreaData(show: true, color: chartLineColor.withOpacity(0.05)),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 28.0, vertical: 8),
                child: Text("Hourly Logs History", style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
              ),

              // --- 2. ส่วนกรอบประวัติ (แสดงทั้ง Watt และ Amp) ---
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: Colors.grey.shade100),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 15, offset: const Offset(0, 5))],
                    ),
                    child: historyList.isEmpty
                        ? const Center(child: Text("Waiting for data..."))
                        : ClipRRect( 
                            borderRadius: BorderRadius.circular(28),
                            child: ListView.separated(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              itemCount: historyList.length,
                              separatorBuilder: (context, index) => Divider(color: Colors.grey.shade50, indent: 70),
                              itemBuilder: (context, index) {
                                return _buildLogTile(historyList[index], accentColor);
                              },
                            ),
                          ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLogTile(EnergyData data, Color accent) {
    String dateStr = DateFormat('dd MMM yyyy').format(DateTime.now());
    String timeStr = "${data.hour.toString().padLeft(2, '0')}:00";

    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: accent.withOpacity(0.08), shape: BoxShape.circle),
        child: Icon(Icons.history_rounded, color: accent, size: 22),
      ),
      title: Text(timeStr, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF334155))),
      subtitle: Text(dateStr, style: const TextStyle(fontSize: 12, color: Colors.black26)), 
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // แสดงค่า Watt
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(data.watt.toStringAsFixed(1), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1E293B))),
              const SizedBox(width: 4),
              const Text("W", style: TextStyle(fontSize: 10, color: Colors.black26, fontWeight: FontWeight.bold)),
            ],
          ),
          // แสดงค่า Amp เพิ่มเติม (ตัวเล็กกว่า)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(data.amp.toStringAsFixed(2), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.blueGrey)),
              const SizedBox(width: 4),
              const Text("A", style: TextStyle(fontSize: 10, color: Colors.black26, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }
}