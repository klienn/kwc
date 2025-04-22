#include <Arduino.h>
#include <WiFi.h>
#include <WiFiClientSecure.h>

// Firebase
#include <FirebaseClient.h>

// Modbus
#include <ModbusRTU.h>

// ArduinoJson
#include <ArduinoJson.h>

#define WIFI_SSID "scam ni"
#define WIFI_PASSWORD "Walakokabalo0123!"

#define API_KEY "AIzaSyD7aoCF1RaeP-7DjR63AcGXt036g-XQ-Eo"
#define USER_EMAIL "test2@getnada.com"
#define USER_PASSWORD "testtest"
#define DATABASE_URL "https://kwc-register-7c3e1-default-rtdb.firebaseio.com/"

#define DE_RE_PIN 4
#define BAUD_RATE 9600
#define FIRST_REG 0x2000
#define REG_COUNT 16
#define ENERGY_ADDR 0x4000

struct MeterInfo {
  uint8_t slaveId;
  const char *name;
};

MeterInfo meters[] = {
  { 11, "meterA" },
  { 12, "meterB" },
  { 13, "meterC" },
  { 14, "meterD" }
};
const int NUM_METERS = sizeof(meters) / sizeof(meters[0]);

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

DefaultNetwork network;
UserAuth user_auth(API_KEY, USER_EMAIL, USER_PASSWORD);
FirebaseApp app;
WiFiClientSecure ssl_client;
using AsyncClient = AsyncClientClass;
AsyncClient aClient(ssl_client, getNetwork(network));
RealtimeDatabase Database;
AsyncResult aResult_no_callback;

unsigned long lastControlCheckMillis = 0;
const long controlCheckInterval = 1000;

void fbThrottle() {
  delay(50);
  app.loop();
  Database.loop();
}

void printResult(AsyncResult &aResult) {
  if (aResult.isEvent()) {
    Firebase.printf("Event task: %s, msg: %s, code: %d\n",
                    aResult.uid().c_str(),
                    aResult.appEvent().message().c_str(),
                    aResult.appEvent().code());
  }
  if (aResult.isDebug()) {
    Firebase.printf("Debug task: %s, msg: %s\n",
                    aResult.uid().c_str(),
                    aResult.debug().c_str());
  }
  if (aResult.isError()) {
    Firebase.printf("Error task: %s, msg: %s, code: %d\n",
                    aResult.uid().c_str(),
                    aResult.error().message().c_str(),
                    aResult.error().code());
  }
  if (aResult.available()) {
    Firebase.printf("task: %s, payload: %s\n",
                    aResult.uid().c_str(),
                    aResult.c_str());
  }
}

void setup() {
  Serial.begin(115200);
  delay(500);

  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  Serial.print("Connecting to Wi-Fi");
  while (WiFi.status() != WL_CONNECTED) {
    Serial.print(".");
    delay(300);
  }
  Serial.println();
  Serial.print("Connected! IP Address: ");
  Serial.println(WiFi.localIP());

  Serial1.begin(BAUD_RATE, SERIAL_8N1, 22, 23);
  mb.begin(&Serial1, DE_RE_PIN);
  mb.master();
  Serial.println("Modbus initialized.");

#if defined(ESP32) || defined(ESP8266) || defined(PICO_RP2040)
  ssl_client.setInsecure();
#if defined(ESP8266)
  ssl_client.setBufferSizes(4096, 1024);
#endif
#endif

  Serial.println("Initializing Firebase...");
  initializeApp(aClient, app, getAuth(user_auth), aResult_no_callback);
  app.getApp<RealtimeDatabase>(Database);
  Database.url(DATABASE_URL);
  Serial.println("Firebase setup complete.");

  for (int i = 0; i < NUM_METER_PINS; i++) {
    pinMode(meterPins[i].pin, OUTPUT);
    digitalWrite(meterPins[i].pin, LOW);
    Serial.printf("Pin %d assigned to %s set HIGH at startup\n", meterPins[i].pin, meterPins[i].meterName);
  }
}

