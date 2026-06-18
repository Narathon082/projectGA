# Watt Monitor (Flutter Application) - คู่มืออธิบายโค้ดและโครงสร้างอย่างละเอียด 📱⚡

เอกสารฉบับนี้จัดทำขึ้นเพื่อแสดงโครงสร้างไฟล์, รายละเอียดสถาปัตยกรรมของแอปพลิเคชัน, โค้ดส่วนหลักที่สำคัญต่อระบบ (Key Code Snippets) และวิธีการอ้างอิงข้อมูลผ่าน Firebase Realtime Database ของแอปพลิเคชันมอนิเตอร์พลังงานไฟฟ้า

---

## 📂 โครงสร้างและส่วนประกอบของโปรเจกต์ (Project Architecture)

โค้ดทั้งหมดที่ใช้ในการขับเคลื่อนแอปพลิเคชันจะอยู่ในโฟลเดอร์ `lib/` โดยมีการจัดระเบียบองค์ประกอบต่าง ๆ ออกเป็น 3 ส่วนหลัก:
1. **หน้าการทำงานหลัก (Pages)**: สำหรับควบคุมสถานะ ข้อมูล และการนำทางหลัก
2. **วิดเจ็ตแสดงผลเฉพาะส่วน (Widgets)**: UI Component ที่ยืดหยุ่นและนำมาประกอบในแดชบอร์ด
3. **การตั้งค่าและโมเดลข้อมูล (Constants & Models)**: ข้อมูลคงที่ ชุดสี และโมเดลสำหรับแปลงข้อมูลจาก Firebase

---

## 🔑 ไฟล์หลักและโค้ดที่สำคัญ (Key Code Snippets)

### 1. จุดเริ่มต้นแอปพลิเคชันและการเชื่อมต่อ Firebase
*   **ไฟล์:** `lib/main.dart`
*   **คำอธิบาย:** ทำการโหลดวิดเจ็ตเพื่อเตรียมความพร้อมสำหรับ Framework และตั้งค่าระบบเริ่มต้นเพื่อเชื่อมต่อกับ Firebase Realtime Database ก่อนทำการรันแอปพลิเคชันหลัก
*   **โค้ดที่สำคัญ:**
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // เริ่มต้นตั้งค่า Firebase ร่วมกับ Option ของ Platform ปัจจุบัน
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Watt Monitor',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF4040C0)),
        useMaterial3: true,
      ),
      home: const WattDashboardPage(), // รันหน้าแดชบอร์ดหลักเป็นหน้าแรก
    );
  }
}
```

---

### 2. การดึงข้อมูลแบบ Real-time จาก Firebase Database
*   **ไฟล์:** `lib/graph_page.dart`
*   **คำอธิบาย:** ระบบจะทำการเปิด `StreamSubscription` ไปยังโหนด `realtime` บน Firebase เพื่อคอยดึงข้อมูลแรงดันไฟฟ้า (V), กระแสไฟฟ้า (A), และกำลังวัตต์ (W) ล่าสุดมาอัปเดตลงในตัวแปร State และพล็อตลงในลิสต์สำหรับการทำกราฟเลื่อนไหลเรียลไทม์
*   **โค้ดที่สำคัญ:**
```dart
// คอยดึงข้อมูลแบบ Stream จากโหนด 'realtime'
void _setupRealtimeData() {
  _realtimeSubscription = FirebaseDatabase.instance.ref('realtime').onValue.listen((event) {
    if (event.snapshot.value != null) {
      final data = _convertToMap(event.snapshot.value);
      setState(() {
        // แปลงและรับค่าไฟฝั่งขาเข้า (Solar Input)
        vin = double.tryParse(data['vin']?.toString() ?? '0') ?? 0.0;
        iin = double.tryParse(data['iin']?.toString() ?? '0') ?? 0.0;
        pin = double.tryParse(data['pin']?.toString() ?? '0') ?? 0.0;

        // แปลงและรับค่าไฟฝั่งขาออก (Battery Output)
        vout = double.tryParse(data['vout']?.toString() ?? '0') ?? 0.0;
        iout = double.tryParse(data['iout']?.toString() ?? '0') ?? 0.0;
        pout = double.tryParse(data['pout']?.toString() ?? '0') ?? 0.0;

        // นำค่ากำลังไฟขาออกล่าสุดไปพล็อตลงในกราฟเส้น Real-time
        _addRealtimePoint(pout);
      });
    }
  });
}

