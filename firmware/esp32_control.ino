#include <WiFi.h>
#include <WebServer.h>
#include <ESP32Servo.h>
#include <Wire.h>
#include <LiquidCrystal_I2C.h>

// Pin Definitions
const int LED1_PIN = 18;
const int LED2_PIN = 19;
const int SERVO_PIN = 23;
const int BUZZER_PIN = 25;

// I2C LCD: address 0x27, 16 cols, 2 rows
LiquidCrystal_I2C lcd(0x27, 16, 2);

// Wi-Fi Credentials
const char* ssid = "Hello";
const char* password = "wael0000";

// Fallback Access Point Settings
const char* fallbackSsid = "ESP32-Control-Hub";
const char* fallbackPassword = "password123";

WebServer server(80);
Servo myServo;

// ─── Helper: Play a cheerful 3-note melody ───────────────────────────────────
void playHappyMelody() {
  int notes[] = {523, 659, 784}; // C5, E5, G5
  int durations[] = {150, 150, 300};
  for (int i = 0; i < 3; i++) {
    tone(BUZZER_PIN, notes[i], durations[i]);
    delay(durations[i] + 50);
    noTone(BUZZER_PIN);
  }
}

// ─── Helper: Full "Happy Birthday to You" song ───────────────────────────────
void playBirthdaySong() {
  // Notes: C4=262, D4=294, E4=330, F4=349, G4=392, A4=440, B4=494
  //        C5=523, D5=587, E5=659, F5=698, G5=784, A5=880
  // Rhythm: S=short(300ms), M=medium(400ms), L=long(600ms), XL=very long(800ms)
  int melody[] = {
    262,262,294,262,349,330,   // Hap-py Birth-day to you
    262,262,294,262,392,349,   // Hap-py Birth-day to you
    262,262,523,440,349,330,294, // Hap-py Birth-day dear [name]
    466,466,440,349,392,349    // Hap-py Birth-day to you!
  };
  int durations[] = {
    300,300,600,600,600,800,
    300,300,600,600,600,800,
    300,300,600,600,600,600,800,
    300,300,600,600,600,900
  };
  int count = sizeof(melody) / sizeof(melody[0]);
  for (int i = 0; i < count; i++) {
    tone(BUZZER_PIN, melody[i], durations[i]);
    delay(durations[i] + 60);
    noTone(BUZZER_PIN);
  }
}

// ─── Birthday Sequence ───────────────────────────────────────────────────────
void runBirthdaySequence(String guestName) {
  // 1. Show name on LCD
  lcd.clear();
  lcd.setCursor(0, 0);
  lcd.print(" Happy Birthday");
  lcd.setCursor(0, 1);
  // Centre the name on 16 chars
  String line2 = guestName.length() > 0 ? guestName + "! :D" : "To You! :D";
  if (line2.length() > 16) line2 = line2.substring(0, 16);
  int pad = (16 - line2.length()) / 2;
  String paddedLine = "";
  for (int p = 0; p < pad; p++) paddedLine += " ";
  paddedLine += line2;
  lcd.print(paddedLine);

  // 2. Play full Happy Birthday song while LEDs party-blink
  //    Run melody in parallel with LED blinking using millis trick
  unsigned long songStart = millis();

  // Notes & durations (same as playBirthdaySong)
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

  bool ledState = false;
  unsigned long ledToggle = millis();
  int noteIndex = 0;
  unsigned long noteEnd = millis();

  // Play the song once (~13 s with gaps), blinking LEDs throughout
  unsigned long totalTime = 10000UL; // 10 seconds minimum
  unsigned long endTime = millis() + totalTime;

  noteIndex = 0;
  noteEnd = millis();

  while (millis() < endTime || noteIndex < count) {
    // LED blink every 200ms
    if (millis() - ledToggle >= 200) {
      ledState = !ledState;
      digitalWrite(LED1_PIN, ledState ? HIGH : LOW);
      digitalWrite(LED2_PIN, ledState ? LOW  : HIGH); // alternate!
      ledToggle = millis();
    }
    // Play next note when previous has finished
    if (noteIndex < count && millis() >= noteEnd) {
      tone(BUZZER_PIN, melody[noteIndex], dur[noteIndex]);
      noteEnd = millis() + dur[noteIndex] + 60;
      noteIndex++;
    }
    delay(10);
  }
  noTone(BUZZER_PIN);

  // 3. Keep LEDs on solid for 1 more second
  digitalWrite(LED1_PIN, HIGH);
  digitalWrite(LED2_PIN, HIGH);
  delay(1000);

  // 4. Return eyes off, keep LCD message
  digitalWrite(LED1_PIN, LOW);
  digitalWrite(LED2_PIN, LOW);
}

