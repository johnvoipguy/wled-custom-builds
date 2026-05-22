# WLED Custom Builds

This repository is a neutral, multi-target home for custom WLED build metadata on top of upstream `main`.

## Repository layering model

| Layer | Location | Role |
|---|---|---|
| **Base / upstream defaults** | repo root (`platformio.ini`, workflows, scripts) | Generic WLED build foundation — not target-specific |
| **Target source of truth** | `targets/<target>/shared/` | Canonical home for all target-specific metadata, config, partitions, usermods |
| **Version-specific deltas** | `targets/<target>/v15/`, `targets/<target>/v16/` | Only what differs per WLED version line; reference `shared/`, do not duplicate it |
| **Preserved firmware assets** | `targets/<target>/v<N>/assets/legacy/` | Intentionally retained validated historical firmware binaries; not generated outputs |

> **Rule:** If a file is target-specific, it belongs under `targets/<target>/shared/`, not in the root.
> The root `platformio.ini` and scripts are the generic base layer; target directories are the source of truth.
> Preserved historical firmware lives under `targets/<target>/v<N>/assets/legacy/` — not in top-level `build_output/` or `builds/`.

## Target highlights

- **Seeed Xiao ESP32S3:** canonical PlatformIO env and build metadata live in
  `targets/seeed-xiao-esp32s3/shared/platformio.env.ini`. Version notes under
  `v15/` and `v16/` are deltas only. **All Seeed preserved firmware is v16** —
  validated historical binaries live in `targets/seeed-xiao-esp32s3/v16/assets/legacy/`.
- **Waveshare ESP32-S3-ETH:** W5500 SPI Ethernet support is documented in
  `targets/waveshare-esp32s3-eth/v15/notes.md`; active migration track.
- **SP530E:** salvaged partition CSV and LED status usermods live in
  `targets/sp530e/shared/`.

## Repository direction

- `main` is the canonical branch.
- The layout is target/version oriented under `targets/`.
- Legacy branch-per-version and clone-per-version workflows are deprecated.
- Generated artifacts, nested repositories, `.pio`, and build outputs must stay out of git.
- **Exception:** intentionally preserved, validated historical firmware binaries may be committed
  under `targets/<target>/v<N>/assets/legacy/` with a clear README explaining their provenance.
  These represent tested/regression-validated firmware and are kept to avoid losing that work.

## Directory layout

```text
manifests/
  build-matrix.yml          ← target/version/env mapping
scripts/
  apply-target.sh           ← stage target assets (usermods, partitions, env fragment) into a workspace
  build-target.sh           ← create temp workspace, apply target, run pio build
  legacy/                   ← old scripts preserved as reference only
targets/
  sp530e/
    shared/                 ← source of truth: partitions, usermods
    v15/  v16/              ← version deltas / notes
  seeed-xiao-esp32s3/
    shared/
      platformio.env.ini    ← canonical Seeed PlatformIO env definition
      partitions/           ← partition table notes (uses tools/WLED_ESP32_8MB.csv)
      usermods/             ← enabled usermod notes
    v15/                    ← version delta (no Seeed-specific content yet)
    v16/
      notes.md              ← v16 delta notes
      assets/
        legacy/             ← preserved validated historical firmware binaries
          README.md
          *.bin
  waveshare-esp32s3-eth/
    shared/
    v15/  v16/
platformio.ini              ← generic WLED base (root = upstream defaults, not target-specific)
```

## Starter workflow

1. Describe target/version combinations in `manifests/build-matrix.yml`.
2. Keep target-specific config and assets under `targets/<target>/shared/`.
3. Use `scripts/apply-target.sh` and `scripts/build-target.sh` to stage and build.

```sh
# Stage Seeed assets into an existing WLED workspace
scripts/apply-target.sh --target seeed-xiao-esp32s3 --version v16 --workspace /path/to/wled

# Stage + build in a temporary workspace
scripts/build-target.sh --target seeed-xiao-esp32s3 --version v16 --environment seeed_xiao_esp32s3v2
```

## Legacy scripts

Legacy shell scripts live in `scripts/legacy/` as reference material only.
They are preserved to document the old repo-sprawl workflow but are not supported.

## Notes on salvaged assets

The SP530E target carries salvaged assets into `targets/sp530e/shared/`:

- custom partition CSV: `WLED_ESP32C3_4MB_audioreactive.csv`
- usermods: `boot_status_led`, `wifi_status_led`

## Notes on preserved firmware assets

The Seeed Xiao ESP32S3 target carries preserved historical validated firmware binaries in
`targets/seeed-xiao-esp32s3/v16/assets/legacy/`. These represent the result of substantial
manual testing and regression work and are intentionally retained in the repository.

See [`targets/seeed-xiao-esp32s3/v16/assets/legacy/README.md`](targets/seeed-xiao-esp32s3/v16/assets/legacy/README.md)
for the full inventory, provenance, and flashing instructions.

> **Convention:** Only deliberately retained, validated firmware belongs in
> `targets/<target>/v<N>/assets/legacy/`. Do not commit routine build outputs there.
> Use GitHub Releases for distributing new firmware builds.

See the per-target `notes.md` files for guidance on where additional target-specific work should land.
