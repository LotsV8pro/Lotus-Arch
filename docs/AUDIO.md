# Audio Pipeline

Lotus Arch includes a complete **streaming/gaming audio pipeline** designed around the SteelSeries Arctis Nova 5 headset and OBS Studio.

## Audio Devices

| Device | Type | Purpose |
|---|---|---|
| **Arctis_Game** | Sink | Game audio (routed automatically to OBS) |
| **Arctis_Chat** | Sink | Chat/voice audio |
| **Arctis_Media** | Sink | Browser/media audio (routed automatically to OBS) |
| **Aux** | Sink | Extra channel via own HeSuVi 7.1 surround sink |
| **OBS Virtual Sink** | Sink | Desktop audio capture for OBS |
| **OBS Virtual Mic** | Source | Microphone from OBS (VST-processed) back to system |
| **EasyEffects sink** | Sink | Master EQ / effects output (auto-bridged to the headset) |

## Systemd Services

| Service | Function |
|---|---|
| `virtual-mic.service` | Permanent loopback from OBS virtual sink to virtual mic |
| `auto-link-obs.service` | Auto-connects Arctis_Game + Arctis_Media monitor outputs to OBS virtual sink |
| `auto-link-ee.service` | Auto-bridges EasyEffects master output to the physical Arctis PCM |
| `easyeffects.service` | EasyEffects in service mode (mic processing for the OBS virtual mic) |
| `arctis-manager.service` | Arctis Sound Manager daemon (Sonar EQ, spatial audio) |
| `arctis-gui.service` | Arctis system tray for quick switching |
| `arctis-video-router.service` | Routes browser/media apps to Arctis_Media automatically |

## Sonar EQ Profiles

Filter-chain profiles under `~/.config/pipewire/filter-chain.conf.d/`:

| Profile | Target |
|---|---|
| `sonar-game-eq.conf` | Arctis_Game sink |
| `sonar-chat-eq.conf` | Arctis_Chat sink |
| `sonar-media-eq.conf` | Arctis_Media sink |
| `sonar-aux-eq.conf` | Aux channel EQ |
| `sonar-micro-eq.conf` | Microphone EQ (feeds EasyEffects) |
| `sonar-output-eq.conf` | Master output EQ (18-band "Arctis Output") |
| `sink-virtual-surround-7.1-hesuvi.conf` | HeSuVi binaural surround (HRIR convolution) |
| `sink-virtual-surround-7.1-hesuvi-aux.conf` | HeSuVi binaural surround for the Aux channel |
| `sink-virtual-surround-7.1-hesuvi-media.conf` | HeSuVi binaural surround for media |

## OBS Virtual Microphone

The `virtual-mic` script creates a permanent `pw-loopback` from the OBS virtual sink to the OBS virtual source, so any audio played through the virtual sink (including VST-processed mic from OBS) appears as a system microphone. This enables **discord calls with OBS voice processing**.

Mic processing itself runs through **EasyEffects** (`easyeffects.service`): the chain is deepfilternet → rnnoise → speex → 8-band EQ → compressor → limiter, taking its input from `effect_output.sonar-micro-eq` and routing to the OBS virtual sink. Its preset can be switched live in the EasyEffects GUI.