// ─── Helper: Blink both LEDs twice ───────────────────────────────────────────
void blinkEyes() {
  for (int i = 0; i < 2; i++) {
    digitalWrite(LED1_PIN, HIGH);
    digitalWrite(LED2_PIN, HIGH);
    delay(250);
    digitalWrite(LED1_PIN, LOW);
    digitalWrite(LED2_PIN, LOW);
    delay(200);
  }
}

// ─── Waiter Sequence ─────────────────────────────────────────────────────────
void runWaiterSequence() {
  // 1. Move arm down (servo to 0°) like holding a tray
  myServo.write(0);

  // 2. Show "Hello there!" on LCD row 0
  lcd.clear();
  lcd.setCursor(0, 0);
  lcd.print("  Hello there! ");
  lcd.setCursor(0, 1);
  lcd.print(" Welcome!      ");

  // 3. Blink the eyes
  blinkEyes();

  // 4. Play happy melody
  playHappyMelody();

  delay(1500);

  // 5. Change message to "Here is your food!"
  lcd.clear();
  lcd.setCursor(0, 0);
  lcd.print(" Here is your  ");
  lcd.setCursor(0, 1);
  lcd.print("   food!  :)   ");

  // 6. Move arm up (serve position 90°)
  myServo.write(90);

  // 7. Both eyes stay on
  digitalWrite(LED1_PIN, HIGH);
  digitalWrite(LED2_PIN, HIGH);
}

// ─── Helper: Play a warm goodbye melody ─────────────────────────────────────
void playGoodbyeMelody() {
  // Warm descending: G5 → E5 → C5 → G4  (friendly wave goodbye)
  int notes[]     = {784, 659, 523, 392};
  int durations[] = {180, 180, 180, 400};
  for (int i = 0; i < 4; i++) {
    tone(BUZZER_PIN, notes[i], durations[i]);
    delay(durations[i] + 60);
    noTone(BUZZER_PIN);
  }
}

// ─── Reset sequence ───────────────────────────────────────────────────────────
void resetRobot() {
  // 1. Show goodbye message
  lcd.clear();
  lcd.setCursor(0, 0);
  lcd.print("   Goodbye!    ");
  lcd.setCursor(0, 1);
  lcd.print(" See you soon! ");

  // 2. Blink eyes as a farewell wave
  for (int i = 0; i < 2; i++) {
    digitalWrite(LED1_PIN, HIGH);
    digitalWrite(LED2_PIN, HIGH);
    delay(300);
    digitalWrite(LED1_PIN, LOW);
    digitalWrite(LED2_PIN, LOW);
    delay(200);
  }

  // 3. Play goodbye melody
  playGoodbyeMelody();

  delay(1000);

  // 4. Return to standby
  myServo.write(0);
  digitalWrite(LED1_PIN, LOW);
  digitalWrite(LED2_PIN, LOW);
  lcd.clear();
  lcd.setCursor(0, 0);
  lcd.print("  BellaBot Pro ");
  lcd.setCursor(0, 1);
  lcd.print("   Standing by ");
}

