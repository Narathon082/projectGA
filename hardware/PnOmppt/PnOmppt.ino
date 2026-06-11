#include <Arduino.h>
#include <WiFi.h>
#include <HTTPClient.h>
#include <time.h>

// --- Configuration Hardware ---
const int PWM_PIN = 12;
const int OUT_CURR_PIN = 26;

// --- Wi-Fi & Firebase Configuration (ที่เพิ่มเข้ามา) ---
const char* WIFI_SSID = "YOUR_WIFI_SSID";          // ใส่ชื่อ Wi-Fi ของคุณ
const char* WIFI_PASSWORD = "YOUR_WIFI_PASSWORD";  // ใส่รหัสผ่าน Wi-Fi ของคุณ
const char* FIREBASE_HOST = "https://projectga-d3f20-default-rtdb.asia-southeast1.firebasedatabase.app";

// --- NTP Time Server (ที่เพิ่มเข้ามา) ---
const char* ntpServer = "pool.ntp.org";
const long  gmtOffset_sec = 7 * 3600; // GMT+7 สำหรับประเทศไทย
const int   daylightOffset_sec = 0;   // ไม่มี Daylight Saving ในไทย

// --- P&O Parameters ---
int currentDuty = 512;      // เริ่มต้นที่ 50%
const int deltaDuty = 5;    // ขนาดการขยับแต่ละก้าว (Step Size)
float lastPower = 0;        // พลังงานในก้าวก่อนหน้า

float offsetOut;
const float sensitivity = 0.0622;
const float vBat = 18;

// --- Step Counting & Adjustable Delay ---
unsigned long mpptStepCount = 0;     // นับว่า P&O ทำงานไปกี่ก้าวแล้ว
unsigned int loopCounter = 0;        // ตัวนับรอบใน loop() 
unsigned int stepDelayMs = 1000;     // ค่าเริ่มต้น: 1000 ms (1 วินาที) ต่อ 1 ก้าว
unsigned int loopsPerStep = stepDelayMs / 10; // คำนวณจำนวนรอบ (เพราะ loop ดีเลย์รอบละ 10ms)

// --- System State ---
bool isRunning = false; // เริ่มต้นให้หยุดรอก่อน

// --- ฟังก์ชันที่เพิ่มเข้ามาสำหรับจัดการ Wi-Fi, NTP และ Firebase ---
void connectWiFiAndNTP() {
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  Serial.print("Connecting to Wi-Fi");
  int wifiTimeout = 0;
  while (WiFi.status() != WL_CONNECTED && wifiTimeout < 20) { // รอสูงสุด 10 วินาที
    delay(500);
    Serial.print(".");
    wifiTimeout++;
  }
  
  if (WiFi.status() == WL_CONNECTED) {
    Serial.println("\n[Wi-Fi] Connected successfully!");
    Serial.print("[Wi-Fi] IP Address: ");
    Serial.println(WiFi.localIP());
    
    // ตั้งค่าเวลา NTP
    configTime(gmtOffset_sec, daylightOffset_sec, ntpServer);
    Serial.println("[NTP] Time synchronized.");
  } else {
    Serial.println("\n[Wi-Fi] Connection failed. Operating in offline mode.");
  }
}

void sendDataToFirebase(float power, float current) {
  if (WiFi.status() == WL_CONNECTED) {
    struct tm timeinfo;
    if (getLocalTime(&timeinfo)) {
      char dateStr[12];
      strftime(dateStr, sizeof(dateStr), "%Y-%m-%d", &timeinfo);
      int currentHour = timeinfo.tm_hour;

      HTTPClient http;
      // สร้าง URL: /history/<date>/<hour>.json
      String url = String(FIREBASE_HOST) + "/history/" + String(dateStr) + "/" + String(currentHour) + ".json";
      
      http.begin(url);
      http.addHeader("Content-Type", "application/json");

      // สร้าง JSON Body สำหรับส่ง
      String jsonPayload = "{\"watt\":" + String(power, 2) + ",\"amp\":" + String(current, 2) + "}";

      // ส่งข้อมูลแบบ PATCH (จะปรับปรุงข้อมูล watt และ amp ที่ชั่วโมงนั้นๆ เสมอ)
      int httpResponseCode = http.PATCH(jsonPayload);
      
      if (httpResponseCode > 0) {
        Serial.printf("[Firebase] Send Success (HTTP %d): %s\n", httpResponseCode, jsonPayload.c_str());
      } else {
        Serial.printf("[Firebase] Send Failed: %s\n", http.errorToString(httpResponseCode).c_str());
      }
      http.end();
    } else {
      Serial.println("[Firebase] NTP Time Error: Failed to obtain local time");
    }
  }
}

