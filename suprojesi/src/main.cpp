
#include <NewPing.h>
#include <Wire.h>
#include <LiquidCrystal_I2C.h>
#include <Arduino.h>
#ifdef ESP32
#include <WiFi.h>
#include <AsyncTCP.h>
#elif defined(ESP8266)
#include <ESP8266WiFi.h>
#include <ESPAsyncTCP.h>
#endif
#include <ESPAsyncWebServer.h>
#include <stdio.h>
#include <stdlib.h>

// 5v - ground olarak 12nin yanındaki pini kullan

#define TRIGGER_PIN 26
#define ECHO_PIN 25
#define MAX_DISTANCE 500

NewPing sonar(TRIGGER_PIN, ECHO_PIN, MAX_DISTANCE);
LiquidCrystal_I2C lcd(0x27, 16, 2);

AsyncWebServer server(80);

const char *ssid = "telefon";
const char *password = "123456789";

void not_found(AsyncWebServerRequest *request)
{
  request->send(404, "text/plain", "Not found");
}

// HTML sayfası
const char index_html[] PROGMEM = R"rawliteral(
<!DOCTYPE HTML><html>
<head>
  <title>Sonar Ping Data</title>
  <script>
    function fetchSonarData() {
      fetch('/sonar')
        .then(response => response.text())
        .then(data => {
          document.getElementById('sonarData').innerText = data + ' cm';
        });
    }
    window.onload = function() {
      fetchSonarData();
      setInterval(fetchSonarData, 2000);
    }
  </script>
</head>
<body>
  <h1>Sonar Ping Data</h1>
  <p>Distance: <span id="sonarData">Loading...</span></p>
</body>
</html>
)rawliteral";

int sonarPing = 0;

void setup()
{
  Serial.begin(115200);

  Serial.print("Connecting to ");
  Serial.print(ssid);

  WiFi.mode(WIFI_STA);
  WiFi.begin(ssid, password);

  while (WiFi.waitForConnectResult() != WL_CONNECTED)
  {
    Serial.printf("WiFi Failed!\n");
    return;
  }

  Serial.println("Wifi connected, IP address: ");
  Serial.println(WiFi.localIP());

  server.on("/", HTTP_GET, [](AsyncWebServerRequest *request)
            { request->send_P(200, "text/html", index_html); });

  server.on("/sonar", HTTP_GET, [](AsyncWebServerRequest *request)
            {
    String sonarData = String(sonarPing);
    request->send(200, "text/plain", sonarData); });

  server.onNotFound(not_found);
  server.begin();

  lcd.init();
  lcd.backlight();
}

static int state = 0;
void distanceSensor()
{
  delay(50);

  sonarPing = sonar.ping_cm();

  if (sonar.ping_cm() < 10)
  {
    if (state == 1 || state == 2)
    {
      lcd.clear();
    }

    state = 0;
    lcd.setCursor(1, 0);
    lcd.print("uzaklik:");
    lcd.setCursor(10, 0);
    lcd.print(sonar.ping_cm());
    lcd.setCursor(12, 0);
    lcd.print("cm");
  }

  else if (sonar.ping() >= 10 && sonar.ping_cm() < 100)
  {
    if (state == 0 || state == 2)
    {
      lcd.clear();
    }

    state = 1;
    lcd.setCursor(1, 0);
    lcd.print("uzaklik:");
    lcd.setCursor(10, 0);
    lcd.print(sonar.ping_cm());
    lcd.setCursor(13, 0);
    lcd.print("cm");
  }

  else if (sonar.ping_cm() >= 100)
  {
    if (state == 0 || state == 1)
    {
      lcd.clear();
    }

    state = 2;
    lcd.setCursor(1, 0);
    lcd.print("uzaklik:");
    lcd.setCursor(10, 0);
    lcd.print(sonar.ping_cm());
    lcd.setCursor(14, 0);
    lcd.print("cm");
  }
  delay(2000);
}
void loop()
{
  distanceSensor();
}
