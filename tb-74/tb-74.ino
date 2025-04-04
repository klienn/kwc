#include <Arduino.h>
#include <WiFi.h>
#include <WiFiClientSecure.h>
#include <HTTPClient.h>  // For sending the POST request

// Firebase
#include <FirebaseClient.h>

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

// ========== Webhook URL ==========
#define WEBHOOK_URL "https://kwc.onrender.com/xendit/webhook"

// ========================
// Bill Acceptor Pins
// ========================
static const int METER_PIN = 23;   // pulses read
static const int INHIBIT_PIN = 5;  // transistor base or direct line to acceptor's inhibit

// ========================
// Bill Acceptor Globals
// ========================
volatile unsigned long pulseCount = 0;
volatile unsigned long lastPulseMillis = 0;

const unsigned long PULSE_DONE_TIMEOUT = 2000;  // 2s no pulses => finalize a bill

enum BillReadingState {
  IDLE,
  READING
};
BillReadingState currentBillState = IDLE;

bool acceptorEnabled = false;
unsigned long currentInsertedPesos = 0;

// We'll store user/payment info from /cashPayments/activePayment
String currentUserId = "";
String currentPaymentId = "";  // set from "referenceId" in DB
String currentPaymentStatus = "";
int currentAmountTarget = 0;

// ========================
// ISR for pulses
// ========================
void IRAM_ATTR meterPulseISR() {
  pulseCount++;
  lastPulseMillis = millis();
}

// ========================
// getBillValueFromPulses
//   Adjust thresholds to match your hardware
// ========================
int getBillValueFromPulses(unsigned long pulses) {
  if (pulses >= 100) {
    return 1000;  // 1000 pesos
  } else if (pulses >= 50) {
    return 500;
  } else if (pulses >= 11) {
    return 100;
  } else if (pulses >= 6) {
    return 50;
  } else if (pulses >= 1) {
    return 20;
  }
  return 0;  // no valid bill
}

// ========================
// setAcceptorEnabled
//   If LOW = accept, HIGH = inhibit (adjust if reversed)
// ========================
void setAcceptorEnabled(bool enable) {
  acceptorEnabled = enable;
  digitalWrite(INHIBIT_PIN, enable ? LOW : HIGH);

  Serial.print("Bill acceptor is now ");
  Serial.println(enable ? "ENABLED" : "DISABLED");
}

// ========================
// Firebase Client Globals
// ========================
DefaultNetwork network;
UserAuth user_auth(API_KEY, USER_EMAIL, USER_PASSWORD);
FirebaseApp app;
WiFiClientSecure ssl_client;
using AsyncClient = AsyncClientClass;
AsyncClient aClient(ssl_client, getNetwork(network));
RealtimeDatabase Database;
AsyncResult aResult_no_callback;

// ========================
// updatePaymentField
//   - partial update: /cashPayments/activePayment
// ========================
void updatePaymentField(const String &paymentPath, int amountInserted, const String &status) {
  // e.g. paymentPath="/cashPayments/activePayment"
  StaticJsonDocument<128> doc;
  doc["amountInserted"] = amountInserted;
  doc["status"] = status;

  String payload;
  serializeJson(doc, payload);

  object_t data(payload);
  Database.update<object_t>(aClient, paymentPath, data, aResult_no_callback);
}

// ========================
// sendArduinoPayment
//   - send a POST to the external webhook
// ========================
void sendArduinoPayment(const String &userId, int amountTarget, int amountInserted, const String &refId) {
  if (WiFi.status() != WL_CONNECTED) {
    Serial.println("WiFi not connected, cannot send payment to webhook");
    return;
  }

  HTTPClient http;
  http.begin(WEBHOOK_URL);
  http.addHeader("Content-Type", "application/json");

  // Build JSON
  StaticJsonDocument<256> doc;
  doc["fromArduino"] = true;
  doc["userId"] = userId;
  doc["amountTarget"] = amountTarget;
  doc["amountInserted"] = amountInserted;
  // If you want "ARD-" prefix, do so; or keep refId as is:
  doc["referenceId"] = "ARD-" + refId;

  String jsonPayload;
  serializeJson(doc, jsonPayload);

  Serial.println("Posting to webhook: " + jsonPayload);

  int httpCode = http.POST(jsonPayload);
  if (httpCode == 200) {
    Serial.println("Webhook POST success.");
  } else {
    Serial.printf("Webhook failed. HTTP code: %d\n", httpCode);
  }
  http.end();
}

// ========================
// pollCashPayments
//   - read /cashPayments/activePayment
//   - parse status, userId, referenceId, etc.
//   - if pending/in_progress => acceptor ON
//   - else => acceptor OFF
// ========================
void pollCashPayments() {
  String singlePaymentJson = Database.get<String>(aClient, "/cashPayments/activePayment");
  if (singlePaymentJson.isEmpty()) {
    Serial.println("No activePayment data or error => disabling acceptor.");
    setAcceptorEnabled(false);
    currentPaymentId = "";
    currentPaymentStatus = "";
    currentUserId = "";
    currentInsertedPesos = 0;
    currentAmountTarget = 0;
    return;
  }

  StaticJsonDocument<512> doc;
  DeserializationError err = deserializeJson(doc, singlePaymentJson);
  if (err) {
    Serial.println("JSON parse error => disabling acceptor.");
    setAcceptorEnabled(false);
    return;
  }

  String userId = doc["userId"] | "";
  String refId = doc["referenceId"] | "";
  String status = doc["status"] | "unknown";
  int amtTarget = doc["amountTarget"] | 0;
  int amtInserted = doc["amountInserted"] | 0;

  currentPaymentId = refId;
  currentUserId = userId;
  currentAmountTarget = amtTarget;

  Serial.println("----- /cashPayments/activePayment -----");
  Serial.printf("referenceId: %s, status: %s, userId: %s\n",
                refId.c_str(), status.c_str(), userId.c_str());
  Serial.printf("amountTarget: %d, amountInserted: %d\n", amtTarget, amtInserted);

  if (status == "pending") {
    updatePaymentField("/cashPayments/activePayment", 0, "in_progress");
    currentPaymentStatus = "in_progress";
    currentInsertedPesos = 0;
    setAcceptorEnabled(true);
  } else if (status == "in_progress") {
    currentPaymentStatus = "in_progress";
    setAcceptorEnabled(true);
  } else if (status == "completed") {
    currentPaymentStatus = "completed";
    setAcceptorEnabled(false);

    // Send webhook only once per completed payment
    static String lastSentRef = "";
    if (lastSentRef != currentPaymentId) {
      sendArduinoPayment(currentUserId, amtTarget, amtInserted, currentPaymentId);
      lastSentRef = currentPaymentId;
    }
  } else {
    // Unknown or irrelevant status
    setAcceptorEnabled(false);
    currentPaymentStatus = status;
  }
}