void setup() {
  Serial.begin(115200);
  ledcAttach(PWM_PIN, 20000, 10);
  ledcWrite(PWM_PIN, 0); // ปิด MOSFET

  // Calibration
  Serial.println("Calibrating...");
  float sOut = 0;
  for(int i=0; i<200; i++) { sOut += analogRead(OUT_CURR_PIN); delay(2); }
  offsetOut = (sOut/200.0)*(3.3/4095.0);

  Serial.println("=========================================");
  Serial.println("       P&O MPPT Algorithm Ready          ");
  Serial.println("=========================================");
  Serial.println(" คำสั่งการควบคุม:");
  Serial.println(" '1'    : เริ่มรัน P&O");
  Serial.println(" '0'    : หยุดฉุกเฉิน (Duty = 0)");
  Serial.println(" 'Dxxx' : ปรับหน่วงเวลาต่อ Step เช่น 'D500' = 500ms");
  Serial.println("-----------------------------------------");
  Serial.println("Step,Duty,Power(W),Status");

  // เชื่อมต่อ Wi-Fi และดึงเวลา (เพิ่มเข้ามา)
  connectWiFiAndNTP();
}

float getPower() {
  float iRaw = 0;
  for(int i=0; i<40; i++) { iRaw += analogRead(OUT_CURR_PIN); delayMicroseconds(100); }
  float voltage = (iRaw/40.0)*(3.3/4095.0);
  float current = (voltage - offsetOut) / sensitivity;
  return vBat * abs(current);
}

void loop() {
  // 1. ตรวจสอบคำสั่งควบคุมจาก Serial Monitor
  if (Serial.available() > 0) {
    char cmd = Serial.read();
    
    if (cmd == '0') {
      isRunning = false;
      ledcWrite(PWM_PIN, 0);
      Serial.println("\n[EMERGENCY STOP] - PWM is OFF (0%)");
    } 
    else if (cmd == '1') {
      isRunning = true;
      currentDuty = 512;
      lastPower = 0;     
      mpptStepCount = 0; 
      loopCounter = 0;   
      Serial.println("\n[SYSTEM STARTED] - Tracking MPP...");
    }
    // ตรวจสอบคำสั่ง 'D' หรือ 'd' สำหรับตั้งค่าเวลา
    else if (cmd == 'D' || cmd == 'd') {
      int newDelay = Serial.parseInt(); // อ่านตัวเลขที่ตามหลัง D
      
      // ป้องกันไม่ให้ใส่ค่าน้อยเกินไป (ขั้นต่ำ 10ms)
      if (newDelay >= 10) { 
        stepDelayMs = newDelay;
        loopsPerStep = stepDelayMs / 10; // คำนวณ loops ใหม่
        
        Serial.print("\n[SETTING] เปลี่ยนความเร็วเป็น ");
        Serial.print(stepDelayMs);
        Serial.println(" ms ต่อ Step");
      }
    }
  }

  // 2. รันอัลกอริทึม P&O 
  if (isRunning) {
    loopCounter++; 

    if (loopCounter >= loopsPerStep) {
      loopCounter = 0; 
      mpptStepCount++; 
      
      float currentPower = getPower();
      static int direction = 1; 

      if (currentPower < lastPower) {
        direction = -direction; 
      }

      currentDuty += (direction * deltaDuty);
      currentDuty = constrain(currentDuty, 0, 1023); 
      
      ledcWrite(PWM_PIN, currentDuty);
      lastPower = currentPower;

      Serial.print(mpptStepCount); Serial.print(",");
      Serial.print(currentDuty); Serial.print(",");
      Serial.print(currentPower, 2); Serial.print(",");
      Serial.println(direction > 0 ? "Increasing" : "Decreasing");

      // ส่งข้อมูลไปยัง Firebase (เพิ่มเข้ามา - ตั้งเวลาให้ส่งทุกๆ 15 วินาที เพื่อไม่ให้กระทบประสิทธิภาพ loop)
      static unsigned long lastUploadTime = 0;
      if (millis() - lastUploadTime >= 15000) {
        lastUploadTime = millis();
        sendDataToFirebase(currentPower, currentPower / vBat);
      }
    }
  }

  // หน่วงเวลาพื้นฐานของ Loop (10ms)
  delay(10); 
}
