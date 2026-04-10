import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';

class WattDashboardPage extends StatefulWidget {
  const WattDashboardPage({Key? key}) : super(key: key);

  @override
  State<WattDashboardPage> createState() => _WattDashboardPageState();
}

class _WattDashboardPageState extends State<WattDashboardPage> {
  // เชื่อมต่อ Node history เป็นหลัก
  final DatabaseReference _historyRef = FirebaseDatabase.instance.ref('history');

  @override
  Widget build(BuildContext context) {
    // --- โทนสีตกแต่งใหม่ให้สวยงามพรีเมียม ---
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
          List<MapEntry<int, double>> logList = [];
          String latestWatt = "0.0";

          if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
            Map<dynamic, dynamic> data = snapshot.data!.snapshot.value as Map;
            
            // --- จัดการข้อมูลป้องกันเวลาซ้ำ ---
            Map<int, double> hourlyMap = {};
            data.forEach((key, value) {
              int hour = int.parse(key.toString());
              double watt = double.parse(value.toString());
              hourlyMap[hour] = watt;
            });

            // เตรียมข้อมูลสำหรับกราฟ (เรียงจากน้อยไปมาก)
            List<int> sortedHours = hourlyMap.keys.toList()..sort();
            for (var hour in sortedHours) {
              spots.add(FlSpot(hour.toDouble(), hourlyMap[hour]!));
            }

            // เตรียมข้อมูลสำหรับ Log ทั้งหมด (เรียงจากใหม่ไปเก่า)
            List<int> reverseHours = hourlyMap.keys.toList()..sort((a, b) => b.compareTo(a));
            for (var hour in reverseHours) {
              logList.add(MapEntry(hour, hourlyMap[hour]!));
            }

            // ดึงค่าล่าสุด (ชั่วโมงที่มากที่สุด) มาแสดงตัวใหญ่
            if (spots.isNotEmpty) {
              latestWatt = spots.last.y.toStringAsFixed(1);
            }
          }

          // ใช้ Column เพื่อแยกส่วนที่อยู่กับที่ (กราฟ) และส่วนที่เลื่อนได้ (Log)
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- 1. ส่วนกราฟ (คงเดิมแต่ปรับขนาด Compact ให้สวยขึ้น) ---
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: purpleBg,
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.purple.withOpacity(0.08),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      )
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
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(color: Colors.white.withOpacity(0.5), shape: BoxShape.circle),
                            child: const Icon(Icons.bolt_rounded, color: Colors.black, size: 24),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // ตัวเลข Watt ล่าสุดที่ดึงจากประวัติ
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)],
                        ),
                        child: Text("$latestWatt Watt",
                            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.black)),
                      ),
                      const SizedBox(height: 18),
                      // กราฟแบบ Smooth พร้อมจุดพิกัด
                      SizedBox(
                        height: 140, // ปรับให้เล็กลงเพื่อให้เปิดมาเจอ Log ทันที
                        child: LineChart(
                          LineChartData(
                            gridData: FlGridData(
                              show: true,
                              drawVerticalLine: false,
                              horizontalInterval: 100,
                              getDrawingHorizontalLine: (value) => FlLine(
                                color: Colors.black.withOpacity(0.03),
                                strokeWidth: 1,
                              ),
                            ),
                            borderData: FlBorderData(show: false),
                            titlesData: FlTitlesData(
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  interval: 1, 
                                  getTitlesWidget: (v, m) => Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: Text("${v.toInt()}:00", 
                                        style: const TextStyle(color: Colors.black38, fontSize: 9, fontWeight: FontWeight.bold)),
                                  ),
                                ),
                              ),
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 40,
                                  getTitlesWidget: (v, m) => Text("${v.toInt()}W", 
                                      style: const TextStyle(color: Colors.black38, fontSize: 9, fontWeight: FontWeight.bold)),
                                ),
                              ),
                              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            ),
                            minY: 0,
                            maxY: spots.isEmpty ? 200 : (spots.map((e) => e.y).reduce((a, b) => a > b ? a : b) / 100).ceil() * 100 + 100,
                            lineBarsData: [
                              LineChartBarData(
                                spots: spots,
                                isCurved: true,
                                color: chartLineColor, 
                                barWidth: 3.5,
                                isStrokeCapRound: true,
                                dotData: FlDotData(
                                  show: true,
                                  getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                                    radius: 4,
                                    color: Colors.white,
                                    strokeWidth: 2.5,
                                    strokeColor: chartLineColor,
                                  ),
                                ),
                                belowBarData: BarAreaData(
                                  show: true, 
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [chartLineColor.withOpacity(0.1), chartLineColor.withOpacity(0.0)],
                                  ),
                                ),
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
                child: Text("Hourly Logs History", 
                    style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
              ),

              // --- 2. ส่วนกรอบประวัติ (เลื่อนแยกเฉพาะในกรอบนี้) ---
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: Colors.grey.shade100),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.02),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        )
                      ],
                    ),
                    child: logList.isEmpty
                        ? const Center(child: Text("Waiting for data...", style: TextStyle(color: Colors.grey)))
                        : ClipRRect( 
                            borderRadius: BorderRadius.circular(28),
                            child: ListView.separated(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              itemCount: logList.length,
                              separatorBuilder: (context, index) => Divider(color: Colors.grey.shade50, indent: 70),
                              itemBuilder: (context, index) {
                                return _buildLogTile(logList[index].key, logList[index].value, accentColor);
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

  // Widget สำหรับแต่ละแถวในรายการประวัติ
  Widget _buildLogTile(int hour, double watt, Color accent) {
    String dateStr = DateFormat('dd MMM yyyy').format(DateTime.now());
    String timeStr = "${hour.toString().padLeft(2, '0')}:00";

    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: accent.withOpacity(0.08), shape: BoxShape.circle),
        child: Icon(Icons.history_rounded, color: accent, size: 22),
      ),
      title: Text(timeStr, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF334155))),
      subtitle: Text(dateStr, style: const TextStyle(fontSize: 12, color: Colors.black26)), 
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text(watt.toStringAsFixed(1),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF1E293B))),
          const SizedBox(width: 4),
          const Text("W", style: TextStyle(fontSize: 12, color: Colors.black26, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}