// ========================
// finalizePaymentIfNeeded
//   - if currentInsertedPesos >= currentAmountTarget => mark completed
//   - then call sendArduinoPayment(...)
// ========================
void finalizePaymentIfNeeded() {
  if (currentPaymentStatus != "in_progress") return;
  if (currentPaymentId.isEmpty()) return;
  if (currentAmountTarget <= 0) return;

  if ((int)currentInsertedPesos >= currentAmountTarget) {
    Serial.println("Payment target reached! Marking completed.");
    updatePaymentField("/cashPayments/activePayment", currentInsertedPesos, "completed");
    setAcceptorEnabled(false);

    // Optionally reset
    // currentPaymentId = "";
    // currentUserId = "";
    // currentPaymentStatus = "";
    // currentInsertedPesos = 0;
  } else {
    // partial update
    updatePaymentField("/cashPayments/activePayment", currentInsertedPesos, "in_progress");
  }
}

// ========================
// handleBillAcceptor
//   - interpret pulses => finalize single bill
// ========================
void handleBillAcceptor() {
  unsigned long now = millis();

  if (currentBillState == IDLE) {
    if (pulseCount > 0 && acceptorEnabled) {
      currentBillState = READING;
      Serial.println("Bill insertion detected: reading pulses...");
    }
  } else if (currentBillState == READING) {
    if ((now - lastPulseMillis) >= PULSE_DONE_TIMEOUT) {
      unsigned long finalCount = pulseCount;
      pulseCount = 0;
      currentBillState = IDLE;

      if (finalCount > 0) {
        // Temporarily disable acceptor while processing this bill
        setAcceptorEnabled(false);

        int billValue = getBillValueFromPulses(finalCount);
        if (billValue > 0) {
          Serial.printf("Detected %lu pulses => %d pesos!\n", finalCount, billValue);
          currentInsertedPesos += billValue;
          Serial.printf("Total inserted so far: %lu\n", currentInsertedPesos);

          // Update DB before enabling acceptor again
          updatePaymentField("/cashPayments/activePayment", currentInsertedPesos, "in_progress");

          // Re-enable acceptor after DB update
          setAcceptorEnabled(true);
        } else {
          Serial.printf("No valid bill for %lu pulses.\n", finalCount);
          // Still re-enable in case it was a misread
          setAcceptorEnabled(true);
        }
      }
    }
  }

  // Debug printing every 3 seconds
  static unsigned long lastPrint = 0;
  if (now - lastPrint >= 3000) {
    lastPrint = now;
    Serial.print("Bill State: ");
    Serial.println((currentBillState == IDLE) ? "IDLE" : "READING");
    Serial.print("Acceptor enabled? ");
    Serial.println(acceptorEnabled ? "YES" : "NO");
    Serial.print("pulseCount: ");
    Serial.println(pulseCount);
    Serial.print("currentInsertedPesos: ");
    Serial.println(currentInsertedPesos);
    Serial.println();
  }
}


// ========================
// setup
// ========================
void setup() {
  Serial.begin(115200);
  delay(1000);

  pinMode(METER_PIN, INPUT);
  attachInterrupt(digitalPinToInterrupt(METER_PIN), meterPulseISR, FALLING);
  lastPulseMillis = millis();

  pinMode(INHIBIT_PIN, OUTPUT);
  digitalWrite(INHIBIT_PIN, HIGH);  // start disabled
  acceptorEnabled = false;

  // Wi-Fi
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  Serial.print("Connecting to Wi-Fi");
  while (WiFi.status() != WL_CONNECTED) {
    Serial.print(".");
    delay(300);
  }
  Serial.println("\nConnected! IP: " + WiFi.localIP().toString());

  // Firebase init
#if defined(ESP32) || defined(ESP8266)
  ssl_client.setInsecure();
#endif
  initializeApp(aClient, app, getAuth(user_auth), aResult_no_callback);
  app.getApp<RealtimeDatabase>(Database);
  Database.url(DATABASE_URL);

  Serial.println("Bill acceptor + Firebase integrated. Ready!");
}

// ========================
// loop
// ========================
void loop() {
  // Handle Firebase tasks
  app.loop();
  Database.loop();

  // Poll /cashPayments/activePayment every 3 seconds
  static unsigned long lastPoll = 0;
  unsigned long now = millis();
  if (now - lastPoll >= 3000) {
    lastPoll = now;
    pollCashPayments();
  }

  // Bill acceptor logic
  handleBillAcceptor();

  // If we've met the target => complete + send webhook
  finalizePaymentIfNeeded();
}
