# Microfono y Easy Effects en este equipo

## Microfono
ROG Kithara por jack (3.5 mm) -> entrada "Rear Mic" del ALC897 (HDA Intel PCH).
El micro interno de la laptop NO es el que se usa.

Controles ALSA relevantes:
  Capture        : 0..63  (0 dB en 23, +30 dB en 63)
  Rear Mic Boost : 0..3   (0, +10, +20, +30 dB)

Estado fijo (lo escribe mic-radio-hardware.service al arrancar):
  Capture 29 (+4.50 dB), Rear Mic Boost 0, monitor 'Rear Mic' off,
  Auto-Mute Mode Disabled.

Por que Auto-Mute esta desactivado: al activarse, el ADC entrega silencio
digital en vez de ruido de fondo, y se pierde el principio de la frase.

Por que el hardware esta fijo: el slider movia el mixer de hardware y la
curva era inservible (0 dB -> +60 dB a saltos de 10 dB). Con
api.alsa.soft-mixer en la tarjeta, el slider es un atenuador de software
continuo y el control ALSA 'Capture' no se mueve.

Regla: ~/.config/wireplumber/wireplumber.conf.d/52-mic-soft-mixer.conf
  device.name = "~alsa_card.pci-0000_00_1f.3"  ->  api.alsa.soft-mixer = true
(Ojo: el selector debe ser device.name con el patron "~alsa_card.*"; con
api.alsa.card.name no se aplicaba.)

## Slider del microfono
El de la interfaz (inir) escribe wpctl set-volume sobre el nodo de captura.
Curva efectiva (PipeWire, escalado cubico): 0.25 = -36 dB, 0.5 = -18 dB,
0.75 = -7.5 dB, 1.0 = 0 dB.

Medido con voz fuerte, 100% = pico -18 dBFS, sin mesetas (sin recorte).
En una grabacion real: pista de micro a -19.8 LUFS, pico -0.95 dBFS.

## Easy Effects - cadena de ENTRADA (micro)
Fichero de preset: ~/.local/share/easyeffects/input/Radio Mic.json
Estado vivo:    ~/.config/easyeffects/db/

Orden: rnnoise -> filter -> expander -> deesser -> equalizer -> compressor -> limiter

  filtro    : paso alto 110 Hz x4 (el rumble 20-60 Hz estaba a solo -4 dB)
  expansor  : -60 dBFS, ratio 1.05, release 150 ms
  de-esser  : -28 dBFS, 5.5/7 kHz
  EQ        : 125 -3 | 350 -2 | 550 -1.5 | 950 +2.5 | 2000 +3.5 |
              3500 +2.5 | 6300 -1 | 9500 +1.5 dB
  compresor : umbral -20 dBFS, ratio 3, attack 12 ms, release 150 ms, makeup 20 dB
  limitador : -1.0 dBFS (red de seguridad)

El expansor va con ratio casi 1 a proposito: el software volume del slider se
aplica ANTES de la cadena de Easy Effects, asi que un expansor agresivo
recortaba la voz hasta el silencio digital en cuanto se bajaba el slider.
El ruido de fondo lo quita el RNNoise, que va antes.

OJO: las dos secciones del db son:
  [sie][...] = cadena de ENTRADA  (micro)   <- tocar aqui
  [soe][...] = cadena de SALIDA   (audio del PC)
El error que hice fue escribir la EQ del micro en [soe]; ahi no suena.

## Easy Effects - cadena de SALIDA (audio del PC)
Los tres plugins (EQ, compresor, limitador) estan en bypass=true, para que
los videos y la musica suenen planos, como estaban antes.
Preset de salida: "Kithara (Peace Win)" (su EQ tiene +7.5 dB @447 Hz y
+8.2 dB @4.6 kHz: es una curva para auriculares gaming, y enListening
altavoz suena estridente).

## Detalles de Easy Effects que costaron tiempo

### LA TRAMPA PRINCIPAL: el bypass global se queda activado
Si el bypass global esta activo, Easy Effects DESCONECTA los plugins de la
cadena de entrada: el micro pasa en crudo (pico ~-18 dBFS en vez de ~-1) y
en Discord se oye muy bajo. Es el sintoma clasico.

