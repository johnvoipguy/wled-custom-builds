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

No other changes. Re-verify this patch is still needed before bumping the vendored commit -
check whether upstream `Makuna/NeoPixelBus` has since fixed the return-code handling or changed
`mem_block_symbols` itself.

See `../../notes.md` for the full investigation (symptom, how the removeAll() hang was
root-caused down to this exact line, and how it was validated on hardware).
