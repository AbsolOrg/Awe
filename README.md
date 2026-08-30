# Awe

- Awe is a curated collection of standalone, interactive Material 3 desktop widgets built with [Quickshell](https://quickshell.outfoxxed.me/) for Linux and Wayland compositors.

- Each widget is an independent QML component that can be moved, scaled, customized, and toggled across your desktop with persistent configuration.

<img width="1361" height="761" alt="all" src="https://github.com/user-attachments/assets/0337ce98-14df-4df8-b627-9ef1f8767197" />

---

## Features

- **Material 3 Expressive Design**: Tonal elevation palettes, organic shapes, and responsive interaction states.
- **Wayland Native**: Optimized for `WlrLayershell` with precise input region masking for wallpaper click-through.
- **Independent Dragging & Scaling**: Every widget can be repositioned via mouse drag and resized using the mouse scroll wheel.
- **State Persistence**: Positions, scale factors, custom notes, timezones, habits, and visibility states automatically save to `~/.config/quickshell/widget_settings.json`.
- **Top Dynamic Notch / Widget Manager**: Floating top bar to toggle visibility for individual widgets in real time with smooth scrolling.

---

## Widget Suite Overview

### Core & Productivity
- **NotesWidget (`NotesWidget.qml`)**: Google Keep-style note pad with instant inline text editing, debounced auto-saving, multi-note navigation, and Material 3 color themes.
- **TodoWidget (`TodoWidget.qml`)**: Interactive task checklist with completion tracking and progress indicator.
- **HabitsWidget (`HabitsWidget.qml`)**: 7-day habit streak tracker with interactive daily check matrix and habit creation prompt.
- **CalcWidget (`CalcWidget.qml`)**: Minimalist floating calculator with expression evaluation, live results, and Material 3 keypad.
- **ClipboardWidget (`ClipboardWidget.qml`)**: Real-time clipboard history monitor using `wl-paste` with one-click copying (`wl-copy`).
- **TimerWidget (`TimerWidget.qml`)**: Pomodoro focus timer, break countdown, stopwatch, and custom duration stepper adjustments (`+1m`, `-1m`, `+5m`).

### Media & Visuals
- **VisualizerWidget (`VisualizerWidget.qml`)**: Live desktop audio spectrum with 3 interactive modes: 16-Bar Spectrum Equalizer, Fluid Sine Waveform, and Radial Soundwave.
- **MediaWidget (`MediaWidget.qml`)**: MPRIS media player featuring an Android 14/15 squiggly waveform seekbar, animated soundwave equalizer bars, playback controls, and active player indicator.
- **PosterWidget (`PosterWidget.qml`)**: Organic Material 3 photo frame (Arch, Scallop, Squircle, Pebble, Heart, Flower, Stadium) with animated GIF playback support and right-click native file picker.
- **QuoteWidget (`QuoteWidget.qml`)**: Rotating daily inspiration card with author tags and refresh shuffle.

### System & Telemetry
- **ResourceWheelWidget (`ResourceWheelWidget.qml`)**: 4 concentric circular progress arcs displaying real-time CPU, RAM, Disk, and Temperature telemetry.
- **StorageMapWidget (`StorageMapWidget.qml`)**: Segmented disk storage visualizer showing Root partition usage, free space, and disk capacity.
- **ThermalWidget (`ThermalWidget.qml`)**: Hardware temperature monitor showing CPU package and core temperatures with thermal status indicators.
- **SystemInfo (`SystemInfo.qml`)**: Clean overview of CPU load, memory utilization, and storage capacity.
- **BatteryWidget (`BatteryWidget.qml`)**: Battery charge level, AC adapter status, and power metrics.
- **VolumeBrightnessWidget (`VolumeBrightnessWidget.qml`)**: PipeWire (`wpctl`) volume pill slider with mute toggle and display backlight (`brightnessctl`) slider.

### Network, Developer & Clocks
- **PingWidget (`PingWidget.qml`)**: Live network latency monitor pinging Cloudflare (1.1.1.1), Google DNS, and GitHub with real-time jitter graph.
- **NetworkWidget (`NetworkWidget.qml`)**: Live Wi-Fi SSID, bandwidth upload/download meters, activity sparklines, and double-click IP address privacy mask.
- **CryptoWidget (`CryptoWidget.qml`)**: Live market prices for Bitcoin (BTC), Ethereum (ETH), and Solana (SOL) with 24h change pills and trend sparklines.
- **GitDashboardWidget (`GitDashboardWidget.qml`)**: Repository workspace monitor showing active branch, uncommitted diff counter, and last commit summary.
- **WorldClockWidget (`WorldClockWidget.qml`)**: Multi-city timezone hub with solar day/night indicators, double-click UI shape cycling (4 layouts), and custom UTC offset addition.
- **Clock (`Clock.qml`)**: Versatile desktop clock supporting Cookie, Nothing OS, Android stacked, and digital typographic styles.
- **CalendarWidget (`CalendarWidget.qml`)**: Interactive monthly calendar with date selection grid.

---

## Installation & Requirements

### Dependencies
Ensure the following packages are installed on your Linux system:

- **Quickshell** (0.3.0 or newer)
- **Qt 6 Declarative / Quick / Effects** (`qt6-declarative`, `qt6-quicktimeline`)
- **Python 3** with `PyGObject` (`python-gobject`, GTK 3.0)
- **playerctl** (for MPRIS media control)
- **brightnessctl** (for backlight control)
- **pipewire / wireplumber** (`wpctl` for audio)
- **wl-clipboard** (`wl-paste` and `wl-copy` for clipboard history)
- **lm_sensors** (for hardware thermals)
- **curl** (for crypto and weather updates)
- **iputils** (for network ping latency)

### Launching

Clone this repository into your Quickshell configuration directory:

```bash
git clone https://github.com/AbsolOrg/Awe.git ~/.config/quickshell/Awe
```

Launch the shell:

```bash
quickshell -p ~/.config/quickshell/Awe
```

---

## Configuration

Widget positions and scale factors are stored automatically in:

```
~/.config/quickshell/widget_settings.json
```

To reset all widgets to their default layout, delete or edit this file.

---

## License

This project is licensed under the MIT License.