Causa: Easy Effects guarda el bypass en su fichero de configuracion y lo
reescribe al salir y cada cierto tiempo. Por eso, editar el db a mano
"mientras corre" no sirve: al reiniciar, Easy Effects devuelve el valor
antiguo desde memoria.

Ademas, el grupo [EffectsPipelines] del db NO se aplica: los valores
inputInactivityTimerEnable=false / inputInactivityTimeout=3600 se escriben
correctamente en el fichero (kreadconfig6 los lee bien) pero Easy Effects los
ignora y sigue usando el valor por defecto (temporizador activo, 10 s).
El grupo [StreamInputs] SI se aplica.

### COMO HABLAR CON LA INSTANCIA QUE YA CORRE (no usar la CLI)
La CLI (easyeffects -b 2, easyeffects --microphone-monitoring 3...) arranca
una SEGUNDA instancia completa de Easy Effects. Esa segunda instancia compite
por la fuente virtual "easyeffects_source" y deja la primera SIN cadena de
plugins (2 nodos). Ademas guarda su propia config al salir.

Usar el socket local:
    printf 'global_bypass:0\n'         | socat - UNIX-CONNECT:/run/user/1000/EasyEffectsServer
    printf 'microphone_monitoring:1\n' | socat - UNIX-CONNECT:/run/user/1000/EasyEffectsServer
    printf 'get_global_bypass\n'       | socat - UNIX-CONNECT:/run/user/1000/EasyEffectsServer
      -> "1" = bypass activo, "2" = desactivado
    printf 'get_microphone_monitoring\n' | socat - UNIX-CONNECT:/run/user/1000/EasyEffectsServer

Para leer/escribir propiedades de un plugin:
    printf 'get_property:input:compressor:0:makeup\n' | socat - UNIX-CONNECT:/run/user/1000/EasyEffectsServer

### COMO SE MANTIENE VIVA LA CADENA DE ENTRADA
El temporizador de inactividad (10 s) desconecta los filtros del micro si
ninguna app captura de easyeffects_source. Como el temporizador no se puede
desactivar por config, se usa la monitorizacion del micro CON VOLUMEN 0:

    [StreamInputs]
    listenToMic=true
    listenToMicVolume=0.0

Eso mantiene la cadena conectada (9 nodos) sin que suene nada por los
altavoces. Medido con correlacion micro/salida:
    listenToMicVolume=1.0  -> correlacion +0.31 a 203 ms  (realimentacion)
    listenToMicVolume=0.0  -> correlacion +0.03           (sin realimentacion)

### COMO SE EDITA EL db A MANO
1. Parar Easy Effects:  systemctl --user stop easyeffects-mic.service
2. Editar ~/.config/easyeffects/db/easyeffectsrc
3. Arrancar:            systemctl --user start easyeffects-mic.service
Si se edita con Easy Effects corriendo, al reiniciar se pierde el cambio.
(Para los .rc de plugins: [sie][...] = entrada, [soe][...] = salida, y cada
grupo en su propia linea: "[soe][Compressor#0]bypass=true" en una sola linea
es un grupo MAL FORMADO y se pierde.)

## Servicio
~/.config/systemd/user/easyeffects-mic.service
  - arranca Easy Effects en modo servicio
  - al arrancar, por el socket: bypass global OFF y monitorizacion ON
  - se habilita con: systemctl --user enable easyeffects-mic.service

~/.config/systemd/user/mic-ee-guard.timer
  - cada 30 s comprueba que Easy Effects corre, que el bypass esta OFF y
    que la cadena de entrada tiene 9 nodos; si algo falla, lo repara
  - se habilita con: systemctl --user enable --now mic-ee-guard.timer

## Herramientas de medicion (en ~/.local/bin)
  audio-beep              pitido (1000 Hz) para marcar cuando hablar
  mic-status              resumen del estado
  mic-test                prueba basica con pitidos
  mic-record-test         graba la frase de referencia, crudo y procesado
  mic-analyze <fichero>   espectro, dinamica, saturacion, LUFS
  mic-slider-curve        curva del slider
  mic-verify-slider       verificacion del slider con voz
  mic-sweep-fine          barrido fino del slider
  mic-voice-truth         nivel crudo real de la voz
  mic-transfer            funcion de transferencia de la cadena
  mic-out-compare         compara el audio del PC entre configuraciones
  mic-out-bypass-test     comprueba el bypass por plugin de la salida

