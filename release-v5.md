# Lotus Arch — Release Notes

## v5.0 — Portable clone: works on any PC, any GPU, any monitors

The repo's core promise is now fully realized: **a clone of Lotus-Arch restores this machine perfectly, and it also installs cleanly on any other PC with different hardware, graphics card, and monitors.** No personal paths, hardware names, or monitor identities are baked in — everything machine-specific is an automatic, opt-in overlay.

### One clone, any machine

- **Any GPU.** The installer works on **NVIDIA / AMD / Intel**. You pick your card during install and Phase 3 installs exactly that stack (NVIDIA `open-dkms`, AMD `vulkan-radeon`, Intel stays integrated-only). The base desktop needs nothing card-specific.
- **`@HOME@` portability.** Configs use a `@HOME@` sentinel the installer rewrites to the real home directory at deploy time (legacy mirrors' `/home/lots` is also rewritten), so it works for any username.
- **Strictly sequential installer.** Phases now run in clean `0→12` order, filenames match phase numbers, and the yay build is hardened (temp dir, auto base-devel, cleanup) so re-runs are safe.
- **Non-owner README.** Docs describe the project for anyone installing it, not a single owner.

### Any monitors — no more hardcoded output names

The compositor configs no longer hardcode this machine's displays. Niri (`monitor.kdl`) and Hyprland (`monitors.lua`) ship **portable** — no output blocks — so niri/Hyprland auto-detect every display on any machine. The iNiR shell (`config.json`) ships with empty/inert monitor fields. Waybar's default workspace module uses portable `"*"` persistent workspaces.

The reference build's exact layout (DP-2 2560×1440@165 primary + HDMI-A-1 1920×1080 secondary, custom positions/scales, workspace pinning 1-5 / 6-10) lives in **optional `.lotus` overlays**:

- `dotfiles/niri/monitor.lotus.kdl`
- `dotfiles/hypr/monitors.lotus.lua`
- `dotfiles/inir/config.lotus.json` (wallpapersByMonitor, widget output overrides, cast output, primary monitor)

`06-dotfiles.sh` applies these **automatically, and only when both connectors are physically present** — detected via `/sys/class/drm`, compositor-independent, so it works even mid-install before any Wayland session. Restoring this machine is one automatic detection away; cloning to a different PC just works.

### Robustness

- **Idempotent mkinitcpio edit** — NVIDIA module injection rewrites the whole `MODULES=(...)` array instead of a greedy prepend, so re-runs can't duplicate/corrupt it.
- **Deterministic secret hygiene** — `scan-secrets.sh`, gitleaks across tree and history, no personal emails/MACs/paths shipped.

### Notes

- Requires [iNiR](https://github.com/snowarch/iNiR) upstream quickshell shell for the Niri session (Phase 12).
- Phase 10 performance tweaks / GPU OC remain **optional**; the OC values are tuned for an RTX 4070 (skip or edit if you have a different card).
