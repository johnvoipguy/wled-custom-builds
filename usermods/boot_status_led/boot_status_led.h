#pragma once
#include "wled.h"

#ifndef BOOT_STATUS_LED_PIN
  #define BOOT_STATUS_LED_PIN 1
#endif

#ifndef BOOT_STATUS_LED_INVERTED
  #define BOOT_STATUS_LED_INVERTED true
#endif

#ifndef USERMOD_ID_BOOT_STATUS_LED
  #define USERMOD_ID_BOOT_STATUS_LED 9902
#endif

class BootStatusLEDUsermod : public Usermod {
  private:
    bool enabled = true;
    int8_t bootStatusLedPin = BOOT_STATUS_LED_PIN;
    bool inverted = BOOT_STATUS_LED_INVERTED;
    bool ledState = false;

  public:
    void setup() {
      if (bootStatusLedPin >= 0) {
        if (!PinManager::allocatePin(bootStatusLedPin, true, PinOwner::UM_Unspecified)) {
          bootStatusLedPin = -1;
          enabled = false;
          return;
        }
        pinMode(bootStatusLedPin, OUTPUT);
        ledState = true;
        digitalWrite(bootStatusLedPin, inverted ? !ledState : ledState);
      }
    }

    void loop() {
      // Nothing to do in loop - LED stays on once boot is complete
    }

    void addToConfig(JsonObject& root) {
      JsonObject top = root.createNestedObject(F("Boot Status LED"));
      top[F("enabled")] = enabled;
      top[F("pin")] = bootStatusLedPin;
      top[F("inverted")] = inverted;
    }

    bool readFromConfig(JsonObject& root) {
      JsonObject top = root[F("Boot Status LED")];
      bool configComplete = !top.isNull();
      
      configComplete &= getJsonValue(top[F("enabled")], enabled);
      configComplete &= getJsonValue(top[F("pin")], bootStatusLedPin);
      configComplete &= getJsonValue(top[F("inverted")], inverted);
      
      return configComplete;
    }

    uint16_t getId() {
      return USERMOD_ID_BOOT_STATUS_LED;
    }
};
