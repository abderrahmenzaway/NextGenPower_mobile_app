/* ======================================================
      FULL MERGED SMART ENERGY SYSTEM
   - Solar tracking (2× LDR)
   - Wind turbine servo control
   - Gas detection with fan + LED alert
   - ACS712 current measurement on LCD
   - Bluetooth serial
   - Fully debugged and unified
   ====================================================== */

#include <Servo.h>
#include <SoftwareSerial.h>
#include <Wire.h>
#include <LiquidCrystal_I2C.h>

// ------------------------------------------------------
//  LCD
// ------------------------------------------------------
LiquidCrystal_I2C lcd(0x27, 16, 2);

// ------------------------------------------------------
//  LDR Solar Tracking
// ------------------------------------------------------
#define LDR1 A0
#define LDR2 A1
#define LDR_ERROR 20

int solarPosition = 90;
Servo solarServo;

// ------------------------------------------------------
//  Wind Servo
// ------------------------------------------------------
Servo windServo;
int windPosition = 90;
int solarServoPin = 10;
int windServoPin  = 9;

// ------------------------------------------------------
//  Bluetooth
// ------------------------------------------------------
SoftwareSerial BTSerial(2, 3);

// ------------------------------------------------------
//  Current Sensor (ACS712)
// ------------------------------------------------------
const int nSamples = 1000;
const float vcc = 5.0;
const int adcMax = 1023;
const float sens = 0.66;  // sensitivity of ACS712

// ------------------------------------------------------
//  Gas Sensor
// ------------------------------------------------------
#define GAS_PIN A2
#define FAN1 5       // Fan output
#define FAN2 6
#define GAS_LED 7
#define GAS_THRESHOLD 350

// ------------------------------------------------------
void setup() {
  Serial.begin(9600);
  BTSerial.begin(9600);
  pinMode(FAN1, OUTPUT);
  pinMode(FAN2, OUTPUT);
  pinMode(GAS_PIN, INPUT);

  pinMode(GAS_LED, OUTPUT);

  // LCD
  lcd.init();
  lcd.backlight();
  lcd.clear();
  lcd.setCursor(0, 0);
  lcd.print("System Ready");

  // Servos
  solarServo.attach(solarServoPin);
  solarServo.write(solarPosition);

  windServo.attach(windServoPin);
  windServo.write(windPosition);

  delay(400);
  Serial.println("SYSTEM_READY...");
}

// ------------------------------------------------------
//  Average current reading
// ------------------------------------------------------
float avgCurrent() {
  float sum = 0;
  for (int i = 0; i < nSamples; i++) {
    sum += analogRead(A3);   // same A0 used for ACS712
    delay(1);
  }
  float avg = sum / nSamples;
  return (vcc / 2 - (avg * vcc / adcMax)) / sens;
}

// ------------------------------------------------------
void loop() {

  // ======================================================
  //  GAS SENSOR
  // ======================================================
  int gasValue = analogRead(GAS_PIN);
  Serial.print("Gas value: ");
  Serial.println(gasValue);

  if (gasValue > GAS_THRESHOLD) {
    digitalWrite(FAN1, HIGH);
    digitalWrite(FAN2 , LOW);

    digitalWrite(GAS_LED, HIGH);
    delay(80);
    digitalWrite(GAS_LED, LOW);
    delay(80);

    // PRIORITY MODE (skips rest of loop)
    return;
  }  
  else {
    // Gas normal mode → turn fan & LED OFF
    digitalWrite(FAN1, LOW);
    digitalWrite(FAN2 , LOW);
    digitalWrite(GAS_LED, LOW);
  }


  // ======================================================
  //  CURRENT MEASUREMENT + LCD
  // ======================================================
  float current = avgCurrent();  
  float mA = (current ) * 1000;  // calibration correction

  lcd.setCursor(0, 0);
  lcd.print("Current:      ");
  lcd.setCursor(0, 1);
  lcd.print(mA);

  Serial.print("Current: ");
  Serial.println(current);
  BTSerial.write((int)mA);


  // ======================================================
  //  SOLAR TRACKING (2× LDR)
  // ======================================================
  int ldr1 = analogRead(LDR1) - 50;
  int ldr2 = analogRead(LDR2);
  int diff = ldr1 - ldr2;

  if (abs(diff) > LDR_ERROR) {
    if (ldr1 > ldr2) solarPosition-=10;
    else solarPosition+=10;
  }

  if (solarPosition < 0) solarPosition = 0;
  if (solarPosition > 180) solarPosition = 180;

  solarServo.write(solarPosition);

  Serial.print("LDR1=");
  Serial.print(ldr1);
  Serial.print("  LDR2=");
  Serial.print(ldr2);
  Serial.print("  Pos=");
  Serial.println(solarPosition);


  // ======================================================
  //  WIND SERVO (commands via Serial)
  // ======================================================
  if (Serial.available() > 0) {
    String cmd = Serial.readStringUntil('\n');
    cmd.trim();
    processWindCommand(cmd);
  }

  delay(10);
}


// ------------------------------------------------------
//  Wind Servo Control Function
// ------------------------------------------------------
void moveWindServo(int target) {
  if (target > windPosition) {
    for (int a = windPosition; a <= target; a++) {
      windServo.write(a);
      delay(10);
    }
  }
  else {
    for (int a = windPosition; a >= target; a--) {
      windServo.write(a);
      delay(10);
    }
  }

  windPosition = target;
}

// ------------------------------------------------------
//  Serial Input Commands
// ------------------------------------------------------
void processWindCommand(String command) {

  if (command.startsWith("SET_ANGLE:")) {
    int target = command.substring(command.indexOf(':') + 1).toInt();

    if (target >= 0 && target <= 180) {
      moveWindServo(target);
      Serial.print("ANGLE_SET:");
      Serial.println(target);
    } else {
      Serial.println("INVALID_ANGLE");
    }
  }

  else if (command == "GET_ANGLE") {
    Serial.print("CURRENT_ANGLE:");
    Serial.println(windPosition);
  }

  else if (command == "TEST") {
    Serial.println("TEST_OK");
  }

  else {
    Serial.print("UNKNOWN_COMMAND: ");
    Serial.println(command);
  }
}
