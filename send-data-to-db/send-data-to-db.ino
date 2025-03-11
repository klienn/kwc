#include <Arduino.h>
#include <WiFi.h>
#include <WiFiClientSecure.h>

#include <FirebaseClient.h>  // Your Firebase library
#include <ModbusRTU.h>       // Modbus library
#include <ArduinoJson.h>     // For JSON building

// ========== Wi-Fi Credentials ==========
#define WIFI_SSID "scam ni"
#define WIFI_PASSWORD "Walakokabalo0123!"

// ========== Firebase ==========
#define API_KEY "AIzaSyD7aoCF1RaeP-7DjR63AcGXt036g-XQ-Eo"
#define USER_EMAIL "test2@getnada.com"
#define USER_PASSWORD "testtest"
#define DATABASE_URL "https://kwc-register-7c3e1-default-rtdb.firebaseio.com/"
// e.g. https://myproj-default-rtdb.firebaseio.com/

// ========== Modbus ==========
#define DE_RE_PIN 4  // RS485 DE/RE pin
#define BAUD_RATE 9600
#define FIRST_REG 0x2000
#define REG_COUNT 16

// For the total energy (kWh) at 0x4000–0x4001
#define ENERGY_ADDR 0x4000

// Example arrangement: multiple meters, each has (slaveId, name)
struct MeterInfo {
  uint8_t slaveId;
  const char *name;  // e.g. "meterA", "meterB", etc.
};

MeterInfo meters[] = {
  { 11, "meterA" },
  { 12, "meterB" },
  { 13, "meterC" },
  { 14, "meterD" }
  // Add more meter slave IDs if needed
};
const int NUM_METERS = sizeof(meters) / sizeof(meters[0]);

// Modbus object
ModbusRTU mb;

// We'll track the result of each Modbus transaction
static Modbus::ResultCode lastModbusResult = Modbus::EX_SUCCESS;

// The callback sets lastModbusResult if there's an error
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

// Forward declaration
bool readAndPushMeterData(uint8_t slaveId, const char *meterName);
bool readInputRegisters(uint8_t slaveId, float &voltage, float &currentVal,
                        float &activePower, float &reactivePower,
                        float &powerFactor, float &frequency);
bool readTotalEnergy(uint8_t slaveId, float &totalEnergy);

// Print any Firebase result messages
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
  Serial1.begin(BAUD_RATE, SERIAL_8N1, 22, 23);  // TX=23, RX=22 (adjust if needed)
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


  // ========== 4) Drive GPIO33 HIGH ==========
  pinMode(33, OUTPUT);
  digitalWrite(33, HIGH);
  Serial.println("GPIO33 set to HIGH.");
}

void loop() {
  // Handle firebase tasks
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
 *  - If no error, pushes data to /meterData/<meterName> in Firebase
 *  - Returns true if data was successfully read & pushed, false on error.
 */
bool readAndPushMeterData(uint8_t slaveId, const char *meterName) {
  Serial.printf("\n--- Reading from slave %d (%s) ---\n", slaveId, meterName);

  // We'll store the results of both reads here:
  float voltage = 0, currentVal = 0, activePower = 0;
  float reactivePower = 0, powerFactor = 0, frequency = 0;
  float totalEnergy = 0;

  // 1) Read input registers for standard measurements
  bool okInput = readInputRegisters(slaveId, voltage, currentVal, activePower,
                                    reactivePower, powerFactor, frequency);
  if (!okInput) return false;

  // 2) Read holding register for total kWh @ 0x4000
  bool okEnergy = readTotalEnergy(slaveId, totalEnergy);
  if (!okEnergy) return false;

  // Debug print
  Serial.printf("  V=%.2f, I=%.2f, P=%.2f, Q=%.2f, PF=%.3f, F=%.2f, Ep=%.4f kWh\n",
                voltage, currentVal, activePower, reactivePower,
                powerFactor, frequency, totalEnergy);

  // Build JSON with ArduinoJson
  StaticJsonDocument<256> doc;
  doc["timestamp"][".sv"] = "timestamp";
  doc["voltage"] = voltage;
  doc["current"] = currentVal;
  doc["activePower"] = activePower;
  doc["reactivePower"] = reactivePower;
  doc["powerFactor"] = powerFactor;
  doc["frequency"] = frequency;
  doc["totalEnergy"] = totalEnergy;  // the newly read kWh

  String jsonPayload;
  serializeJson(doc, jsonPayload);

  // Push to /meterData/<meterName>
  String path = String("/meterData/") + meterName;
  object_t data(jsonPayload);

  // If Firebase app is ready, do the push
  if (app.ready()) {
    Database.push<object_t>(aClient, path, data, aResult_no_callback);
    Serial.printf("  Pushed to %s\n", path.c_str());
    return true;
  } else {
    Serial.println("  Firebase app not ready. Skipped push.");
    return false;
  }
}

/**
 * readInputRegisters
 *  - Reads addresses 0x2000..0x200F from the meter (input registers, function code 0x04)
 *  - Parses voltage/current/power/frequency, returns true if success
 */
bool readInputRegisters(uint8_t slaveId, float &voltage, float &currentVal,
                        float &activePower, float &reactivePower,
                        float &powerFactor, float &frequency) {
  uint16_t res[REG_COUNT] = { 0 };

  lastModbusResult = Modbus::EX_SUCCESS;
  // Read input registers (function code 0x04)
  mb.readIreg(slaveId, FIRST_REG, res, REG_COUNT, modbusCallback);

  // Wait for transaction
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

  // Parse them (same logic as before)
  // Voltage @ 0x2000–0x2001 => res[0],res[1]
  datamod.i[0] = res[1];
  datamod.i[1] = res[0];
  voltage = datamod.f;

  // Current @ 0x2002–0x2003 => res[2],res[3]
  datamod.i[0] = res[3];
  datamod.i[1] = res[2];
  currentVal = datamod.f;

  // Active Power @ 0x2004–0x2005 => res[4],res[5]
  datamod.i[0] = res[5];
  datamod.i[1] = res[4];
  activePower = datamod.f;

  // Reactive Power @ 0x2006–0x2007 => res[6],res[7]
  datamod.i[0] = res[7];
  datamod.i[1] = res[6];
  reactivePower = datamod.f;

  // Power Factor @ 0x200A–0x200B => res[10],res[11]
  datamod.i[0] = res[11];
  datamod.i[1] = res[10];
  powerFactor = datamod.f;

  // Frequency @ 0x200E–0x200F => res[14],res[15]
  datamod.i[0] = res[15];
  datamod.i[1] = res[14];
  frequency = datamod.f;

  // success
  return true;
}

/**
 * readTotalEnergy
 *  - Reads 2 registers from 0x4000 (holding registers, function code 0x03)
 *  - Interprets them as a single precision float
 *  - Returns true if success, modifies totalEnergy
 */
bool readTotalEnergy(uint8_t slaveId, float &totalEnergy) {
  // Adjust if you suspect offset issues (e.g. 0x3FFF or 0x4001).
  const uint16_t energyReg = ENERGY_ADDR;

  uint16_t epRegs[2] = { 0 };

  lastModbusResult = Modbus::EX_SUCCESS;
  // Use readHreg => function code 0x03
  mb.readHreg(slaveId, energyReg, epRegs, 2, modbusCallback);

  // Wait for transaction
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

  // Try same word order as the others
  datamod.i[0] = epRegs[1];  // low word
  datamod.i[1] = epRegs[0];  // high word
  totalEnergy = datamod.f;

  return true;
}