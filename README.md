# Whale Drift

**A 2D endless underwater runner built with Godot 4.7.**

> This repository contains the **game source code and tests only**. Textures, audio, fonts and the logo are intentionally not included. See [`godot/assets/ASSETS.md`](godot/assets/ASSETS.md) for the asset list required to build a playable copy.

## About

Whale Drift is a 2D endless underwater runner. Guide a whale through sunlit reefs, twilight canyons and abyssal trenches, slipping between tapered spikes, drifting urchins and fast currents. Collect pearls, bubble shields and current boosts. Six difficulties, gamepad support and a deliberately slow speed ramp. There is no jump button: only flow, timing and one deep breath. Built with Godot 4.7.2.

## Features

- Infinite side-scrolling dive with free vertical movement
- Tapered spike and gate polygons, small ellipse hitboxes for rocks, jellies and urchins
- Pearls, stackable bubble shields, current boost, dash (fully invulnerable) and checkpoints
- **6-point health bar drawn as 3 hearts**; a clean hit costs half a heart, and hearts render in quarter steps so the bar always matches the value
- **Bubble stacking**: each bubble soaks half of one hit and is used up; up to 6 layers, with a visible aura
- **Talent shop with pearl economy** (see below): permanent upgrades for shield time, dash range and pearl magnet
- Six difficulties from Driftling to Trench Extinction
- Slow speed ramp, 30–240 FPS options, resolution and display settings
- FPS counter reads the engine measurement, and vsync only turns off when your cap is below the panel refresh rate
- Keyboard, mouse, standard gamepad, and touch controls
- Android build support: fullscreen, immersive, ETC2/ASTC, back-button and app-switch handling
- Tablet friendly layout: the design canvas is 1280×720 and expands instead of letterboxing, and content stays centred
- English and Chinese UI, switchable in **Settings → LANGUAGE** or with **L**
- Local JSON save with automatic checkpoints

## Controls

### Health and bubbles

The bar holds **6 points** and is drawn as **3 hearts** (2 points each).
Each heart renders in quarter steps (full / 3⁄4 / half / 1⁄4 / empty).

- A clean hit costs **1 point** = **half a heart**
- A bubble **soaks half of one hit** and is used up
- Collect another bubble while one is active to **add a layer**
- Up to **6 layers**; they orbit the whale and show as `BUBBLES ×N` in the HUD
- Layers expire after the shield duration and refresh when you pick one up

### Talent shop and economy

`GlobalData.gd` is an autoload singleton that owns the wallet, the three talent
levels and the save file (`user://save_data.cfg` via `ConfigFile`).

| Talent | Effect | Prices |
|---|---|---|
| Shield time | 3.0 s → 5.0 s | 50 / 120 / 250 / 500 |
| Dash range | 100 → 180 | 60 / 140 / 280 / 560 |
| Pearl magnet | 0 → 200 px | 80 / 180 / 360 / 720 |

Payout per run:

```text
depth   = floor(distance / 100)
pickups = min(collected, 12)
score   = 0, or 1 + floor((score - 100000) / 50000) when score >= 100000 (max 10)
total   = min(depth + pickups + score, 50)
```

A typical 1200 m run pays about 24 pearls, so the first upgrade needs 2–3 runs.

`ShopUI.tscn` draws the panel and handles mouse **and** touch (mouse emulation is
disabled globally). Insufficient pearls flash the row red; maxed rows turn grey
and show **MAX**.

### Keyboard / mouse

| Action | Input |
|---|---|
| Move up / down | W / S or ↑ / ↓ |
| Dash | SHIFT / SPACE |
| Pause | ESC / P |
| Mute | M |
| Fullscreen | F11 |
| Language | L |
| Menus | Mouse |

### Gamepad

| Action | Input |
|---|---|
| Move / menu | Left stick or D-pad |
| Change setting | Left stick / D-pad ← → |
| Dash | A / X / RB / RT |
| Confirm | A |
| Back | B |
| Pause / resume | START |

### Touch

| Action | Input |
|---|---|
| Move | Drag anywhere in the play area |
| Dash | Round DASH button, bottom-right |
| Pause | Button, bottom-left |
| Menus / settings | Tap (tapping the right side of a settings row cycles the value) |

On mobile the **Display mode** and **Resolution** rows are hidden because the OS owns the window; everything else is available.

## Build

Requirements: **Godot 4.7.2**, the Windows x86_64 export template, and the assets listed in [`godot/assets/ASSETS.md`](godot/assets/ASSETS.md).

1. Add the required textures, audio and fonts under `godot/assets/`.
2. Open `godot/project.godot` in Godot.
3. Use **Project → Export → Windows Desktop**, enable **Embed PCK**, and export.

For Android, install the Android build template and the Android SDK, then export from the Android preset. The project is already set to landscape, immersive mode and ETC2/ASTC textures.

## Tests

The project ships three self-checking scenes; run any of them with Godot:

```bash
godot --path godot --rendering-driver opengl3 res://TouchTest.tscn
godot --path godot --rendering-driver opengl3 res://DesktopTest.tscn
godot --path godot --rendering-driver opengl3 res://ShopTest.tscn
godot --path godot --rendering-driver opengl3 res://Bench.tscn
```

- `TouchTest` opens a 4:3 window, injects real `InputEventScreenTouch` events and checks the menu, settings, language row, drag-to-swim, on-screen buttons, restart reset, dash invulnerability, the health model and collision responses.
- `DesktopTest` checks window modes, resolution changes, FPS caps, the mouse click path and settings rows.
- `ShopTest` checks the economy formula, price ladder, talent getters, buy/deny/max flows, save round-trip, the shop tap path, magnet pull, quarter-heart textures and the run payout.
- `Bench` reports average, p95 and worst frame times.

## Save data

Desktop settings and progress are stored in:

```text
%APPDATA%\Godot\app_userdata\Whale Drift
```

Delete that folder to reset records, settings and checkpoints. On Android, use the app's system data clearing option.

## Project layout

```text
godot/          Godot 4.7 project (Main.tscn, scripts, tests, project files)
godot/assets/   Asset list only — no textures, audio or fonts included
README.md       English
README.zh-CN.md Chinese
SHORT_DESCRIPTION.md  Ready-to-use short descriptions
```

## Credits

Code and game design created for Whale Drift. Built with Godot 4.7.2. UI font in release builds: Noto Sans SC (SIL Open Font License).

## License

The source code is released under the MIT License. See [LICENSE](LICENSE).

The MIT license does **not** cover the original game textures, audio, logo or UI font; those are not included in this repository.
