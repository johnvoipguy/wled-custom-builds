# ap_bridge — Backbone-AP-Bridge settings

Settings page for the `waveshare_esp32s3_eth_v5_apbridge` build (`-D WLED_AP_BRIDGE`).
Shows up under **Settings → Usermods → ApBridge**, saved in `cfg.json`.

| Setting | What it does |
|---|---|
| `bridge` | W5500 ↔ AP L2 bridge on/off (off = behaves like regular v17) |
| `ssid` | AP SSID (same global as the WiFi settings page). Default `WLED_BRIDGE` |
| `key` | AP key, write-only (8–64 chars), default `876543210`. Leave empty to keep the current key. **The AP is not bridged until the key is changed from the default** (an AP with no key, or still on the default, stays a local 4.3.2.1 AP; the default is public in this repo). The Usermods page shows a warning while the default is active |
| `channel` | AP channel 1–13 |
| `hidden` | Hide the AP SSID |
| `alwaysOn` | Force AP always on. Forced on while `bridge` is enabled |
| `staCap` | Max wireless nodes on the AP (default 3, firmware-enforced) |
| `no11b` | Disable 802.11b rates on the AP |
| `txPower` | Max WiFi TX power (same global as the WiFi settings page). Default 21 dBm, the IDF maximum |

Writes directly into WLED's core globals (`apSSID`, `apPass`, `apChannel`, `apHide`,
`apBehavior`, `txPower`), so the WiFi settings page stays in sync. WLED doesn't restart the AP when these
change, so saving a change here **reboots** the device.

This usermod is the settings home only. The bridge bring-up is in `patches/0002-backbone-ap-bridge.patch`.
