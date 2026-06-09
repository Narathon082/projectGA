# บทที่ 3 วิธีดำเนินการวิจัย (Methodology)
## ส่วนการออกแบบและพัฒนาส่วนติดต่อผู้ใช้งาน (User Interface Design and Development)

การพัฒนาส่วนติดต่อผู้ใช้งาน (User Interface: UI) ของแอพพลิเคชัน **Watt Monitor** (ระบบติดตามค่ากำลังไฟฟ้าและกระแสไฟฟ้าแบบเรียลไทม์) พัฒนาขึ้นด้วยเฟรมเวิร์ก Flutter (ภาษา Dart) โดยเน้นสถาปัตยกรรมแบบคอมโพเนนต์ (Component-based Architecture) ที่แบ่งหน้าจอและวิดเจ็ตออกเป็นส่วนย่อย ๆ เพื่อความสะดวกในการบำรุงรักษาและการนำกลับมาใช้ใหม่ (Reusable Widgets)

---

### 3.1 โครงสร้างและการจัดวางหน้าจอหลัก (Main Screen Architecture)

โครงสร้างหน้าจอถูกควบคุมโดยคลาส [WattDashboardPage](file:///c:/ProjectFlutter/projectGA/flutter_app_ga/lib/graph_page.dart) ซึ่งเป็น `StatefulWidget` ทำหน้าที่เป็นผู้ประสานงานหลักในการจัดโครงสร้างหน้าและการสลับมุมมองระหว่าง **หน้าหลัก (Dashboard)** และ **หน้าประวัติ (History List)** โดยใช้โครงร่างโครงสร้างแบบชั้น (Layered Layout) ร่วมกับ `Scaffold` ดังนี้:

1. **ส่วนบน (TopBar)**: แสดงโลโก้ ชื่อแอพพลิเคชัน (Energy Monitor) และปุ่มเปลี่ยนโหมดกลางคืน (Dark Mode Toggle)
2. **ส่วนกลาง (Body)**: เปลี่ยนมุมมองตามแท็บนำทางที่เลือก (Navigation Index):
   * **Dashboard View**: แสดงแผงควบคุมหลัก ได้แก่ การ์ดกำลังไฟฟ้าแบบเรียลไทม์ กราฟเส้นแนวโน้มการใช้ไฟ และตารางประวัติกิจกรรมชั่วโมงต่อชั่วโมง
   * **History View**: แสดงรายการประวัติวันที่สามารถเลือกดูย้อนหลังได้ โดยดึงข้อมูลจาก Firebase Realtime Database
3. **ส่วนล่าง (BottomNav)**: แถบนำทางด้านล่างสำหรับการสลับมุมมองระหว่าง หน้าหลัก (หน้าแรก) และ ประวัติ

---

### 3.2 รายละเอียดการทำงานและการเชื่อมต่อส่วนเก็บข้อมูลหลัก (Core Integration)

#### 3.2.1 การเริ่มต้นระบบและการเชื่อมต่อ Firebase (Firebase Initialization)
แอพพลิเคชันจะเริ่มต้นสถาปัตยกรรมผ่านฟังก์ชันหลัก `main()` ในไฟล์ [main.dart](file:///c:/ProjectFlutter/projectGA/flutter_app_ga/lib/main.dart) โดยทำการเริ่มต้นการเชื่อมต่อแบบอะซิงโครนัส (Asynchronous) เข้ากับ Firebase เพื่อเตรียมความพร้อมสำหรับการทำ Data Streaming:

```dart
// โค้ดส่วนการเริ่มต้นระบบและการเชื่อมต่อกับ Firebase (main.dart)
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}
```

#### 3.2.2 การดึงข้อมูลและเชื่อมโยงข้อมูลแบบเรียลไทม์ (Firebase Realtime Stream Integration)
ระบบใช้โครงสร้าง `StreamBuilder` ในคลาส [WattDashboardPage](file:///c:/ProjectFlutter/projectGA/flutter_app_ga/lib/graph_page.dart) เพื่อสมัครรับข้อมูล (Subscribe) จากตำแหน่ง `history` บน Firebase Realtime Database ทำให้หน้าจอแอพพลิเคชันสามารถรีเรนเดอร์ตัวเองใหม่โดยอัตโนมัติทันทีที่มีการเปลี่ยนแปลงข้อมูลจากฝั่งฮาร์ดแวร์:

```dart
// โค้ดส่วนดึงข้อมูลประวัติและค่าเรียลไทม์จาก Firebase Realtime Database (graph_page.dart)
class _WattDashboardPageState extends State<WattDashboardPage> {
  // การกำหนดตำแหน่งอ้างอิงของโฟลเดอร์ใน Database
  final DatabaseReference _historyRef = FirebaseDatabase.instance.ref('history');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: StreamBuilder(
          stream: _historyRef.onValue, // เชื่อมโยง Stream จาก Firebase
          builder: (context, snapshot) {
            // เมื่อได้รับข้อมูลจาก Firebase สำเร็จ
            if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
              final raw = snapshot.data!.snapshot.value as Map;
              
              // ดึงคีย์ข้อมูลวันที่ทั้งหมดเพื่อแสดงผลในรายการประวัติ
              availableDates = raw.keys.map((e) => e.toString()).toList();
              availableDates.sort((a, b) => b.compareTo(a)); // เรียงลำดับวันล่าสุดขึ้นก่อน
              
              // ... ขั้นตอนการคำนวณและแปลงค่ากำลังไฟฟ้าเพื่อส่งต่อไปยัง Widget อื่น ๆ ...
            }
            // ...
          },
        ),
      ),
    );
  }
}
```

---

### 3.3 รายละเอียดการออกแบบและโครงสร้างโค้ดของวิดเจ็ตย่อย (UI Component Breakdown)

#### 3.3.1 [TopBar (แถบเมนูด้านบน)](file:///c:/ProjectFlutter/projectGA/flutter_app_ga/lib/widgets/top_bar.dart)
ทำหน้าที่แสดงชื่อระบบและสลับสถานะสีธีมผ่านตัวแปร `onToggleTheme` ที่เชื่อมกับสถานะหน้าจอหลัก

#### 3.3.2 [PowerCard (การ์ดแสดงผลค่ากำลังไฟฟ้าหลัก)](file:///c:/ProjectFlutter/projectGA/flutter_app_ga/lib/widgets/power_card.dart)
แสดงค่ากำลังไฟฟ้าหลัก (วัตต์ และ แอมป์) พร้อมระบบแปลงรูปแบบการแสดงผลวันที่ที่กำลังถูกดึงข้อมูลจากค่าเริ่มต้นของเซสชันหรือค่าที่ดึงมาจากฐานข้อมูล:

```dart
// โค้ดส่วนการรับข้อมูลและแปลงแสดงผลการ์ดหลัก (power_card.dart)
class PowerCard extends StatelessWidget {
  final String watt;
  final String amp;
  final String dateStr; // รับค่าวันที่ในรูปแบบ YYYY-MM-DD
  final bool dayView;

  // ...

  @override
  Widget build(BuildContext context) {
    // การแปลงรูปแบบวันที่ YYYY-MM-DD ให้เป็นสากล D/M/Y
    final parts = dateStr.split('-');
    final formattedDate = parts.length == 3 ? '${parts[2]}/${parts[1]}/${parts[0]}' : dateStr;

    return Container(
      // ... การกำหนดสไตล์โครงสร้างการจัดวาง ...
      child: Column(
        children: [
          Text(
            dayView ? formattedDate : 'Last 7 Days', // แสดงวันที่ในฟอร์แมต D/M/Y ที่แปลงแล้ว
            style: TextStyle(fontSize: 11, color: AppColors.textMuted),
          ),
          // ... แสดงค่ากำลังไฟฟ้าและกระแสไฟฟ้า ...
        ],
      ),
    );
  }
}
```

#### 3.3.3 [TrendChart (กราฟแนวโน้มแสดงผลการใช้พลังงาน)](file:///c:/ProjectFlutter/projectGA/flutter_app_ga/lib/widgets/trend_chart.dart)
ใช้โมดูลกราฟของ `fl_chart` ในการแสดงแนวโน้มแบบเส้นเชื่อมความหนา `3.5` และใช้โครงร่างความโปร่งใสแบบไล่โทนสี (Gradient) แสดงผลข้อมูลได้ทั้งแบบ Day (ข้อมูลประชากรชั่วโมงต่อชั่วโมง) และ Week (ข้อมูลประชากรแบบ 7 วันล่าสุด)

#### 3.3.4 [ActivityLogs (ส่วนแสดงประวัติกิจกรรมเชิงลึก)](file:///c:/ProjectFlutter/projectGA/flutter_app_ga/lib/widgets/activity_logs.dart)
มีลอจิกแปลงรูปแบบช่วงวันที่ในการแสดงบันทึกแบบแถวรายการย้อนหลังหากมองผ่านมุมมองรายสัปดาห์:

```dart
// โค้ดส่วนแยกการจัดแสดงผลวันที่กิจกรรมรายวัน (activity_logs.dart)
if (dayView) {
  subStr = '${data.hour.toString().padLeft(2, '0')}:00';
} else {
  final idx = data.hour;
  if (idx >= 0 && idx < weekLabels.length) {
    final parts = weekLabels[idx].split('-');
    // แปลงรูปแบบคีย์ฐานข้อมูล YYYY-MM-DD ในแต่ละจุดแกนข้อมูลให้ออกเป็น D/M/Y
    subStr = parts.length == 3 ? '${parts[2]}/${parts[1]}/${parts[0]}' : weekLabels[idx];
  }
}
```

#### 3.3.5 [HistoryList (ส่วนรายการประวัติการตรวจสอบย้อนหลัง)](file:///c:/ProjectFlutter/projectGA/flutter_app_ga/lib/widgets/history_list.dart)
แสดงรายการคีย์ประวัติวันที่ที่นำมาเรียงเป็นปุ่มกด โดยลอจิกการแปลงรูปแบบจะแปลงก่อนส่งเข้าวาดข้อความเพื่อความสะดวกของมนุษย์ และส่งคีย์ดั้งเดิมกลับไปประมวลผลผ่าน `onDateSelected`:

```dart
// โค้ดส่วนแสดงผลรายการประวัติย้อนหลัง (history_list.dart)
class HistoryList extends StatelessWidget {
  final List<String> dates;
  final String? selectedDate;
  final ValueChanged<String> onDateSelected;

  // ...

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: dates.length,
      itemBuilder: (context, i) {
        final date = dates[i];
        final isSelected = date == (selectedDate ?? (dates.isNotEmpty ? dates.first : ''));
        
        // แยกส่วนคีย์ความปลอดภัย YYYY-MM-DD ออกเป็น D/M/Y
        final parts = date.split('-');
        final formattedDate = parts.length == 3 ? '${parts[2]}/${parts[1]}/${parts[0]}' : date;

        return GestureDetector(
          onTap: () => onDateSelected(date), // ส่งคีย์ดั้งเดิม YYYY-MM-DD กลับไปคิวรี Firebase
          child: Container(
            // ...
            child: Text(
              formattedDate, // แสดงผลวันที่ในหน้าจอเป็น D/M/Y 
              style: TextStyle(
                // ...
              ),
            ),
          ),
        );
      },
    );
  }
}
```
