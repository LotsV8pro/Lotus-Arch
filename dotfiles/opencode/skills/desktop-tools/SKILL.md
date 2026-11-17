---
name: desktop-tools
description: >
  Herramientas del escritorio: waybar, swaync, awww, capturas con grim/slurp,
  portapapeles cliphist, bloqueo, fuzzel/rofi, pipewire y EasyEffects, fcitx5,
  temas de iNiR. Usar al configurar o depurar alguna de esas piezas.
---

# Resto del escritorio

## 6. Resto del escritorio

| Función | Herramienta / ruta |
|---|---|
| Barra | **waybar** → `~/.config/waybar/` (variantes: `full`, `left`, `minimal`, `neon`, `coredge`, `module`) |
| Notificaciones | **swaync** → `~/.config/swaync/{config.json,style.css}` (`swaync-client -swb`) |
| Fondo | **awww** (fork de swww), daemon `awww-daemon` en marcha; `swww` sigue instalado como comando |
| Captura / OCR / grabación | `inir region …` sobre **grim**, **slurp**, **wf-recorder** |
| Portapapeles | `cliphist` + `wl-clipboard`, watchers en `~/.config/quickshell/inir/scripts/` |
| Bloqueo | `inir lock activate` (swaylock/hyprlock instalados) |
| Lanzadores | **fuzzel**, `rofi` |
| Audio | **pipewire + wireplumber + EasyEffects** (`ee-preset`, `easyeffects-mic.service`, `virtual-mic.service`) |
| Entrada | **fcitx5** (layout `us`) |
| Portales | `xdg-desktop-portal-gnome` / `-gtk` |
| Juegos | `steam`, `gamescope`, `mangohud`, `gamemoderun`, `vkBasalt` |
| Color/tema | sistema propio de iNiR: `inir theme list-targets` / `inspect` / `apply <target>` · scripts en `~/.config/quickshell/inir/scripts/colors/` (wallust/matugen **no** están instalados) |