void loop() {
  if (WiFi.status() != WL_CONNECTED) {
    Serial.println("Wi-Fi disconnected! Attempting reconnect...");
    WiFi.disconnect();
    WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
    delay(1000);
    return;
  }

  app.loop();
  Database.loop();

  unsigned long currentMillis = millis();

  if (currentMillis - lastControlCheckMillis >= controlCheckInterval) {
    lastControlCheckMillis = currentMillis;
    for (int i = 0; i < NUM_METERS; i++) {
      bool meterEnabled = true;
      if (getMeterEnabled(meters[i].name, meterEnabled)) {
        for (int j = 0; j < NUM_METER_PINS; j++) {
          if (strcmp(meterPins[j].meterName, meters[i].name) == 0) {
            digitalWrite(meterPins[j].pin, meterEnabled ? HIGH : LOW);
            break;
          }
        }
      }
    }
  }

  static int meterIndex = 0;
  static bool waitingToPush = false;
  static bool meterReadSuccess = false;

  if (!waitingToPush && !mb.slave() && app.ready()) {
    Serial.printf("\n[Meter %s] Starting read and prepare\n", meters[meterIndex].name);
    meterReadSuccess = readAndPushMeterData(meters[meterIndex].slaveId, meters[meterIndex].name);
    waitingToPush = meterReadSuccess;
  }

  if (waitingToPush) {
    if (aResult_no_callback.available() || aResult_no_callback.isError()) {
      if (aResult_no_callback.isError()) {
        Serial.printf("[Meter %s] Firebase push failed. Will retry this meter.\n", meters[meterIndex].name);
      } else {
        Serial.printf("[Meter %s] Firebase push success.\n", meters[meterIndex].name);
        meterIndex = (meterIndex + 1) % NUM_METERS;
      }
      waitingToPush = false;
      aResult_no_callback.clear();
    }
  }

  printResult(aResult_no_callback);
}

bool readAndPushMeterData(uint8_t slaveId, const char *meterName) {
  float voltage = 0, currentVal = 0, activePower = 0;
  float reactivePower = 0, powerFactor = 0, frequency = 0;
  float totalEnergy = 0;

  bool okInput = readInputRegisters(slaveId, voltage, currentVal, activePower,
                                    reactivePower, powerFactor, frequency);
  if (!okInput) return false;

  bool okEnergy = readTotalEnergy(slaveId, totalEnergy);
  if (!okEnergy) return false;

  Serial.printf("  V=%.2f, I=%.2f, P=%.2f, Q=%.2f, PF=%.3f, F=%.2f, Ep=%.4f kWh\n",
                voltage, currentVal, activePower, reactivePower,
                powerFactor, frequency, totalEnergy);

  DynamicJsonDocument doc(256);
  doc["timestamp"][".sv"] = "timestamp";
  doc["voltage"] = voltage;
  doc["current"] = currentVal;
  doc["activePower"] = activePower;
  doc["reactivePower"] = reactivePower;
  doc["powerFactor"] = powerFactor;
  doc["frequency"] = frequency;
  doc["totalEnergy"] = totalEnergy;

  String jsonPayload;
  serializeJson(doc, jsonPayload);
  fbThrottle();

  String path = String("/meterData/") + meterName;
  object_t data(jsonPayload);
  Database.push<object_t>(aClient, path, data, aResult_no_callback);
  fbThrottle();
  return true;
}

bool readInputRegisters(uint8_t slaveId, float &voltage, float &currentVal,
                        float &activePower, float &reactivePower,
                        float &powerFactor, float &frequency) {
  uint16_t res[REG_COUNT] = { 0 };
  lastModbusResult = Modbus::EX_SUCCESS;
  mb.readIreg(slaveId, FIRST_REG, res, REG_COUNT, modbusCallback);

  while (mb.slave()) {
    mb.task();
    delay(10);
  }

  if (lastModbusResult != Modbus::EX_SUCCESS) {
    Serial.println("Failed to read input registers (0x2000..).\n");
    return false;
  }

  union {
    uint16_t i[2];
    float f;
  } datamod;

  datamod.i[0] = res[1];
  datamod.i[1] = res[0];
  voltage = datamod.f;
  datamod.i[0] = res[3];
  datamod.i[1] = res[2];
  currentVal = datamod.f;
  datamod.i[0] = res[5];
  datamod.i[1] = res[4];
  activePower = datamod.f;
  datamod.i[0] = res[7];
  datamod.i[1] = res[6];
  reactivePower = datamod.f;
  datamod.i[0] = res[11];
  datamod.i[1] = res[10];
  powerFactor = datamod.f;
  datamod.i[0] = res[15];
  datamod.i[1] = res[14];
  frequency = datamod.f;

  return true;
}

bool readTotalEnergy(uint8_t slaveId, float &totalEnergy) {
  uint16_t epRegs[2] = { 0 };
  lastModbusResult = Modbus::EX_SUCCESS;
  mb.readHreg(slaveId, ENERGY_ADDR, epRegs, 2, modbusCallback);

  while (mb.slave()) {
    mb.task();
    delay(10);
  }

  if (lastModbusResult != Modbus::EX_SUCCESS) {
    Serial.println("Failed to read totalEnergy (0x4000).\n");
    return false;
  }

  union {
    uint16_t i[2];
    float f;
  } datamod;
  datamod.i[0] = epRegs[1];
  datamod.i[1] = epRegs[0];
  totalEnergy = datamod.f;
  return true;
}

bool getMeterEnabled(const char *meterName, bool &enabledOut) {
  String path = String("/meterControl/") + meterName + "/enabled";
  fbThrottle();
  bool val = false;
  val = Database.get<bool>(aClient, path);
  fbThrottle();
  enabledOut = val;
  return true;
}