## Nota sobre las capturas
Tras reiniciar PipeWire, el PRIMER stream de captura abre el PCM en un
estado mudo. Hay que descartarlo (script mic-radio-hardware ya lo hace).
Tambien: si el micro devuelve silencio digital de forma persistente,
reiniciar pipewire (no wireplumber) lo revive.

## "Voz robotica" - diagnostico y correccion (21/10)

Medido sobre ~/Videos/recording_2026-10-21_21.05.49.mp4 (pista de micro):
  pico -0.99 dBFS | rms -21.1 dBFS | crest 20.1 dB | suelo de ruido -86 dBFS
Espectro de la voz (1/3 octava, dB):
  80-125 +7.6 | 125-250 +25.9 | 250-500 +37.9 | 500-1k +42.7 |
  1-2k +41.2 | 2-4k +37.3 | 4-6k +19.3 | 6-8k +4.3 | 8-12k +2.3

Diagnostico: la presencia (250 Hz - 4 kHz) estaba PLANA (megafonia) y la
sibilancia (4-8 kHz) caia 23-38 dB -> la voz se oye "cubierta"/robotica.
El nivel NO era el problema (ya esta a -1 dBFS de pico).

Causas y correcciones aplicadas al preset "Radio Mic":
  de-esser  : umbral -28 -> -14 dBFS, ratio 4 -> 2.5
               (a -28 dBFS con ratio 4 se comia la banda de sibilantes)
  EQ 950     : +2.5 -> +1 dB   (rellenaba el hueco natural 700-1200)
  EQ 2000    : +3.5 -> +1 dB   (era el principal responsable de la megafonia)
  EQ 3500    : +2.5 -> +1 dB
  EQ 6300    : -1   -> +2 dB   (recuperar sibilancia)
  EQ 9500    : +1.5 -> +3.5 dB (mas aire, hi-shelf)
  EQ 125     : -3   -> -2 dB
  filtro HPF : 110 -> 95 Hz x4  (el fundamental de la voz esta en 110-119 Hz;
                                  a 110 Hz el HPF x4 le quitaba 3.5 dB)
  compresor  : umbral -20 -> -22, ratio 3 -> 2.2, knee -6 -> -8,
               boost automatico +6 -> 0 (era una segunda capa de compresion),
               makeup 20 -> 24 dB
  limitador  : igual (ALR = etapa de reduccion suavizada, no tocar)

Siguen en pie: RNNoise, expansor (-60/1.05), limitador -1 dBFS.

Ayudas para comparar:
  ~/.local/share/easyeffects/input/Radio Mic (sin RNNoise).json
        -> preset alternativo SIN el denoiser neuronal, para hacer un A/B en
           un clic desde la ventana de Easy Effects (el RNNoise es el otro
           sospechoso clsico de voz "metalica").
  ~/Videos/A_voz_actual.wav | B_voz_corregida.wav | C_voz_mas_aire.wav
        -> comparaciones de timbre con la frase grabada.

OTRO CULPABLE FUERA de Easy Effects: Discord/Chromium tiene activada la
cancelacion de eco (echoCancellation=true en su config). Con fuente virtual
 atenua el micro y mete artefactos. En Discord: Ajustes de voz y video ->
Entrada de audio -> Cancelacion de eco = DESACTIVADA.

## La curva de los cascos (salida) - por que se cuela sola

Los presets de SALIDA traian guardados bypass=false en la EQ y el limitador.
Al cargar cualquier preset de salida (a mano, o por el autoload de Easy
Effects cuando cambia el dispositivo de salida) se reactivaba la curva de
los cascos (+2 dB @1 kHz, +1.5 dB @6 kHz, -2 dB @100 Hz) sobre el audio del
PC, que es justo lo que el usuario no quiere: el PC tiene que sonar plano,
como antes de tocar Easy Effects.

Ademas, mi config previa (los 3 plugins de salida en bypass) estaba solo en
el estado en memoria y en el .db: cualquier carga de preset la borraba.

