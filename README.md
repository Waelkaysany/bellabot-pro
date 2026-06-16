# 🤖 BellaBot Pro - Robot Controller

A premium IoT robot prototype system utilizing an **ESP32** microcontroller and a modern **Flutter companion application** to build an interactive assistant robot with a moving arm, light-up eyes, LCD feedback, a buzzer, and an **RFID RC522 card reader** for payment simulation.

---

## 📂 Project Structure

* **`lib/`**: Flutter mobile application code (Provider state management, custom UI pages, and REST API controller integration).
* **`firmware/`**: ESP32 C++ Arduino sketch containing:
  * Local HTTP web server endpoints (`/led`, `/servo`, `/waiter`, `/birthday`, `/reset`).
  * Non-blocking melody playback and light sequence routines.
  * Auto-reconnect Wi-Fi client mode with SoftAP access point fallback.
  * MFRC522 RFID reader integration for scanning payments.

---

## 🦾 Hardware Wiring Topology

### ⚠️ Important Prerequisites
* **Ground Rail:** Use a shared Ground (GND) rail on your breadboard.
* **Power (5V vs 3.3V):**
  * The **SG90 Servo** and **LCD** must be powered from the **VIN (5V)** pin on the ESP32.
  * The **RC522 RFID module** MUST be powered from the **3.3V** pin, *not* 5V (5V will damage it!).

| Component | Pin / Wire | Connects to ESP32 | Notes |
| :--- | :--- | :--- | :--- |
| **Left Eye (Green LED)** | Anode (+) | **GPIO 4** | Use a 220Ω resistor |
| | Cathode (-) | **Shared GND** | |
| **Right Eye (Red LED)** | Anode (+) | **GPIO 2** | Use a 220Ω resistor |
| | Cathode (-) | **Shared GND** | |
| **SG90 Servo** | Signal (Orange) | **GPIO 13** | PWM Control |
| | VCC (Red) | **VIN (5V)** | Power |
| | GND (Brown) | **Shared GND** | |
| **I2C LCD (16x2)** | SDA | **GPIO 21** | Data line |
| | SCL | **GPIO 22** | Clock line |
| | VCC | **VIN (5V)** | Power |
| | GND | **Shared GND** | |
| **Buzzer** | Signal (+) | **GPIO 25** | Tone output |
| | GND (-) | **Shared GND** | |
| **RFID RC522 Reader** | 3.3V | **3.3V** | Power |
| | RST | **GPIO 14** | Reset |
| | GND | **Shared GND** | Ground |
| | MISO | **GPIO 19** | SPI Data |
| | MOSI | **GPIO 23** | SPI Data |
| | SCK | **GPIO 18** | SPI Clock |
| | SDA (SS) | **GPIO 5** | Chip Select |

---

## 🛠️ Setup Instructions

### 1. ESP32 Firmware
1. Open the [esp32_control.ino](firmware/esp32_control.ino) file in Arduino IDE.
2. Install the following libraries via the Library Manager:
   * **MFRC522** by GithubCommunity
   * **LiquidCrystal I2C by Frank de Brabander**
   * **ESP32Servo**
3. Set your phone hotspot details or use the default `Hello` SSID.
4. Select **ESP32 Dev Module** and upload the sketch.

### 2. Flutter Mobile Application
1. Configure Flutter on your system.
2. Run `flutter pub get` in this directory to restore packages.
3. Connect your Android device and run `flutter run --release` to install.
