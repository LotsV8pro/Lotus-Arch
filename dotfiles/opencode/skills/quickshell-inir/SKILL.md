---
name: quickshell-inir
description: >
  Quickshell/iNiR: shell colgado, reiniciar inir.service sin tocar niri, inir
  doctor y logs, recarga de QML, CLI de inir. Usar cuando el escritorio se
  quede colgado o haya que depurar el shell, waybar no aplica aqui.
---

# Quickshell / iNiR

## 4-bis. Reiniciar el shell SIN tocar niri (verificado 2026-10-28)

Esto es lo que hay que hacer cuando el shell (Quickshell/iNiR) se queda colgado:

```bash
systemctl --user restart inir.service      # forma correcta
# o:  inir restart
```

**Verificado en vivo**: `systemctl --user restart inir.service` deja el mismo
PID de niri (`MainPID` 44891 antes y después). Niri **no se reinicia**, la sesión
no se cierra y no se pierde nada.

Lo que **rompe la sesión** y hay que prohibir:

```bash
pkill niri && niri &     # ← esto es lo que hizo el modelo el 28-10 a las 11:17 y 11:20
killall niri
niri msg action quit
```

Eso manda SIGTERM al compositor, mata TODAS las ventanas y cierra la sesión.
En el journal se ve como `niri[...]: quitting due to receiving signal SIGTERM`.

En el menú de sesión (`Super+Shift+Q`) **"Log Out"** cierra la sesión entera
(`Session.logout()` → `NiriService.quit()`). No es un "reiniciar shell".

Si lo que quieres es recargar la config de niri: **solo guarda el archivo**,
niri recarga solo. No hay `niri msg reload-config`.

## 5. Quickshell / iNiR (el shell del escritorio)

- Servicio: `inir.service` (systemd **--user**) → `~/.local/bin/inir run --session`
- Config QML: `~/.config/quickshell/inir/` (hay otros shells sin usar: `lotus-shell`,
  `end4-pC`, `Persona-Quickshell`, `modules`, `services`)
- CLI: `inir run|settings|status|doctor|update|repair|logs|overview|clipboard|lock|region|session|cheatsheet|theme|terminal|browser|colorpicker`
- Si el shell falla: `inir doctor`, luego `inir logs`. Nunca lo arranques a mano en
  paralelo con el servicio (duplica instancias).
- Tras cambiar QML: `qs` recarga solo si el servicio está vivo; si no, `systemctl --user restart inir.service`.
