#include <Arduino.h>
#include <WiFi.h>
#include <HTTPClient.h>
#include <time.h>

// --- Configuration ---
const int PWM_PIN = 12;
const int OUT_CURR_PIN = 26;
const int POP_SIZE = 5;
const int GENE_LENGTH = 10; // 10-bit สำหรับ 0-1023

// --- Wi-Fi & Firebase Configuration ---
const char* WIFI_SSID = "YOUR_WIFI_SSID";          // ใส่ชื่อ Wi-Fi ของคุณ
const char* WIFI_PASSWORD = "YOUR_WIFI_PASSWORD";  // ใส่รหัสผ่าน Wi-Fi ของคุณ
const char* FIREBASE_HOST = "https://projectga-d3f20-default-rtdb.asia-southeast1.firebasedatabase.app";

// --- NTP Time Server ---
const char* ntpServer = "pool.ntp.org";
const long  gmtOffset_sec = 7 * 3600; // GMT+7 สำหรับประเทศไทย
const int   daylightOffset_sec = 0;   // ไม่มี Daylight Saving ในไทย

// --- GA Data Structure ---
int population[POP_SIZE][GENE_LENGTH]; // ยีนเป็น Array 2 มิติ [ประชากร][บิต]
float fitness[POP_SIZE];

float offsetOut;
const float sensitivity = 0.0622;
const float vBat = 12.6;

// --- System Control ---
volatile bool isRunning = false;      // สถานะการทำงาน (ใช้ volatile เพื่อความปลอดภัยในการข้าม Thread)
unsigned long stepCount = 0; // ตัวแปรนับจำนวนครั้งที่แสดงผล (1 รุ่น = 1 Step)

// --- Global Variables for Measurement (for Firebase) ---
volatile float currentPowerVal = 0.0;
volatile float currentAmpVal = 0.0;

// --- Function Declarations ---
int binaryToDecimal(int genes[]);
float getPower();
void firebaseUploadTask(void * parameter);

