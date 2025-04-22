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

// Adjust these if you have different IDs/names
MeterInfo meters[] = {
  { 11, "meterA" },
  { 12, "meterB" },
  { 13, "meterC" },
  { 14, "meterD" }
};
const int NUM_METERS = sizeof(meters) / sizeof(meters[0]);

// We'll assign each meter a dedicated GPIO pin for on/off control
struct MeterPinMap {
  const char *meterName;  // same as in meters[]
  uint8_t pin;
};

MeterPinMap meterPins[] = {
  { "meterA", 33 },
  { "meterB", 32 },
  { "meterC", 25 },
  { "meterD", 26 }
};
const int NUM_METER_PINS = sizeof(meterPins) / sizeof(meterPins[0]);

// Modbus object
ModbusRTU mb;
static Modbus::ResultCode lastModbusResult = Modbus::EX_SUCCESS;

// Callback that sets lastModbusResult if there's an error
bool modbusCallback(Modbus::ResultCode event, uint16_t transactionId, void *data) {
  lastModbusResult = event;
  if (event != Modbus::EX_SUCCESS) {
    Serial.print("Modbus request error: 0x");
    Serial.println(event, HEX);
  }
  return true;
}

// Firebase objects
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
bool readAndPushMeterData(uint8_t slaveId, const char *meterName);
bool readInputRegisters(uint8_t slaveId, float &voltage, float &currentVal,
                        float &activePower, float &reactivePower,
                        float &powerFactor, float &frequency);
bool readTotalEnergy(uint8_t slaveId, float &totalEnergy);
bool getMeterEnabled(const char *meterName, bool &enabledOut);

void fbThrottle() {
  delay(50);
  app.loop();
  Database.loop();
}

// Print any Firebase result messages (same as before)
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

  // 1) Wi-Fi
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  Serial.print("Connecting to Wi-Fi");
  while (WiFi.status() != WL_CONNECTED) {
    Serial.print(".");
    delay(300);
  }
  Serial.println();
  Serial.print("Connected! IP Address: ");
  Serial.println(WiFi.localIP());

  // 2) Modbus
  Serial1.begin(BAUD_RATE, SERIAL_8N1, 22, 23);
  mb.begin(&Serial1, DE_RE_PIN);
  mb.master();
  Serial.println("Modbus initialized.");

  // 3) Firebase
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

  // 4) Initialize Meter Control Pins
  for (int i = 0; i < NUM_METER_PINS; i++) {
    pinMode(meterPins[i].pin, OUTPUT);
    digitalWrite(meterPins[i].pin, LOW);  // default to HIGH
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

  // Let Firebase handle any async tasks
  app.loop();
  Database.loop();

  unsigned long currentMillis = millis();
  if (currentMillis - previousMillis >= interval) {
    previousMillis = currentMillis;

    // Query each meter in turn
    for (int i = 0; i < NUM_METERS; i++) {
      bool success = readAndPushMeterData(meters[i].slaveId, meters[i].name);
      if (!success) {
        Serial.printf("[Meter: %s] Read or push skipped due to error.\n", meters[i].name);
      }
    }
  }

  printResult(aResult_no_callback);
}

/**
 * readAndPushMeterData
 *  - Reads from a single Modbus slave
 *  - Pushes data to /meterData/<meterName> in Firebase
 *  - Then checks /meterControl/<meterName>/enabled to set the corresponding GPIO
 */
