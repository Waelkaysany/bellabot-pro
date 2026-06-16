#include <WiFi.h>
#include <WebServer.h>
#include <ESP32Servo.h>
#include <Wire.h>
#include <LiquidCrystal_I2C.h>
#include <SPI.h>
#include <MFRC522.h>

// ─── Pin Definitions ──────────────────────────────────────────────────────────
const int LED1_PIN   = 4;   // Green LED
const int LED2_PIN   = 2;   // Red LED
const int SERVO_PIN  = 13;  // SG90 Servo
const int BUZZER_PIN = 25;  // Buzzer

// ─── RFID RC522 Pins (SPI) ────────────────────────────────────────────────────
const int RST_PIN = 14;
const int SS_PIN  = 5;

// ─── I2C LCD: address 0x27, 16 cols, 2 rows ───────────────────────────────────
LiquidCrystal_I2C lcd(0x27, 16, 2);

// ─── MFRC522 RFID instance ────────────────────────────────────────────────────
MFRC522 mfrc522(SS_PIN, RST_PIN);

// ─── Hardcoded Payment Card ───────────────────────────────────────────────────
// Card UID: 23 50 B5 1F  →  Jebbar (APPROVED)
// All other cards        →  DECLINED
const String JEBBAR_UID = "23 50 B5 1F";

// ─── LED Configuration (Active-Low vs Active-High) ───────────────────────────
const bool LEDS_ACTIVE_LOW = false; // Set to true if LEDs turn ON when pin is LOW

// ─── RFID Status State (polled by Flutter app) ────────────────────────────────
String lastScanStatus = "IDLE";   // "IDLE" | "SUCCESS" | "FAILED"
String lastScanUID    = "";
String lastScanName   = "";

// ─── Custom LED Control helper ───────────────────────────────────────────────
void setLed(int pin, bool turnOn) {
  if (LEDS_ACTIVE_LOW) {
    digitalWrite(pin, turnOn ? LOW : HIGH);
  } else {
    digitalWrite(pin, turnOn ? HIGH : LOW);
  }
}

// ─── Custom Tone Generator (Bit-Banged to avoid LEDC / Servo conflicts) ───────
void playTone(int pin, int frequency, int durationMs) {
  if (frequency <= 0) {
    delay(durationMs);
    return;
  }
  long halfPeriod = 500000L / frequency;
  long cycles = (long)durationMs * frequency / 1000L;
  pinMode(pin, OUTPUT);
  for (long i = 0; i < cycles; i++) {
    digitalWrite(pin, HIGH);
    delayMicroseconds(halfPeriod);
    digitalWrite(pin, LOW);
    delayMicroseconds(halfPeriod);
  }
}

// ─── Wi-Fi Credentials ────────────────────────────────────────────────────────
const char* ssid             = "Hello";
const char* password         = "wael0000";
const char* fallbackSsid     = "ESP32-Control-Hub";
const char* fallbackPassword = "password123";

WebServer server(80);
Servo myServo;

// ══════════════════════════════════════════════════════════════════════════════
//  MUSIC HELPERS
// ══════════════════════════════════════════════════════════════════════════════

// ─── Happy 3-note melody ──────────────────────────────────────────────────────
void playHappyMelody() {
  int notes[]     = {523, 659, 784};
  int durations[] = {150, 150, 300};
  for (int i = 0; i < 3; i++) {
    playTone(BUZZER_PIN, notes[i], durations[i]);
    delay(50);
  }
}

// ─── Payment SUCCESS chime — soaring 6-note fanfare ──────────────────────────
void playPaymentSuccessChime() {
  // E5 → G5 → C6 → E6 → G6 → C7   (rising triumphant fanfare)
  int notes[]     = {659, 784, 1047, 1319, 1568, 2093};
  int durations[] = {120, 120,  180,  180,  220,   500};
  for (int i = 0; i < 6; i++) {
    playTone(BUZZER_PIN, notes[i], durations[i]);
    delay(40);
  }
}