void setup() {
  Serial.begin(115200);
  ledcAttach(PWM_PIN, 20000, 10);
  ledcWrite(PWM_PIN, 0); // ปิด MOSFET ไว้ก่อนเพื่อความปลอดภัย

  // 1. Calibration
  Serial.println("Calibrating... Please do not connect panel/load yet.");
  float sOut = 0;
  for(int i=0; i<200; i++) { sOut += analogRead(OUT_CURR_PIN); delay(2); }
  offsetOut = (sOut/200.0)*(3.3/4095.0);

  // เชื่อมต่อ Wi-Fi
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  Serial.print("Connecting to Wi-Fi");
  int wifiTimeout = 0;
  while (WiFi.status() != WL_CONNECTED && wifiTimeout < 20) { // รอ 10 วินาที
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

  // สร้าง Task สำหรับส่งข้อมูล Firebase บน Core 0 (เพื่อไม่ให้รบกวนการคำนวณและหน่วงเวลาของ GA MPPT บน Core 1)
  xTaskCreatePinnedToCore(
    firebaseUploadTask,    // ฟังก์ชันของ Task
    "FirebaseTask",        // ชื่อ Task
    8192,                  // Stack size (bytes)
    NULL,                  // Parameter ส่งเข้า Task
    1,                     // Priority
    NULL,                  // Task handle
    0                      // Run on Core 0
  );

  Serial.println("=========================================");
  Serial.println("     GA-MPPT Algorithm (Binary Gene)     ");
  Serial.println("=========================================");
  Serial.println(" พิมพ์ '1' : สั่งเริ่มรัน GA (เริ่มนับ Step 1 ใหม่)");
  Serial.println(" พิมพ์ '0' : สั่งหยุดฉุกเฉิน (Duty = 0)");
  Serial.println("-----------------------------------------");
}

// แปลง Binary Array เป็นตัวเลข Decimal (0-1023)
int binaryToDecimal(int genes[]) {
  int decimal = 0;
  for(int i=0; i<GENE_LENGTH; i++) {
    if(genes[i] == 1) {
      decimal += pow(2, (GENE_LENGTH - 1) - i);
    }
  }
  return decimal;
}

float getPower() {
  float iRaw = 0;
  for(int i=0; i<40; i++) { iRaw += analogRead(OUT_CURR_PIN); delayMicroseconds(100); }
  float voltage = (iRaw/40.0)*(3.3/4095.0);
  float current = (voltage - offsetOut) / sensitivity;
  
  // อัปเดตกระแสล่าสุดเก็บในตัวแปร global
  currentAmpVal = abs(current);
  return vBat * currentAmpVal;
}

void loop() {
  // --- 1. ตรวจสอบคำสั่งควบคุมจาก Serial Monitor ---
  if (Serial.available() > 0) {
    char cmd = Serial.read();
    
    if (cmd == '0') {
      isRunning = false;
      ledcWrite(PWM_PIN, 0); // ตัดการทำงานทันที
      Serial.println("\n[EMERGENCY STOP] - PWM is OFF (0%)");
    } 
    else if (cmd == '1') {
      isRunning = true;
      stepCount = 0;         // รีเซ็ตการนับ Step ให้เริ่ม 0 ใหม่

      // สุ่มประชากรรุ่นแรกใหม่ทุกครั้งที่กดเริ่ม
      for(int i=0; i<POP_SIZE; i++) {
        for(int j=0; j<GENE_LENGTH; j++) {
          population[i][j] = random(0, 2); 
        }
      }
      
      Serial.println("\n[SYSTEM STARTED] - Searching for MPP...");
      // เปลี่ยนหัวคอลัมน์ให้เหลือแค่ Step กับ Watt
      Serial.println("Step,Watt"); 
    }
  }

  // --- 2. รันอัลกอริทึม GA ---
  if (isRunning) {
    int bestIdx = 0;
    float maxFit = -1;
    float bestAmpOfGen = 0.0;

    // Evaluation (ประเมินความเหมาะสมของประชากรทั้ง 5 ตัว)
    for(int i=0; i<POP_SIZE; i++) {
      int duty = binaryToDecimal(population[i]);
      ledcWrite(PWM_PIN, duty);
      delay(100); // หน่วงเวลาให้ระบบเสถียรก่อนอ่านค่า (Step time 100ms)
      
      float p = getPower();
      fitness[i] = p;
      
      // หาตัวที่ดีที่สุด
      if(fitness[i] > maxFit) {
        maxFit = fitness[i];
        bestIdx = i;
        bestAmpOfGen = currentAmpVal; // บันทึกกระแสของตัวที่ดีที่สุดของรุ่น
      }
    }

    // อัปเดตผลลัพธ์ที่ดีที่สุดลงตัวแปร Global เพื่อให้ Task อัปโหลดขึ้น Firebase ไปทำงาน
    currentPowerVal = maxFit;
    currentAmpVal = bestAmpOfGen;

    // --- แสดงผลเฉพาะตัวที่ดีที่สุดของรุ่น (1 รุ่น = 1 Step) ---
    stepCount++; 
    Serial.print(stepCount); Serial.print(",");
    Serial.println(maxFit, 2); 

    // Reproduction (Crossover & Mutation)
    int nextGen[POP_SIZE][GENE_LENGTH];

    // Elitism: เก็บตัวที่ดีที่สุดไว้ที่ index 0 ของรุ่นถัดไปแน่นอน
    for(int j=0; j<GENE_LENGTH; j++) nextGen[0][j] = population[bestIdx][j];

    for(int i=1; i<POP_SIZE; i++) {
      // Single Point Crossover
      int crossoverPoint = random(1, GENE_LENGTH);
      for(int j=0; j<GENE_LENGTH; j++) {
        if(j < crossoverPoint) {
          nextGen[i][j] = population[0][j];
        } else {
          nextGen[i][j] = population[random(0, POP_SIZE)][j];
        }

        // Bit-Flip Mutation (โอกาสกลายพันธุ์ 5%)
        if(random(0, 100) < 5) {
          nextGen[i][j] = !nextGen[i][j];
        }
      }
    }

    // อัปเดตประชากรทั้งหมดเพื่อเตรียมรันในรุ่นต่อไป
    memcpy(population, nextGen, sizeof(population));
  }
}

// --- Task สำหรับอัปโหลดข้อมูลไปยัง Firebase (ทำงานแยกบน Core 0 แบบ Non-blocking) ---
void firebaseUploadTask(void * parameter) {
  for (;;) {
    // อัปโหลดข้อมูลทุกๆ 15 วินาที
    vTaskDelay(pdMS_TO_TICKS(15000));
    
    if (isRunning && WiFi.status() == WL_CONNECTED) {
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

        // ดึงค่าล่าสุดจากตัวแปร Global (ซึ่งเป็นค่าที่ดีที่สุดของรุ่นล่าสุด)
        float w = currentPowerVal;
        float a = currentAmpVal;
        
        // สร้าง JSON Body สำหรับส่ง
        String jsonPayload = "{\"watt\":" + String(w, 2) + ",\"amp\":" + String(a, 2) + "}";

        // ส่งข้อมูลแบบ PATCH
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
}