// ฟังก์ชันเพิ่มจุดในกราฟเรียลไทม์จำกัดจำนวนที่ _maxRealtimePoints (12 จุดล่าสุด)
void _addRealtimePoint(double wattValue) {
  _realtimeSpots.add(FlSpot(_realtimeSpots.length.toDouble(), wattValue));
  final nowStr = DateFormat('HH:mm:ss').format(DateTime.now());
  _realtimeLabels.add(nowStr);
  
  if (_realtimeSpots.length > _maxRealtimePoints) {
    _realtimeSpots.removeAt(0);
    _realtimeLabels.removeAt(0);
    // ปรับดัชนีแกน X ใหม่ให้เริ่มต้นเรียงลำดับจาก 0 เสมอ
    for (int i = 0; i < _realtimeSpots.length; i++) {
      _realtimeSpots[i] = FlSpot(i.toDouble(), _realtimeSpots[i].y);
    }
  }
}
```

---

### 3. การวิเคราะห์สถานะการชาร์จแบตเตอรี่และประสิทธิภาพพลังงาน
*   **ไฟล์:** `lib/in_out_page.dart`
*   **คำอธิบาย:** ส่วนประมวลผลประสิทธิภาพการประจุไฟฟ้า (Charging Efficiency) คำนวณจากสูตร: `(P_out / P_in) * 100` พร้อมทั้งคำนวณปริมาณกำลังไฟฟ้าที่สูญเสียในระบบ (Loss) และคัดแยกโหมดการชาร์จของเครื่องควบคุมประจุ (Solar Charge Controller)
*   **โค้ดที่สำคัญ:**
```dart
// คำนวณหาประสิทธิภาพพลังงานและกำลังไฟสูญเสีย
final double efficiency = pin > 0 ? (pout / pin) * 100 : 0.0;
final double loss = pin > pout ? pin - pout : 0.0;
final double constrainedEfficiency = efficiency.clamp(0.0, 100.0);

// วิเคราะห์โหมดการทำงานจำลองตามประสิทธิภาพการชาร์จ
String chargingStatus = 'ระบบไม่ทำงาน';
Color statusColor = AppColors.textMuted;
IconData statusIcon = Icons.stop_circle_rounded;

if (pin > 0.5) {
  if (efficiency > 90) {
    chargingStatus = 'กำลังชาร์จประสิทธิภาพสูง (Bulk)'; // แรงดันต่ำ ชาร์จกระแสสูงสุด
    statusColor = Colors.green;
    statusIcon = Icons.bolt_rounded;
  } else if (efficiency > 70) {
    chargingStatus = 'กำลังชาร์จปกติ (Absorption)';  // แรงดันคงที่ กระแสเริ่มลดลง
    statusColor = AppColors.primary;
    statusIcon = Icons.battery_charging_full_rounded;
  } else {
    chargingStatus = 'ประคองประจุชาร์จ (Float)';      // ประคองแรงดันแบตเตอรี่เต็ม
    statusColor = Colors.amber;
    statusIcon = Icons.battery_saver_rounded;
  }
}
```

---

### 4. การจัดการพล็อตกราฟเส้นแนวโน้มพลังงานไฟฟ้า
*   **ไฟล์:** `lib/widgets/trend_chart.dart`
*   **คำอธิบาย:** จัดแต่งองค์ประกอบของกราฟเส้นโดยใช้แพ็กเกจ `fl_chart` โดยจะทำการคำนวณสเกลระยะห่างแกน Y (Interval) โดยอัตโนมัติตามระดับค่าไฟวัตต์สูงสุด เพื่อป้องกันสเกลกราฟทับซ้อนกัน และพ่นสีไล่เฉด (Gradient) ใต้เส้นกราฟให้ดูสวยงาม
*   **โค้ดที่สำคัญ:**
```dart
LineChartData _buildLineChartData() {
  double maxWatt = 0;
  for (var spot in spots) {
    if (spot.y > maxWatt) maxWatt = spot.y;
  }
  final maxY = maxWatt == 0 ? 10.0 : maxWatt * 1.25; // สำรองพื้นที่ด้านบนกราฟ 25%

  // คำนวณหาระยะความห่างของแกน Y อัตโนมัติ (Dynamic Y-Interval)
  double yInterval = maxY / 4;
  if (yInterval <= 0) {
    yInterval = 10;
  } else if (yInterval <= 20) {
    yInterval = 10;
  } else if (yInterval <= 50) {
    yInterval = 25;
  } else {
    yInterval = (yInterval / 100).ceil() * 100.0;
  }

  return LineChartData(
    maxY: maxY,
    minY: 0,
    minX: 0,
    // ... ตั้งค่า Titles ด้านล่างและด้านซ้าย ...
    lineBarsData: [
      LineChartBarData(
        spots: spots,
        isCurved: chartMode != ChartMode.realtime, // เส้นโค้งใน Daily/Weekly, เส้นตรงใน Real-time
        curveSmoothness: 0.35,
        gradient: const LinearGradient(
          colors: [Color(0xFF8C88FF), Color(0xFF4040C0)], // ไล่โทนสีเส้นกราฟ
        ),
        barWidth: 3.0,
        isStrokeCapRound: true,
        dotData: FlDotData(
          show: true,
          getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
            radius: 3.0,
            color: Colors.white,
            strokeWidth: 2.0,
            strokeColor: AppColors.primary,
          ),
        ),
        belowBarData: BarAreaData(
          show: true,
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.primary.withOpacity(0.25),
              AppColors.primary.withOpacity(0.0), // ไล่เฉดโปร่งใสลงล่างกราฟ
            ],
          ),
        ),
      ),
    ],
  );
}
```

---

### 5. การสลับธีมสีของแอปพลิเคชัน (Light/Dark Theme)
*   **ไฟล์:** `lib/constants/app_colors.dart`
*   **คำอธิบาย:** จัดเก็บพารามิเตอร์คงที่ของสีแบบ Getter เพื่อให้ Widget ต่างๆ สามารถดึงสีไปแสดงผลตามสถานะของโหมดหน้าจอ (`isDark`) ได้อย่างทันท่วงที
*   **โค้ดที่สำคัญ:**
```dart
class AppColors {
  // ค่าสถานะธีมเริ่มต้น
  static bool isDark = false;

