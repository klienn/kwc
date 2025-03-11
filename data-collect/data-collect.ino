#include <Arduino.h>
#include <ModbusRTU.h>

#define SLAVE_ID 11
#define FIRST_REG 0x2000
#define REG_COUNT 16
#define DE_RE = 4

ModbusRTU mb;

union {
  uint16_t i[2];
  float f;
} datamod;

bool cb(Modbus::ResultCode event, uint16_t transactionId, void* data) {
  if (event != Modbus::EX_SUCCESS) {
    Serial.print("Request result: 0x");
    Serial.println(event, HEX);
  }
  return true;
}

unsigned long previousMillis = 0;
const long interval = 5000;

float voltage;
float current;
float activePower;
float reactivePower;
float powerFactor;
float frequency;

void setup() {
  Serial.begin(115200);
  delay(500);

  Serial1.begin(9600, SERIAL_8N1, 22, 23);

  mb.begin(&Serial1, DE_RE);
  mb.master();

  Serial.println("Modbus setup complete");
}

void loop() {
  unsigned long currentMillis = millis();

  if (currentMillis - previousMillis >= interval) {
    previousMillis = currentMillis;
    Serial.println("\n--- Reading Meter Data ---");

    // Only send new request if not waiting on previous
    if (!mb.slave()) {
      // Request 16 holding registers from address 0x2000
      static uint16_t res[REG_COUNT];

      mb.readIreg(SLAVE_ID, FIRST_REG, res, REG_COUNT, cb);

      // Wait for transaction to complete
      while (mb.slave()) {
        mb.task();
        delay(10);
      }

      // Print out raw data to see if frequency is non-zero now
      for (int i = 0; i < REG_COUNT; i++) {
        Serial.printf("res[%d] = 0x%04X\n", i, res[i]);
      }

      // Now parse the data from res[]:
      // 1) Voltage @ 0x2000–0x2001 => res[0],res[1]
      datamod.i[0] = res[1];  // low word
      datamod.i[1] = res[0];  // high word
      voltage = datamod.f;    // If you see a big value, maybe do voltage/10

      // 2) Current @ 0x2002–0x2003 => res[2],res[3]
      datamod.i[0] = res[3];
      datamod.i[1] = res[2];
      current = datamod.f;  // Possibly current/100 if needed

      // 3) Active Power @ 0x2004–0x2005 => res[4],res[5]
      datamod.i[0] = res[5];
      datamod.i[1] = res[4];
      activePower = datamod.f;  // in kW (as doc states)

      // 4) Reactive Power @ 0x2006–0x2007 => res[6],res[7]
      datamod.i[0] = res[7];
      datamod.i[1] = res[6];
      reactivePower = datamod.f;  // in kVar

      // 5) PF @ 0x200A–0x200B => res[10],res[11]
      datamod.i[0] = res[11];
      datamod.i[1] = res[10];
      powerFactor = datamod.f;  // typically -1 .. +1

      // 6) Frequency @ 0x200E–0x200F => res[14],res[15]
      datamod.i[0] = res[15];
      datamod.i[1] = res[14];
      frequency = datamod.f;  // Typically around 50 or 60

      Serial.printf("res[14] = 0x%04X\n", res[14]);
      Serial.printf("res[15] = 0x%04X\n", res[15]);

      // Print them out
      Serial.print("Voltage (V): ");
      Serial.println(voltage);

      Serial.print("Current (A): ");
      Serial.println(current);

      Serial.print("Active Power (kW): ");
      Serial.println(activePower);

      Serial.print("Reactive Power (kVar): ");
      Serial.println(reactivePower);

      Serial.print("Power Factor: ");
      Serial.println(powerFactor);

      Serial.print("Frequency (Hz): ");
      Serial.println(frequency);
    }
  }
}