// ─── HTML Page ────────────────────────────────────────────────────────────────
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
    <div><div class="label">Left Eye</div><div class="desc">Green LED · GPIO 18</div></div>
    <label class="switch"><input type="checkbox" id="led1" onchange="sendCmd('led1/'+(this.checked?'on':'off'))"><span class="slider"></span></label>
  </div>
  <div class="row">
    <div><div class="label">Right Eye</div><div class="desc">Red LED · GPIO 19</div></div>
    <label class="switch"><input type="checkbox" id="led2" onchange="sendCmd('led2/'+(this.checked?'on':'off'))"><span class="slider"></span></label>
  </div>
  <div class="row">
    <div><div class="label">Arm (Servo)</div><div class="desc">SG90 · GPIO 23</div></div>
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

// ─── HTTP Handlers ────────────────────────────────────────────────────────────
void handleRoot()     { server.sendHeader("Access-Control-Allow-Origin","*"); server.send(200,"text/html",htmlPage); }
void handleLed1On()   { server.sendHeader("Access-Control-Allow-Origin","*"); digitalWrite(LED1_PIN,HIGH); server.send(200,"text/plain","OK"); }
void handleLed1Off()  { server.sendHeader("Access-Control-Allow-Origin","*"); digitalWrite(LED1_PIN,LOW);  server.send(200,"text/plain","OK"); }
void handleLed2On()   { server.sendHeader("Access-Control-Allow-Origin","*"); digitalWrite(LED2_PIN,HIGH); server.send(200,"text/plain","OK"); }
void handleLed2Off()  { server.sendHeader("Access-Control-Allow-Origin","*"); digitalWrite(LED2_PIN,LOW);  server.send(200,"text/plain","OK"); }
void handleMotorOn()  { server.sendHeader("Access-Control-Allow-Origin","*"); myServo.write(90);           server.send(200,"text/plain","OK"); }
void handleMotorOff() { server.sendHeader("Access-Control-Allow-Origin","*"); myServo.write(0);            server.send(200,"text/plain","OK"); }

void handleLED() {
  server.sendHeader("Access-Control-Allow-Origin","*");
  if (server.hasArg("id") && server.hasArg("val")) {
    int id  = server.arg("id").toInt();
    int val = server.arg("val").toInt();
    if (id == 1) digitalWrite(LED1_PIN, val);
    else if (id == 2) digitalWrite(LED2_PIN, val);
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
  runWaiterSequence(); // Run after responding so app doesn't time out
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
  runBirthdaySequence(name); // runs AFTER response is sent so app won't time out
}

// ─── Setup ────────────────────────────────────────────────────────────────────
void setup() {
  Serial.begin(115200);

  // Hardware init
  pinMode(LED1_PIN, OUTPUT);
  pinMode(LED2_PIN, OUTPUT);
  pinMode(BUZZER_PIN, OUTPUT);
  digitalWrite(LED1_PIN, LOW);
  digitalWrite(LED2_PIN, LOW);

  myServo.attach(SERVO_PIN);
  myServo.write(0);

  // LCD init
  lcd.init();
  lcd.backlight();
  lcd.setCursor(0, 0);
  lcd.print(" BellaBot Pro  ");
  lcd.setCursor(0, 1);
  lcd.print("  Booting...   ");

  // Wi-Fi
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

  // Routes
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

  server.begin();
  Serial.println("HTTP Server started");

  // Startup beep
  tone(BUZZER_PIN, 880, 100); delay(150); noTone(BUZZER_PIN);
  tone(BUZZER_PIN, 1047, 200); delay(250); noTone(BUZZER_PIN);
}

// ─── Loop ─────────────────────────────────────────────────────────────────────
void loop() {
  server.handleClient();

  // Serial commands (USB mode)
  if (Serial.available() > 0) {
    String input = Serial.readStringUntil('\n');
    input.trim();
    if (input.startsWith("L1:"))      { digitalWrite(LED1_PIN, input.substring(3).toInt()); Serial.println("LED1_OK"); }
    else if (input.startsWith("L2:"))  { digitalWrite(LED2_PIN, input.substring(3).toInt()); Serial.println("LED2_OK"); }
    else if (input.startsWith("S:"))   { myServo.write(input.substring(2).toInt()); Serial.println("SERVO_OK"); }
    else if (input == "WAITER")        { runWaiterSequence(); }
    else if (input == "RESET")         { resetRobot(); }
  }
  delay(2);
}
