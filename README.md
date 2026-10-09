# zmk-config-hpd

[简体中文](README.md) | [English](README_EN.md)

---

HPD 分体人体工学键盘的 [ZMK](https://zmk.dev/) 固件配置仓库，默认分支为 **`dya`**。

该分支在标准 ZMK 之上接入 **DYA Studio**（cormoran 维护的 ZMK Studio 增强分支），把键位、宏、组合键、轨迹球参数、编码器行为、电池历史等配置从「改代码 + 重新编译烧录」迁移到「浏览器里直接改、即时生效并持久化」。

---

## 目录

- [1. 项目简介与硬件配置](#1-项目简介与硬件配置)
- [2. 键盘布局与按键说明](#2-键盘布局与按键说明)
- [3. 固件特性](#3-固件特性)
- [4. 编译与烧录](#4-编译与烧录)
- [5. 配置自定义](#5-配置自定义)
- [6. 仓库文件索引](#6-仓库文件索引)

---

## 1. 项目简介与硬件配置

### 1.1 键盘型号

**HPD** —— 6 列 × 5 行 + 拇指区 + 底部附加键的**分体人体工学键盘**，左右各一半（`requires: [pro_micro]`）。总计 **61 个按键位**（矩阵 12 列 × 6 行 = 72 个位置，其中 61 个布键）。

| 项目 | 说明 |
| --- | --- |
| 型号 | HPD（Shield 名即 `HPD`，子 shield `HPD_left` / `HPD_right`） |
| 架构 | 分体键盘（`CONFIG_ZMK_SPLIT=y`） |
| 左半（peripheral） | 按键矩阵、EC11 旋转编码器、WS2812 底灯 |
| 右半（central） | 按键矩阵、PMW3610 轨迹球、WS2812 底灯、USB/BLE 主机连接、DYA Studio RPC |
| 矩阵规模 | 每半 6 行 × 6 列；`default_transform` 为 12 列 × 6 行，右半通过 `col-offset = <6>` 偏移到 6–11 列 |
| 供电 | `CONFIG_ZMK_EXT_POWER=y`（外接电源） |

### 1.2 主控与固件方案

| 项目 | 值 |
| --- | --- |
| MCU | **nice!nano v2**（nRF52840） |
| 板名写法 | `nice_nano//zmk`（ZMK 官方板名 + ZMK 板级 revision 选择器） |
| 固件基线 | `cormoran/zmk`，revision `e5c9b69`（main + dya），**非** upstream ZMK |
| Zephyr | `7c6b4cc`（v4.1.0 + zmk-fixes + nrf-half-duplex-uart） |
| 无线连接 | BLE 5，`CONFIG_BT_CTLR_TX_PWR_PLUS_8=y`（发射功率 +8 dBm） |

> ⚠️ 该分支**不能**用 upstream `zmkfirmware/zmk` 编译。`west-dependency.yml` 中所有 remote 均指向 `https://github.com/cormoran`，并锁定到具体 commit hash。升级时手动 bump。

---

## 2. 键盘布局与按键说明

### 2.1 布局图

以下图形由 `keymap-drawer/HPD.svg` 按层拆分而来，随 `config/HPD.keymap` 自动重新生成。

**默认层（QWRT）**

![QWRT 默认层](keymap-drawer/layers/QWRT.svg)

**NUM / SYM / FUN 层**

| NUM | SYM | FUN |
| --- | --- | --- |
| ![NUM 数字层](keymap-drawer/layers/NUM.svg) | ![SYM 符号层](keymap-drawer/layers/SYM.svg) | ![FUN 功能层](keymap-drawer/layers/FUN.svg) |

**MOUSE 层**（SCROLL 与 SNIPE 层整层透传，只有轨迹球处理链不同，故不单列图示）

![MOUSE 鼠标层](keymap-drawer/layers/MOUSE.svg)

完整图（含全部 7 层）：[`keymap-drawer/HPD.svg`](keymap-drawer/HPD.svg)

### 2.2 图层与进入方式

| 索引 | 标签 | 名称 | 进入方式 | 编码器 |
| --- | --- | --- | --- | --- |
| 0 | `QWRT` | 默认层 | — | 音量 |
| 1 | `NUM` | 数字 / 方向键层 | 按住 R4-0 | 滚动 |
| 2 | `SYM` | 符号层 | 按住 R4-11 | — |
| 3 | `FUN` | 功能 / RGB 层 | 从 SYM 层按 R4-11 | — |
| 4 | `MOUSE` | 鼠标按键层 | 按住 R4-10 | — |
| 5 | `SCROLL` | 轨迹球慢速 / 滚动层 | 按住 R4-1 | — |
| 6 | `SNIPE` | 轨迹球降速层 | 按住 R4-5 | — |

> 默认层没有直达 FUN（3）的键，必须先按 R4-11 进 SYM 层，再按同一位置的 `&mo 3`。

### 2.3 默认层（QWRT）键位

每个图层均为 **61 个 binding**（5 行 × 12 列 + 1 个底部附加键）。下表按矩阵行列展开，行内**先左半（列 0–5）、后右半（列 6–11）**。

| 行 | 左半（列 0–5） | 右半（列 6–11） |
| --- | --- | --- |
| **R0** | `ESC` `1` `2` `3` `4` `5` | `6` `7` `8` `9` `0` `BACKSPACE` |
| **R1** | `TAB` `Q` `W` `E` `R` `T` | `Y` `U` `I` `O` `P` `\` <sup>`\|`</sup> |
| **R2** | `CAPS` `A` `S` `D` `F` `G` | `H` `J` `K` `L` `;` `'` <sup>`"`</sup> |
| **R3** | `LSHIFT` `Z` `X` `C` `V` `B` | `N` `M` `,` `.` `/` `RSHIFT` |
| **R4** | `NUM` `SCROLL` `CTRL` `ALT` `GUI` `SNIPE` | `BACKSPACE` `DELETE` `[` `]` `MOUSE` `SYM` |
| **R5** | 附加键 `MUTE`（列 0） | — |

- **底部附加键**：`&kp K_MUTE` 是矩阵中唯一的第 6 行键位，位于左半最内侧。
- **keymap 与 `HPD.json` 的 label 不一致属正常**：`HPD.json` 的 `label` 描述**键帽丝印**，而 keymap 是实际功能。**改键位以 `HPD.keymap` 为准**，改物理布局才动 `HPD.json`。

### 2.4 各层要点

以下均按矩阵行列（列 0–11）给出实际 binding。

**NUM（1）** —— 仅 14 个有效键，其余透传

| 位置 | 按键 |
| --- | --- |
| R0 列 1–10 | `1` `2` `3` `4` `5` `6` `7` `8` `9` `0` |
| R2 列 1–4 | `←` `↓` `↑` `→` |

**SYM（2）** —— 蓝牙选择 + 符号

| 位置 | 按键 |
| --- | --- |
| R0 列 1–10 | `!` `@` `#` `$` `%` `^` `&` `*` `(` `)` |
| R2 列 1–4 | `BT_CLR` `BT_SEL 0` `BT_SEL 1` `BT_SEL 2` |
| R2 列 6–9 | `-` `=` `[` `]` |
| R3 列 6–7 | `_` `+` |
| R4 列 11 | `&mo 3` → 进入 FUN 层 |

**FUN（3）** —— RGB 控制 + F 键

| 位置 | 按键 |
| --- | --- |
| R0 列 0–8 | `RGB_TOG` `RGB_BRI` `RGB_BRD` `RGB_EFF` `RGB_EFR` `RGB_SAD` `RGB_SAI` `RGB_HUD` `RGB_HUI` |
| R1 列 1–4 | `F1` `F2` `F3` `F4` |
| R2 列 1–4 | `F5` `F6` `F7` `F8` |
| R3 列 1–4 | `F9` `F10` `F11` `F12` |

**MOUSE（4）**

| 位置 | 按键 |
| --- | --- |
| R2 列 1–4 | `←` `↓` `↑` `→` |
| R4 列 6 | `&mkp MCLK`（**鼠标中键**） |
| R4 列 10 | `&mkp LCLK`（**鼠标左键**） |
| R4 列 11 | `&mkp RCLK`（**鼠标右键**） |

> ZMK 命名以鼠标侧为准：`LCLK` = 鼠标左键、`RCLK` = 鼠标右键、`MCLK` = 鼠标中键。

**SCROLL（5）/ SNIPE（6）**：整层 61 键全为 `&trans`，不含任何普通键位，仅改变轨迹球输入处理链（见 [3.3](#33-轨迹球与编码器)）。

---

## 3. 固件特性

### 3.1 DYA Studio 功能模块

`dya` 分支的核心。以下模块均位于 **右半（central）** 的 `HPD_right.conf`；左半通过 `CONFIG_ZMK_SPLIT_RELAY_EVENT` + `CONFIG_ZMK_CUSTOM_SETTINGS_SPLIT_RPC_RELAY` 接收同步。

| Studio 页签 | 功能 | 对应 west 模块 |
| --- | --- | --- |
| 连接 Connection | 蓝牙设备管理、OS 检测、默认图层切换 | `zmk-module-ble-management`、`zmk-feature-os-detection`、`zmk-feature-default-layer` |
| 设置 Settings | 键位级持久化设置 | `zmk-module-settings-rpc`、`zmk-feature-custom-settings` |
| 键位 Keymap | 布局预览、运行时宏、运行时组合键 | `zmk-feature-module-physical-layout`、`zmk-feature-runtime-macro`、`zmk-feature-runtime-combo` |
| 轨迹球 Trackball | CPI、轴缩放/旋转/反转、inertia、轴吸附、temp-layer | `zmk-module-runtime-input-processor`、`zmk-driver-pmw3610-with-custom-studio-rpc` |
| 传感器旋转 Sensor rotation | 逐层设置编码器 CW/CCW 行为 | `zmk-behavior-runtime-sensor-rotate` |
| 诊断 Diagnostics | 设备信息、硬件看门狗 | `zmk-feature-device-info`、`zmk-feature-watchdog` |
| 电池历史 | 电池曲线记录 | `zmk-module-battery-history` |

其中「键位」「设置」「轨迹球」「传感器旋转」「电池历史」页签的改动**不需要重新编译固件**，保存即生效并持久化。

### 3.2 显示与主题

> **本仓库没有显示屏。** 全部配置中不存在 `CONFIG_ZMK_DISPLAY` / SSD1306 / OLED 相关项，也未引入显示模块。

**"主题"对应 RGB 底灯**：

| 配置项 | 值 | 说明 |
| --- | --- | --- |
| `CONFIG_ZMK_RGB_UNDERGLOW` | `y` | 启用底灯 |
| `CONFIG_ZMK_RGB_UNDERGLOW_ON_START` | `y` | 上电即亮 |
| `CONFIG_ZMK_RGB_UNDERGLOW_SAT_START` | `0` | 启动饱和度 0（全白） |
| `CONFIG_ZMK_RGB_UNDERGLOW_BRT_START` | `30` | 启动亮度 30% |
| 驱动 | `CONFIG_WS2812_STRIP_SPI` + `CONFIG_LED_STRIP` | WS2812 走 SPI3（MOSI = P0.11），每半 `chain-length = 1` |

底灯颜色/亮度/效果速度可在 **FUN 层**实时调节：`RGB_TOG`（开关）、`RGB_BRI`/`RGB_BRD`（亮度±）、`RGB_EFF`（切换效果）、`RGB_EFR`（效果速度±）、`RGB_SAD`/`RGB_SAI`（饱和度±）、`RGB_HUD`/`RGB_HUI`（色相±）。

### 3.3 轨迹球与编码器

**硬件**

| 项目 | 值 |
| --- | --- |
| 传感器 | PMW3610，devicetree compatible `cormoran,pmw3610` |
| 位置 | **仅右半（central）**，`HPD.dtsi` 中默认 `disabled`，由 `HPD_right.overlay` 打开 |
| 总线 | SPI1 @ 2 MHz，CS = P0.22（低有效），IRQ = P0.20 |
| 方向映射 | `SWAP_XY` + `INVERT_X` + `INVERT_Y` |
| CPI | **400**（`&trackball { cpi = <400>; }`） |

**编码器**：`alps,ec11`，位于**左半**，`steps = <20>`，`triggers-per-rotation = <10>`，`A`=P0.29、`B`=P0.31。

**输入处理链**（`HPD_right.overlay` 的 `trackball_listener`）

| 生效层 | 处理链 |
| --- | --- |
| 默认（全部层） | `&mouse_runtime_input_processor &scroll_runtime_input_processor` |
| 第 5 层 `SCROLL` | `&zip_xy_scaler 1 2 &scroll_runtime_input_processor`（XY 降为 1/2 速率 + 转滚动） |
| 第 6 层 `SNIPE` | `&zip_xy_scaler 1 2 &mouse_runtime_input_processor`（XY 降为 1/2 速率） |

- `mouse_runtime_input_processor`：`temp-layer-enabled`、`temp-layer = <4>`（MOUSE 层）、激活延迟 `0 ms`、失活延迟 `700 ms`——移动轨迹球自动切到 MOUSE 层，按键或超时后自动回默认层。
- `scroll_runtime_input_processor`：`active-layers = <BIT(5)>`、`xy-to-scroll-enabled`、`axis-snap-threshold = <100>`。

**Runtime Sensor Rotate（逐层编码器绑定）**

通过自定义 RPC 子系统 `cormoran_rsr`，可在 Studio 的「传感器旋转」页签**按层**重设编码器 CW/CCW 行为，配置持久化。当前 keymap 中定义了三个实例：

| 实例 | 用于 | 行为 |
| --- | --- | --- |
| `rsr_vol` | 默认层 | 音量上/下 |
| `rsr_scroll` | NUM 层 | 滚动，`tap-ms` 100 |
| `rsr_none` | 其余各层 | 透传（无默认行为） |

> 每个图层都必须绑定一个 `&rsr_*` 实例。若某层未绑定或绑了 `&trans`，该层在 Studio 中**不可见**。

---

## 4. 编译与烧录

### 4.1 三个编译目标

`build.yaml`：

| 目标 | 板 / shield | 产物 |
| --- | --- | --- |
| 左半 | `nice_nano//zmk` + `HPD_left` | `nice_nano__zmk_HPD_left.uf2` |
| 右半 | `nice_nano//zmk` + `HPD_right` | `nice_nano__zmk_HPD_right.uf2` |
| 复位 | `nice_nano//zmk` + `settings_reset` | 用于清除已保存的 Studio 设置 |

右半目标带 `snippet: studio-rpc-usb-uart`，用于把 Studio RPC 挂到 USB CDC-ACM 串口。

### 4.2 方式 A：GitHub Actions（推荐）

`.github/workflows/build.yml` 在 push 到 `master` / `dya`、PR 或手动触发时运行，产物上传为 workflow artifact `hpd`。

手动触发并出 Release：**Actions → Build ZMK firmware → Run workflow → 填入 `release`（如 `v0.1.0`）**。

### 4.3 方式 B：本地 west 构建

前置：`west`、`cmake`、`ninja`、`arm-none-eabi-gcc`（Zephyr SDK）。

```bash
# 依赖装在仓库内 ./dependencies（CI 用的方式，推荐）
make init-standalone
make build-all

# 或：依赖装在上一级目录（标准 west workspace）
make init-workspace
make build-all
```

调试构建（启用 `zmk-usb-logging`，会牺牲一部分体积换日志）：

```bash
make debug-all      # 等价于 west zmk-build -S zmk-usb-logging
```

编译完成后固件位于：

```
build/nice_nano__zmk_HPD_left/zephyr/zmk.uf2
build/nice_nano__zmk_HPD_right/zephyr/zmk.uf2
```

### 4.4 烧录到键盘

本仓库**不提供** `west flash` 目标，采用 UF2 直刷：

1. nice!nano v2 进入 bootloader：按住 **RESET**，松开后立即双击任意一侧的键（或按住 RESET 同时插拔 USB）。
2. 出现可移动盘 `NICE_NANO`。
3. 把对应的 `zmk.uf2` **拖进该盘符**，等待指示灯熄灭。
4. 复位拔线，键盘启动（底灯会以 30% 亮度白色常亮）。

**左半 / 右半不要烧错。** 首次配对时**只上电右半**，先在 Studio 里完成配置，再给左半上电。

### 4.5 使用 DYA Studio 配置

1. 浏览器打开 DYA Studio。
2. **只连接右半**——把 nice!nano 的 USB 线接到**右半**。
3. Studio 通过 WebSerial 打开 CDC-ACM 端口后，即可看到本固件暴露的各页签。
4. 改动即时写入非易失存储，重启后保留；左半通过 split relay 同步。

---

## 5. 配置自定义

### 5.1 修改 keymap（改键位）

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

### 5.2 修改 behavior / 宏

**静态 behavior**（需编译）：

- 标准 ZMK behavior：改 `config/HPD.keymap`，必要时 `#include <behaviors/...>`。
- 自定义 behavior：在 `/ { behaviors { ... }; };` 中定义（该节点当前为空）。
- Runtime sensor rotate 实例：`rsr_vol` / `rsr_scroll` / `rsr_none`，属性 `tap-ms`、`cw-binding`、`ccw-binding`。

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

### 5.3 修改底灯主题

**固件默认值**（`config/HPD.conf`）：

```conf
CONFIG_ZMK_RGB_UNDERGLOW_ON_START=y
CONFIG_ZMK_RGB_UNDERGLOW_SAT_START=0
CONFIG_ZMK_RGB_UNDERGLOW_BRT_START=30
```

**按键实时调节**：FUN 层顶排 9 个 `&rgb_ug` 绑定（见 [2.4](#24-各层要点)）。

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

### 5.4 修改传感器参数

**静态**（`config/HPD.keymap` + `HPD_right.conf`）：

```dts
&trackball { cpi = <400>; };                  /* keymap */
&mmv { time-to-max-speed-ms = <500>; acceleration-exponent = <1>; trigger-period-ms = <16>; };
&msc { acceleration-exponent = <1>; time-to-max-speed-ms = <100>; delay-ms = <0>; };
```

**运行时**（免编译）：Studio「轨迹球」页签可改 CPI、轴缩放/旋转/反转、inertia、轴吸附、temp-layer 等。运行时设置会覆盖静态值。

### 5.5 布局可视化

`.github/workflows/keymap_drawer.yml` 使用 `caksoylar/keymap-drawer@v0.23.0`，在 `config/**` 变化时自动重绘，产物：

- `keymap-drawer/HPD.svg` —— 全部 7 层
- `keymap-drawer/HPD.yaml` —— 布局描述
- `keymap-drawer/layers/*.svg` —— 按层拆分的单图（本 README 2.1 节所用）

样式由 `keymap_drawer.config.yaml` 控制。

`config/HPD.json` 是布局的**结构化描述**（键位标签、行列、坐标、旋转 `r`/`rx`/`ry`，以及 `left_encoder` 传感器定义），供 keymap-drawer 与 Studio 布局预览共用——**改了 `HPD.dtsi` 里的旋转键务必同步这里**，否则预览与实物不一致。

### 5.6 升级 DYA Studio 模块

`config/west-dependency.yml` 中所有 revision 均为具体 commit hash。升级时：

1. 编辑对应 `revision:` 为目标 commit。
2. `west update --narrow`。
3. `make build-all` 验证（左半右半一起编译）。

---

## 6. 仓库文件索引

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
│   ├── HPD.svg                       # 全7 层布局图
│   ├── HPD.yaml                      # 布局描述
│   └── layers/*.svg                  # 按层拆分的单图（README 2.1 节使用）
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