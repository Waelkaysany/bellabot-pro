# 🤖 BellaBot Pro - Robot Controller

A premium IoT robot prototype system utilizing an **ESP32** microcontroller and a modern **Flutter companion application** to build an interactive assistant robot with a moving arm, light-up eyes, LCD feedback, and sound melodies.

---

## 📂 Project Structure

* **`lib/`**: Flutter mobile application code (Provider state management, custom UI pages, and REST API controller integration).
* **`firmware/`**: ESP32 C++ Arduino sketch containing:
  * Local HTTP web server endpoints (`/led`, `/servo`, `/waiter`, `/birthday`, `/reset`).
  * Non-blocking melody playback and light sequence routines.
  * Auto-reconnect Wi-Fi client mode with SoftAP access point fallback.

---

## 🦾 Hardware Wiring Topology

### ⚠️ Important Prerequisites
* **Ground Rail:** Use a shared Ground (GND) rail on your breadboard.
* **Power (5V):** The SG90 Servo and LCD display must be powered from the **VIN (5V)** pin on the ESP32 to operate reliably.

| Component | Pin / Wire | Connects to ESP32 | Notes |
| :--- | :--- | :--- | :--- |
| **Left Eye (Green LED)** | Anode (+) | **GPIO 18** | Use a 220Ω resistor |
| | Cathode (-) | **Shared GND** | |
| **Right Eye (Red LED)** | Anode (+) | **GPIO 19** | Use a 220Ω resistor |
| | Cathode (-) | **Shared GND** | |
| **SG90 Servo** | Signal (Orange) | **GPIO 23** | PWM Control |
| | VCC (Red) | **VIN (5V)** | Power |
| | GND (Brown) | **Shared GND** | |
| **I2C LCD (16x2)** | SDA | **GPIO 21** | Data line |
| | SCL | **GPIO 22** | Clock line |
| | VCC | **VIN (5V)** | Power |
| | GND | **Shared GND** | |
| **Buzzer** | Signal (+) | **GPIO 25** | Tone output |
| | GND (-) | **Shared GND** | |

---

## 🛠️ Setup Instructions

### 1. ESP32 Firmware
1. Open the [esp32_control.ino](firmware/esp32_control.ino) file in Arduino IDE.
2. Install the **LiquidCrystal I2C by Frank de Brabander** and **ESP32Servo** libraries via the Library Manager.
3. Set your phone hotspot details or use the default `Hello` SSID.
4. Select **ESP32 Dev Module** and upload the sketch.

### 2. Flutter Mobile Application
1. Configure Flutter on your system.
2. Run `flutter pub get` in this directory to restore packages.
3. Connect your Android device and run `flutter run --release` to install.
