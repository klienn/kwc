#include <Arduino.h>
#include <WiFi.h>
#include <WiFiClientSecure.h>

// Firebase
#include <FirebaseClient.h>  // Your Firebase library

// Modbus
#include <ModbusRTU.h>

// ArduinoJson
#include <ArduinoJson.h>

// ========== Wi-Fi Credentials ==========
#define WIFI_SSID "scam ni"
#define WIFI_PASSWORD "Walakokabalo0123!"

// ========== Firebase ==========
#define API_KEY "AIzaSyD7aoCF1RaeP-7DjR63AcGXt036g-XQ-Eo"
#define USER_EMAIL "test2@getnada.com"
#define USER_PASSWORD "testtest"
#define DATABASE_URL "https://kwc-register-7c3e1-default-rtdb.firebaseio.com/"

// ========== Modbus ==========
#define DE_RE_PIN 4  // RS485 DE/RE pin
#define BAUD_RATE 9600
#define FIRST_REG 0x2000
#define REG_COUNT 16

// For the total energy (kWh) at 0x4000–0x4001
#define ENERGY_ADDR 0x4000

// Each meter has a slave ID and a "name"
struct MeterInfo {
  uint8_t slaveId;
  const char *name;  // e.g. "meterA", "meterB"
};

MeterInfo meters[] = {
  { 11, "meterA" },
  { 12, "meterB" },
  { 13, "meterC" },
  { 14, "meterD" }
};
const int NUM_METERS = sizeof(meters) / sizeof(meters[0]);

// We'll assign each meter a dedicated GPIO pin for on/off control
struct MeterPinMap {
  const char *meterName;
  uint8_t pin;
};

MeterPinMap meterPins[] = {
  { "meterA", 33 },
  { "meterB", 32 },
  { "meterC", 25 },
  { "meterD", 26 }
};
const int NUM_METER_PINS = sizeof(meterPins) / sizeof(meterPins[0]);

ModbusRTU mb;
static Modbus::ResultCode lastModbusResult = Modbus::EX_SUCCESS;

bool modbusCallback(Modbus::ResultCode event, uint16_t transactionId, void *data) {
  lastModbusResult = event;
  if (event != Modbus::EX_SUCCESS) {
    Serial.print("Modbus request error: 0x");
    Serial.println(event, HEX);
  }
  return true;
}

// Firebase
DefaultNetwork network;
UserAuth user_auth(API_KEY, USER_EMAIL, USER_PASSWORD);
FirebaseApp app;
WiFiClientSecure ssl_client;
using AsyncClient = AsyncClientClass;
AsyncClient aClient(ssl_client, getNetwork(network));
RealtimeDatabase Database;
AsyncResult aResult_no_callback;

unsigned long previousMillis = 0;
const long interval = 5000;  // poll every 5 seconds

// Forward declarations
bool readInputRegisters(uint8_t, float &, float &, float &, float &, float &, float &);
bool readTotalEnergy(uint8_t, float &);
bool getMeterEnabled(const char *, bool &);

void fbThrottle() {
  delay(50);
  app.loop();
  Database.loop();
}

void printResult(AsyncResult &aResult) {
  if (aResult.isEvent()) {
    Firebase.printf("Event task: %s, msg: %s, code: %d\n", aResult.uid().c_str(), aResult.appEvent().message().c_str(), aResult.appEvent().code());
  }
  if (aResult.isDebug()) {
    Firebase.printf("Debug task: %s, msg: %s\n", aResult.uid().c_str(), aResult.debug().c_str());
  }
  if (aResult.isError()) {
    Firebase.printf("Error task: %s, msg: %s, code: %d\n", aResult.uid().c_str(), aResult.error().message().c_str(), aResult.error().code());
  }
  if (aResult.available()) {
    Firebase.printf("task: %s, payload: %s\n", aResult.uid().c_str(), aResult.c_str());
  }
}