bool readAndPushMeterData(uint8_t slaveId, const char *meterName) {
  Serial.printf("\n--- Reading from slave %d (%s) ---\n", slaveId, meterName);

  // 5) Now poll the "enabled" value from DB for this meter
  bool meterEnabled = true;  // default
  bool gotStatus = getMeterEnabled(meterName, meterEnabled);
  if (gotStatus) {
    // Find which pin belongs to this meter
    int meterPin = -1;
    for (int i = 0; i < NUM_METER_PINS; i++) {
      if (strcmp(meterPins[i].meterName, meterName) == 0) {
        meterPin = meterPins[i].pin;
        break;
      }
    }
    if (meterPin >= 0) {
      digitalWrite(meterPin, meterEnabled ? HIGH : LOW);
      Serial.printf("  => Setting pin %d to %s\n", meterPin, meterEnabled ? "HIGH" : "LOW");
    }
  } else {
    Serial.println("  => Could not read meterEnabled from DB (error). Keeping pin as-is.");
  }

  float voltage = 0, currentVal = 0, activePower = 0;
  float reactivePower = 0, powerFactor = 0, frequency = 0;
  float totalEnergy = 0;

  // 1) Read input registers
  bool okInput = readInputRegisters(slaveId, voltage, currentVal, activePower,
                                    reactivePower, powerFactor, frequency);
  if (!okInput) return false;

  // 2) Read total energy
  bool okEnergy = readTotalEnergy(slaveId, totalEnergy);
  if (!okEnergy) return false;

  // Debug
  Serial.printf("  V=%.2f, I=%.2f, P=%.2f, Q=%.2f, PF=%.3f, F=%.2f, Ep=%.4f kWh\n",
                voltage, currentVal, activePower, reactivePower,
                powerFactor, frequency, totalEnergy);

  // 3) Build JSON
  // Using DynamicJsonDocument to avoid the deprecation warning:
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
  // 4) Push to /meterData/<meterName>
  String path = String("/meterData/") + meterName;
  object_t data(jsonPayload);
  if (app.ready()) {
    Database.push<object_t>(aClient, path, data, aResult_no_callback);
    fbThrottle();
    Serial.printf("  Pushed to %s\n", path.c_str());
  } else {
    Serial.println("  Firebase app not ready. Skipped push.");
    return false;
  }

  return true;
}

/**
 * readInputRegisters
 *  - Reads addresses 0x2000..0x200F from the meter (function code 0x04)
 *  - Returns true if success
 */
bool readInputRegisters(uint8_t slaveId, float &voltage, float &currentVal,
                        float &activePower, float &reactivePower,
                        float &powerFactor, float &frequency) {
  uint16_t res[REG_COUNT] = { 0 };
  lastModbusResult = Modbus::EX_SUCCESS;
  mb.readIreg(slaveId, FIRST_REG, res, REG_COUNT, modbusCallback);

  // Wait
  while (mb.slave()) {
    mb.task();
    delay(10);
  }

  if (lastModbusResult != Modbus::EX_SUCCESS) {
    Serial.println("Failed to read input registers (0x2000..).");
    return false;
  }

  union {
    uint16_t i[2];
    float f;
  } datamod;

  // Voltage (0x2000-0x2001)
  datamod.i[0] = res[1];
  datamod.i[1] = res[0];
  voltage = datamod.f;

  // Current (0x2002-0x2003)
  datamod.i[0] = res[3];
  datamod.i[1] = res[2];
  currentVal = datamod.f;

  // Active Power (0x2004-0x2005)
  datamod.i[0] = res[5];
  datamod.i[1] = res[4];
  activePower = datamod.f;

  // Reactive Power (0x2006-0x2007)
  datamod.i[0] = res[7];
  datamod.i[1] = res[6];
  reactivePower = datamod.f;

  // Power Factor (0x200A-0x200B)
  datamod.i[0] = res[11];
  datamod.i[1] = res[10];
  powerFactor = datamod.f;

  // Frequency (0x200E-0x200F)
  datamod.i[0] = res[15];
  datamod.i[1] = res[14];
  frequency = datamod.f;

  return true;
}

/**
 * readTotalEnergy
 *  - Reads 2 registers from 0x4000 (holding registers, function code 0x03)
 *  - Interprets as float
 */
bool readTotalEnergy(uint8_t slaveId, float &totalEnergy) {
  uint16_t epRegs[2] = { 0 };
  lastModbusResult = Modbus::EX_SUCCESS;
  mb.readHreg(slaveId, ENERGY_ADDR, epRegs, 2, modbusCallback);

  // Wait
  while (mb.slave()) {
    mb.task();
    delay(10);
  }

  if (lastModbusResult != Modbus::EX_SUCCESS) {
    Serial.println("Failed to read totalEnergy (0x4000).");
    return false;
  }

  union {
    uint16_t i[2];
    float f;
  } datamod;
  datamod.i[0] = epRegs[1];  // low word
  datamod.i[1] = epRegs[0];  // high word
  totalEnergy = datamod.f;

  return true;
}

/**
 * getMeterEnabled
 *  - Reads a boolean from "/meterControl/<meterName>/enabled"
 *    via a synchronous call that returns a bool
 */
bool getMeterEnabled(const char *meterName, bool &enabledOut) {
  // Build path e.g. "/meterControl/meterA/enabled"
  String path = String("/meterControl/") + meterName + "/enabled";
  fbThrottle();
  bool val = false;
  val = Database.get<bool>(aClient, path);
  fbThrottle();
  enabledOut = val;
  return true;
}
