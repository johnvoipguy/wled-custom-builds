# Waveshare ESP32S3 Ethernet — v17 notes

## Hardware validation status

Validated on **two** physical Waveshare ESP32-S3-ETH boards:

- Ethernet (LAN/PoE): pass
- WiFi: pass
- xLights → DDP over Ethernet: pass
- xLights → DDP over WiFi: pass
- Web UI over Ethernet: pass
- Web UI over WiFi: pass
- Live LED-hardware-settings changes (add/remove/reconfigure buses at runtime, no reboot,
  including "skip first N LEDs" on both RMT- and I2S/LCD-driven buses) over both Ethernet
  and WiFi: pass

Not yet tested: MQTT, and a few other minor items — treat those as open until confirmed.

## Why this line exists (vs. v16)

The v16 line ports the *original* v0.15.1 approach forward: W5500 as its own hardware TCP/IP
socket engine (a vendored, patched `Ethernet_Generic` library), bridged into WLED's realtime
protocol handlers by hand. It's real hardware offload and it boots and runs — but it only
carries traffic that was explicitly wired up to go over it. **DDP/E1.31/pixel data does not
traverse the Ethernet interface in that model** — those protocols bind to lwIP/AsyncUDP, and
the W5500 hardware-socket stack is a separate, parallel stack that nothing else in WLED knows
about. Confirmed by testing: xLights DDP to the v16 firmware's Ethernet IP does not reach the
strip.

v17 targets WLED `main` on **ESP-IDF 5.5.4 / arduino-esp32 Core 3.3.8**, where W5500 is wired
up as `ETH_PHY_W5500` — a first-class lwIP network interface, exactly like the built-in RMII
Ethernet PHYs WLED already supports on other boards. Because it's a real lwIP interface, DDP,
E1.31, MQTT, the web UI, and OTA all work over it automatically, with no per-protocol glue code.
That's the whole point of this line existing separately from v16.

`build.json` sets `"wled_ref": "main"` — a **moving target**, refetched fresh on every build
(see `../seeed-xiao-esp32s3/nightly/build.json` for the same pattern already in use elsewhere
in this repo). Use `scripts/check-target-patches.sh waveshare-esp32s3-eth v17` periodically to
catch upstream drift (a `main` commit that no longer applies these patches cleanly) before it
turns into a build failure.

## What's in this target

- `patches/0001-w5500-native-lwip-ethernet.patch` — the WLED source changes: a parallel,
  SPI-only `ethernetBoards[]` table in `network.cpp` (WLED's stock table is RMII-only and
  `#error`s out on chips without `CONFIG_ETH_USE_ESP32_EMAC`, which includes the S3), a deferred
  `handleW5500()` in `wled.cpp`'s `loop()` (see below for why `ETH.begin()` can't run during
  early boot), reserved-pin reporting in `xml.cpp`, and dual WiFi+Ethernet IP display in the
  info panel (`json.cpp` / `data/index.js`). Also includes the `bus_manager.cpp` fixes described
  below (not Ethernet-specific, but part of the same patch since all were developed together).
- `lib/NeoPixelBus/` — vendored, patched copy of the exact NeoPixelBus commit WLED main's
  `[esp32_idf_V5]` env already pins. See `lib/NeoPixelBus/WLED_PATCH_NOTES.md` for the fixes
  themselves (RMT channel memory-block starvation, and an uninitialized pixel-buffer pointer —
  both on ESP32-S3, see below).
- `build.json` — `wled_ref: main`.
- `platformio.env.ini` — the `[env:waveshare_esp32s3_eth_v5]` fragment.

## Four bugs found and fixed along the way

The first two were found while chasing "LED hardware settings silently don't save" — which
turned out to be a real WLED-main/Core3.x bug, **not Ethernet/W5500-specific** (independently
reproduced on a SEEED ESP32-S3 board with no Ethernet at all).

### 1. `network.cpp` null-pointer-constant comparison (Ethernet-specific)

