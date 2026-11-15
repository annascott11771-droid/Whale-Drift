# Asset list

This repository contains **code only**. The original textures, audio, fonts
and logo are not included. Add the files below under `godot/assets/` to build
a playable copy.

## Textures

The loader accepts `.png` for these names, or `.webp` if no `.png` exists:

```text
ocean_bg
layer_far
layer_mid
canyon_top
canyon_bottom
vignette
glow_warm
glow_pearl
bubble_small
pearl
power_shield
power_boost
urchin
icon_heart
icon_dash
icon_save
```

Animation frames (PNG):

```text
whale_0.png ... whale_5.png
jelly_0.png ... jelly_3.png
rock_0.png ... rock_2.png
coral_0.png ... coral_2.png
spike_0.png ... spike_2.png
fish_0.png ... fish_2.png
```

Optional application icons:

```text
icon.png
icon.ico
```

## Audio

```text
ambient.ogg
sfx_collect.wav
sfx_dash.wav
sfx_gameover.wav
sfx_hit.wav
sfx_power.wav
sfx_save.wav
sfx_ui.wav
```

## Fonts (required for Chinese UI)

The game falls back to a system font when these are missing, which on Linux
and Android may not contain CJK glyphs. Add a Noto Sans SC subset as:

```text
fonts/NotoSansSC-Regular.otf
fonts/NotoSansSC-Bold.otf
```

Noto Sans SC is licensed under the SIL Open Font License; ship `OFL.txt` with it.

## Notes

- Keep the original filenames and folder layout.
- Textures and audio are not covered by the repository's MIT license.
- The playable release build contains the assets; this source repository does not.