void setup() {
  Serial.begin(115200);
  delay(500);
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  while (WiFi.status() != WL_CONNECTED) {
    Serial.print(".");
    delay(300);
  }
  Serial.println("\nWiFi connected");

  Serial1.begin(BAUD_RATE, SERIAL_8N1, 22, 23);
  mb.begin(&Serial1, DE_RE_PIN);
  mb.master();

  ssl_client.setInsecure();
  initializeApp(aClient, app, getAuth(user_auth), aResult_no_callback);
  app.getApp<RealtimeDatabase>(Database);
  Database.url(DATABASE_URL);

  for (int i = 0; i < NUM_METER_PINS; i++) {
    pinMode(meterPins[i].pin, OUTPUT);
    digitalWrite(meterPins[i].pin, LOW);
  }
}

void loop() {
  app.loop();
  Database.loop();
  unsigned long currentMillis = millis();
  if (currentMillis - previousMillis >= interval) {
    previousMillis = currentMillis;

    DynamicJsonDocument batchDoc(2048);
    for (int i = 0; i < NUM_METERS; i++) {
      float v, c, p, q, pf, f, ep;
      if (!readInputRegisters(meters[i].slaveId, v, c, p, q, pf, f)) continue;
      if (!readTotalEnergy(meters[i].slaveId, ep)) continue;

      JsonObject obj = batchDoc[meters[i].name].to<JsonObject>();
      obj["timestamp"][".sv"] = "timestamp";
      obj["voltage"] = v;
      obj["current"] = c;
      obj["activePower"] = p;
      obj["reactivePower"] = q;
      obj["powerFactor"] = pf;
      obj["frequency"] = f;
      obj["totalEnergy"] = ep;

      bool enabled;
      if (getMeterEnabled(meters[i].name, enabled)) {
        for (int j = 0; j < NUM_METER_PINS; j++) {
          if (strcmp(meterPins[j].meterName, meters[i].name) == 0) {
            digitalWrite(meterPins[j].pin, enabled ? HIGH : LOW);
          }
        }
      }
    }

    String json;
    serializeJson(batchDoc, json);
    object_t all(json);
    Database.update<object_t>(aClient, "/meterData", all, aResult_no_callback);
  }

  printResult(aResult_no_callback);
}

bool readInputRegisters(uint8_t slaveId, float &v, float &c, float &p, float &q, float &pf, float &f) {
  uint16_t res[REG_COUNT] = { 0 };
  lastModbusResult = Modbus::EX_SUCCESS;
  mb.readIreg(slaveId, FIRST_REG, res, REG_COUNT, modbusCallback);
  while (mb.slave()) {
    mb.task();
    delay(10);
  }
  if (lastModbusResult != Modbus::EX_SUCCESS) return false;
  union {
    uint16_t i[2];
    float f;
  } d;
  d.i[0] = res[1];
  d.i[1] = res[0];
  v = d.f;
  d.i[0] = res[3];
  d.i[1] = res[2];
  c = d.f;
  d.i[0] = res[5];
  d.i[1] = res[4];
  p = d.f;
  d.i[0] = res[7];
  d.i[1] = res[6];
  q = d.f;
  d.i[0] = res[11];
  d.i[1] = res[10];
  pf = d.f;
  d.i[0] = res[15];
  d.i[1] = res[14];
  f = d.f;
  return true;
}

bool readTotalEnergy(uint8_t slaveId, float &ep) {
  uint16_t r[2] = { 0 };
  lastModbusResult = Modbus::EX_SUCCESS;
  mb.readHreg(slaveId, ENERGY_ADDR, r, 2, modbusCallback);
  while (mb.slave()) {
    mb.task();
    delay(10);
  }
  if (lastModbusResult != Modbus::EX_SUCCESS) return false;
  union {
    uint16_t i[2];
    float f;
  } d;
  d.i[0] = r[1];
  d.i[1] = r[0];
  ep = d.f;
  return true;
}

bool getMeterEnabled(const char *name, bool &enabledOut) {
  String path = String("/meterControl/") + name + "/enabled";
  fbThrottle();
  enabledOut = Database.get<bool>(aClient, path);
  fbThrottle();
  return true;
}
