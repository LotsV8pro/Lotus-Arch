---
name: niri-animations
description: >
  Animaciones de niri: nombres validos, custom-shader, open_color/close_color,
  window-open/layer-open, iris en QML y rendimiento a 165 Hz. Usar antes de
  tocar config.d/60-animations.kdl, medir frames con wf-recorder o diagnosticar
  una animacion que va lenta o rompe la config.
---

# Animaciones de niri

## 4. Animaciones (verificado con `niri validate`)

### Nombres válidos
`window-open` · `window-close` · `window-movement` · `window-resize` ·
`workspace-switch` · `horizontal-view-movement` · `layer-open` · `layer-close` ·
`overview-open-close` · `recent-windows-close` · `config-notification-open-close` ·
`screenshot-ui-open`

### NO existen (rompen la config)
`window-destroy` · `recent-windows-open` · `layer-destroy` · `window-destroy-open`

### `custom-shader`: solo donde funciona
- ✅ `window-open`, `window-close`, `layer-open`, `layer-close`
- ❌ `overview-open-close`, `config-notification-open-close`, `screenshot-ui-open`
  (rechazan `custom-shader`; solo aceptan `duration-ms`/`curve`/`spring`)
- La función de entrada debe llamarse **`open_color`** / **`close_color`**.

### Qué anima qué
- Ventanas → `window-open` / `window-close`
- **Paneles de qs que crean superficie al abrirse (overview `Super+D`,
  portapapeles `Super+V`, cheatsheet, sesión, dashboard, panel de control,
  overlay, notificaciones de qs)** → `layer-open` / `layer-close`.
- **Sidebars (`Super+N`/`Super+P`)** → iris en QML (`MultiEffect`), ver abajo:
  su superficie nunca se desmapea.
- Overview nativo de niri (`Super+Tab`) → `overview-open-close` (sin shader)
- Animaciones internas de un panel de Quickshell (el contenido moviéndose dentro
  del panel) → **QML**, no niri.

Estado actual: iris desde la esquina superior izquierda (200 ms, `ease-out-quad`)
en ventanas y en todas las superficies layer.

### Rendimiento del shader (medido 2026-10-28, DP-2 165 Hz)

El iris **solo llega a 165 Hz si el shader es barato**. Medición con
`wf-recorder -g` + deltas de frames (`fps=165`, todo lo que no sea 6 ms es un
vblank perdido):

| Shader | Frames a 6 ms |
|---|---|
| versión "matemática pesada" (varias `length`, división y `smoothstep` por píxel) | **49 %** |
| versión optimizada (1 división + `sqrt(dot(d,d))` + `clamp`) | **94–100 %** |
| `window-open` sin `custom-shader` | 80 % |

Reglas para no volver a romperlo:
- Calcular el radio máximo **una vez** con `length(vec2(ar, 1.0)) * p`; no
  recalcular `length(vec2(size_geo.x/size_geo.y, 1.0))` por píxel.
- Borde suave con `clamp((m - dist) / 0.03, 0.0, 1.0)`, no con `smoothstep`
  anidado.
- Salir con `if (a <= 0.0) return vec4(0.0);` **antes** del `texture2D`.
- Copia buena: `/tmp/opencode/60-animations.final.kdl`.

### Sidebars: el iris va en QML, no en niri

`quickshell:sidebarLeft/Right` **no se desmapean** (solo se crea/destruye
`dualSidebarBackdrop`), así que `layer-open/close` nunca se ejecuta para ellas.
Desmapearlas a mano (`visible: presentationOpen`) hace que el panel desaparezca
de golpe en vez de animar. Por eso `SidebarHost.qml` monta su propio iris con
`MultiEffect` + máscara circular:

- `MultiEffect` (1 pase): **165 Hz** — 194 ms de animación, 100 % de frames a 6 ms.
- `Qt5Compat OpacityMask` (varios pases): **~88 Hz** con vblanks perdidos. No usar.
- La máscara necesita `layer.enabled: true` además de `visible: false`; sin eso
  su alfa llega vacía y el panel desaparece en un frame.
- `layer.effect` es un `QQmlComponent`: los efectos van dentro de `Component {}`.

### El resto de paneles de qs ya animan solos

Verificado con `niri msg layers` (comparando antes/después): `overview`,
`clipboardPanel`, `cheatsheet`, `session`, `dashboard`, `controlPanel`, `overlay`,
`equalizer`, `coverflowSelector` y `notificationPopup` **crean una superficie
nueva al abrirse** → niri les aplica `layer-open/close` sin tocar nada. La
ventana de ajustes es un toplevel → `window-open/close`.
