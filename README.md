# Water Level Measurement System - ESP32 & Flutter

## About the Project
This project was developed as part of the BBM434 Embedded Systems Lab. It uses an ultrasonic distance sensor to measure the water level in any well or objects up to 5 meters away. It displays this data on an LCD screen installed in the tank and transmits it instantly to an Android/Web application using the ESP32's WiFi/Bluetooth capabilities.

---

## Tools Used
- **ESP32** (or Arduino with WiFi Shield is preferred)
- **HC-SR04 Ultrasonic Distance Sensor**
- **Flutter Framework** (for Android/Web application development)
- **Internet Connection**
- **(Optional) LCD I2C Display**
- **PlatformIO VS Code Extension** (for ESP32 programming)

---

## Features
- **Real-Time Monitoring:** Thanks to the Flutter-based Android/Web application that communicates with the ESP32, the user can view the water level in real time and with animations.
- **LCD Display:** On-site monitoring of the water level via an LCD I2C display installed in the tank.
