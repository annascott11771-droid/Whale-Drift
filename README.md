# Whale Drift

**A 2D endless underwater runner built with Godot 4.7.**

> This repository contains the **game code only**. Textures, audio and other art assets are intentionally not included. See [`godot/assets/ASSETS.md`](godot/assets/ASSETS.md) for the asset list required to build a playable copy.

## About

Whale Drift is a 2D endless underwater runner. Guide a whale through sunlit reefs, twilight canyons and abyssal trenches, slipping between tapered spikes, drifting urchins and fast currents. Collect pearls, bubble shields and current boosts. Six difficulties, gamepad support and a deliberately slow speed ramp. There is no jump button: only flow, timing and one deep breath. Built with Godot 4.7.2.

## Features

- Infinite side-scrolling dive with free vertical movement
- Tapered spike, gate, rock, jellyfish and urchin hitboxes
- Pearls, bubble shield, current boost, dash and checkpoints
- Six difficulties from Driftling to Trench Extinction
- Slow speed ramp, 60–240 FPS options, resolution and display settings
- Keyboard, mouse and standard gamepad support
- English by default; switch to Chinese in **Settings → LANGUAGE** or with **L**
- Local JSON save with automatic checkpoints

## Controls

### Keyboard / mouse

| Action | Input |
|---|---|
| Move up / down | W / S or ↑ / ↓ |
| Dash | SHIFT / SPACE |
| Pause | ESC / P |
| Mute | M |
| Fullscreen | F11 |
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

## Build

Requirements: **Godot 4.7.2** (standard build), the Windows x86_64 export template, and the asset files listed in [`godot/assets/ASSETS.md`](godot/assets/ASSETS.md).

1. Add the required textures and audio under `godot/assets/`.
2. Open `godot/project.godot` in Godot.
3. Use **Project → Export → Windows Desktop**.
4. Enable **Embed PCK** and export.

The game uses a 1280×720 content canvas and scales cleanly to other resolutions.

## Save data

Settings and progress are stored in:

```text
%APPDATA%\Godot\app_userdata\Whale Drift
```

Delete that folder to reset records, settings and checkpoints.

## Project layout

```text
godot/          Godot 4.7 project (Main.tscn, scripts, project files)
godot/assets/   Asset list only — no textures or audio included
README.md       English
README.zh-CN.md Chinese
SHORT_DESCRIPTION.md  Ready-to-use short descriptions
```

## Credits

Code and game design created for Whale Drift. Built with Godot 4.7.2.

## License

The source code is released under the MIT License. See [LICENSE](LICENSE).

The MIT license does **not** cover the original game textures, audio, logo or other art assets; those are not included in this repository.
