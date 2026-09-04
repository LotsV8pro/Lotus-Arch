# Audio (EasyEffects)

Lotus Arch ships a **system-wide audio stack** built on PipeWire + WirePlumber with **EasyEffects** providing the master EQ / effects chain. It works with any sound card or headset — no vendor-specific pipeline required.

## Stack

| Layer | Role |
|---|---|
| **PipeWire** | Audio server (session + real-time processing) |
| **WirePlumber** | Device/routing policy (suspension timeouts, device priorities) |
| **EasyEffects** | Input + output effects chains (EQ, compressor, limiter, noise suppression) |
| **OBS virtual mic/sink** *(optional streaming)* | Desktop audio capture + processed mic loopback for OBS |

## Systemd services

| Service | Function |
|---|---|
| `easyeffects.service` | EasyEffects in service mode (mic + output processing) |
| `virtual-mic.service` | Permanent loopback from the OBS virtual sink to a virtual mic source |

`easyeffects.service` only ships when the OBS streaming pack is selected in the installer.

## EasyEffects

- Master input/output EQ & effects chain, live-switchable in the EasyEffects GUI.
- Headless service mode (`easyeffects.service`) runs the chain without a window.
- Presets live in `~/.config/easyeffects/db/`, with autoload presets under `~/.local/share/easyeffects/`.
- The repo ships generic presets configured against the **system default** input/output devices, so they apply to whatever hardware you have — adjust the device in EasyEffects to match your own microphone/speakers.

## OBS Virtual Microphone *(optional streaming)*

The `virtual-mic` script creates a permanent `pw-loopback` from the OBS virtual sink to the OBS virtual source, so audio played through the virtual sink (including VST-processed mic from OBS) appears as a system microphone — useful for **discord calls with OBS voice processing**. This is part of the optional OBS streaming pack, not a required audio feature.