SOLUCION (definitiva): los bypass se guardan DENTRO de los presets de salida
  ~/.local/share/easyeffects/output/Kithara (Peace Win).json
  ~/.local/share/easyeffects/output/ROG Kithara.json
  ~/.local/share/easyeffects/output/Artics Nova 5.json
  -> equalizer#0, compressor#0 y limiter#0 con bypass=true
Los valores de la curva se conservan: si algun dia se quiere la curva de
cascos, se activa el plugin con su casilla en la ventana de Easy Effects.

Comprobado con multitono (100 Hz ... 8 kHz), directo al ALSA vs. por
Easy Effects: diferencias de +-0.24 dB en todo el espectro = transparente.

Ademas el vigilante (mic-ee-guard.timer) revisa cada 30 s que los tres
plugins de salida sigan en bypass y los vuelve a planar si alguien los
activa.

## Presets de audio (panel de iNiR) - 22/10

El panel de ecualizador de iNiR (modulo iiEqualizer) controla la EQ de
SALIDA de EasyEffects por el socket local:
  ~/.config/quickshell/inir/scripts/audio/easyeffects-eq.sh
  ~/.config/quickshell/inir/scripts/audio/eq-preset-store.sh  (almacen)
Comandos: get | bootstrap | set-band N GANANCIA | configure | preset NOMBRE |
           list-presets | save-preset NOMBRE | delete-preset NOMBRE

Como abrirlo: SUPER+SHIFT+U  (niri: config.d/70-binds.kdl)
             o "inir equalizer open" / "inir equalizer status"

### Lo que estaba mal
La EQ de salida tenia 10 bandas pero a 100/1000/6000 Hz (curva Kithara), no
en la rejilla que el panel asume (32/64/125/250/500/1000/2000/4000/8000/
16000). El boton "Configure 10 bands" del panel NO aparecia (ya habia 10
bandas), asi que los deslizadores movian frecuencias equivocadas.
Ademas el script del panel hace set bypass:false en la EQ cada vez que la
toca, lo que reactivaba la curva de cascos sobre el audio del PC.

### Como queda ahora
- La EQ de salida esta en la rejilla de 10 bandas del panel, PLANA por
  defecto: el audio del PC es transparente (+-0.04 dB medido con multitono
  de 1 a 8 kHz, ALSA directo vs. por Easy Effects).
- El compresor y el limitador de salida siguen en bypass.
- La EQ la controla el panel; el vigilante (mic-ee-guard.timer) ya NO la
  toca (se peleaba con el panel), solo mantiene el compresor y el limitador
  en bypass.

### Presets propios del usuario
Almacen: ~/.config/inir/eq-presets/<nombre>.json
   {"name": "Kithara", "gains": [0,0,-2,0,0,2,0,0,1.5,0]}   (10 ganancias)
En el panel:
   - el boton de "guardar" (icono de marcador, junto a "Presets") pide un
     nombre y guarda la curva actual
   - el boton de papelera borra el preset elegido (solo si es del usuario)
   - los presets del usuario aparecen junto a los de serie
   - el panel reconoce cual esta aplicado ("Flat", "Kithara", "Custom"...)
Desde la terminal:
   inir equalizer preset "Kithara"
   inir equalizer status
   ~/.config/quickshell/inir/scripts/audio/easyeffects-eq.sh save-preset "Mi curva"

## Sistema de presets (22/10) - por que "no cambia nada al darle clic"

El panel de ecualizador de iNiR (iiEqualizer) controla la EQ de SALIDA
(cascos), NO la del microfono. Una curva de +-2 dB en la salida tampoco se
oye apenas en un micro: por eso "no cambiaba nada".
Ademas la EQ de salida tenia las bandas a 100/1000/6000 Hz (no en la
rejilla de 10 del panel) y el boton "Configure 10 bands" no aparecia.

### Presets del MICROFONO (lo que afecta a tu voz)
  ~/.local/bin/ee-preset menu        <- menu rofi (Super+Shift+Z)
  ~/.local/bin/ee-preset list entrada
  ~/.local/bin/ee-preset load entrada "Radio Mic"
  ~/.local/bin/ee-preset save entrada "Mi voz"
  ~/.local/bin/ee-preset delete entrada "Mi voz"
  ~/.local/bin/ee-preset-save entrada "Mi voz"   (guarda el estado actual)