// ─── Payment DECLINE buzz — low dramatic descending drone ─────────────────────
void playPaymentDeclineBuzz() {
  // Two low descending groans, then a short flat reject beep
  playTone(BUZZER_PIN, 200, 450);
  delay(80);
  playTone(BUZZER_PIN, 160, 450);
  delay(80);
  playTone(BUZZER_PIN, 120, 700);
}

// ─── Full Happy Birthday song ─────────────────────────────────────────────────
void playBirthdaySong() {
  int melody[] = {
    262,262,294,262,349,330,
    262,262,294,262,392,349,
    262,262,523,440,349,330,294,
    466,466,440,349,392,349
  };
  int durations[] = {
    300,300,600,600,600,800,
    300,300,600,600,600,800,
    300,300,600,600,600,600,800,
    300,300,600,600,600,900
  };
  int count = sizeof(melody) / sizeof(melody[0]);
  for (int i = 0; i < count; i++) {
    playTone(BUZZER_PIN, melody[i], durations[i]);
    delay(60);
  }
}

// ─── Warm goodbye melody ──────────────────────────────────────────────────────
void playGoodbyeMelody() {
  int notes[]     = {784, 659, 523, 392};
  int durations[] = {180, 180, 180, 400};
  for (int i = 0; i < 4; i++) {
    playTone(BUZZER_PIN, notes[i], durations[i]);
    delay(60);
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  LED HELPERS
// ══════════════════════════════════════════════════════════════════════════════

void blinkEyes() {
  for (int i = 0; i < 2; i++) {
    setLed(LED1_PIN, true);
    setLed(LED2_PIN, true);
    delay(250);
    setLed(LED1_PIN, false);
    setLed(LED2_PIN, false);
    delay(200);
  }
}

// Green LED pulses N times (success feel)
void pulseGreen(int times) {
  for (int i = 0; i < times; i++) {
    setLed(LED1_PIN, true);
    delay(180);
    setLed(LED1_PIN, false);
    delay(120);
  }
}

// Red LED flashes N times (alarm feel)
void flashRed(int times) {
  for (int i = 0; i < times; i++) {
    setLed(LED2_PIN, true);
    delay(100);
    setLed(LED2_PIN, false);
    delay(80);
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  ROBOT SEQUENCES
// ══════════════════════════════════════════════════════════════════════════════

// ─── Birthday Sequence ────────────────────────────────────────────────────────
void runBirthdaySequence(String guestName) {
  lcd.clear();
  lcd.setCursor(0, 0);
  lcd.print(" Happy Birthday");
  lcd.setCursor(0, 1);
  String line2 = guestName.length() > 0 ? guestName + "! :D" : "To You! :D";
  if (line2.length() > 16) line2 = line2.substring(0, 16);
  int pad = (16 - line2.length()) / 2;
  String paddedLine = "";
  for (int p = 0; p < pad; p++) paddedLine += " ";
  paddedLine += line2;
  lcd.print(paddedLine);

  int melody[] = {
    262,262,294,262,349,330,
    262,262,294,262,392,349,
    262,262,523,440,349,330,294,
    466,466,440,349,392,349
  };
  int dur[] = {
    300,300,600,600,600,800,
    300,300,600,600,600,800,
    300,300,600,600,600,600,800,
    300,300,600,600,600,900
  };
  int count = sizeof(melody) / sizeof(melody[0]);

  for (int i = 0; i < count; i++) {
    setLed(LED1_PIN, i % 2 == 0);
    setLed(LED2_PIN, i % 2 != 0);
    playTone(BUZZER_PIN, melody[i], dur[i]);
    delay(60);
  }

  setLed(LED1_PIN, true);
  setLed(LED2_PIN, true);
  delay(1000);
  setLed(LED1_PIN, false);
  setLed(LED2_PIN, false);
}

// ─── Waiter Sequence ──────────────────────────────────────────────────────────
void runWaiterSequence() {
  myServo.write(0);
  lcd.clear();
  lcd.setCursor(0, 0);
  lcd.print("  Hello there! ");
  lcd.setCursor(0, 1);
  lcd.print(" Welcome!      ");
  blinkEyes();
  playHappyMelody();
  delay(1500);
  lcd.clear();
  lcd.setCursor(0, 0);
  lcd.print(" Here is your  ");
  lcd.setCursor(0, 1);
  lcd.print("   food!  :)   ");
  myServo.write(90);
  setLed(LED1_PIN, true);
  setLed(LED2_PIN, true);
}

// ─── Reset ────────────────────────────────────────────────────────────────────
void resetRobot() {
  lcd.clear();
  lcd.setCursor(0, 0);
  lcd.print("   Goodbye!    ");
  lcd.setCursor(0, 1);
  lcd.print(" See you soon! ");
  for (int i = 0; i < 2; i++) {
    setLed(LED1_PIN, true);
    setLed(LED2_PIN, true);
    delay(300);
    setLed(LED1_PIN, false);
    setLed(LED2_PIN, false);
    delay(200);
  }
  playGoodbyeMelody();
  delay(1000);
  myServo.write(0);
  setLed(LED1_PIN, false);
  setLed(LED2_PIN, false);
  lcd.clear();
  lcd.setCursor(0, 0);
  lcd.print("  BellaBot Pro ");
  lcd.setCursor(0, 1);
  lcd.print("   Standing by ");
}

// ══════════════════════════════════════════════════════════════════════════════
//  RFID PAYMENT HANDLER
// ══════════════════════════════════════════════════════════════════════════════
void handleRFIDCard(String scannedUid) {
  Serial.print("Card scanned: ");
  Serial.println(scannedUid);

  if (scannedUid == JEBBAR_UID) {
    // ── JEBBAR — PAYMENT APPROVED ─────────────────────────────────────────
    Serial.println(">>> PAYMENT APPROVED — Jebbar");

    lastScanStatus = "SUCCESS";
    lastScanUID    = scannedUid;
    lastScanName   = "Jebbar";

    // Phase 1: Welcome
    lcd.clear();
    lcd.setCursor(0, 0);
    lcd.print("Welcome Jebbar!");
    lcd.setCursor(0, 1);
    lcd.print("Processing...  ");

    // Play fanfare chime
    playPaymentSuccessChime();

    // Phase 2: Approved confirmation
    lcd.clear();
    lcd.setCursor(0, 0);
    lcd.print("  APPROVED  ✓  ");
    lcd.setCursor(0, 1);
    lcd.print(" Charged $12.50");

    // Green LED pulse x4
    pulseGreen(4);

    delay(800);

    // Phase 3: Thank you
    lcd.clear();
    lcd.setCursor(0, 0);
    lcd.print(" Thank you,    ");
    lcd.setCursor(0, 1);
    lcd.print(" Jebbar!  :)   ");

    // Solid green for 2 seconds
    setLed(LED1_PIN, true);
    delay(2000);
    setLed(LED1_PIN, false);

    delay(500);
    resetRobot();

  } else {
    // ── UNKNOWN CARD — PAYMENT DECLINED ───────────────────────────────────
    Serial.print(">>> PAYMENT DECLINED — unknown card: ");
    Serial.println(scannedUid);

    lastScanStatus = "FAILED";
    lastScanUID    = scannedUid;
    lastScanName   = "Anass";

    // Phase 1: Declined alert
    lcd.clear();
    lcd.setCursor(0, 0);
    lcd.print("  DECLINED  X  ");
    lcd.setCursor(0, 1);
    lcd.print(" Sorry, Anass! ");

    // Red LED ON solid
    setLed(LED2_PIN, true);

    // Play decline buzz
    playPaymentDeclineBuzz();

    // Flash red x5 rapidly
    flashRed(5);
    setLed(LED2_PIN, false);

    delay(600);

    // Phase 2: Instruction
    lcd.clear();
    lcd.setCursor(0, 0);
    lcd.print("Payment Failed ");
    lcd.setCursor(0, 1);
    lcd.print("Contact Staff  ");

    delay(2000);
    resetRobot();
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  HTML PAGE (built-in web interface)
// ══════════════════════════════════════════════════════════════════════════════
const char htmlPage[] PROGMEM = R"rawhtml(
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>BellaBot Pro Controller</title>
  <style>
    :root {
      --bg: #0b0f19;
      --primary: #f59e0b;
      --accent: #10b981;
      --text: #f8fafc;
      --muted: #64748b;
    }
    body { margin:0; font-family: sans-serif; background: radial-gradient(circle at 50% 0%, #451a03 0%, var(--bg) 70%); color:var(--text); display:flex; justify-content:center; align-items:center; min-height:100vh; }
    .card { background:rgba(22,30,49,0.8); border:1px solid rgba(255,255,255,0.08); border-radius:28px; padding:36px 28px; max-width:440px; width:90%; }
    h1 { text-align:center; background:linear-gradient(135deg,#fcd34d,#f59e0b); -webkit-background-clip:text; -webkit-text-fill-color:transparent; margin:0 0 4px; }
    .sub { text-align:center; color:var(--muted); font-size:12px; letter-spacing:2px; margin-bottom:24px; }
    .row { display:flex; justify-content:space-between; align-items:center; background:rgba(15,23,42,0.4); padding:16px 20px; border-radius:16px; margin-bottom:14px; border-left:4px solid var(--primary); }
    .label { font-weight:700; font-size:15px; }
    .desc { font-size:11px; color:var(--muted); margin-top:3px; }
    .switch { position:relative; display:inline-block; width:52px; height:28px; }
    .switch input { opacity:0; width:0; height:0; }
    .slider { position:absolute; cursor:pointer; inset:0; background:#334155; transition:.3s; border-radius:34px; }
    .slider:before { position:absolute; content:""; height:20px; width:20px; left:4px; bottom:4px; background:white; transition:.3s; border-radius:50%; }
    input:checked+.slider { background:var(--accent); box-shadow:0 0 12px rgba(16,185,129,0.4); }
    input:checked+.slider:before { transform:translateX(24px); }
    .waiter-btn { width:100%; padding:18px; border:none; border-radius:18px; background:linear-gradient(135deg,#f59e0b,#f97316); color:#111; font-size:17px; font-weight:800; cursor:pointer; margin-top:8px; box-shadow:0 6px 20px rgba(245,158,11,0.4); transition:all .2s; letter-spacing:.5px; }
    .waiter-btn:hover { transform:translateY(-2px); opacity:.9; }
    .waiter-btn:active { transform:scale(.97); }
    .reset-btn { width:100%; padding:14px; border:1px solid rgba(255,255,255,0.1); border-radius:14px; background:transparent; color:var(--muted); font-size:14px; cursor:pointer; margin-top:10px; transition:.2s; }
    .reset-btn:hover { color:white; border-color:white; }
  </style>
</head>
<body>
<div class="card">
  <h1>BellaBot Pro</h1>
  <div class="sub">ROBOT CONTROL INTERFACE</div>
  <div class="row">
    <div><div class="label">Left Eye</div><div class="desc">Green LED · GPIO 4</div></div>
    <label class="switch"><input type="checkbox" id="led1" onchange="sendCmd('led1/'+(this.checked?'on':'off'))"><span class="slider"></span></label>
  </div>
  <div class="row">
    <div><div class="label">Right Eye</div><div class="desc">Red LED · GPIO 2</div></div>
    <label class="switch"><input type="checkbox" id="led2" onchange="sendCmd('led2/'+(this.checked?'on':'off'))"><span class="slider"></span></label>
  </div>
  <div class="row">
    <div><div class="label">Arm (Servo)</div><div class="desc">SG90 · GPIO 13</div></div>
    <label class="switch"><input type="checkbox" id="motor" onchange="sendCmd('motor/'+(this.checked?'on':'off'))"><span class="slider"></span></label>
  </div>
  <button class="waiter-btn" onclick="sendCmd('waiter')">🍽️ Cheerful Waiter Mode</button>
  <button class="reset-btn" onclick="sendCmd('reset')">↺ Reset Robot</button>
</div>
<script>
  function sendCmd(ep) { fetch('/'+ep).catch(e=>console.error(e)); }
</script>
</body>
</html>
)rawhtml";

// ══════════════════════════════════════════════════════════════════════════════
//  HTTP HANDLERS
// ══════════════════════════════════════════════════════════════════════════════
void handleRoot()     { server.sendHeader("Access-Control-Allow-Origin","*"); server.send(200,"text/html",htmlPage); }
void handleLed1On()   { server.sendHeader("Access-Control-Allow-Origin","*"); setLed(LED1_PIN, true);  server.send(200,"text/plain","OK"); }
void handleLed1Off()  { server.sendHeader("Access-Control-Allow-Origin","*"); setLed(LED1_PIN, false); server.send(200,"text/plain","OK"); }
void handleLed2On()   { server.sendHeader("Access-Control-Allow-Origin","*"); setLed(LED2_PIN, true);  server.send(200,"text/plain","OK"); }
void handleLed2Off()  { server.sendHeader("Access-Control-Allow-Origin","*"); setLed(LED2_PIN, false); server.send(200,"text/plain","OK"); }
void handleMotorOn()  { server.sendHeader("Access-Control-Allow-Origin","*"); myServo.write(90);           server.send(200,"text/plain","OK"); }
void handleMotorOff() { server.sendHeader("Access-Control-Allow-Origin","*"); myServo.write(0);            server.send(200,"text/plain","OK"); }

void handleLED() {
  server.sendHeader("Access-Control-Allow-Origin","*");
  if (server.hasArg("id") && server.hasArg("val")) {
    int id  = server.arg("id").toInt();
    int val = server.arg("val").toInt();
    if (id == 1) setLed(LED1_PIN, val);
    else if (id == 2) setLed(LED2_PIN, val);
    server.send(200,"text/plain","OK");
  } else { server.send(400,"text/plain","Bad Request"); }
}

void handleServo() {
  server.sendHeader("Access-Control-Allow-Origin","*");
  if (server.hasArg("val")) {
    int val = server.arg("val").toInt();
    if (val >= 0 && val <= 180) { myServo.write(val); server.send(200,"text/plain","OK"); }
    else server.send(400,"text/plain","Invalid Angle");
  } else { server.send(400,"text/plain","Bad Request"); }
}

void handleWaiter() {
  server.sendHeader("Access-Control-Allow-Origin","*");
  server.send(200,"text/plain","OK");
  runWaiterSequence();
}

void handleReset() {
  server.sendHeader("Access-Control-Allow-Origin","*");
  server.send(200,"text/plain","OK");
  resetRobot();
}

void handleBirthday() {
  server.sendHeader("Access-Control-Allow-Origin","*");
  String name = "";
  if (server.hasArg("name")) name = server.arg("name");
  server.send(200,"text/plain","OK");
  runBirthdaySequence(name);
}

// ─── GET /rfid/status ─────────────────────────────────────────────────────────
// Returns JSON: {"status":"SUCCESS","uid":"23 50 B5 1F","name":"Jebbar"}
void handleRfidStatus() {
  server.sendHeader("Access-Control-Allow-Origin","*");
  server.sendHeader("Content-Type","application/json");
  String json = "{";
  json += "\"status\":\"" + lastScanStatus + "\",";
  json += "\"uid\":\"" + lastScanUID + "\",";
  json += "\"name\":\"" + lastScanName + "\"";
  json += "}";
  server.send(200, "application/json", json);
}

// ─── GET /rfid/clear ─────────────────────────────────────────────────────────
// Resets state back to IDLE so the app stops showing overlay
void handleRfidClear() {
  server.sendHeader("Access-Control-Allow-Origin","*");
  lastScanStatus = "IDLE";
  lastScanUID    = "";
  lastScanName   = "";
  server.send(200,"text/plain","CLEARED");
}

// ══════════════════════════════════════════════════════════════════════════════
//  SETUP
// ══════════════════════════════════════════════════════════════════════════════
void setup() {
  Serial.begin(115200);

  SPI.begin();
  mfrc522.PCD_Init();
  Serial.println("RFID MFRC522 Initialized");
  Serial.print("Authorized card (Jebbar): ");
  Serial.println(JEBBAR_UID);

  pinMode(LED1_PIN, OUTPUT);
  pinMode(LED2_PIN, OUTPUT);
  pinMode(BUZZER_PIN, OUTPUT);
  setLed(LED1_PIN, false);
  setLed(LED2_PIN, false);

  myServo.attach(SERVO_PIN);
  myServo.write(0);

  lcd.init();
  lcd.backlight();
  lcd.setCursor(0, 0);
  lcd.print(" BellaBot Pro  ");
  lcd.setCursor(0, 1);
  lcd.print("  Booting...   ");

  Serial.print("Connecting to Wi-Fi: ");
  Serial.println(ssid);
  WiFi.begin(ssid, password);
  int attempts = 0;
  while (WiFi.status() != WL_CONNECTED && attempts < 20) {
    delay(500); Serial.print("."); attempts++;
  }
  Serial.println("");

  if (WiFi.status() == WL_CONNECTED) {
    Serial.print("Connected! IP: "); Serial.println(WiFi.localIP());
    lcd.clear();
    lcd.setCursor(0, 0);
    lcd.print(" BellaBot Pro  ");
    lcd.setCursor(0, 1);
    lcd.print("   Online!     ");
  } else {
    WiFi.softAP(fallbackSsid, fallbackPassword);
    Serial.print("AP Mode. IP: "); Serial.println(WiFi.softAPIP());
    lcd.clear();
    lcd.setCursor(0, 0);
    lcd.print(" BellaBot Pro  ");
    lcd.setCursor(0, 1);
    lcd.print("  AP Mode      ");
  }

  // ─── Routes ────────────────────────────────────────────────────────────────
  server.on("/",            handleRoot);
  server.on("/led",         handleLED);
  server.on("/servo",       handleServo);
  server.on("/led1/on",     handleLed1On);
  server.on("/led1/off",    handleLed1Off);
  server.on("/led2/on",     handleLed2On);
  server.on("/led2/off",    handleLed2Off);
  server.on("/motor/on",    handleMotorOn);
  server.on("/motor/off",   handleMotorOff);
  server.on("/waiter",      handleWaiter);
  server.on("/reset",       handleReset);
  server.on("/birthday",    handleBirthday);
  server.on("/rfid/status", handleRfidStatus);
  server.on("/rfid/clear",  handleRfidClear);

  server.begin();
  Serial.println("HTTP Server started");

  // Startup beep
  playTone(BUZZER_PIN, 880, 100);  delay(150);
  playTone(BUZZER_PIN, 1047, 200); delay(250);
}

// ══════════════════════════════════════════════════════════════════════════════
//  LOOP
// ══════════════════════════════════════════════════════════════════════════════
void loop() {
  server.handleClient();

  // ─── RFID Poll ─────────────────────────────────────────────────────────────
  if (mfrc522.PICC_IsNewCardPresent() && mfrc522.PICC_ReadCardSerial()) {
    String uidStr = "";
    for (byte i = 0; i < mfrc522.uid.size; i++) {
      uidStr += String(mfrc522.uid.uidByte[i] < 0x10 ? "0" : "");
      uidStr += String(mfrc522.uid.uidByte[i], HEX);
      if (i < mfrc522.uid.size - 1) uidStr += " ";
    }
    uidStr.toUpperCase();

    handleRFIDCard(uidStr);

    mfrc522.PICC_HaltA();
    mfrc522.PCD_StopCrypto1();
  }

  // ─── Serial commands ────────────────────────────────────────────────────────
  if (Serial.available() > 0) {
    String input = Serial.readStringUntil('\n');
    input.trim();
    if      (input.startsWith("L1:")) { setLed(LED1_PIN, input.substring(3).toInt()); Serial.println("LED1_OK"); }
    else if (input.startsWith("L2:")) { setLed(LED2_PIN, input.substring(3).toInt()); Serial.println("LED2_OK"); }
    else if (input.startsWith("S:"))  { myServo.write(input.substring(2).toInt());           Serial.println("SERVO_OK"); }
    else if (input == "WAITER")       { runWaiterSequence(); }
    else if (input == "RESET")        { resetRobot(); }
  }

  delay(2);
}
