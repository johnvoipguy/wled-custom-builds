# WLED Custom Builds Mission Control

Welcome to the launchpad.
This repo is the build-and-release cockpit for custom WLED targets.
Upstream WLED is the engine core. Target folders are where board-specific magic happens.

![Build Matrix](https://img.shields.io/badge/Build-Matrix-blue?style=for-the-badge&logo=githubactions&logoColor=white)
![Release Tokens](https://img.shields.io/badge/Release-Token%20Gated-orange?style=for-the-badge&logo=rocket&logoColor=white)
![Artifacts](https://img.shields.io/badge/Firmware-App%20%2B%20Full-success?style=for-the-badge&logo=esphome&logoColor=white)

🔥 Fast builds. 🚀 Intentional releases. 📦 Predictable firmware outputs.

## Users first: get firmware fast

Most people only need three things: where to get binaries, which file to flash, and what to do if it fails.

### 1) Pick your board guide

| Board | User guide | What you get |
|---|---|---|
| SP530E (ESP32-C3) | [targets/sp530e/README.md](targets/sp530e/README.md) | Download links, OTA/UART flash, troubleshooting, legacy hard-task pointers |
| Seeed Xiao ESP32S3 | [targets/seeed-xiao-esp32s3/README.md](targets/seeed-xiao-esp32s3/README.md) | User flashing guide + link to preserved known-good binaries |
| Waveshare ESP32-S3-ETH | [targets/waveshare-esp32s3-eth/README.md](targets/waveshare-esp32s3-eth/README.md) | User flashing guide + target-specific troubleshooting |

### 2) Get binaries from Releases

- Open Releases: [https://github.com/johnvoipguy/wled-custom-builds/releases](https://github.com/johnvoipguy/wled-custom-builds/releases)
- Download the file for your board from release assets.
- File meanings:
  - `.app.bin` = OTA update for already-running WLED
  - `.full.bin` = first-time USB/UART flash (bootloader + partitions + app)

### 3) Quick flash rules

- If WLED is already installed and healthy: use `.app.bin` via Manual OTA.
- If board is new, bricked, or partition layout changed: use `.full.bin` over UART.

### Troubleshooting quick hits

- OTA rejected or fails to boot: flash the matching `.full.bin` over UART.
- Wrong board behavior (pins/network/features): verify you downloaded the correct target asset.
- No release asset yet: use workflow artifacts from the latest successful run while waiting for release promotion.

## Maintainer runway (build + release internals)

## Launch in 60 seconds

If you want fast results with zero wandering, run this sequence like a launch checklist:

1. Update files under `targets/<target>/shared/` and/or `targets/<target>/<version>/`.
2. Build locally with `scripts/build-target.sh --target <target> --version <version>`.
3. Push changes to trigger CI artifacts.
4. Include `release` in the push commit message only when you want a GitHub Release.

Commit message intent:

- Ignition only (build artifacts): `sp530e v0.15.4 config update`
- Liftoff (build + release): `sp530e v0.15.4 release`
- Time-capsule liftoff (legacy prerelease): `sp530e v0.15.4 release legacy`

Quick mental model:
- No `release` token = build artifacts only.
- `release` token = publish release.
- `release legacy` token = publish as legacy prerelease (not latest).

If you remember one thing: type `release` only when you want fireworks on the Releases page.

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

- **Seeed Xiao ESP32S3**
  - Canonical env: `targets/seeed-xiao-esp32s3/shared/platformio.env.ini`
  - Preserved legacy firmware: `targets/seeed-xiao-esp32s3/v16/assets/legacy/`
- **Waveshare ESP32-S3-ETH**
  - Canonical env: `targets/waveshare-esp32s3-eth/shared/platformio.env.ini`
  - Active line notes: `targets/waveshare-esp32s3-eth/v15/notes.md`
- **SP530E**
  - Shared target assets: `targets/sp530e/shared/`

## Repository direction

- `main` is the canonical branch.
- The layout is target/version oriented under `targets/`.
- Legacy branch-per-version and clone-per-version workflows are deprecated.
- Generated artifacts, nested repositories, `.pio`, and build outputs must stay out of git.
- **Exception:** intentionally preserved, validated historical firmware binaries may be committed
  under `targets/<target>/v<N>/assets/legacy/` with a clear README explaining their provenance.
  These represent tested/regression-validated firmware and are kept to avoid losing that work.

In short: commit source and intent, not build byproducts.

## Guardrails that save your weekend

- Keep target-specific files inside `targets/<target>/...`.
- Keep root files generic and reusable.
- Keep generated outputs out of git (unless explicitly preserved legacy firmware).
- Keep releases intentional by using commit-message tokens.
- If a change feels random, it probably belongs in notes, not in source-of-truth config.

## Directory layout

```text
manifests/
  build-matrix.yml          ← target/version/env mapping
scripts/
  apply-target.sh           ← stage target assets (usermods, partitions, env fragment) into a workspace
  build-target.sh           ← read target manifest, resolve WLED base, apply target, run pio build
  legacy/                   ← old scripts preserved as reference only
wled_bases/
  <wled_ref>/               ← optional local WLED base checkouts used before upstream fallback
targets/
  sp530e/
    shared/                 ← source of truth: partitions, usermods, build.default.json
    v15/  v16/              ← version deltas / notes (+ build.json manifest)
  seeed-xiao-esp32s3/
    shared/
      platformio.env.ini    ← canonical Seeed PlatformIO env definition
      build.default.json    ← fallback manifest when targets/<target>/<version>/build.json is missing
      build.example.json    ← complete manifest example (environment, wled_ref, optional wled_repo)
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
      platformio.env.ini    ← canonical Waveshare PlatformIO env definition
      build.default.json    ← fallback manifest when targets/<target>/<version>/build.json is missing
      build.example.json    ← complete manifest example (environment, wled_ref, optional wled_repo)
    v15/
      notes.md              ← v15 active-line delta notes
      assets/
        README.md           ← no preserved legacy firmware currently tracked
    v16/                    ← future placeholder only
platformio.ini              ← generic WLED base (root = upstream defaults, not target-specific)
logs/
  <target>/<version>/
    <YYYYMMDD>/             ← one folder per calendar day (UTC)
      run-<HHMMSS>.log      ← consolidated run log for that run
      meta-<HHMMSS>.json    ← build metadata for that run
      summary-<HHMMSS>.txt  ← end-of-run summary for that run
    latest/                 ← always contains the most recent successful run as run.log / meta.json / summary.txt
outputs/
  <target>/<version>/<YYYYMMDD-HHMMSS>/
    release/
      <name>.bin            ← WLED release binary (OTA-flashable app image)
      <name>.full.bin       ← merged full flash image (bootloader+partitions+app, use for first-time UART flash)
    <env>/
      firmware.bin          ← raw app binary from PlatformIO
      firmware.elf          ← ELF with debug symbols
      firmware.map          ← linker map
      bootloader.bin        ← raw bootloader (ESP32 targets)
      partitions.bin        ← raw partition table (ESP32 targets)
```

## Starter workflow

1. Keep target-specific config and assets under `targets/<target>/shared/`.
2. Add version-specific deltas under `targets/<target>/<version>/`.
3. Set `targets/<target>/<version>/build.json` (`environment`, `wled_ref`, optional `wled_repo`).
4. Use `scripts/build-target.sh` locally, and `.github/workflows/build-target.yml` for CI build/release.

## CI and release behavior (the fireworks panel)

Primary automation lives in `.github/workflows/build-target.yml`.

- Push/PR auto-build triggers are intentionally narrow and only run for:
  - `targets/**`
  - `.github/workflows/build-target.yml`
- Push/PR runs build and upload workflow artifacts; they do not create releases by default.
- Manual `workflow_dispatch` can create a release when `create_release=true`.

### Push-to-release token gate

Pushes to `main` can create releases when the commit message contains `release`.

No token, no boom. Token, boom.

- Example (creates release): `git commit -m "sp530e v0.15.4 release"`
- Example (build only): `git commit -m "sp530e v0.15.4 config cleanup"`

Legacy release intent can be signaled by including `legacy` in the push commit message,
or by setting `legacy_release=true` in manual dispatch.

- Legacy releases are marked as prerelease and not latest.
- Stable releases are marked latest.

### Release notes scope

Releases from `build-target.yml` use target-scoped custom notes (not repo-wide auto-generated notes),
including target, version, environment, publish suffix, commit, run URL, and attached files.

That means each release tells the story of exactly one target build, not a random dump of unrelated repo changes.

### Published firmware naming

Published artifact/release filenames are normalized to:

- `wled-<version>-<target>-<publish_suffix>.app.bin`
- `wled-<version>-<target>-<publish_suffix>.full.bin`

`publish_suffix` comes from manifest `publish_suffix` (fallback `tag`, then `default`).

```sh
# Stage Seeed assets into an existing WLED workspace (overlay mode: v16/ dir exists)
scripts/apply-target.sh --target seeed-xiao-esp32s3 --version v16 --workspace /path/to/wled

# Stage + build in a temporary workspace (overlay mode)
scripts/build-target.sh --target seeed-xiao-esp32s3 --version v16

# Build against a specific upstream WLED ref (WLED-ref mode: 'main' dir does not exist)
scripts/build-target.sh --target seeed-xiao-esp32s3 --version main

# Force a specific environment when needed
scripts/build-target.sh --target seeed-xiao-esp32s3 --version v16 --environment seeed_xiao_esp32s3v2
```

### Version semantics

`scripts/build-target.sh` interprets `--version <v>` in one of two ways:

| Condition | Mode | Behavior |
|---|---|---|
| `targets/<target>/<v>/` **exists** | **Overlay** | `<v>` is a version key. Assets from `shared/` and `<v>/` are applied. Manifest: `<v>/build.json` → `shared/build.default.json`. |
| `targets/<target>/<v>/` **does not exist** | **WLED-ref** | `<v>` is treated as the WLED git ref (branch or tag). Only `shared/` assets are applied. Manifest: `shared/build.default.json` (optional). |

In WLED-ref mode, the WLED ref defaults to `--version` unless `--wled-ref` is explicitly passed.

### Environment resolution

The build environment is resolved in this order (first non-empty value wins):

1. `--environment <env>` CLI flag
2. `environment` field in the resolved manifest (`build.json` or `build.default.json`)
3. `[env:<name>]` sections parsed from `targets/<target>/shared/platformio.env.ini`

When parsing the env fragment:
- **Exactly one env found**: used automatically.
- **Multiple envs found (local)**: all environments are built sequentially; per-env logs written as `build.<env>.log`.
- **Multiple envs found (CI)**: build fails with an error. Specify `--environment` or set `environment` in the manifest.

To always use a known single environment, pass `--environment` explicitly or set it in the manifest.

### Base checkout strategy 🚀

- `scripts/build-target.sh` first looks for a local base checkout at `wled_bases/<wled_ref>/`.
- If not found, it fetches upstream (`wled_repo`, default `https://github.com/Aircoookie/WLED.git`) at `wled_ref` into a temporary workspace.

### Manifest fallback logic 📦

- If `targets/<target>/<version>/build.json` exists, it is used for version-specific settings.
- If it is missing, the script automatically falls back to `targets/<target>/shared/build.default.json`.

### PlatformIO env bridge 🔗

- `scripts/apply-target.sh` makes sure copied `platformio.env.ini` is included from workspace `platformio.ini` through `[platformio] extra_configs`.
- This ensures custom env names are recognized in upstream workspaces.

### Run logs and metadata trail 🧾

Each run writes dated logs/metadata under `logs/<target>/<version>/<YYYYMMDD>/`:
- `run-<HHMMSS>.log` — consolidated run output (`apply-target`, `npm`, and all `pio` environments)
- `summary-<HHMMSS>.txt` — end-of-run summary including metadata, paths, and copied artifacts
- `meta-<HHMMSS>.json` — build metadata (target, version, wled_ref, environment(s), version_mode, etc.)
- `latest/` — copy of the newest successful run's log and meta for quick access (`run.log`, `meta.json`, `summary.txt`)

Multiple runs on the same day share the same `<YYYYMMDD>/` folder; each run is identified by its `<HHMMSS>` filename suffix.

Build artifacts are persisted outside the temporary workspace under
`outputs/<target>/<version>/<YYYYMMDD-HHMMSS>/` before cleanup. The script copies:
- `release/*.bin` — primary release deliverables from `build_output/release/` (renamed by WLED's post-build script)
- `release/*.full.bin` — **merged full flash image** generated by `esptool.py merge_bin`:
  combines `bootloader.bin` (at 0x1000 for esp32/esp32s2, 0x0 for esp32s3/c3/c6 and newer) +
  `partitions.bin` (0x8000) + `firmware.bin` (0x10000) into a single image suitable for
  first-time UART flashing (`esptool.py write_flash 0x0 <name>.full.bin`).
  Named after the release bin: e.g. `WLED_17.0.0-dev_TARGET.full.bin`.
  Fails loudly if any required input (`bootloader.bin`, `partitions.bin`, `firmware.bin`) is missing.
- `<env>/firmware.bin`, `<env>/firmware.elf`, `<env>/firmware.map` — raw PlatformIO build outputs
- `<env>/bootloader.bin`, `<env>/partitions.bin` — raw component binaries when present

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