Easy Effects NO tiene comando para "guardar el estado actual", asi que
ee-preset-save lo arma leyendo:
  ~/.config/easyeffects/db/easyeffectsrc  (lista de plugins)
  ~/.config/easyeffects/db/*rc            (valores actuales, grupos [sie]/[soe])
  un preset existente                     (estructura y nombres de clave)

### TRAMPAS al escribir presets a mano (las perdi por el camino)
1. Los ENUMS se guardan como INDICE en el db (slope=3) y como ETIQUETA en el
   preset JSON ("x4"). Si copias el numero, Easy Effects aborta la carga con
   "type must be string, but is number" y NO aplica NADA.
2. Los valores fuera de rango se rechazan: el limitador admite release de 1
   a 20 ms (tengo 80 en un preset, avisaba en el log).
3. Al cargar un preset, Easy Effects cambia la LISTA de plugins a la del
   preset (plugins_order). Un preset con solo 3 plugins deja la cadena de
   entrada con 3.
4. load_preset NO devuelve nada cuando funciona (solo escribe si hay error):
   una respuesta vacia es un EXITO.

Comprobacion de que un preset carga bien (con Easy Effects en --debug):
  journalctl --user -u easyeffects-mic.service | grep -i preset
  -> "Successfully loaded the preset: ..." = correcto

## El panel de iNiR no actualizaba nada (22/10) - 4 bugs encadenados

1. El deslizador (EqualizerBandSlider.qml) copiaba el valor del estado a
   _localValue SOLO en Component.onCompleted. Al aplicar un preset, el
   Repeater REUTILIZA los delegates (el numero de bandas no cambia) y solo
   actualiza el rol modelData -> onCompleted no se vuelve a llamar y los
   deslizadores se quedaban en 0 mientras el boton si se marcaba.
   Arreglo: onModelDataChanged + un Binding que sincroniza _localValue.
   (Un Connections con target: root.modelData rompia el modulo entero:
   con target undefined da error y el panel no carga.)

2. El IpcHandler "equalizer" vivia dentro de ShellIiPanelsImpl, que se
   cargaba DIFERIDO (GlobalStates.deferredPanelsReady). Al empezar la
   sesion el target no existia -> "inir equalizer open" respondia
   "Target not found" y el atajo no hacia NADA.
   Arreglo: ShellIiPanels.qml y shell.qml cargan el arbol de paneles ii de
   forma residente (los paneles visuals siguen siendo OnDemand).

3. Mis ediciones con regex dejaron ShellIiPanelsImpl.qml con un error de
   sintaxis (las funciones del IpcHandler sin su IpcHandler). Quickshell lo
   avisa en el log:
     journalctl --user -u inir.service | grep -i "Syntax error"
   OJO: qmllint NO lo detecto.

4. easyeffects-eq.sh: el comando "preset" devolvia vacio al funcionar
   (solo escribe si hay error). Una respuesta vacia es un EXITO.

Y ADEMAS: el panel de iNiR controla la SALIDA (los cascos), no el microfono.
Para el microfono esta el menu de presets: ee-preset menu (Super+Shift+Z).


## 10/11/2026 - DAC/amp ASUS USB-C (0b05:1d6e) sustituye al jack de la placa

El micro y los auriculares pasan al dongle USB-C ASUS (Realtek), tarjeta
`alsa_card.usb-Realtek_USB-C_Audio_Adapter_A702251225000088-00` (card 0).
La cadena "Radio Mic" seguia siendo la misma, pero este dongle entrega el
micro MUCHO mas caliente.

Medido con voz normal, ANTES de corregir:
  crudo      : pico -3.3 dBFS  | RMS -35.1 dBFS
  procesado  : pico -1.0 dBFS  | RMS -19.6 dBFS  (cientos de muestras en el
               techo del limitador: sonaba a boost/compresion constante)
La referencia de diseno con el ALC897 era pico crudo ~-18 dBFS.

### Mixer de hardware del dongle (fijo)
  Mic       : 7/47   (-15.00 dB)   [antes 46 = -0.38 dB -> demasiado]
  Headphone : 142/169 (-11.63 dB)  [antes 169 = -1.50 dB -> atronaba]
  Sidetone  : off
  Extension Unit: off

Lo aplica `~/.local/bin/dac-asus-usb-hardware`, servicio
`dac-asus-usb-hardware.service` (oneshot) + `.path` (reconexion USB).
Busca la tarjeta por USB ID 0b05:1d6e, no por indice.

### Slider = software (no puede volver a saturar)
`~/.config/wireplumber/wireplumber.conf.d/53-usb-dac-soft-mixer.conf`
  device.name = "~alsa_card.usb-Realtek_USB-C_Audio_Adapter"
  api.alsa.soft-mixer = true
Con esto el mixer de hardware queda fijo y el slider de PipeWire es un
atenuador de software. Maximo del slider = -15 dB en el micro y -11.6 dB
en la salida. Para mas nivel, subir MIC_VOL / HP_VOL del script.

### Autoload de la cadena de ENTRADA
`~/.local/share/easyeffects/autoload/input/alsa_input.usb-Realtek_USB-C_Audio_Adapter_A702251225000088-00.analog-stereo:.json`
  preset-name = "Radio Mic"
Sin esto Easy Effects usaba el fallback "Current" (solo EQ+limiter) al
conectar el dongle.

### Medido DESPUES
  crudo      : pico -25.3 dBFS | RMS -49.3 dBFS  (-14.2 dB respecto a antes)
  procesado  : pico -1.8 dBFS  | RMS -26.4 dBFS  (1 muestra en el techo)
El procesado quedo ~7 dB mas bajo y sin limitacion constante.

### Cuidado con SignalRgb (bug aparte)
SignalRgb (RGB, /opt/signalrgb) tenia abierto `pcmC1D2c` (entrada digital
del ALC897) y con eso WirePlumber NO exponia la tarjeta de la placa
(desaparecia de `pactl list cards`). Ademas gastaba 22 % de CPU. Con
SignalRgb parado la tarjeta vuelve sola. Si se quiere RGB, desactivar en
SignalRgb cualquier modulo de audio/captura.

### Backup de esta intervencion
/tmp/opencode/audio-backup-20261110-0759/

## Cadena "Voz pro - doblaje" (10/11/2026)

Medicion de la voz cruda (16 s, Mic 40/47 = -2.63 dB, card ASUS USB-C):
  pico -20.8 dBFS | RMS voz -49.3 | ruido -81.9 | SNR 32.7 dB | F0 138 Hz
  1/3 octava rel. 1 kHz:
    50 +16.4 | 100 +9.7 | 250 +6.2 | 400 +8.7 | 500 +6.8
    1k 0 | 2k -3.9 (hueco) | 4k -5.3 | 5k -15.8 | 8k -25.6 (micro oscuro)

Preset ~/.local/share/easyeffects/input/Voz pro - doblaje.json
Orden: filter -> deesser -> equalizer -> compressor -> limiter (5 etapas)
  filtro    : paso alto 90 Hz x2
  de-esser  : -22 dBFS, ratio 2.5, 5.5/6.5 kHz
  EQ        : 80 -2 | 160 -1.5 | 320 -2.5 | 500 -4 | 800 -1 |
              1250 0 | 2000 +4 | 3150 +3 | 5000 +3.5 | 9000 +3.5 (hi-shelf)
  compresor : umbral -26, ratio 2.5, attack 15 ms, release 120 ms, makeup 19
  limitador : -1 dBFS (ALR)

Medido despues (misma frase): -16.4 LUFS integrados, LRA 6.5 LU,
pico -0.8 dBFS, limiter solo en 0.04 % de las muestras.
Comparado con el crudo, el grave baja ~9 dB en 50 Hz y la presencia
1.6k-5k sube ~16-22 dB respecto al nivel global.

Muestras para escuchar (misma toma, 24-bit):
  ~/Videos/voz_pro_crudo.wav            (crudo, -32.8 LUFS)
  ~/Videos/voz_pro_procesado.wav        (cadena, -16.4 LUFS)
  ~/Videos/voz_pro_crudo_igualado.wav   (crudo +15.8 dB, para A/B justo)

Autoload del micro USB -> "Voz pro - doblaje".
Presets alternativos: "USB Mic natural" (sin EQ), "USB Mic RNNoise" y
"USB Mic RNNoise + cuerpo", "Radio Mic" (el viejo).
