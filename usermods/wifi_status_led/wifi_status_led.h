#pragma once
#include "wled.h"

#ifndef WIFI_STATUS_LED_PIN
  #define WIFI_STATUS_LED_PIN 0
#endif

#ifndef WIFI_STATUS_LED_INVERTED
  #define WIFI_STATUS_LED_INVERTED true
#endif

#ifndef USERMOD_ID_WIFI_STATUS_LED
  #define USERMOD_ID_WIFI_STATUS_LED 9901
#endif

class WiFiStatusLEDUsermod : public Usermod {
  private:
    bool enabled = true;
    int8_t wifiStatusLedPin = WIFI_STATUS_LED_PIN;
    bool inverted = WIFI_STATUS_LED_INVERTED;
    bool lastWifiState = false;

  public:
    void setup() {
      if (wifiStatusLedPin >= 0) {
        if (!PinManager::allocatePin(wifiStatusLedPin, true, PinOwner::UM_Unspecified)) {
          wifiStatusLedPin = -1;
          enabled = false;
          return;
        }
        pinMode(wifiStatusLedPin, OUTPUT);
        digitalWrite(wifiStatusLedPin, inverted ? true : false);
      }
    }

    void loop() {
      if (!enabled || wifiStatusLedPin < 0) return;
      
      bool currentWifiState = (WLED_CONNECTED);
      
      if (currentWifiState != lastWifiState) {
        lastWifiState = currentWifiState;
        digitalWrite(wifiStatusLedPin, inverted ? !currentWifiState : currentWifiState);
      }
    }

    void addToConfig(JsonObject& root) {
      JsonObject top = root.createNestedObject(F("WiFi Status LED"));
      top[F("enabled")] = enabled;
      top[F("pin")] = wifiStatusLedPin;
      top[F("inverted")] = inverted;
    }

    bool readFromConfig(JsonObject& root) {
      JsonObject top = root[F("WiFi Status LED")];
      bool configComplete = !top.isNull();
      
      configComplete &= getJsonValue(top[F("enabled")], enabled);
      configComplete &= getJsonValue(top[F("pin")], wifiStatusLedPin);
      configComplete &= getJsonValue(top[F("inverted")], inverted);
      
      return configComplete;
    }

    uint16_t getId() {
      return USERMOD_ID_WIFI_STATUS_LED;
    }
};
