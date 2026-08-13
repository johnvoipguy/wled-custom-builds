# Waveshare ESP32S3 Ethernet — v16 notes

W5500 Ethernet ported forward from the validated `waveshare-esp32s3-eth-v15.1` branch to
WLED `v16.0.1`. Compiled clean against a real `wled/WLED` v16.0.1 checkout (RAM 13.7%, Flash
39.3% on the partition layout below) — **not yet validated on physical hardware.**

## Active line status

- **Active line for this target:** `v16`
- WLED ref: `v16.0.1` (see `build.json`; there is no `0.16.1` — WLED dropped the `0.` prefix and
  moved from `Aircoookie/WLED` to `wled/WLED` between the 0.15.x and 16.x lines)
- Canonical PlatformIO environment: `waveshare_esp32s3_eth`
- Canonical env definition: `platformio.env.ini` **in this directory**, not `../shared/`.
  `../shared/platformio.env.ini` is frozen for the v15 line only — see "Why this isn't in
  shared/" below.

## What changed vs. the v15.1 port

The original `waveshare-esp32s3-eth-v15.1` branch is real, working code, not the dead-flag
scaffolding that existed in `main`/`shared/` before this port (those flags were never consumed
by any C++ code — verified by grep across `wled00/` — likely dating to a refactor of this
repo's `targets/` layout that never carried the actual driver forward). Porting it to 16.x
required real adaptation, not a copy-paste:

1. **`initEthernet()` moved from a `WLED` class method to a free function** between 0.15.1 and
   16.x (part of the "Static PinManager & UsermodManager" internal API change). The W5500 hook
   had to move with it — `initW5500Ethernet()`/`handleW5500()` are free functions declared in
   `fcn_declare.h`, not `WLED::` methods.
2. **Ethernet board index 13 is no longer free.** The 15.1-line port used `ethernetType == 13`
   for W5500. By 16.0.1, WLED's own `ethernetBoards[]` had grown to 16 entries and index 13 is
   now legitimately `WLED_ETH_GLEDOPTO`. Reusing 13 would silently hijack a real board's slot.
   This port appends a new entry instead: `WLED_ETH_WAVESHARE_S3_ETH_W5500 = 16`,
   `WLED_NUM_ETH_TYPES` 16→17. The array entry itself is a documented placeholder (W5500 is
   SPI-attached, none of the RMII fields apply) — `initEthernet()` still requires the table and
   the constant to agree in size (`static_assert` added upstream since 0.15.1), so the slot has
   to exist even though it's never read.
3. **`Network.cpp`'s `isEthernet()`/`isConnected()` were refactored** (isConnected now derives
   from isEthernet rather than duplicating the ETH check) — the W5500 hook follows the current
   shape rather than reintroducing the old duplication.
4. **The Arduino `Ethernet` library doesn't compile against this WLED line's arduino-esp32 core
   (2.0.18).** `IPAddress(0xFFFFFFFFul)` is ambiguous against that core's `IPAddress.h`, which
   added an `IPAddress(int)` constructor alongside `IPAddress(uint32_t)` — a real, reproducible
   compile error, not a WLED-specific issue. Swapping to `khoih-prog/Ethernet_Generic` (drop-in
   API-compatible, widely used for exactly this ESP32+W5500 combination) hits the *same*
   ambiguity in its own code, plus a second real issue below — so this port vendors a
   minimally-patched copy rather than depending on either library as-is. See `lib/Ethernet_Generic`.
5. **`Ethernet_Generic` is an h-only library** (function bodies live in headers, not just
   declarations) — including it from more than one `.cpp` causes ODR "multiple definition" link
   errors. `network.cpp` is its only `#include` site; `Network.cpp` talks to it through thin
   wrapper functions (`w5500LocalIP()`, `w5500IsConnected()`, etc.) instead of including the
   library directly. This is a structural difference from the 0.15.1-line code, which didn't hit
   this because `Network.cpp` there used the ESP32-only Arduino `Ethernet.h`, which apparently
   wasn't hit this way at that WLED/core version pairing — not reproducible without checking, so
   don't assume it was fine there; check before backporting this change to older lines.
6. **`WLED_DISABLE_INFRARED` is required, not optional.** `IRremoteESP8266` (WLED's default IR
   remote library) and `Ethernet_Generic`'s `w5100.h` both define a global enum value named
   `UNKNOWN`. Building both into the same firmware is a hard compile error (verified). The
   0.15.1-line port already carried `WLED_DISABLE_INFRARED` in its working config without
   documenting why — this is why. A future revision wanting both IR remote control and W5500
   would need to patch the vendored library's enum name, not drop this flag.

## Why this isn't in `shared/`

`shared/platformio.env.ini` is the source of truth for the **v15 line only**, which
`v15/notes.md` documents as "preserved/frozen" — its shipped binaries under
`v15/assets/legacy/` were not reproducibly built from that shared fragment in the first place
(the fragment's flags were dead weight; the actual v15.1 binaries came from the separate
`waveshare-esp32s3-eth-v15.1` branch's own complete `platformio.ini`, built outside this repo's
current tooling). Changing `shared/` risks changing what "v15" means without being able to
verify v15 still builds the same way. This port's real, verified, compiling code lives entirely
under this `v16/` directory (`patches/`, `lib/`, `platformio.env.ini`) instead.

