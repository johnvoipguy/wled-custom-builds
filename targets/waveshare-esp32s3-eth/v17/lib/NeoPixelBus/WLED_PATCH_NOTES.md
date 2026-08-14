# Vendored, patched copy

Source: `Makuna/NeoPixelBus` commit `76afe832f74b0738a3fa1bba0caf389ade9e7693` ("CORE3 branch" -
the exact commit WLED main's `[esp32_idf_V5]` `lib_deps` currently pins via
`git+https://github.com/Makuna/NeoPixelBus#76afe832f74b0738a3fa1bba0caf389ade9e7693`).

Patched in `src/internal/methods/ESP/ESP32/NeoEsp32RmtXMethod.h` (search `DIAG/FIX`), inside
`NeoEsp32RmtMethodBase::Initialize()`:

- `config.mem_block_symbols` was `192`. ESP32-S3's RMT TX peripheral has only 4 channels
  sharing a total of ~192 symbol-words of on-chip memory (48 per channel,
  `SOC_RMT_MEM_WORDS_PER_CHANNEL`). Requesting 192 symbols for the *first* channel alone
  silently consumed the entire shared pool, starving `rmt_new_tx_channel()` for every channel
  created after it. The three IDF calls in `Initialize()` (`rmt_new_tx_channel`,
  `rmt_new_led_strip_encoder`, `rmt_enable`) summed their return codes into a local `ret` that
  was never checked or logged, so the failure was silent: the starved channels' `_channel`
  handle stayed unset, and `IsReadyToUpdate()` (`rmt_tx_wait_all_done(_channel, 0)`) could then
  never report success - which meant `BusManager::removeAll()`'s `while (!canAllShow()) yield();`
  (called from every runtime LED-settings-page save, via `WS2812FX::finalizeInit()`) hung
  forever the first time a save tried to tear down more than one RMT-driven bus. Boot-time bus
  creation was unaffected (nothing waits on `canAllShow()` there), which is why this only
  surfaced as "LED settings never save" rather than a boot failure.
  - Fixed: `config.mem_block_symbols = 48` - one full hardware block per channel, so all 4
    channels fit without contention. The encoder refills this block incrementally via interrupt
    (`RMT_ENCODING_MEM_FULL`), so a small block does not limit frame size.
  - Also added explicit `retChan`/`retEnc`/`retEnable` capture with a `Serial.printf` on failure
    (and a one-line success confirmation), so a future starvation/allocation failure is visible
    in the boot log instead of manifesting as a silent, permanent hang somewhere else.

Also patched in `src/internal/methods/ESP/ESP32/NeoEsp32LcdXMethod.h` (S3's LCD/I2S-parallel
driver) and `src/internal/methods/ESP/ESP32/Core_2_x/NeoEsp32I2sXMethod.h` (classic ESP32/S2's
real-I2S driver) - search `DIAG/FIX` in both:

- `_data` (the method's own pixel-buffer pointer, separate from `NeoPixelBus<>`'s constructor)
  was never initialized in either class's constructor - only ever set inside `Initialize()`,
  which WLED calls later via `begin()`, not at construction time. If a bus object is destroyed
  before `Initialize()` ever ran on it, the destructor still unconditionally calls `free(_data)`
  on whatever garbage was sitting in that pointer - a crash inside `free()`/`heap_caps_free()`
  on a bogus, non-null address.
  - Fixed: `_data(nullptr)` added to both constructors' initializer lists, so an un-Initialize()'d
    bus's destructor calls `free(nullptr)` - a safe no-op - instead of freeing garbage. Also
    added a one-line log on that path so it's visible rather than silent.
  - Note: the actual crash this was chasing (see `../../notes.md`) turned out to have a second,
    primary cause in WLED's own `bus_manager.cpp` (writing sacrificial/skipped pixels in the
    `BusDigital` constructor, before `begin()`/`Initialize()` ever ran - fixed separately, not
    in this vendored copy). This `_data(nullptr)` fix is still worth keeping as a general safety
    net against the same class of bug from any other call path.

No other changes. Re-verify these patches are still needed before bumping the vendored commit -
check whether upstream `Makuna/NeoPixelBus` has since fixed the return-code handling, changed
`mem_block_symbols`, or initialized `_data` itself.

See `../../notes.md` for the full investigation (symptoms, root causes, and how both were
validated on hardware).