`multiWiFi[0].staticIP != (uint32_t)0x00000000` compiled as a null-pointer-constant comparison
against `IPAddress::operator==(const uint8_t*)`, i.e. `memcmp(NULL, ...)` — crashed on boot the
moment `handleW5500()` tried to apply a static IP config. Fixed by rewriting as
`(uint32_t)multiWiFi[0].staticIP != 0u`. (Also why `ETH.begin()` itself was moved out of
`initEthernet()` into a deferred `handleW5500()` called from `loop()`: calling it during early
boot, before Core 3.x's network stack exists, crashed with `LoadProhibited`/`EXCVADDR=0`.)

### 2. RMT channel memory-block starvation (not Ethernet-specific — a stock Core3/S3 bug)

Symptom: saving the LED settings page hung `loop()` forever (not a crash — `esp_task_wdt_reset()`
never got a chance to run either, since `WLED_WATCHDOG_TIMEOUT=0` on this env). Root-caused via
targeted logging to `BusManager::removeAll()`'s `while (!canAllShow()) yield();`
(`FX_fcn.cpp` → `finalizeInit()`), which spins forever if any bus's `canShow()` never returns
true. Traced to `NeoEsp32RmtXMethod.h`'s `Initialize()` requesting `mem_block_symbols = 192`
per RMT channel — ESP32-S3's RMT peripheral only has ~192 symbol-words *total*, shared across
all 4 TX channels (48 each), so the first channel created silently consumed the entire pool and
starved every channel after it. The three IDF driver calls' return codes were summed into a
local variable that was never checked, so the failure was invisible. Fixed in the vendored
NeoPixelBus copy (`mem_block_symbols = 48`, one block per channel) — see
`lib/NeoPixelBus/WLED_PATCH_NOTES.md` for the full writeup.

`bus_manager.cpp`'s `removeAll()` also got a **permanent, general-purpose fix** independent of
the above: the wait is now bounded (~3s) with a per-bus diagnostic dump on timeout instead of an
unconditional infinite spin, so any *future* stuck-bus condition (from any cause) can no longer
hang a save forever — it'll log which bus/type/pin is stuck and proceed anyway.

### 3. Sacrificial-pixel write before buffer allocation (a WLED bug, exposed by the I2S/LCD driver)

Symptom: setting "skip first N LEDs" on an **I2S/LCD-driven** bus (not RMT — a board with only
RMT-driven buses, i.e. 4 or fewer digital buses, did not reproduce this) and saving crashed
immediately (`Guru Meditation Error`, `StoreProhibited`, `EXCVADDR=0x0`) during the very next
boot's bus creation — not even during the save itself, since the poisoned config gets replayed
on every subsequent boot until fixed or reverted (this looked like a "bricked" board; it wasn't
— restoring the auto-saved `/bkp.cfg.json` backup recovers it).

Root-caused via exact `addr2line` resolution (LTO temporarily disabled for the diagnostic build)
of the crash backtrace to `BusDigital::BusDigital(const BusConfig&)` in `bus_manager.cpp`: the
"paint sacrificial/skipped pixels black" fix for wled#4759 called `PolyBus::setPixelColor()`
directly inside the bus constructor, immediately after `PolyBus::create()` — before
`bus->begin()` (called later, from `WS2812FX::finalizeInit()`) ever runs. For RMT-driven buses
this happens to be harmless, because `NeoEsp32RmtMethodBase`'s pixel buffer is malloc'd
unconditionally in its constructor. For I2S/LCD-driven buses it is not: `NeoEsp32LcdXMethodBase`
(and the classic-ESP32 `NeoEsp32I2sXMethodBase`) only allocate their pixel buffer inside
`Initialize()`, which is called from `begin()` — so writing a pixel color before `begin()` wrote
through a garbage/uninitialized pointer.

Fixed by moving the sacrificial-pixel blackout out of `BusDigital`'s constructor and into
`BusDigital::begin()`, after `PolyBus::begin()` (which allocates the buffer) has run. Also
added `_data(nullptr)` to both NeoPixelBus method constructors in the vendored copy as a general
safety net (see `lib/NeoPixelBus/WLED_PATCH_NOTES.md`) — not the primary fix, but it means an
un-`Initialize()`'d bus's destructor now does a safe `free(nullptr)` instead of freeing garbage,
for any other call path that might hit the same gap in the future.

### 4. LED Hardware settings page shows stale data right after a save (minor UX race)

Symptom: save the LED settings page, get redirected to the config menu, immediately click back
into LED Hardware — the pre-save config still shows, until a manual refresh or a moment's wait.
Not data loss — the save itself is correct; it's a display race.

Cause: `getSettingsJS()` (`xml.cpp`) builds the LED Hardware page from the *live*
`BusManager::busses` list, which is only rebuilt when `loop()` consumes `doInitBusses` (via
`finalizeInit()`) — asynchronously, on a later `loop()` iteration than the one that sent the
save's HTTP response. A fast enough client (or a request that happens to land before that
`loop()` iteration) can see the settings page before the rebuild finishes.

Fixed in `wled_server.cpp`'s POST handler: after `handleSettingsSet()` returns for
`SUBPAGE_LEDS`, the response is now held (bounded wait, ~3s) until `doInitBusses` is consumed,
so by the time the browser gets the response and navigates onward, the rebuild has already
happened. Safe to block here — this is the request-handler task polling a flag that `loop()`
clears independently, not the two tasks waiting on each other.

## Pin configuration

Same physical pins as v16 (`MISO=12 MOSI=11 SCLK=13 CS=14 INT=10 RST=9`), confirmed against the
Waveshare pinout diagram. `DATA_PINS` order is the *reverse* of v16's, with GPIO0 swapped for
GPIO21 and moved to the end (`18,17,16,15,3,2,1,21`) — GPIO0 is an S3 strapping pin that shares
the BOOT button and is the pin WLED's settings UI is most likely to reject; GPIO21 is free on
this board and clear of the W5500 SPI pins, SD card, and USB.

## What's not done

- MQTT not yet tested (see validation status above).
- Diagnostic `DEBUG_PRINT`/`Serial.printf` instrumentation from the investigation is still
  present (`set.cpp`, `wled.cpp`'s `entering finalizeInit`/`configNeedsWrite` lines,
  `bus_manager.cpp`'s bounded-wait diagnostic dump and pre-teardown bus manifest, and the RMT
  init ok/FAILED + LCD-destructor-null logging in the vendored NeoPixelBus). All are
  low-frequency/event-driven, not spam, and only emit under `WLED_DEBUG`. Left in deliberately
  for now since they're cheap insurance if anything else surfaces; strip if/when confidence is
  high enough to not need them.
- LTO is currently disabled on this env (`build_unflags` in `platformio.env.ini`) so any future
  crash backtrace resolves to an exact file:line via `addr2line` instead of collapsing to the
  enclosing function. Costs a bit of flash size/performance; re-enable once confidence is high.
- This target is deliberately scoped to the Waveshare board only, not sp530e/seeed-xiao.

## Building

```
scripts/apply-target.sh --target waveshare-esp32s3-eth --version v17 --workspace <wled-checkout>
scripts/build-target.sh --target waveshare-esp32s3-eth --version v17 ...
```

`build-target.sh` fetches `wled_ref` (`main`) fresh each run per `build.json`. Flash mode is the
same dual `board_build.flash_mode=qio` / `custom_merge_flash_mode=dio` split as v16 — see v16's
notes.md for why both values are required and load-bearing.
