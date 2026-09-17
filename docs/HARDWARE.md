# Hardware & Performance (optional)

Lotus Arch runs on **any** hardware out of the box. The base desktop — Hyprland
and/or Niri + iNiR, EasyEffects audio, the whole palette engine — works on any
GPU (NVIDIA / AMD / Intel), any CPU, and any monitors. Everything in this doc is
**optional tuning**, shipped so anyone can reproduce the developer's setup.

## Reference build (the machine this repo is tuned on)

| Component | Spec |
|---|---|
| CPU | Intel (pstate, `performance` governor) |
| GPU | NVIDIA GeForce **RTX 4070** (AD104, 12 GB GDDR6X) |
| Notes | Driver package: `nvidia-open-dkms`; Xorg `Coolbits=28` for OC + fan control |

The exact overclock values below are **written for an RTX 4070**. On any other
card you should **skip** the power-limit / clock-lock tweaks (Phase 10 asks about
each one individually) or edit the numbers first. The non-OC tweaks (fan curve,
CPU governor, sysctl, NVMe read-ahead) are safe on any hardware.

## GPU tuning — what it actually applies (NVIDIA, RTX 4070)

Applied at boot by `performance-tweaks/nvidia/gpu-tweaks.sh` (via `gpu-tweaks.service`):

| Setting | Value | Meaning |
|---|---|---|
| Power limit | `216 W` | `nvidia-smi -pl 216` — the card's own power max |
| Memory clock lock | `12001 MHz` | `nvidia-smi -lmc 12001` (over the 10501 stock) |
| Graphics clock lock | `3255 MHz` | `nvidia-smi -lgc 3255` (the VF-curve ceiling) |

`performance-tweaks/nvidia/gpu-fan-curve.sh` (via `gpu-fan-curve.service`) then:

- Applies a **+150 MHz** core offset on all performance levels (`nvidia-settings`).
- Sets **Prefer Maximum Performance** mode (`GPUPowerMizerMode=1`).
- Enables a **dynamic fan curve** 30→100 % by temperature step (45 °C and below
  stays at 30 %, hitting 100 % past 80 °C), keeping the card under ~65 °C.

Requires `Coolbits=28` in `performance-tweaks/nvidia/10-nvidia.conf`.

> Watching the values on the dev's own machine right now: 216 W limit,
> memory 10501/12001 MHz, graphics 2985→3255 MHz — matching the two scripts.

## AMD profile

`performance-tweaks/amd/` ships the mirrored approach for AMD cards:

- `50-amdgpu.conf` — modprobe tuning (optional `ppfeaturemask` for CoreCtrl OC).
- `gpu-tweaks.sh` — forces the highest **DPM performance level** + a 3D-workload
  profile via `sysfs`.
- `gpu-fan-curve.sh` + service — hwmon temperature fan curve like the NVIDIA one.

## CPU / common tweaks (both profiles)

| Tweak | Files |
|---|---|
| CPU `performance` governor + 50 % min perf (pstate) | `performance-tweaks/common/cpu-tweaks.sh` + `performance-governor.service` |
| sysctl (swappiness=5, lower dirty ratios, autogroup off, NUMA off) | `performance-tweaks/common/99-performance.conf` |
| NVMe read-ahead 512 KB | `performance-tweaks/common/grub-cmdline.sh` (GRUB) + udev rule |
| GRUB C-state limits | `performance-tweaks/common/cpu-tweaks.sh` |

## Graphics card selection during install

During install you pick your graphics card (or it is auto-detected via
`lspci`). That choice:

1. Gates **which GPU driver packages** Phase 3 installs
   (NVIDIA `nvidia-open-dkms` + settings / AMD `vulkan-radeon` / Intel).
2. Defaults the **Phase 10** hardware profile (NVIDIA vs AMD).

Every tweak in Phase 10 is a separate `[Y/n]` prompt — decline any you don't
want. See [INSTALLATION.md → Phase 10](INSTALLATION.md#performance-tweaks-phase-10).

## Starter wallpapers (optional)

The repo ships a small stock collection — **3 wallpapers per color of the
filter** (the same 11 named color families the iNiR wallpaper selector uses:
Red, Orange, Yellow, Green, Cyan, Blue, Violet, Pink, Brown, Black, White) plus
a dracula/violet dark set and the default `Default/2b2.jpg`. Installing it is a
**separate optional prompt**; declining leaves your `~/Pictures/wallpapers`
**exactly as-is** — your current wallpaper is never touched.

## Repo layout

```
performance-tweaks/        Phase 10 (opt-in) — common/ + nvidia/ or amd/
optional/                  Phase 11 — GPU tuning pack, movie-tui
wallpapers/                Stock wallpaper packs (3 per color) + Default/
```

Related: [INSTALLATION.md](INSTALLATION.md) · [SETUP.md](SETUP.md)