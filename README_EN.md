# zmk-config-hpd

[简体中文](README.md) | [English](README_EN.md)

---

[ZMK](https://zmk.dev/) firmware configuration repository for the **HPD** split ergonomic keyboard. The default branch is **`dya`**.

That branch builds on stock ZMK by adding **DYA Studio** (cormoran's enhanced ZMK Studio fork), moving a large amount of configuration — keymap, macros, combos, trackball parameters, encoder behaviour, battery history — away from "edit code, rebuild, reflash" and into "change it in the browser, effective immediately, persisted to flash".

---

## Table of Contents

- [1. Branch Notes](#1-branch-notes)
- [2. Project Overview & Hardware](#2-project-overview--hardware)
- [3. Layout & Key Assignments](#3-layout--key-assignments)
- [4. Firmware Features](#4-firmware-features)
- [5. Building & Flashing](#5-building--flashing)
- [6. Customisation](#6-customisation)
- [7. Troubleshooting & Gotchas](#7-troubleshooting--gotchas)
- [8. Repository File Index](#8-repository-file-index)

---

## 1. Branch Notes

### 1.1 `dya` is now the default branch

The repository default branch was `master`; it is now **`dya`**:

| Item | Value |
| --- | --- |
| Default branch | `dya` |
| Default branch HEAD | `f230937` — *fix: enable runtime sensor rotate on the central half only* |
| Other branch | `master` (HEAD `e0aaf8e` — *chore: set startup underglow brightness to 30%*) |
| `dya` relative to `master` | 9 commits ahead, 0 behind |

### 1.2 `dya` fully contains everything on `master`

`git rev-list --left-right --count master...dya` returns `0  9` — the left count is 0, meaning **no commit reachable from `master` is missing from `dya`**. `dya` is therefore a strict superset of `master` (a fast-forward relationship), so making it the default branch loses no existing functionality.

The 9 commits `dya` adds on top of `master`:

| Commit | Date | Description |
| --- | --- | --- |
| `e534e0c` | 2026-09-26 | feat(dya): add DYA Studio firmware support (new `west-dependency.yml`, Makefile, CI build) |
| `f9cbabd` | 2026-09-27 | fix: remove obsolete `CONFIG_WS2812_STRIP` |
| `fa00802` | 2026-09-27 | feat: light RGB underglow on startup |
| `928a942` | 2026-10-02 | fix: review cleanup for dya branch |
| `1b1c113` | 2026-10-02 | build: drop studio-rpc-usb-uart snippet and studio cmake-args from right half |
| `2296e8f` | 2026-10-02 | fix: give rotated thumb keys an explicit rotation origin (`rx`/`ry`) |
| `1239a1c` | 2026-10-02 | fix: restore studio-rpc-usb-uart snippet on the right half |
| `ecbaee3` | 2026-10-02 | feat: add runtime sensor rotate (per-layer encoder bindings via DYA Studio) |
| `f230937` | 2026-10-02 | fix: enable runtime sensor rotate on the central half only |

### 1.3 Impact of switching the default branch

- **Clone default changes**: new `git clone https://github.com/tangbonze/zmk-config-hpd.git` checks out `dya` instead of `master`.
- **CI behaviour unchanged**: the `push` trigger in `.github/workflows/build.yml` already listens to both `master` and `dya`, so both branches build.
- **`git archive` and any external link that assumes the default branch** now points at `dya`.
- **Existing local clones are unaffected**: configured upstream tracking stays as-is. To follow the new default branch, run:
  ```bash
  git remote set-head origin -a
  ```
- **`master` is retained, not deleted**, and reverting is trivial: change the repository's default branch back to `master` in settings. No commit operations are involved, so there is no risk.

---

## 2. Project Overview & Hardware

### 2.1 Keyboard model

**HPD** — a **split ergonomic keyboard** with 6 columns × 5 rows, a thumb cluster and one bottom extra key, one half per side (`requires: [pro_micro]`; the interconnect method is not declared anywhere in this repository's config, so defer to the actual hardware). **61 keys in total** (the matrix is 12 columns × 6 rows = 72 positions, of which 61 are populated).

| Item | Description |
| --- | --- |
| Model | HPD (shield name `HPD`, sub-shields `HPD_left` / `HPD_right`) |
| Architecture | Split keyboard (`CONFIG_ZMK_SPLIT=y`) |
| Left half (peripheral) | Key matrix, EC11 rotary encoder, WS2812 underglow |
| Right half (central) | Key matrix, PMW3610 trackball, WS2812 underglow, USB/BLE host link, DYA Studio RPC |
| Matrix size | 6 rows × 6 columns per half; `default_transform` is 12 columns × 6 rows, with the right half offset via `col-offset = <6>` into columns 6–11 |
| Power | `CONFIG_ZMK_EXT_POWER=y` (external power) |

### 2.2 MCU and ZMK firmware approach

| Item | Value |
| --- | --- |
| MCU | **nice!nano v2** (nRF52840) |
| Board notation | `nice_nano//zmk` (ZMK board name + ZMK board revision selector) |
| Firmware baseline | `cormoran/zmk`, revision `e5c9b69` (main + dya) — **not** upstream ZMK |
| Zephyr | `7c6b4cc` (v4.1.0 + zmk-fixes + nrf-half-duplex-uart), with many HALs pruned to shorten CI time |
| Wireless | BLE 5, `CONFIG_BT_CTLR_TX_PWR_PLUS_8=y` (+8 dBm TX power) |
| Key Zephyr tweak | `CONFIG_CONSOLE=n` (Zephyr 4.1 enables the console by default; a keyboard does not need it) |

> ⚠️ This branch **cannot** be built with upstream `zmkfirmware/zmk`. Every remote in `west-dependency.yml` points at `https://github.com/cormoran`, and every revision is **pinned to a concrete commit hash** so an upstream push cannot silently change firmware behaviour. Bump them deliberately.

---

## 3. Layout & Key Assignments

### 3.1 Default layer (QWRT) — full keymap

Every layer holds **61 bindings** (5 rows × 12 columns + 1 bottom extra key). Rows below are laid out by matrix position, **left half (columns 0–5) first, then right half (columns 6–11)**.

| Row | Left half (cols 0–5) | Right half (cols 6–11) |
| --- | --- | --- |
| **R0** | `ESC` `1` `2` `3` `4` `5` | `6` `7` `8` `9` `0` `BACKSPACE` |
| **R1** | `TAB` `Q` `W` `E` `R` `T` | `Y` `U` `I` `O` `P` `\` <sup>`\|`</sup> |
| **R2** | `CAPS` `A` `S` `D` `F` `G` | `H` `J` `K` `L` `;` `'` <sup>`"`</sup> |
| **R3** | `LSHIFT` `Z` `X` `C` `V` `B` | `N` `M` `,` `.` `/` `RSHIFT` |
| **R4** | <kbd>NUM</kbd> <kbd>SCROLL</kbd> `CTRL` `ALT` `GUI` <kbd>SNIPE</kbd> | `BACKSPACE` `DELETE` `[` `]` <kbd>MOUSE</kbd> <kbd>SYM</kbd> |
| **R5** | extra key <kbd>MUTE</kbd> (col 0) | — |

- **Shift combinations on R1–R3** (`\|`, `"`) come from the `s` secondary labels recorded in `config/HPD.json`.
- **R4 has 8 rotated keys**: columns 0/1/4/5 are `+15°`, columns 6/7/10/11 are `-15°` — that is <kbd>NUM</kbd> <kbd>SCROLL</kbd> `GUI` <kbd>SNIPE</kbd> and `BACKSPACE` `DELETE` <kbd>MOUSE</kbd> <kbd>SYM</kbd>. All eight carry `rot` plus **explicit `rx`/`ry` rotation origins** in `HPD.dtsi` (fixed by DYA commit `2296e8f`); a missing origin makes the DYA Studio layout preview disagree with the physical board.
- **Bottom extra key**: `&kp K_MUTE` is the only key in matrix row 6 (`x = 625, y = 325`), on the innermost position of the left half.
- **A mismatch between keymap and `HPD.json` labels is expected**: `label` in `HPD.json` describes the **keycap legend** (e.g. col 0 is labelled `SPACE`, col 11 is labelled `ENTER`), while the keymap actually binds col 0 to the NUM layer and col 11 to the SYM layer. **Edit `HPD.keymap` to change key assignments**; only touch `HPD.json` when changing the physical layout.

### 3.2 Layers and how to reach them

| Index | Label | Name | How to enter | Encoder binding |
| --- | --- | --- | --- | --- |
| 0 | `QWRT` | Default layer | — | `&rsr_vol` (volume) |
| 1 | `NUM` | Number / arrow layer | Hold R4-0 (`&lt 1`) | `&rsr_scroll` (scroll, `tap-ms` 100) |
| 2 | `SYM` | Symbol layer | Hold R4-11 (`&lt 2`) | `&rsr_none` |
| 3 | `FUN` | Function / RGB layer | From SYM layer, press R4-11 (`&mo 3`) | `&rsr_none` |
| 4 | `MOUSE` | Mouse buttons layer | Hold R4-10 (`&mo 4`) | `&rsr_none` |
| 5 | `SCROLL` | Slow-trackball / scroll layer | Hold R4-1 (`&mo 5`) | `&rsr_none` |
| 6 | `SNIPE` | Snipe (slowed trackball) layer | Hold R4-5 (`&mo 6`) | `&rsr_none` |

> The default layer has no direct key for FUN (3) — press `&lt 2` to reach SYM first, then `&mo 3`.

### 3.3 Layer highlights

All positions below are matrix row/column indices (cols 0–11).

**NUM (1)** — only 14 active keys, everything else passes through

| Position | Keys |
| --- | --- |
| R0 cols 1–10 | `1` `2` `3` `4` `5` `6` `7` `8` `9` `0` |
| R2 cols 1–4 | `←` `↓` `↑` `→` |

**SYM (2)** — Bluetooth selection + symbols

| Position | Keys |
| --- | --- |
| R0 cols 1–10 | `!` `@` `#` `$` `%` `^` `&` `*` `(` `)` |
| R2 cols 1–4 | `BT_CLR` `BT_SEL 0` `BT_SEL 1` `BT_SEL 2` |
| R2 cols 6–9 | `-` `=` `[` `]` |
| R3 cols 6–7 | `_` `+` |
| R4 col 11 | `&mo 3` → enter the FUN layer |

**FUN (3)** — RGB control + F-keys

| Position | Keys |
| --- | --- |
| R0 cols 0–8 | `RGB_TOG` `RGB_BRI` `RGB_BRD` `RGB_EFF` `RGB_EFR` `RGB_SAD` `RGB_SAI` `RGB_HUD` `RGB_HUI` |
| R1 cols 1–4 | `F1` `F2` `F3` `F4` |
| R2 cols 1–4 | `F5` `F6` `F7` `F8` |
| R3 cols 1–4 | `F9` `F10` `F11` `F12` |

**MOUSE (4)**

| Position | Keys |
| --- | --- |
| R2 cols 1–4 | `←` `↓` `↑` `→` |
| R4 col 6 | `&mkp MCLK` (**middle mouse button**) |
| R4 col 10 | `&mkp LCLK` (**left mouse button**) |
| R4 col 11 | `&mkp RCLK` (**right mouse button**) |

> ZMK naming follows the mouse side: `LCLK` = left mouse button, `RCLK` = right mouse button, `MCLK` = middle mouse button — independent of where the keyboard's `CTRL`/`ALT` keys sit.

**SCROLL (5) / SNIPE (6)**: all 61 bindings are `&trans`, with no ordinary key positions at all. They exist purely to alter the trackball input-processor chain through the input listener (see [4.3](#43-trackball-and-encoder)).

---

## 4. Firmware Features

### 4.1 DYA Studio module matrix

The core of the `dya` branch. The Kconfig switches below correspond one-to-one with the modules in `config/west-dependency.yml`, and all live in **`HPD_right.conf`** (right half, central). The left half receives synced values via `CONFIG_ZMK_SPLIT_RELAY_EVENT` + `CONFIG_ZMK_CUSTOM_SETTINGS_SPLIT_RPC_RELAY`.

| Studio tab | Kconfig switches | Matching west module |
| --- | --- | --- |
| Connection | `CONFIG_ZMK_BLE_MANAGEMENT` `..._STUDIO_RPC`<br>`CONFIG_ZMK_OS_DETECTION` (+USB/BLE/STUDIO_RPC)<br>`CONFIG_ZMK_DEFAULT_LAYER` (min 0 / max 6, +OS_DETECTION) | `zmk-module-ble-management`<br>`zmk-feature-os-detection`<br>`zmk-feature-default-layer` |
| Settings | `CONFIG_ZMK_SETTINGS_RPC` `..._STUDIO`<br>`CONFIG_ZMK_CUSTOM_SETTINGS` (+SPLIT_RPC_RELAY / STUDIO_RPC)<br>`LARGE_VALUE_MAX_SIZE=256` | `zmk-module-settings-rpc`<br>`zmk-feature-custom-settings` |
| Keymap | `CONFIG_ZMK_PHYSICAL_LAYOUTS_FEATURE` `..._STUDIO_RPC`<br>`CONFIG_ZMK_RUNTIME_MACRO` / `_COMBO` (+STUDIO_RPC)<br>`CONFIG_ZMK_BEHAVIOR_LOCAL_ID_TYPE_CRC16` | `zmk-feature-module-physical-layout`<br>`zmk-feature-runtime-macro`<br>`zmk-feature-runtime-combo` |
| Trackball | `CONFIG_ZMK_RUNTIME_INPUT_PROCESSOR` `..._STUDIO_RPC`<br>`CONFIG_PMW3610` `CONFIG_ZMK_PMW3610_STUDIO_RPC` / `_CUSTOM_SETTINGS` | `zmk-module-runtime-input-processor`<br>`zmk-driver-pmw3610-with-custom-studio-rpc` |
| Sensor rotation | `CONFIG_ZMK_RUNTIME_SENSOR_ROTATE` `..._STUDIO_RPC`<br>`CONFIG_ZMK_BEHAVIOR_LOCAL_IDS_IN_BINDINGS` | `zmk-behavior-runtime-sensor-rotate` |
| Diagnostics | `CONFIG_ZMK_DEVICE_INFO` `..._STUDIO_RPC`<br>`CONFIG_ZMK_WATCHDOG` `..._STUDIO_RPC` | `zmk-feature-device-info`<br>`zmk-feature-watchdog` |
| Battery history | `CONFIG_ZMK_BATTERY_HISTORY` `..._STUDIO_RPC` | `zmk-module-battery-history` |

Additionally, `config/HPD.zmk.yml` declares `features: [keys, pointer, underglow, studio]` so external tooling can discover the capabilities.

### 4.2 Display and theming

> **This repository has no display.** Every `.conf` / `.overlay` / `.dtsi` has been checked: there is **no `CONFIG_ZMK_DISPLAY` / SSD1306 / OLED configuration** anywhere, and no display module is pulled in. Do not attempt to attach a screen to this repo — you would have to add a display shield and driver yourself.

**"Theme" in this repository means the RGB underglow**, implemented with ZMK's native underglow:

| Setting | Value | Meaning |
| --- | --- | --- |
| `CONFIG_ZMK_RGB_UNDERGLOW` | `y` | Enable underglow |
| `CONFIG_ZMK_RGB_UNDERGLOW_ON_START` | `y` | Light up at boot (DYA commit `fa00802`) |
| `CONFIG_ZMK_RGB_UNDERGLOW_SAT_START` | `0` | Start saturation 0 (white) |
| `CONFIG_ZMK_RGB_UNDERGLOW_BRT_START` | `30` | Start brightness 30% |
| Driver | `CONFIG_WS2812_STRIP_SPI` + `CONFIG_LED_STRIP` | WS2812 over SPI3 (MOSI = P0.11), `chain-length = 1` per half |

Underglow colour, brightness and effect speed are adjustable at runtime from the **FUN layer** (enter via `&mo 3` from SYM): `RGB_TOG` (on/off), `RGB_BRI`/`RGB_BRD` (brightness ±), `RGB_EFF` (cycle effect), `RGB_EFR` (effect speed ±), `RGB_SAD`/`RGB_SAI` (saturation ±), `RGB_HUD`/`RGB_HUI` (hue ±).

> Note that the non-SPI `CONFIG_WS2812_STRIP` was removed in `f9cbabd` and only the SPI variant remains. **Do not add it back by hand** — it conflicts with the SPI version.

### 4.3 Trackball and encoder

**Hardware**

| Item | Value |
| --- | --- |
| Sensor | PMW3610, devicetree compatible **`cormoran,pmw3610`** (driver from cormoran, not upstream's `zmk,pmw3610`) |
| Placement | **Right half only (central)**; `status = "disabled"` by default in `HPD.dtsi`, enabled by `HPD_right.overlay` |
| Bus | SPI1 @ 2 MHz, CS = P0.22 (active low), IRQ = P0.20 |
| Axis mapping | `SWAP_XY` + `INVERT_X` + `INVERT_Y` — preserves HPD's traditional `ORIENTATION_90 + INVERT_X` feel |
| CPI | **400** (`&trackball { cpi = <400>; }`) |
| Other | `disable-burst-read`; `CONFIG_PMW3610_SMART_ALGORITHM=y`; `RUN_DOWNSHIFT_TIME_MS=3264`; `REST1_SAMPLE_TIME_MS=20`; `REPORT_INTERVAL_MIN=8`; `INIT_POWER_UP_EXTRA_DELAY_MS=200` |

**Encoder**

`alps,ec11`, on the **left half**, `steps = <20>`, `triggers-per-rotation = <10>`, `A`=P0.29, `B`=P0.31.

**Input processor chain** (`trackball_listener` in `HPD_right.overlay`)

| Active on | Chain |
| --- | --- |
| Default (all layers) | `&mouse_runtime_input_processor &scroll_runtime_input_processor` |
| Layer 5 `SCROLL` | `&zip_xy_scaler 1 2 &scroll_runtime_input_processor` (XY at half rate + convert to scroll) |
| Layer 6 `SNIPE` | `&zip_xy_scaler 1 2 &mouse_runtime_input_processor` (XY at half rate) |

- `mouse_runtime_input_processor`: `temp-layer-enabled`, `temp-layer = <4>` (MOUSE layer), activation delay `0 ms`, deactivation delay `700 ms` — moving the trackball switches to the MOUSE layer automatically; pressing a key or timing out returns to the default layer.
- `scroll_runtime_input_processor`: `active-layers = <BIT(5)>`, `xy-to-scroll-enabled`, `axis-snap-threshold = <100>`.
- Classic mouse/scrollwheel tuning (`&mmv` / `&msc`): `mmv` acceleration exponent 1, `time-to-max-speed-ms=500`, `trigger-period-ms=16`; `msc` acceleration exponent 1, `time-to-max-speed-ms=100`; `zip_xy_scaler 2 1` / `zip_scroll_scaler 1 2`.

**Runtime Sensor Rotate (per-layer encoder bindings)**

The newest `dya` feature (`ecbaee3` / `f230937`): via the custom RPC subsystem `cormoran_rsr`, encoder CW/CCW behaviour can be redefined **per layer** from Studio's "Sensor rotation" tab, and the configuration persists.

```dts
rsr_vol: rsr_vol {                       /* default layer: volume */
    compatible = "zmk,behavior-runtime-sensor-rotate";
    #sensor-binding-cells = <0>;
    cw-binding  = <&kp K_VOLUME_UP>;
    ccw-binding = <&kp K_VOLUME_DOWN>;
};
rsr_scroll: rsr_scroll {                 /* NUM layer: scroll, tap-ms 100 */
    compatible = "zmk,behavior-runtime-sensor-rotate";
    #sensor-binding-cells = <0>;
    tap-ms = <100>;
    cw-binding  = <&msc SCRL_DOWN>;
    ccw-binding = <&msc SCRL_UP>;
};
rsr_none: rsr_none {                     /* all other layers: transparent */
    compatible = "zmk,behavior-runtime-sensor-rotate";
    #sensor-binding-cells = <0>;
};
```

| Constraint | Explanation |
| --- | --- |
| Every layer must bind one | If a layer omits `sensor-bindings` or binds `&trans`, the module's process hook never runs there and the layer is **invisible** in Studio |
| `cw-/ccw-binding` are fallbacks | They apply only until a runtime binding has been saved for that layer; their values reproduce the static bindings they replaced, so out-of-the-box behaviour is unchanged |
| Central only | Enabling this in the shared `config/HPD.conf` breaks the left half's link step (see [7.2](#72-central--peripheral-configuration-boundaries-important)) |

---

## 5. Building & Flashing

### 5.1 The three build targets

`build.yaml`:

| Target | Board / shield | Extras | Artifact |
| --- | --- | --- | --- |
| Left half | `nice_nano//zmk` + `HPD_left` | — | `nice_nano__zmk_HPD_left.uf2` |
| Right half | `nice_nano//zmk` + `HPD_right` | `snippet: studio-rpc-usb-uart`<br>`cmake-args: -DCONFIG_ZMK_STUDIO=y -DCONFIG_ZMK_STUDIO_LOCKING=n` | `nice_nano__zmk_HPD_right.uf2` |
| Reset | `nice_nano//zmk` + `settings_reset` | — | clears saved Studio settings |

Artifact filenames come from the west build directory name, hence forms like `nice_nano__zmk_HPD_left.uf2` and `nice_nano__zmk_HPD_right.uf2`.

> **What the `studio-rpc-usb-uart` snippet does** (commit `1b1c113` removed it, `1239a1c` restored it — keep it as-is): the snippet appends `CONFIG_ZMK_USB` + `CONFIG_USB_CDC_ACM` and binds Studio RPC to the USB CDC-ACM serial port through `zmk,studio-rpc-uart`, while also adding `-DZMK_BEHAVIORS_KEEP_ALL`. **Without it, Studio cannot reach the right half over WebSerial.**

### 5.2 Option A: GitHub Actions (recommended)

`.github/workflows/build.yml` runs on pushes to `master` / `dya`, on pull requests, and on manual dispatch:

1. `make init-standalone` (dependencies into `./dependencies`)
2. `make build-all`
3. Collect every `*/zephyr/zmk.uf2` → upload as workflow artifact `hpd`
4. On manual dispatch with a `release` input, also run `gh release create` to package a Release

To build and publish a Release manually: **Actions → Build ZMK firmware → Run workflow → fill in `release` (e.g. `v0.1.0`)**.

### 5.3 Option B: local west build

Prerequisites: `west`, `cmake`, `ninja`, `arm-none-eabi-gcc` (Zephyr SDK).

```bash
# dependencies inside the repo at ./dependencies (the CI approach, recommended)
make init-standalone
make build-all

# or: dependencies one level up (standard west workspace layout)
make init-workspace
make build-all
```

Equivalent manual commands:

```bash
west init -l config --mf west-standalone.yml
west update --narrow
west zephyr-export
west zmk-build -d ./build -q
```

Debug build (enables `zmk-usb-logging`, trading some size for logs):

```bash
make debug-all      # equivalent to west zmk-build -S zmk-usb-logging
```

> Historical master commit `30edfff` removed `CONFIG_ZMK_USB_LOGGING` from `config/HPD.conf` because it aborted the Kconfig build. **The default build therefore contains no USB logging** — use `-S zmk-usb-logging` when you need logs.

After building, firmware lands at:

```
build/nice_nano__zmk_HPD_left/zephyr/zmk.uf2
build/nice_nano__zmk_HPD_right/zephyr/zmk.uf2
```

### 5.4 Flashing to the keyboard

This repository does **not** ship a `west flash` target; flashing is done by dragging the UF2 onto the bootloader drive:

1. Put the nice!nano v2 into bootloader: hold **RESET**, release it, then immediately double-tap any key on either half (some revisions: hold RESET while replugging USB).
2. A removable drive `NICE_NANO` appears (RP2040 / nRF528 bootloader).
3. **Drag the matching `zmk.uf2` onto that drive** and wait for the indicator LED to stop blinking.
4. Unplug and reset; the keyboard boots (underglow comes on solid white at 30% brightness).

**Do not flash the wrong half.** On first pair-up, **power only the right half**, complete the configuration in Studio, and only then power the left half.

### 5.5 Configuring with DYA Studio

1. Open DYA Studio (cormoran's Studio build) in a browser.
2. **Connect the right half only** — plug the nice!nano USB cable into the **right half**, using the CDC-ACM serial port provided by `studio-rpc-usb-uart`.
3. Once Studio opens the CDC-ACM port over WebSerial, all tabs exposed by this firmware appear (Connection / Settings / Keymap / Trackball / Sensor rotation / Diagnostics / Battery history).
4. Changes are written to non-volatile storage immediately and survive reboots; the left half is synced through the split relay.

> ⚠️ **This repository does not bind `&studio_unlock` anywhere in the keymap.** In this fork, unlocking is *physical-key only* — once Studio locks there is no RPC or PIN-based way back in. Fortunately both `build.yaml` and `HPD_right.conf` set `CONFIG_ZMK_STUDIO_LOCKING=n`, which **disables auto-locking**, so the unrecoverable-lock state cannot occur. If you switch back to `CONFIG_ZMK_STUDIO_LOCKING=y`, you **must** also add `&studio_unlock` to some key in the keymap.

---

## 6. Customisation

### 6.1 Changing the keymap

Edit `config/HPD.keymap`. Each layer looks like this:

```dts
function_layer {
    label = "FUN";
    bindings = <
&trans  &kp F1  &kp F2   &kp F3   &kp F4   &trans  &trans  &trans  &trans  &trans  &trans  &trans
            >;
    sensor-bindings = <&rsr_none>;
};
```

- `label` is the layer name shown by DYA Studio / keymap-drawer.
- Each line of 12 bindings corresponds to the matrix's 12 columns (**6 on the left half + 6 on the right**, not "one row per half").
- `&trans` passes through to the layer below.
- Rebuild and reflash with `make build-all` afterwards.

> **Reflash-free alternative**: DYA Studio's "Keymap" tab supports runtime macros and runtime combos. Changes of those two kinds **do not require rebuilding the firmware** — saving in the browser is enough.

### 6.2 Changing behaviors / macros

**Static behaviors** (require a build):

- Standard ZMK behaviors: edit `config/HPD.keymap`, adding `#include <behaviors/...>` where needed.
- Custom behaviors: define them under `/ { behaviors { ... }; };`. That node is currently empty in this repository, so add entries using ZMK syntax.
- Runtime sensor rotate instances: `rsr_vol` / `rsr_scroll` / `rsr_none`, with properties `tap-ms`, `cw-binding`, `ccw-binding` (see [4.3](#43-trackball-and-encoder)).

**Runtime macros / combos** (no rebuild): configure them in Studio's "Keymap" tab.

**Temporary-parameter behaviors** (from `zmk-module-runtime-input-processor`):

```dts
&hdpi   // hold for temporary speed-up (default 3/2)
&ldpi   // hold for temporary slow-down (default 1/2)
&hscr   // high scroll speed
&lscr   // low scroll speed
&ysnap AXIS_SNAP_MODE_Y 100   // hold to snap to Y axis (threshold 100)
&xsnap AXIS_SNAP_MODE_X 50    // hold to snap to X axis (threshold 50)
&amka   // hold to keep the temp-layer active
```

The keymap already includes `#include <behaviors/runtime-input-processor.dtsi>` and `<dt-bindings/zmk/runtime_input_processor.h>`; adjust the default ratios with `&hdpi { scale-multiplier = <3>; scale-divisor = <2>; };`.

### 6.3 Changing the lighting theme (RGB underglow)

**Firmware defaults** (`config/HPD.conf`):

```conf
CONFIG_ZMK_RGB_UNDERGLOW_ON_START=y
CONFIG_ZMK_RGB_UNDERGLOW_SAT_START=0
CONFIG_ZMK_RGB_UNDERGLOW_BRT_START=30
```

**Runtime adjustment from the keyboard**: the 9 `&rgb_ug` bindings in the top row of the FUN layer (enter via `&mo 3` from SYM).

**Hardware spec** (`HPD_left.overlay` / `HPD_right.overlay`, identical on both sides):

```dts
led_strip: ws2812@0 {
    compatible = "worldsemi,ws2812-spi";
    spi-max-frequency = <4000000>;
    chain-length = <1>;
    spi-one-frame = <0x70>;
    spi-zero-frame = <0x40>;
    color-mapping = <LED_COLOR_ID_GREEN LED_COLOR_ID_RED LED_COLOR_ID_BLUE>;
};
```

> If you want to add a display, note that **this repository has no display configuration at all** — you must add the shield and driver yourself.

### 6.4 Changing sensor parameters

**Static** (`config/HPD.keymap` + `HPD_right.conf`):

```dts
&trackball { cpi = <400>; };                  /* keymap */
&mmv { time-to-max-speed-ms = <500>; acceleration-exponent = <1>; trigger-period-ms = <16>; };
&msc { acceleration-exponent = <1>; time-to-max-speed-ms = <100>; delay-ms = <0>; };
```

**Runtime** (no rebuild): Studio's "Trackball" tab exposes CPI, axis scaling/rotation/inversion, inertia, axis snapping and temp-layer. Runtime settings override the static values.

### 6.5 Layout visualisation

`.github/workflows/keymap_drawer.yml` uses `caksoylar/keymap-drawer@v0.23.0` (pinned from `@main` to a tag) and redraws automatically whenever `config/**` changes, producing:

- `keymap-drawer/HPD.svg`
- `keymap-drawer/HPD.yaml`

Styling is controlled by `keymap_drawer.config.yaml` (single column, show both halves, 60×56 key size, 30 split gap, Ubuntu Mono 12px bold, and so on).

`config/HPD.json` is the **structured description** of the layout (key labels, row/column, coordinates, rotation `r`/`rx`/`ry`, plus the `left_encoder` sensor definition), shared by keymap-drawer and Studio's layout preview — **when you change a rotated key in `HPD.dtsi`, update it here too** or the preview will not match the physical board.

### 6.6 Upgrading the DYA Studio modules

Every revision in `config/west-dependency.yml` is a concrete commit hash. To upgrade:

1. Edit the relevant `revision:` to the target commit.
2. `west update --narrow`.
3. Verify with `make build-all`.
4. If `zmk` / `zephyr` itself is upgraded too, **always build both halves together** — central-only modules fail to link on the left half (see [7.2](#72-central--peripheral-configuration-boundaries-important)).

---

## 7. Troubleshooting & Gotchas

### 7.1 Build problems

| Symptom | Cause / fix |
| --- | --- |
| `undefined reference to 'zmk_behavior_queue_add'` | A central-only module (runtime sensor rotate / runtime macro / runtime combo / PMW3610 …) was enabled in the **shared `config/HPD.conf`**. These modules call functions the peripheral half does not link. **Move them to `HPD_right.conf`.** The behavior calls `zmk_behavior_queue_add()`, while `app/CMakeLists.txt` only compiles `behavior_queue.c` (alongside `keymap.c` and `hid.c`) under `if ((NOT CONFIG_ZMK_SPLIT) OR CONFIG_ZMK_SPLIT_ROLE_CENTRAL)` |
| Kconfig build aborts | Most often caused by `CONFIG_ZMK_USB_LOGGING`. The default build no longer sets it; use `make debug-all` when you need logs |
| A Studio tab saves but the firmware ignores it | Check that `CONFIG_ZMK_BEHAVIOR_LOCAL_IDS_IN_BINDINGS=y` is still present. The module turns a stored runtime binding back into a behavior name via `zmk_behavior_find_behavior_name_from_local_id()`, and that path is compiled out by default. The CRC16 local-id type selected above does **not** imply it (only `..._TYPE_SETTINGS_TABLE` selects it), so ask for it explicitly — otherwise the tab lets you save bindings the firmware silently ignores |
| `CONFIG_ZMK_LOW_PRIORITY_THREAD_STACK_SIZE` trips the MPU stack guard | Notifications from several RPC subsystems run on ZMK's shared low-priority work queue, and encoding them through the Studio RPC core needs more than the 768-byte default stack. The right half sets `4096`, the left half `2048`; `ZMK_STUDIO_RPC_THREAD_STACK_SIZE=6000` |
| Fails to build against upstream ZMK | This branch depends on `cormoran/zmk`'s custom Studio RPC protocol; upstream cannot build it |

### 7.2 central / peripheral configuration boundaries (important)

The two halves of a split keyboard do not have equal capabilities, and putting configuration in the wrong place causes build failures or misbehaviour:

| Item | Left half (peripheral) | Right half (central) |
| --- | --- | --- |
| Role definition | `config/HPD.conf` (shared, no `ZMK_SPLIT_ROLE_CENTRAL`) | `Kconfig.defconfig`, under `if SHIELD_HPD_RIGHT` → `CONFIG_ZMK_SPLIT_ROLE_CENTRAL=y` |
| DYA Studio RPC | ✗ (only receives synced data via `SPLIT_RELAY_EVENT`) | ✓ |
| Trackball / runtime input processors | ✗ | ✓ |
| Encoder (EC11) | ✓ | ✗ |
| Underglow WS2812 | ✓ (chain 1) | ✓ (chain 1) |
| Battery proxy / history | `BATTERY_REPORTING` only | additionally `..._LEVEL_PROXY` / `..._FETCHING` / `BATTERY_HISTORY` |

### 7.3 Studio connectivity

| Symptom | Fix |
| --- | --- |
| Studio cannot open the serial port / WebSerial cannot open CDC-ACM | ① Confirm you plugged in the **right half**; ② confirm the `studio-rpc-usb-uart` snippet and studio cmake-args for `HPD_right` are **still present** in `build.yaml` (`1b1c113` removed them, `1239a1c` restored them — do not remove them again); ③ the snippet works by adding a `zephyr,cdc-acm-uart` node under `zephyr_udc0`, which is what WebSerial's port detection keys off |
| Studio suddenly shows "locked" | This repository sets `CONFIG_ZMK_STUDIO_LOCKING=n`, so it should not auto-lock. If you set it back to `y`, note that once locked (default: 600 s of RPC idle, or any BLE disconnect) it can **only** be unlocked by pressing a key — and the current keymap does not bind `&studio_unlock`, so you would have to reflash |
| The left half is invisible in Studio | Expected. The left half is the peripheral; it only receives synced data through `CONFIG_ZMK_SPLIT_RELAY_EVENT` (`DATA_LEN=240`) and hosts no RPC |
| Saved settings disappear | Settings live in flash; `CONFIG_ZMK_SETTINGS_SAVE_DEBOUNCE=10000` (10 s debounce). Flash the `settings_reset` target to wipe all stored settings |

### 7.4 Layout and keys

| Symptom | Fix |
| --- | --- |
| Thumb keys look wrong in the Studio preview | `HPD.dtsi` and `config/HPD.json` are out of sync. Rotated keys need `r` + `rx` + `ry` in **both** places (fixed by commit `2296e8f`) |
| A layer is missing from Studio's "Sensor rotation" tab | That layer's `sensor-bindings` does not bind an `&rsr_*`, or binds `&trans`. The layer is invisible while the module's process hook does not run |
| Encoder does nothing on some layer and Studio does not offer it | `rsr_none` is deliberately transparent; bind `&rsr_vol` / `&rsr_scroll` to that layer, or save a binding from Studio |
| Cannot reach the FUN layer from the default layer | The default layer has no direct `&mo 3` key — press `&lt 2` for SYM first, then `&mo 3` |
| Underglow stays dark | Check `CONFIG_ZMK_RGB_UNDERGLOW_ON_START=y`; confirm you are on the SPI variant (`CONFIG_WS2812_STRIP_SPI`) and **not** the removed `CONFIG_WS2812_STRIP`; check `chain-length` and wiring on both halves |

### 7.5 Power and battery life

| Item | Value |
| --- | --- |
| Auto sleep | `CONFIG_ZMK_IDLE_SLEEP_TIMEOUT=900000` (**15 minutes**, identical on both halves) |
| Battery reading | `FETCH_MODE_STATE_OF_CHARGE` (percentage of charge rather than voltage) |
| Battery proxy | `CONFIG_ZMK_SPLIT_BLE_CENTRAL_BATTERY_LEVEL_PROXY` + `..._FETCHING` (**central only**; these lived in the shared conf on master, `dya` moved them into `HPD_right.conf`) |
| TX power | +8 dBm (`CONFIG_BT_CTLR_TX_PWR_PLUS_8`) |
| BLE parameters | `PREF_MAX_INT=9`, `PREF_LATENCY=16`, `ACL_TX_COUNT=8`, `EVT_RX_COUNT=10`, `L2CAP_TX_BUF_COUNT=32` |
| Extra power consumers | `CONFIG_ZMK_EXT_POWER=y`, underglow solid-on at boot (30%), `CONFIG_ZMK_BLE_EXPERIMENTAL_CONN=y` |

> Always-on underglow and the experimental BLE connection both cost battery. For maximum endurance, turn off `UNDERGLOW_ON_START` in `HPD.conf`.

### 7.6 Upgrading Zephyr / ZMK

The `zephyr` revision pinned in `west-dependency.yml` (`v4.1.0+zmk-fixes+nrf-half-duplex-uart`) prunes a large number of HAL modules. If you move to a Zephyr mainline that restores them, CI build times will increase substantially. Get `make init-standalone && make build-all` working locally first.

---

## 8. Repository File Index

```
.
├── Makefile                          # make init-standalone / init-workspace / build-all / debug-all
├── build.yaml                        # three build targets (left / right / settings_reset)
├── .gitignore                        # build/ dependencies/ .west/
├── keymap_drawer.config.yaml         # keymap-drawer styling
├── .github/workflows/
│   ├── build.yml                     # ZMK build + artifact + optional Release
│   └── keymap_drawer.yml             # automatic redraw via keymap-drawer v0.23.0
├── keymap-drawer/
│   ├── HPD.svg                       # generated layout drawing
│   └── HPD.yaml                      # generated layout description
└── config/
    ├── HPD.conf                      # config shared by both halves (BLE tuning, underglow, ext power)
    ├── HPD.keymap                    # 7 layers + sensor bindings + input processors  ★core
    ├── HPD.json                      # structured layout description (rotation origins, encoder definition)
    ├── west.yml                      # workspace manifest (imports west-dependency)
    ├── west-dependency.yml           # DYA Studio dependencies, pinned per commit  ★core
    ├── west-standalone.yml           # standalone manifest (path-prefix: dependencies)
    └── boards/shields/HPD/
        ├── Kconfig.defconfig         # split / central role declaration
        ├── Kconfig.shield
        ├── HPD.dtsi                  # physical_layout, matrix transform, kscan, EC11, PMW3610 (disabled)  ★core
        ├── HPD.zmk.yml               # shield metadata + features
        ├── HPD.conf                  # (empty; shared config lives in config/HPD.conf)
        ├── HPD_left.overlay          # left: kscan GPIO, WS2812, encoder enabled
        ├── HPD_left.conf             # left-half Kconfig (peripheral)
        ├── HPD_right.overlay         # right: kscan GPIO, WS2812, SPI1 trackball, input listener
        └── HPD_right.conf            # right-half Kconfig (central + all DYA RPC)  ★core
```

---

## References

- [ZMK official documentation](https://zmk.dev/docs/)
- [DYA Studio developer guide](https://dya-studio-dev.cormoran707.workers.dev/developer-guide)
- [cormoran/zmk](https://github.com/cormoran/zmk) — the ZMK fork this repository depends on
- [cormoran/zmk-module-runtime-input-processor](https://github.com/cormoran/zmk-module-runtime-input-processor)
- [cormoran/zmk-behavior-runtime-sensor-rotate](https://github.com/cormoran/zmk-behavior-runtime-sensor-rotate)
- [cormoran/zmk-driver-pmw3610-with-custom-studio-rpc](https://github.com/cormoran/zmk-driver-pmw3610-with-custom-studio-rpc)
- [caksoylar/keymap-drawer](https://github.com/caksoylar/keymap-drawer)

## Licence

The key layout and keymap configuration are distributed with this repository; ZMK and the individual west modules remain under their respective upstream licences.