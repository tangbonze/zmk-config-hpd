# zmk-config-hpd

[简体中文](README.md) | [English](README_EN.md)

---

HPD 分体人体工学键盘的 [ZMK](https://zmk.dev/) 固件配置仓库，默认分支为 **`dya`**。

该分支在标准 ZMK 之上接入 **DYA Studio**（cormoran 维护的 ZMK Studio 增强分支），把键位、宏、组合键、轨迹球参数、编码器行为、电池历史等大量配置从「改代码 + 重新编译烧录」迁移到「浏览器里直接改、即时生效并持久化」。

---

## 目录

- [1. 分支说明](#1-分支说明)
- [2. 项目简介与硬件配置](#2-项目简介与硬件配置)
- [3. 键盘布局与主要功能按键](#3-键盘布局与主要功能按键)
- [4. 固件特性](#4-固件特性)
- [5. 固件安装与编译](#5-固件安装与编译)
- [6. 配置自定义](#6-配置自定义)
- [7. 常见问题与注意事项](#7-常见问题与注意事项)
- [8. 仓库文件索引](#8-仓库文件索引)

---

## 1. 分支说明

### 1.1 默认分支已切换为 `dya`

仓库原先默认分支为 `master`，现已改为 **`dya`**：

| 项目                | 值                                                                           |
| ----------------- | --------------------------------------------------------------------------- |
| 默认分支              | `dya`                                                                       |
| 默认分支 HEAD         | `f230937` — *fix: enable runtime sensor rotate on the central half only*    |
| 另一分支              | `master`（HEAD `e0aaf8e` — *chore: set startup underglow brightness to 30%*） |
| `dya` 相对 `master` | 领先 9 个提交，落后 0 个提交                                                           |

### 1.2 `dya` 完整包含 `master` 的最新改动

`git rev-list --left-right --count master...dya` 的结果为 `0  9`——左侧为 0，表示 **没有任何一个 `master` 上的提交是 `dya` 缺少的**。因此 `dya` 是 `master` 的严格超集（fast-forward 关系），把它设为默认分支不会丢失任何已有功能。

`dya` 相对 `master` 新增的 9 个提交：

| 提交        | 日期         | 说明                                                                     |
| --------- | ---------- | ---------------------------------------------------------------------- |
| `e534e0c` | 2026-09-26 | feat(dya): 接入 DYA Studio 固件支持（新增 `west-dependency.yml`、Makefile、CI 构建） |
| `f9cbabd` | 2026-09-27 | fix: 移除废弃的 `CONFIG_WS2812_STRIP`                                       |
| `fa00802` | 2026-09-27 | feat: 上电即点亮 RGB 底灯                                                     |
| `928a942` | 2026-10-02 | fix: dya 分支评审清理                                                        |
| `1b1c113` | 2026-10-02 | build: 右半移除 `studio-rpc-usb-uart` snippet 与 studio cmake-args          |
| `2296e8f` | 2026-10-02 | fix: 为旋转拇指键补齐显式旋转原点（`rx`/`ry`）                                         |
| `1239a1c` | 2026-10-02 | fix: 恢复右半的 `studio-rpc-usb-uart` snippet                               |
| `ecbaee3` | 2026-10-02 | feat: 新增 runtime sensor rotate（通过 DYA Studio 逐层配置编码器）                  |
| `f230937` | 2026-10-02 | fix: runtime sensor rotate 仅在 central 半边启用                             |

### 1.3 切换为默认分支的影响

- **克隆默认分支改变**：新用户 `git clone https://github.com/tangbonze/zmk-config-hpd.git` 检出 `dya` 而非 `master`。
- **CI 行为不变**：`.github/workflows/build.yml` 的 `push` 触发器本来就同时监听 `master` 与 `dya`，两条分支都会构建。
- **`git archive` / 依赖默认分支的外部链接**会指向 `dya`。
- **本地已有克隆不受影响**：已配置的 upstream 追踪关系保持原样；若要跟随新默认分支，执行：
  ```bash
  git remote set-head origin -a
  ```
- **`master` 分支保留未删除**，可随时回退：把仓库设置的默认分支改回 `master` 即可（不涉及任何提交操作，无风险）。

---

## 2. 项目简介与硬件配置

### 2.1 键盘型号

**HPD** —— 6 列 × 5 行 + 拇指区 + 底部附加键的**分体人体工学键盘**，左右各一半（`requires: [pro_micro]`，分体互联方式在本仓库配置中未显式声明，以实际硬件为准）。总计 **61 个按键位**（矩阵 12 列 × 6 行 = 72 个位置，其中 61 个布键）。

| 项目             | 说明                                                                               |
| -------------- | -------------------------------------------------------------------------------- |
| 型号             | HPD（Shield 名即 `HPD`，子 shield `HPD_left` / `HPD_right`）                           |
| 架构             | 分体键盘（`CONFIG_ZMK_SPLIT=y`）                                                       |
| 左半（peripheral） | 按键矩阵、EC11 旋转编码器、WS2812 底灯                                                        |
| 右半（central）    | 按键矩阵、PMW3610 轨迹球、WS2812 底灯、USB/BLE 主机连接、DYA Studio RPC                           |
| 矩阵规模           | 每半 6 行 × 6 列；`default_transform` 为 12 列 × 6 行，右半通过 `col-offset = <6>` 偏移到 6–11 列 |
| 供电             | `CONFIG_ZMK_EXT_POWER=y`（外接电源）                                                   |

### 2.2 主控与 ZMK 固件方案

| 项目           | 值                                                                       |
| ------------ | ----------------------------------------------------------------------- |
| MCU          | **nice!nano v2**（nRF52840）                                              |
| 板名写法         | `nice_nano//zmk`（ZMK 官方板名 + ZMK 板级 revision 选择器）                        |
| 固件基线         | `cormoran/zmk`，revision `e5c9b69`（main + dya），**非** upstream ZMK        |
| Zephyr       | `7c6b4cc`（v4.1.0 + zmk-fixes + nrf-half-duplex-uart），大量裁剪 HAL 以缩短 CI 时间 |
| 无线连接         | BLE 5，`CONFIG_BT_CTLR_TX_PWR_PLUS_8=y`（发射功率 +8 dBm）                     |
| 关键 Zephyr 调整 | `CONFIG_CONSOLE=n`（Zephyr 4.1 默认开启 console，键盘不需要）                       |

> ⚠️ 该分支**不能**用 upstream `zmkfirmware/zmk` 编译。`west-dependency.yml` 中所有 remote 均指向 `https://github.com/cormoran`，并**全部锁定到具体 commit hash**，以防上游推送静默改变固件行为。需要升级时手动 bump。

---

## 3. 键盘布局与主要功能按键

### 3.1 默认层（QWRT）完整键位

每个图层均为 **61 个 binding**（5 行 × 12 列 + 1 个底部附加键）。下表按矩阵行列展开，行内**先左半（列 0–5）、后右半（列 6–11）**。

| 行      | 左半（列 0–5）                                 | 右半（列 6–11）                                 |
| ------ | ----------------------------------------- | ------------------------------------------ |
| **R0** | `ESC` `1` `2` `3` `4` `5`                 | `6` `7` `8` `9` `0` `BACKSPACE`            |
| **R1** | `TAB` `Q` `W` `E` `R` `T`                 | `Y` `U` `I` `O` `P` `\` <sup>`\|`</sup>    |
| **R2** | `CAPS` `A` `S` `D` `F` `G`                | `H` `J` `K` `L` `;` `'` <sup>`"`</sup>     |
| **R3** | `LSHIFT` `Z` `X` `C` `V` `B`              | `N` `M` `,` `.` `/` `RSHIFT`               |
| **R4** | `NUM` `SCROLL` `CTRL` `ALT` `GUI` `SNIPE` | `BACKSPACE` `DELETE` `[` `]` `MOUSE` `SYM` |
| **R5** | 附加键 `MUTE`（列 0）                           | —                                          |

- **R1–R3 的 Shift 组合**（`|`、`"`）由 `config/HPD.json` 中记录的 `s` 副标签给出。
- **R4 的 8 个倾斜键位**：列 0/1/4/5 为 `+15°`，列 6/7/10/11 为 `-15°`，即 `NUM` `SCROLL` `GUI` `SNIPE` 与 `BACKSPACE` `DELETE` `MOUSE` `SYM`。这 8 键在 `HPD.dtsi` 中均写有 `rot` + **显式 `rx`/`ry` 旋转原点**（DYA 提交 `2296e8f` 修复）；缺了原点会导致 DYA Studio 的布局预览与实物位置不符。
- **底部附加键**：`&kp K_MUTE` 是矩阵中唯一的第 6 行键位（`x = 625, y = 325`），位于左半最内侧。
- **keymap 与 `HPD.json` 的 label 不一致属正常**：`HPD.json` 的 `label` 描述**键帽丝印**（如列 0 标为 `SPACE`、列 11 标为 `ENTER`），而 keymap 实际把列 0 绑成了 NUM 层、列 11 绑成了 SYM 层。**改键位以 `HPD.keymap` 为准**，改物理布局才动 `HPD.json`。

### 3.2 图层与进入方式

| 索引 | 标签       | 名称          | 进入方式                      | 编码器绑定                          |
| -- | -------- | ----------- | ------------------------- | ------------------------------ |
| 0  | `QWRT`   | 默认层         | —                         | `&rsr_vol`（音量）                 |
| 1  | `NUM`    | 数字 / 方向键层   | 按住 R4-0（`&lt 1`）          | `&rsr_scroll`（滚动，`tap-ms` 100） |
| 2  | `SYM`    | 符号层         | 按住 R4-11（`&lt 2`）         | `&rsr_none`                    |
| 3  | `FUN`    | 功能 / RGB 层  | 从 SYM 层按 R4-11（`&mo 3`）进入 | `&rsr_none`                    |
| 4  | `MOUSE`  | 鼠标按键层       | 按住 R4-10（`&mo 4`）         | `&rsr_none`                    |
| 5  | `SCROLL` | 轨迹球慢速 / 滚动层 | 按住 R4-1（`&mo 5`）          | `&rsr_none`                    |
| 6  | `SNIPE`  | 轨迹球降速层      | 按住 R4-5（`&mo 6`）          | `&rsr_none`                    |

> 默认层没有直达 FUN（3）的键，必须先按 `&lt 2` 进 SYM 层，再按 `&mo 3`。

### 3.3 各层要点

以下均按矩阵行列（列 0–11）给出实际 binding。

**NUM（1）** —— 仅 14 个有效键，其余透传

| 位置        | 按键                                      |
| --------- | --------------------------------------- |
| R0 列 1–10 | `1` `2` `3` `4` `5` `6` `7` `8` `9` `0` |
| R2 列 1–4  | `←` `↓` `↑` `→`                         |

**SYM（2）** —— 蓝牙选择 + 符号

| 位置        | 按键                                        |
| --------- | ----------------------------------------- |
| R0 列 1–10 | `!` `@` `#` `$` `%` `^` `&` `*` `(` `)`   |
| R2 列 1–4  | `BT_CLR` `BT_SEL 0` `BT_SEL 1` `BT_SEL 2` |
| R2 列 6–9  | `-` `=` `[` `]`                           |
| R3 列 6–7  | `_` `+`                                   |
| R4 列 11   | `&mo 3` → 进入 FUN 层                        |

**FUN（3）** —— RGB 控制 + F 键

| 位置       | 按键                                                                                        |
| -------- | ----------------------------------------------------------------------------------------- |
| R0 列 0–8 | `RGB_TOG` `RGB_BRI` `RGB_BRD` `RGB_EFF` `RGB_EFR` `RGB_SAD` `RGB_SAI` `RGB_HUD` `RGB_HUI` |
| R1 列 1–4 | `F1` `F2` `F3` `F4`                                                                       |
| R2 列 1–4 | `F5` `F6` `F7` `F8`                                                                       |
| R3 列 1–4 | `F9` `F10` `F11` `F12`                                                                    |

**MOUSE（4）**

| 位置       | 按键                    |
| -------- | --------------------- |
| R2 列 1–4 | `←` `↓` `↑` `→`       |
| R4 列 6   | `&mkp MCLK`（**鼠标中键**） |
| R4 列 10  | `&mkp LCLK`（**鼠标左键**） |
| R4 列 11  | `&mkp RCLK`（**鼠标右键**） |

> ZMK 命名以鼠标侧为准：`LCLK` = 鼠标左键、`RCLK` = 鼠标右键、`MCLK` = 鼠标中键，与键盘 `CTRL`/`ALT` 的左右位置无关。

**SCROLL（5）/ SNIPE（6）**：整层 61 键全为 `&trans`，不含任何普通键位，仅通过 input-listener 改变轨迹球输入处理链（见 [4.3](#43-轨迹球与编码器)）。

---

## 4. 固件特性

### 4.1 DYA Studio 模块矩阵

`dya` 分支的核心。以下 Kconfig 开关与 `config/west-dependency.yml` 中的模块一一对应，均位于 **右半（central）** 的 `HPD_right.conf`；左半通过 `CONFIG_ZMK_SPLIT_RELAY_EVENT` + `CONFIG_ZMK_CUSTOM_SETTINGS_SPLIT_RPC_RELAY` 接收同步。

| Studio 页签              | Kconfig 开关                                                                                                                                                       | 对应 west 模块                                                                                             |
| ---------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------ |
| 连接（Connection）         | `CONFIG_ZMK_BLE_MANAGEMENT` `..._STUDIO_RPC`<br />`CONFIG_ZMK_OS_DETECTION` (+USB/BLE/STUDIO_RPC)<br />`CONFIG_ZMK_DEFAULT_LAYER` (min 0 / max 6, +OS_DETECTION) | `zmk-module-ble-management`<br />`zmk-feature-os-detection`<br />`zmk-feature-default-layer`           |
| 设置（Settings）           | `CONFIG_ZMK_SETTINGS_RPC` `..._STUDIO`<br />`CONFIG_ZMK_CUSTOM_SETTINGS` (+SPLIT_RPC_RELAY / STUDIO_RPC)<br />`LARGE_VALUE_MAX_SIZE=256`                         | `zmk-module-settings-rpc`<br />`zmk-feature-custom-settings`                                           |
| 键位（Keymap）             | `CONFIG_ZMK_PHYSICAL_LAYOUTS_FEATURE` `..._STUDIO_RPC`<br />`CONFIG_ZMK_RUNTIME_MACRO` / `_COMBO` (+STUDIO_RPC)<br />`CONFIG_ZMK_BEHAVIOR_LOCAL_ID_TYPE_CRC16`   | `zmk-feature-module-physical-layout`<br />`zmk-feature-runtime-macro`<br />`zmk-feature-runtime-combo` |
| 轨迹球（Trackball）         | `CONFIG_ZMK_RUNTIME_INPUT_PROCESSOR` `..._STUDIO_RPC`<br />`CONFIG_PMW3610` `CONFIG_ZMK_PMW3610_STUDIO_RPC` / `_CUSTOM_SETTINGS`                                 | `zmk-module-runtime-input-processor`<br />`zmk-driver-pmw3610-with-custom-studio-rpc`                  |
| 传感器旋转（Sensor rotation） | `CONFIG_ZMK_RUNTIME_SENSOR_ROTATE` `..._STUDIO_RPC`<br />`CONFIG_ZMK_BEHAVIOR_LOCAL_IDS_IN_BINDINGS`                                                             | `zmk-behavior-runtime-sensor-rotate`                                                                   |
| 诊断（Diagnostics）        | `CONFIG_ZMK_DEVICE_INFO` `..._STUDIO_RPC`<br />`CONFIG_ZMK_WATCHDOG` `..._STUDIO_RPC`                                                                            | `zmk-feature-device-info`<br />`zmk-feature-watchdog`                                                  |
| 电池历史                   | `CONFIG_ZMK_BATTERY_HISTORY` `..._STUDIO_RPC`                                                                                                                    | `zmk-module-battery-history`                                                                           |

此外 `config/HPD.zmk.yml` 声明了 `features: [keys, pointer, underglow, studio]`，便于外部工具识别。

### 4.2 显示与主题

> **本仓库当前没有显示屏。** 已核查全部 `.conf` / `.overlay` / `.dtsi`，**不存在任何 `CONFIG_ZMK_DISPLAY` / SSD1306 / OLED 配置**，也未引入显示模块。因此不要在本仓库上尝试接显示屏——需要的话须自行添加显示 shield 与驱动。

**"主题"在本仓库中对应 RGB 底灯**，通过 ZMK 原生底灯实现：

| 配置项                                  | 值                                              | 说明                                                |
| ------------------------------------ | ---------------------------------------------- | ------------------------------------------------- |
| `CONFIG_ZMK_RGB_UNDERGLOW`           | `y`                                            | 启用底灯                                              |
| `CONFIG_ZMK_RGB_UNDERGLOW_ON_START`  | `y`                                            | 上电即亮（DYA 提交 `fa00802`）                            |
| `CONFIG_ZMK_RGB_UNDERGLOW_SAT_START` | `0`                                            | 启动饱和度 0（全白）                                       |
| `CONFIG_ZMK_RGB_UNDERGLOW_BRT_START` | `30`                                           | 启动亮度 30%                                          |
| 驱动                                   | `CONFIG_WS2812_STRIP_SPI` + `CONFIG_LED_STRIP` | WS2812 走 SPI3（MOSI = P0.11），每半 `chain-length = 1` |

底灯颜色/亮度/速度效果可在 **FUN 层**（`&mo 3` → SYM 层进入）实时调节：`RGB_TOG`（开关）、`RGB_BRI`/`RGB_BRD`（亮度±）、`RGB_EFF`（切换效果）、`RGB_EFR`（效果速度±）、`RGB_SAD`/`RGB_SAI`（饱和度±）、`RGB_HUD`/`RGB_HUI`（色相±）。

> 注意 `CONFIG_WS2812_STRIP`（非 SPI 版）已在 `f9cbabd` 中移除，仅保留 SPI 版本，**不要再手工加回**，否则与 SPI 版本冲突。

### 4.3 轨迹球与编码器

**硬件**

| 项目   | 值                                                                                                                                                                         |
| ---- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 传感器  | PMW3610，devicetree compatible **`cormoran,pmw3610`**（驱动来自 cormoran，不是 upstream 的 `zmk,pmw3610`）                                                                           |
| 位置   | **仅右半（central）**，`HPD.dtsi` 中默认 `status = "disabled"`，由 `HPD_right.overlay` 打开                                                                                            |
| 总线   | SPI1 @ 2 MHz，CS = P0.22（低有效），IRQ = P0.20                                                                                                                                  |
| 方向映射 | `SWAP_XY` + `INVERT_X` + `INVERT_Y`——保留 HPD 传统 `ORIENTATION_90 + INVERT_X` 的手感                                                                                            |
| CPI  | **400**（`&trackball { cpi = <400>; }`）                                                                                                                                    |
| 其他   | `disable-burst-read`；`CONFIG_PMW3610_SMART_ALGORITHM=y`；`RUN_DOWNSHIFT_TIME_MS=3264`；`REST1_SAMPLE_TIME_MS=20`；`REPORT_INTERVAL_MIN=8`；`INIT_POWER_UP_EXTRA_DELAY_MS=200` |

**编码器**

`alps,ec11`，位于**左半**，`steps = <20>`，`triggers-per-rotation = <10>`，`A`=P0.29、`B`=P0.31。

**输入处理链**（`HPD_right.overlay` 的 `trackball_listener`）

| 生效层            | 处理链                                                                      |
| -------------- | ------------------------------------------------------------------------ |
| 默认（全部层）        | `&mouse_runtime_input_processor &scroll_runtime_input_processor`         |
| 第 5 层 `SCROLL` | `&zip_xy_scaler 1 2 &scroll_runtime_input_processor`（XY 降为 1/2 速率 + 转滚动） |
| 第 6 层 `SNIPE`  | `&zip_xy_scaler 1 2 &mouse_runtime_input_processor`（XY 降为 1/2 速率）        |

- `mouse_runtime_input_processor`：`temp-layer-enabled`、`temp-layer = <4>`（MOUSE 层）、激活延迟 `0 ms`、失活延迟 `700 ms`——移动轨迹球自动切到 MOUSE 层，按键或超时后自动回默认层。
- `scroll_runtime_input_processor`：`active-layers = <BIT(5)>`、`xy-to-scroll-enabled`、`axis-snap-threshold = <100>`。
- 传统鼠标/滚轮微调（`&mmv` / `&msc`）：`mmv` 加速指数 1、`time-to-max-speed-ms=500`、`trigger-period-ms=16`；`msc` 加速指数 1、`time-to-max-speed-ms=100`；`zip_xy_scaler 2 1` / `zip_scroll_scaler 1 2`。


**Runtime Sensor Rotate（逐层编码器绑定）**

`dya` 分支最新特性（`ecbaee3` / `f230937`）：通过自定义 RPC 子系统 `cormoran_rsr`，可在 Studio 的「传感器旋转」页签**按层**重设编码器 CW/CCW 行为，配置持久化。

```dts
rsr_vol: rsr_vol {                       /* 默认层：音量 */
    compatible = "zmk,behavior-runtime-sensor-rotate";
    #sensor-binding-cells = <0>;
    cw-binding  = <&kp K_VOLUME_UP>;
    ccw-binding = <&kp K_VOLUME_DOWN>;
};
rsr_scroll: rsr_scroll {                 /* NUM 层：滚动，tap-ms 100 */
    compatible = "zmk,behavior-runtime-sensor-rotate";
    #sensor-binding-cells = <0>;
    tap-ms = <100>;
    cw-binding  = <&msc SCRL_DOWN>;
    ccw-binding = <&msc SCRL_UP>;
};
rsr_none: rsr_none {                     /* 其余层：透传 */
    compatible = "zmk,behavior-runtime-sensor-rotate";
    #sensor-binding-cells = <0>;
};
```

| 约束                    | 说明                                                                           |
| --------------------- | ---------------------------------------------------------------------------- |
| 每层必须绑定                | 层未绑定或绑 `&trans` 时，模块的 process hook 不运行，该层在 Studio 中**不可见**                   |
| `cw-/ccw-binding` 是兜底 | 仅在该层尚未保存运行时绑定时生效，值与被替换的静态绑定一致，开箱行为不变                                         |
| 仅 central             | 在共享的 `config/HPD.conf` 中启用会导致左半链接失败（见 [7.2](#72-central--peripheral-配置边界重要)） |

---

## 5. 固件安装与编译

### 5.1 三个编译目标

`build.yaml`：

| 目标 | 板 / shield                          | 附加项                                                                                                   | 产物                             |
| -- | ----------------------------------- | ----------------------------------------------------------------------------------------------------- | ------------------------------ |
| 左半 | `nice_nano//zmk` + `HPD_left`       | —                                                                                                     | `nice_nano__zmk_HPD_left.uf2`  |
| 右半 | `nice_nano//zmk` + `HPD_right`      | `snippet: studio-rpc-usb-uart`<br />`cmake-args: -DCONFIG_ZMK_STUDIO=y -DCONFIG_ZMK_STUDIO_LOCKING=n` | `nice_nano__zmk_HPD_right.uf2` |
| 复位 | `nice_nano//zmk` + `settings_reset` | —                                                                                                     | 用于清除已保存的 Studio 设置             |

产物文件名取自 west 构建目录名，故实际形如 `nice_nano__zmk_HPD_left.uf2`、`nice_nano__zmk_HPD_right.uf2`。

> **`studio-rpc-usb-uart` snippet 的作用**（提交 `1b1c113` 曾移除、`1239a1c` 又恢复，务必保持现状）：该 snippet 追加 `CONFIG_ZMK_USB` + `CONFIG_USB_CDC_ACM`，并通过 `zmk,studio-rpc-uart` 把 Studio RPC 挂到 USB CDC-ACM 串口上，同时加上 `-DZMK_BEHAVIORS_KEEP_ALL`。**没有它，Studio 无法通过 WebSerial 连接右半。**

### 5.2 方式 A：GitHub Actions（推荐）

`.github/workflows/build.yml` 在 push 到 `master` / `dya`、PR 或手动触发时运行：

1. `make init-standalone`（依赖装到 `./dependencies`）
2. `make build-all`
3. 收集所有 `*/zephyr/zmk.uf2` → 上传为 workflow artifact `hpd`
4. 手动触发时若填入 `release` 输入，还会 `gh release create` 打包发布

手动触发并出 Release：**Actions → Build ZMK firmware → Run workflow → 填入 `release`（如 `v0.1.0`）**。

### 5.3 方式 B：本地 west 构建

前置：`west`、`cmake`、`ninja`、`arm-none-eabi-gcc`（Zephyr SDK）。

```bash
# 依赖装在仓库内 ./dependencies（CI 用的方式，推荐）
make init-standalone
make build-all

# 或：依赖装在上一级目录（标准 west workspace）
make init-workspace
make build-all
```

等价的手工命令：

```bash
west init -l config --mf west-standalone.yml
west update --narrow
west zephyr-export
west zmk-build -d ./build -q
```

调试构建（启用 `zmk-usb-logging`，会牺牲一部分体积换日志）：

```bash
make debug-all      # 等价于 west zmk-build -S zmk-usb-logging
```

> master 分支历史提交 `30edfff` 曾移除 `config/HPD.conf` 里的 `CONFIG_ZMK_USB_LOGGING`，因为它会导致 Kconfig 构建中止。**因此默认构建不含 USB 日志**，需要日志请走 `-S zmk-usb-logging`。

编译完成后固件位于：

```
build/nice_nano__zmk_HPD_left/zephyr/zmk.uf2
build/nice_nano__zmk_HPD_right/zephyr/zmk.uf2
```

### 5.4 烧录到键盘

本仓库**不提供** `west flash` 目标，采用 UF2 直刷：

1. nice!nano v2 进入 bootloader：按住 **RESET**，松开后立即双击任意一侧的键（部分版本为按住 RESET + 插拔 USB）。
2. 出现可移动盘 `NICE_NANO`（RP2040 / nRF528 bootloader）。
3. 把对应的 `zmk.uf2` **拖进该盘符**，等待指示灯熄灭。
4. 复位拔线，键盘启动（底灯会以 30% 亮度白色常亮）。

**左半 / 右半不要烧错。** 首次配对时**只上电右半**，先在 Studio 里完成配置，再给左半上电。

### 5.5 使用 DYA Studio 配置

1. 浏览器打开 DYA Studio（cormoran 提供的 Studio 构建）。
2. **只连接右半**——把 nice!nano 的 USB 线接到**右半**，使用 `studio-rpc-usb-uart` 提供的 CDC-ACM 串口。
3. Studio 通过 WebSerial 打开 CDC-ACM 端口后，即可看到本固件暴露的各页签（连接 / 设置 / 键位 / 轨迹球 / 传感器旋转 / 诊断 / 电池历史）。
4. 改动即时写入非易失存储，重启后保留；左半通过 split relay 同步。

> ⚠️ **本仓库未在 keymap 中绑定 `&studio_unlock`。** 该 fork 的解锁是"物理按键式"——一旦 Studio 锁定就没有 RPC/PIN 解锁途径。好在本仓库在 `build.yaml` 与 `HPD_right.conf` 中都设了 `CONFIG_ZMK_STUDIO_LOCKING=n`，**禁用了自动锁定**，因此不会出现"锁死后无法恢复"。若你改回 `CONFIG_ZMK_STUDIO_LOCKING=y`，**必须**同时在 keymap 中给某个键加上 `&studio_unlock`。

---

## 6. 配置自定义

### 6.1 修改 keymap（改键位）

编辑 `config/HPD.keymap`。每个图层形如：

```dts
function_layer {
    label = "FUN";
    bindings = <
&trans  &kp F1  &kp F2   &kp F3   &kp F4   &trans  &trans  &trans  &trans  &trans  &trans  &trans
            >;
    sensor-bindings = <&rsr_none>;
};
```

- `label` 是 DYA Studio / keymap-drawer 显示的图层名。
- 每行 12 个 binding 对应矩阵 12 列（**左半 6 列 + 右半 6 列**，不是"左半一行、右半一行"）。
- `&trans` 表示透传，落到下层。
- 改完执行 `make build-all` 重新编译烧录。

> **免编译的替代方案**：DYA Studio 的「键位」页签支持运行时宏（runtime macro）与运行时组合键（runtime combo），这两类改动**不需要重新编译固件**，直接在浏览器里保存即生效。

### 6.2 修改 behavior / 宏

**静态 behavior**（需编译）：

- 标准 ZMK behavior：改 `config/HPD.keymap`，必要时 `#include <behaviors/...>`。
- 自定义 behavior：在 `/ { behaviors { ... }; };` 中定义。仓库当前该节点为空，可按 ZMK 语法添加。
- Runtime sensor rotate 实例：`rsr_vol` / `rsr_scroll` / `rsr_none`，属性 `tap-ms`、`cw-binding`、`ccw-binding`（见 [4.3](#43-轨迹球与编码器)）。

**运行时宏 / 组合键**（免编译）：Studio「键位」页签配置。

**临时参数 behavior**（来自 `zmk-module-runtime-input-processor`）：

```dts
&hdpi   // 按住临时加速（默认 3/2）
&ldpi   // 按住临时减速（默认 1/2）
&hscr   // 按住高速滚动
&lscr   // 按住低速滚动
&ysnap AXIS_SNAP_MODE_Y 100   // 按住吸附 Y 轴（阈值 100）
&xsnap AXIS_SNAP_MODE_X 50    // 按住吸附 X 轴（阈值 50）
&amka   // 按住以保持 temp-layer 激活
```

需要在 keymap 中 `#include <behaviors/runtime-input-processor.dtsi>` 与 `<dt-bindings/zmk/runtime_input_processor.h>`（仓库已包含），再用 `&hdpi { scale-multiplier = <3>; scale-divisor = <2>; };` 调整默认倍率。

### 6.3 修改显示主题（RGB 底灯）

**固件默认值**（`config/HPD.conf`）：

```conf
CONFIG_ZMK_RGB_UNDERGLOW_ON_START=y
CONFIG_ZMK_RGB_UNDERGLOW_SAT_START=0
CONFIG_ZMK_RGB_UNDERGLOW_BRT_START=30
```

**按键实时调节**：FUN 层（`&mo 3` → SYM 层 `&mo 3`）顶排 9 个 `&rgb_ug` 绑定。

**硬件规格**（`HPD_left.overlay` / `HPD_right.overlay`，两侧相同）：

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

> 如需接入显示屏，**本仓库当前无任何显示配置**，须自行添加 shield 与驱动。

### 6.4 修改传感器参数

**静态**（`config/HPD.keymap` + `HPD_right.conf`）：

```dts
&trackball { cpi = <400>; };                  /* keymap */
&mmv { time-to-max-speed-ms = <500>; acceleration-exponent = <1>; trigger-period-ms = <16>; };
&msc { acceleration-exponent = <1>; time-to-max-speed-ms = <100>; delay-ms = <0>; };
```

**运行时**（免编译）：Studio「轨迹球」页签可改 CPI、轴缩放/旋转/反转、inertia、轴吸附、temp-layer 等。运行时设置会覆盖静态值。

### 6.5 布局可视化

`.github/workflows/keymap_drawer.yml` 使用 `caksoylar/keymap-drawer@v0.23.0`（已从 `@main` 固定到 tag），在 `config/**` 变化时自动重绘，产物：

- `keymap-drawer/HPD.svg`
- `keymap-drawer/HPD.yaml`

样式由 `keymap_drawer.config.yaml` 控制（单列、显示左右手、60×56 键宽、30 split gap、Ubuntu Mono 12px 粗体等）。

`config/HPD.json` 则是布局的**结构化描述**（键位标签、行列、坐标、旋转 `r`/`rx`/`ry`，以及 `left_encoder` 传感器定义），供 keymap-drawer 与 Studio 布局预览共用——**改了 `HPD.dtsi` 里的旋转键务必同步这里**，否则预览与实物不一致。

### 6.6 升级 DYA Studio 模块

`config/west-dependency.yml` 中所有 revision 均为具体 commit hash。升级时：

1. 编辑对应 `revision:` 为目标 commit。
2. `west update --narrow`。
3. `make build-all` 验证。
4. 若 `zmk` / `zephyr` 本体也升级，**务必两块半一起编译**——central-only 的模块在左半会链接失败（见 [7.2](#72-central--peripheral-配置边界重要)）。

---

## 7. 常见问题与注意事项

### 7.1 构建相关

| 现象                                                    | 原因 / 处理                                                                                                                                                                                                                                                                                                                |
| ----------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `undefined reference to 'zmk_behavior_queue_add'`     | 在**共享的 `config/HPD.conf`** 里启用了 central-only 模块（runtime sensor rotate / runtime macro / runtime combo / PMW3610 等）。这些模块会调用 peripheral 半不链接的函数。**移到 `HPD_right.conf`**。该行为调用 `zmk_behavior_queue_add()`，而 `app/CMakeLists.txt` 仅在 `if ((NOT CONFIG_ZMK_SPLIT) OR CONFIG_ZMK_SPLIT_ROLE_CENTRAL)` 下编译 `behavior_queue.c` |
| Kconfig 构建中止                                          | 多因 `CONFIG_ZMK_USB_LOGGING`。默认构建已移除它；需要日志请用 `make debug-all`                                                                                                                                                                                                                                                           |
| Studio 页签能保存但固件无反应                                    | 检查 `CONFIG_ZMK_BEHAVIOR_LOCAL_IDS_IN_BINDINGS=y` 是否还在。模块通过 `zmk_behavior_find_behavior_name_from_local_id()` 把运行时绑定转回 behavior 名，该路径默认被编译掉；`..._TYPE_CRC16` **不会**自动带上它，必须显式开启                                                                                                                                         |
| `CONFIG_ZMK_LOW_PRIORITY_THREAD_STACK_SIZE` 报 MPU 栈守卫 | 多个 RPC 子系统的通知走 ZMK 共享低优先级工作队列，编码通知需要大于默认 768 字节。右半设 `4096`，左半设 `2048`；`ZMK_STUDIO_RPC_THREAD_STACK_SIZE=6000`                                                                                                                                                                                                          |
| upstream ZMK 编译失败                                     | 本分支依赖 `cormoran/zmk` 的自定义 Studio RPC 协议，upstream 无法编译                                                                                                                                                                                                                                                                  |

### 7.2 central / peripheral 配置边界（重要）

分体键盘两半的能力不对等，配置放错位置会直接导致构建失败或功能异常：

| 项目             | 左半 peripheral                                    | 右半 central                                                                      |
| -------------- | ------------------------------------------------ | ------------------------------------------------------------------------------- |
| 角色定义           | `config/HPD.conf`（共享，无 `ZMK_SPLIT_ROLE_CENTRAL`） | `Kconfig.defconfig` 中 `if SHIELD_HPD_RIGHT` → `CONFIG_ZMK_SPLIT_ROLE_CENTRAL=y` |
| DYA Studio RPC | ✗（仅通过 `SPLIT_RELAY_EVENT` 接收同步）                  | ✓                                                                               |
| 轨迹球 / 运行时输入处理器 | ✗                                                | ✓                                                                               |
| 编码器（EC11）      | ✓                                                | ✗                                                                               |
| 底灯 WS2812      | ✓（chain 1）                                       | ✓（chain 1）                                                                      |
| 电池代理 / 历史      | 仅 `BATTERY_REPORTING`                            | 额外含 `..._LEVEL_PROXY` / `..._FETCHING` / `BATTERY_HISTORY`                      |

### 7.3 Studio 连接相关

| 现象                                    | 处理                                                                                                                                                                                                                        |
| ------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Studio 无法打开串口 / WebSerial 打不开 CDC-ACM | ① 确认接的是**右半**；② 确认 `build.yaml` 中 `HPD_right` 的 `studio-rpc-usb-uart` snippet 与 studio cmake-args **仍在**（`1b1c113` 曾删除、`1239a1c` 已恢复，勿再删）；③ 该 snippet 是通过 `zephyr,udc0` 的 `zephyr,cdc-acm-uart` 节点实现的，与 WebSerial 的端口识别有关 |
| Studio 突然显示"已锁定"                      | 本仓库已设 `CONFIG_ZMK_STUDIO_LOCKING=n`，正常不会自动锁。若你改回 `y`，锁定后（默认 600s 无 RPC 或 BLE 断开即锁）**只能按键解锁**，而当前 keymap 未绑定 `&studio_unlock` —— 届时只能重新烧录                                                                                  |
| 左半在 Studio 里看不到                       | 预期行为。左半是 peripheral，只通过 `CONFIG_ZMK_SPLIT_RELAY_EVENT`（`DATA_LEN=240`）接收同步，不承载 RPC                                                                                                                                        |
| 保存的设置丢失                               | 设置存在 flash；`CONFIG_ZMK_SETTINGS_SAVE_DEBOUNCE=10000`（10 s 去抖）。烧录 `settings_reset` 目标可清空全部已存设置                                                                                                                             |

### 7.4 布局与按键相关

| 现象                      | 处理                                                                                                                                      |
| ----------------------- | --------------------------------------------------------------------------------------------------------------------------------------- |
| Studio 预览里拇指键位置不对       | `HPD.dtsi` 与 `config/HPD.json` 未同步。旋转键需在**两处**都写 `r` + `rx` + `ry`（提交 `2296e8f` 修复）                                                     |
| 某层在 Studio「传感器旋转」页签里看不到 | 该层的 `sensor-bindings` 未绑定 `&rsr_*`，或绑了 `&trans`。模块的 process hook 不运行时该层不可见                                                              |
| 某层编码器无反应且未被 Studio 接管   | `rsr_none` 本身就是"透明"，符合预期；给该层绑 `&rsr_vol` / `&rsr_scroll` 或在 Studio 里保存绑定                                                                |
| FUN 层从默认层进不去            | 默认层没有直达 `&mo 3` 的键，需先按 `&lt 2` 进 SYM 层再按 `&mo 3`                                                                                        |
| 底灯不亮                    | 确认 `CONFIG_ZMK_RGB_UNDERGLOW_ON_START=y`；确认是 SPI 版（`CONFIG_WS2812_STRIP_SPI`）而**不是**已被移除的 `CONFIG_WS2812_STRIP`；确认两侧 `chain-length` 与接线 |

### 7.5 电源与续航

| 项目     | 值                                                                                                                                |
| ------ | -------------------------------------------------------------------------------------------------------------------------------- |
| 自动休眠   | `CONFIG_ZMK_IDLE_SLEEP_TIMEOUT=900000`（**15 分钟**，两半一致）                                                                           |
| 电池读取   | `FETCH_MODE_STATE_OF_CHARGE`（按电量百分比而非电压）                                                                                         |
| 电池代理   | `CONFIG_ZMK_SPLIT_BLE_CENTRAL_BATTERY_LEVEL_PROXY` + `..._FETCHING`（**仅 central**，master 上曾放在共享 conf，`dya` 已移入 `HPD_right.conf`） |
| 发射功率   | +8 dBm（`CONFIG_BT_CTLR_TX_PWR_PLUS_8`）                                                                                           |
| BLE 参数 | `PREF_MAX_INT=9`、`PREF_LATENCY=16`、`ACL_TX_COUNT=8`、`EVT_RX_COUNT=10`、`L2CAP_TX_BUF_COUNT=32`                                    |
| 额外功耗项  | `CONFIG_ZMK_EXT_POWER=y`、底灯上电常亮（30%）、`CONFIG_ZMK_BLE_EXPERIMENTAL_CONN=y`                                                        |


> 底灯常亮与 BLE 实验性连接都会增加耗电。追求续航可在 `HPD.conf` 关掉 `UNDERGLOW_ON_START`。

### 7.6 升级 Zephyr / ZMK

`west-dependency.yml` 锁定的 `zephyr` revision（`v4.1.0+zmk-fixes+nrf-half-duplex-uart`）裁掉了大量 HAL 模块。升级 Zephyr 主线时若恢复这些模块，CI 构建时间会显著上升。升级前请先在本地跑通 `make init-standalone && make build-all`。

---

## 8. 仓库文件索引

```
.
├── Makefile                          # make init-standalone / init-workspace / build-all / debug-all
├── build.yaml                        # 三个编译目标（左半 / 右半 / settings_reset）
├── .gitignore                        # build/ dependencies/ .west/
├── keymap_drawer.config.yaml         # keymap-drawer 样式配置
├── .github/workflows/
│   ├── build.yml                     # ZMK 编译 + artifact + 可选 Release
│   └── keymap_drawer.yml             # keymap-drawer v0.23.0 自动重绘
├── keymap-drawer/
│   ├── HPD.svg                       # 自动生成的布局图
│   └── HPD.yaml                      # 自动生成的布局描述
└── config/
    ├── HPD.conf                      # 两半共享配置（BLE 调参、底灯、ext power）
    ├── HPD.keymap                    # 7 个图层 + 传感器绑定 + 输入处理器  ★核心
    ├── HPD.json                      # 结构化布局描述（含旋转原点、编码器定义）
    ├── west.yml                      # workspace manifest（import west-dependency）
    ├── west-dependency.yml           # DYA Studio 依赖，commit 级锁定  ★核心
    ├── west-standalone.yml           # standalone manifest（path-prefix: dependencies）
    └── boards/shields/HPD/
        ├── Kconfig.defconfig         # split / central 角色声明
        ├── Kconfig.shield
        ├── HPD.dtsi                  # physical_layout、matrix transform、kscan、EC11、PMW3610(disabled)  ★核心
        ├── HPD.zmk.yml               # shield 元数据 + features
        ├── HPD.conf                  # （空，共享配置在 config/HPD.conf）
        ├── HPD_left.overlay          # 左半：kscan GPIO、WS2812、encoder 启用
        ├── HPD_left.conf             # 左半 Kconfig（peripheral）
        ├── HPD_right.overlay         # 右半：kscan GPIO、WS2812、SPI1 轨迹球、input-listener
        └── HPD_right.conf            # 右半 Kconfig（central + 全部 DYA RPC）  ★核心
```

---

## 参考

- [ZMK 官方文档](https://zmk.dev/docs/)
- [DYA Studio 开发者指南](https://dya-studio-dev.cormoran707.workers.dev/developer-guide)
- [cormoran/zmk](https://github.com/cormoran/zmk) —— 本仓库依赖的 ZMK fork
- [cormoran/zmk-module-runtime-input-processor](https://github.com/cormoran/zmk-module-runtime-input-processor)
- [cormoran/zmk-behavior-runtime-sensor-rotate](https://github.com/cormoran/zmk-behavior-runtime-sensor-rotate)
- [cormoran/zmk-driver-pmw3610-with-custom-studio-rpc](https://github.com/cormoran/zmk-driver-pmw3610-with-custom-studio-rpc)
- [caksoylar/keymap-drawer](https://github.com/caksoylar/keymap-drawer)

## 许可

键位布局与 keymap 配置随本仓库分发；ZMK 及各 west 模块遵循其各自的上游许可证。