  // เมธอดดึงสีพื้นหลังและสีอักษรที่จะสลับตามสถานะ isDark อัตโนมัติ
  static Color get bg         => isDark ? const Color(0xFF121212) : const Color(0xFFEEEEFF);
  static Color get surface    => isDark ? const Color(0xFF1E1E1E) : const Color(0xFFFFFFFF);
  static Color get cardBorder => isDark ? const Color(0xFF333333) : const Color(0xFFE0E0F0);
  static Color get primary    => isDark ? const Color(0xFF8C88FF) : const Color(0xFF4040C0);
  static Color get textDark   => isDark ? const Color(0xFFE0E0E0) : const Color(0xFF1A1A50);
  static Color get textMuted  => isDark ? const Color(0xFF888888) : const Color(0xFF9090B0);
  static Color get textSub    => isDark ? const Color(0xFFAAAAAA) : const Color(0xFF6060A0);
}
```

---

## 🔌 การบูรณาการโครงสร้างข้อมูล Firebase JSON

ข้อมูลเรียลไทม์และข้อมูลประวัติย้อนหลังจะถูกผูกโยงเข้ากับฐานข้อมูลตามรูปแบบโครงสร้างนี้ เพื่อให้โค้ดสามารถพาร์สข้อมูลคีย์ต่าง ๆ ได้อย่างถูกต้อง:

*   **เรียลไทม์ (`/realtime`):**
    ```json
    {
      "vin": 19.2,   // แรงดันแผงโซลาร์
      "iin": 2.45,   // กระแสแผงโซลาร์
      "pin": 47.04,  // วัตต์แผงโซลาร์
      "vout": 13.8,  // แรงดันแบตเตอรี่
      "iout": 3.12,  // กระแสชาร์จแบตเตอรี่
      "pout": 43.05  // วัตต์ชาร์จแบตเตอรี่
    }
    ```
*   **ข้อมูลประวัติย้อนหลังรายชั่วโมง (`/history/YYYY-MM-DD/HH`):**
    ```json
    {
      "2026-06-18": {
        "8": { "watt": 35.5, "amp": 2.6 },
        "9": { "watt": 42.1, "amp": 3.0 }
      }
    }
    ```

---

## ⚙️ ขั้นตอนการรันและการปรับปรุง
1. เชื่อมต่ออุปกรณ์หรือเปิด Emulator ของ Android/iOS
2. รันคำสั่ง `flutter pub get` เพื่อติดตั้งไลบรารี
3. รันคำสั่ง `flutter run` เพื่อทำการบิลด์และทดสอบตัวแอปฯ บนเครื่องจำลองหรือโทรศัพท์จริง
