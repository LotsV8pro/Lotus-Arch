# Structure

A high-level view of the config tree — every entry maps to a `dotfiles/<name>/` folder deployed to `~/.config/<name>/`:

```
.config/
├── hypr/                  # Hyprland session (Lua) — entry + configs + UserConfigs + scripts
├── niri/                  # Niri session (KDL) — config.kdl + config.d/ modules
├── inir/                  # iNiR shell user config (AI models, prefs)
├── quickshell/            # iNiR Quickshell shell + overview plugin
├── pipewire/              # Generic pipewire tuning (10-quality.conf)
├── easyeffects/           # EasyEffects EQ/denoise chain
├── wireplumber/           # Device suspend + routing priority rules
├── systemd/user/          # Audio & session services (virtual-mic, easyeffects, inir…)
├── lotus-palette/         # Preset engine + palette tools
└── spicetify/Themes/Lotus/# Spotify Lotus theme
optional/                  # Opt-in extras (Phase 11) — GPU tuning pack, movie-tui, GT Racing wallpapers
performance-tweaks/        # Phase 10 — common/ + nvidia/ or amd/ hardware profiles
.local/                    # User bins (virtual-mic, steam-gamescope, shader limiter) + EasyEffects presets
```

> The Phase 10 `performance-tweaks/` layout and its RTX 4070-tuned OC values are described under [INSTALLATION.md → Performance Tweaks](INSTALLATION.md#performance-tweaks-phase-10).
