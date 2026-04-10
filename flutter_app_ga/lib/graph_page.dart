import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:firebase_database/firebase_database.dart';

class WattGraphPage extends StatelessWidget {
  final DatabaseReference _historyRef = FirebaseDatabase.instance.ref('history');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("สถิติการใช้ไฟฟ้า (รายชั่วโมง)")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: StreamBuilder(
          stream: _historyRef.onValue,
          builder: (context, snapshot) {
            if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
              // แปลงข้อมูลจาก Firebase เป็น List สำหรับวาดกราฟ
              Map<dynamic, dynamic> data = snapshot.data!.snapshot.value as Map;
              List<FlSpot> spots = [];
              
              data.forEach((key, value) {
                // key คือชั่วโมง (0-23), value คือค่า Watt
                spots.add(FlSpot(double.parse(key.toString()), double.parse(value.toString())));
              });

              // เรียงลำดับข้อมูลตามชั่วโมง
              spots.sort((a, b) => a.x.compareTo(b.x));

              return LineChart(
                LineChartData(
                  gridData: FlGridData(show: true),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 30)),
                    leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40)),
                  ),
                  lineBarsData: [
                    LineChartPacket(spots: spots),
                  ],
                ),
              );
            }
            return const Center(child: CircularProgressIndicator());
          },
        ),
      ),
    );
  }
}

// ฟังก์ชันย่อยสำหรับสร้างเส้นกราฟ
LineChartBarData LineChartPacket({required List<FlSpot> spots}) {
  return LineChartBarData(
    spots: spots,
    isCurved: true,
    color: Colors.blue,
    barWidth: 4,
    dotData: FlDotData(show: true),
    belowBarData: BarAreaData(show: true, color: Colors.blue.withOpacity(0.2)),
  );
}