## Architecture: why WiFi + Ethernet run simultaneously (kept from the v15.1 port)

The W5500's actual differentiating hardware is its onboard hardwired TCP/IP stack (WIZnet's own
silicon socket engine) — using it means AsyncTCP (which is hardwired to ESP32's lwIP, not a
generic sockets API) cannot bind to the Ethernet interface. The alternative — running the W5500
in ESP-IDF's native MACRAW mode via `ETH_PHY_W5500` — gets lwIP/AsyncTCP compatibility for free,
but per Espressif's own driver docs, explicitly **does not use the W5500's hardware TCP/IP
engine at all**; the chip becomes a bare MAC/PHY bridge and the ESP32 CPU does all protocol
processing in software, same as any RMII PHY. This port deliberately keeps the hardware-socket
approach (real offload) and accepts the WiFi/Ethernet split as the necessary consequence:

- **WiFi**: Web UI, WebSockets, HTTP/JSON API, OTA (whatever needs AsyncTCP/lwIP)
- **W5500 (hardware sockets)**: realtime UDP LED protocols (E1.31/Art-Net/DDP), MQTT

A single-interface, Ethernet-only design is possible but requires replacing WLED's web/socket
layer with one built on the W5500's own hardware socket API — a genuinely large, standing fork
of WLED's networking core (not a target overlay), scoped separately if pursued.

## Hardware / pin configuration

- Target board profile: **Waveshare ESP32-S3-ETH**, ESP32-S3, 16MB flash, 8MB PSRAM
- W5500 SPI pins: MISO=12, MOSI=11, SCLK=13, CS=14, RST=9, INT=10 (matches the validated
  v0.15.1 pinout and `../shared/platformio.env.ini`'s values — only the build-flag macro names
  changed, from `W5500_*_PIN` to `W5500_*`, to match what the ported driver code reads)
- LED outputs: 8× single-wire (WS281x-family), `DATA_PINS=0,1,2,3,15,16,17,18` — driven via RMT
  (4 hardware channels) + I2S-parallel (remaining 4); WLED's `bus_manager.cpp` already handles
  this generically at runtime, no build-time RMT/I2S split needed.
- GPIO caveats (per `wled00/pin_manager.cpp`'s own strapping-pin list for ESP32-S3):
  - **GPIO0, GPIO3** are strapping pins, both used here for LED data. Safe as regular outputs
    once boot completes (strap sampling only happens during reset). If GPIO0 is also wired to a
    physical BOOT button on this board: pressing it *during normal runtime* (not boot) while the
    RMT peripheral is actively driving it means the output driver and a grounded button contend
    electrically for that instant — a separate concern from the boot-strap question, and not
    fully characterized here. Revisit in a future hardware revision.
  - **GPIO46 is hardware input-only** on ESP32-S3 (not configurable) — noted for anyone
    populating the optional-device headers (39,40,41,42,45,46,47,48); it cannot drive an output.
  - **GPIO45** is also a strapping pin (VDD_SPI/flash-voltage select) — low risk since nothing
    on the optional headers is driven by default firmware, but avoid driving it externally
    during boot.
- Pin ownership shows up automatically in WLED 16.x's Settings → Pin Info page
  (`/json/pins`, driven by `PinManager::getPinOwner()`) as long as `initW5500Ethernet()`'s
  `PinManager::allocateMultiplePins(..., PinOwner::Ethernet)` call stays intact — no separate UI
  work needed.

## Forward-compat check against WLED nightly (`main`, checked 2026-08-12)

`WLED_NUM_ETH_TYPES` and the board-index defines (including `WLED_ETH_GLEDOPTO = 13`) are
unchanged between `v16.0.1` and current `main` — the board-index choice above (16) is stable
going forward as of this check. However, this port's patch does **not** apply cleanly to `main`
as-is: `wled00/wled.cpp` and `wled00/src/dependencies/network/Network.cpp` have diverged further
upstream since 16.0.1 (`network.cpp`, `const.h`, `fcn_declare.h`, `settings_wifi.htm` still
applied cleanly in that same check). Re-verify and hand-adjust the patch context around those two
files specifically when moving this port to a 17.x/nightly base — don't assume a clean
`git apply`.

## What's not done

- **No physical hardware validation.** DHCP lease acquisition, hot-plug detection, and dual
  WiFi+Ethernet runtime behavior are unverified beyond compilation.
- **Root `platformio.ini`'s `[env:waveshare_esp32s3_eth]` compatibility copy is not wired to
  this driver** — it still only carries build flags against this repo's own vendored `wled00/`,
  which does not have this patch applied. Use `scripts/build-target.sh` (below), not a direct
  root-level `pio run`, until/unless that's addressed separately.
- **Option 2 (fully hardware-socket, no WiFi needed at all)** — replacing WLED's web/socket
  layer to run entirely on the W5500's hardware sockets — was scoped in discussion but not
  started. It's a standing fork of WLED's networking core, not a target overlay.

## Building

```sh
scripts/build-target.sh --target waveshare-esp32s3-eth --version v16
```

Fetches `wled/WLED` at `v16.0.1` (per `build.json`), applies this directory's env fragment +
`lib/Ethernet_Generic` + `patches/0001-w5500-native-hardware-socket-ethernet.patch`, builds, and
produces `WLED_16.0.1_WAVESHARE-ESP32S3-ETH.bin` under the run's `output_dir`.
