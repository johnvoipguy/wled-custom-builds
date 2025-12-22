#include <Arduino.h>
#include "config.h"

void setup() {
    // Initialize serial communication at 115200 baud rate
    Serial.begin(115200);
    // Add any additional setup code here
}

void loop() {
    // Main loop code goes here
    Serial.println("Hello, Seeed XIAO ESP32-S3!");
    delay(1000); // Delay for 1 second
}