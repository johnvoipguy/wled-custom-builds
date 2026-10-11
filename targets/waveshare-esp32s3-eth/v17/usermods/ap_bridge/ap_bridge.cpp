// Backbone-AP-Bridge settings usermod (rev 1, 2026-10-11)
// One-stop settings page for the WLED_AP_BRIDGE build (Usermods page, saved in cfg.json).
// Settings home only: the bridge itself lives in the 0002 core patch.
// Writes straight into the core globals (apSSID/apPass/apChannel/apHide/apBehavior plus the
// apBridge* globals from 0002), so the WiFi settings page and this page stay in sync.
// WLED doesn't restart the AP when these change, so a save that changes anything reboots.
#include "wled.h"

#ifndef WLED_AP_BRIDGE
  #error "ap_bridge usermod requires the WLED_AP_BRIDGE build (0002 patch)"
#endif

class ApBridgeUsermod : public Usermod {
  private:
    bool initDone = false;
    bool alwaysOn = true;
    static const char _name[];

  public:
    void setup() override { initDone = true; }
    void loop() override {}

    void addToConfig(JsonObject& root) override {
      JsonObject top = root.createNestedObject(FPSTR(_name));
      top[F("bridge")]   = apBridgeEnabled;
      top[F("ssid")]     = apSSID;
      top[F("key")]      = "";      // write-only: the AP key stays in wsec.json, never shown here
      top[F("channel")]  = apChannel;
      top[F("hidden")]   = (bool)apHide;
      top[F("alwaysOn")] = alwaysOn;
      top[F("staCap")]   = apBridgeMaxSta;
      top[F("no11b")]    = apBridgeNo11b;
    }

    bool readFromConfig(JsonObject& root) override {
      JsonObject top = root[FPSTR(_name)];
      bool configComplete = !top.isNull();

      bool bridge = apBridgeEnabled;
      char ssid[33];
      strlcpy(ssid, apSSID, sizeof(ssid));
      byte channel = apChannel;
      bool hidden = apHide;
      byte staCap = apBridgeMaxSta;
      bool no11b = apBridgeNo11b;

      configComplete &= getJsonValue(top[F("bridge")], bridge, true);
      const char *s = top[F("ssid")] | "";
      if (*s) strlcpy(ssid, s, sizeof(ssid));
      configComplete &= !top[F("ssid")].isNull();
      configComplete &= getJsonValue(top[F("channel")], channel);
      configComplete &= getJsonValue(top[F("hidden")], hidden);
      configComplete &= getJsonValue(top[F("alwaysOn")], alwaysOn, true);
      configComplete &= getJsonValue(top[F("staCap")], staCap, 3);
      configComplete &= getJsonValue(top[F("no11b")], no11b, false);
      if (channel < 1 || channel > 13) channel = 6;
      if (staCap < 1) staCap = 1;
      if (staCap > 10) staCap = 10;    // ESP32 softAP limit

      bool changed = bridge != apBridgeEnabled || strcmp(ssid, apSSID) != 0 || channel != apChannel
                  || hidden != (bool)apHide || staCap != apBridgeMaxSta || no11b != apBridgeNo11b;

      apBridgeEnabled = bridge;
      strlcpy(apSSID, ssid, sizeof(apSSID));
      apChannel = channel;
      apHide = hidden;
      apBridgeMaxSta = staCap;
      apBridgeNo11b = no11b;

      // Key is write-only: only a non-empty entry replaces it (8-64 chars, WPA2 minimum).
      const char *key = top[F("key")] | "";
      size_t keyLen = strlen(key);
      if (keyLen >= 8 && keyLen <= 64 && strcmp(key, apPass) != 0) {
        strlcpy(apPass, key, sizeof(apPass));
        changed = true;
      }

      // The bridge needs the AP up all the time (a stopped AP would leave a dead bridge port),
      // so always-on is forced while the bridge is enabled.
      byte behavior = (alwaysOn || apBridgeEnabled) ? AP_BEHAVIOR_ALWAYS : apBehavior;
      if (behavior != apBehavior) changed = true;
      apBehavior = behavior;

      if (initDone && changed) doReboot = true;  // save from the Usermods page: reboot to apply
      return configComplete;
    }

    void appendConfigData() override {
      oappend(F("addInfo('ApBridge:bridge',1,'reboots on save');"));
      oappend(F("addInfo('ApBridge:key',1,'leave empty to keep current (8-64 chars)');"));
      oappend(F("addInfo('ApBridge:alwaysOn',1,'forced on while bridge is enabled');"));
      oappend(F("addInfo('ApBridge:staCap',1,'max wireless nodes (default 3)');"));
      oappend(F("addInfo('ApBridge:no11b',1,'disable 802.11b rates on the AP');"));
    }
};

const char ApBridgeUsermod::_name[] PROGMEM = "ApBridge";

static ApBridgeUsermod ap_bridge;
REGISTER_USERMOD(ap_bridge);
