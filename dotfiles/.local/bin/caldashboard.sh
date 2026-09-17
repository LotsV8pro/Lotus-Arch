#!/usr/bin/env bash
# Dashboard de calendario (sin quickshell): calendario, agenda, notas, todo,
# crear evento en Google. Estética sincronizada con el theme (rofi-style.rasi).

[ -f "$HOME/hakuspace-control/main_setting.sh" ] && source "$HOME/hakuspace-control/main_setting.sh"

CW="$HOME/.local/bin/calwidget.py"
GCAL="$HOME/.config/inir-birthdays/sync-calendars.py"

rasis() {
    cat <<EOF
@import "$HOME/.config/rofi/vertical.rasi"
window { width: 600px; location: center; }
listview { columns: 1; lines: 10; spacing: 3px; }
element { padding: 8px 16px; border-radius: 12px; }
EOF
}

grid_rasi() {
    cat <<EOF
@import "$HOME/.config/rofi/vertical.rasi"
window { width: 540px; location: center; }
listview { columns: 7; orientation: horizontal; lines: 6; spacing: 2px; padding: 6px; }
element { padding: 8px 0px; border-radius: 10px; }
element selected {
    background-color: @accent;
}
EOF
}

# ---------- Calendario mensual ----------
calendar_view() {
    local y="${1:-$(date +%Y)}" m="${2:-$(date +%-m)}" sel rc
    while true; do
        local yp yf mp mf
        if [ "$m" -eq 1 ]; then yp=$((y-1)); mp=12; else yp=$y; mp=$((m-1)); fi
        if [ "$m" -eq 12 ]; then yf=$((y+1)); mf=1; else yf=$y; mf=$((m+1)); fi

        local cells
        cells=$("$CW" grid "$y-$(printf '%02d' "$m")")
        sel=$(printf '%s\n' "$cells" | rofi -dmenu -format i -i \
            -p "$(date -d "$y-$m-01" '+%B %Y')" \
            -theme-str "$(grid_rasi)" \
            -kb-custom-1 "Ctrl+Right" \
            -kb-custom-2 "Ctrl+Left" \
            -kb-custom-3 "Ctrl+Home" \
            -mesg "Ctrl+→: $(date -d "$yp-$mp-01" +%B)   Ctrl+←: $(date -d "$yf-$mf-01" +%B)   Ctrl+Inicio: hoy   *=evento +=hoy")
        rc=$?

        # kb-custom-1 = mes siguiente, kb-custom-2 = previo, kb-custom-3 = hoy
        case "$sel" in
            10001) y=$yf; m=$mf; continue ;;
            10002) y=$yp; m=$mp; continue ;;
            10003) y=$(date +%Y); m=$(date +%-m); continue ;;
        esac
        [ $rc -ne 0 ] && return 0
        [ -z "$sel" ] && continue

        # índice → día. Cell 0..6 = weekday names
        local daynum offset dim maxday
        offset=$(( $(date -d "$y-$m-01" +%u) - 1 ))
        dim=$(cal "$m" "$y" | awk 'NF{s=$NF} END{print s}')
        daynum=$(( sel - 7 - offset + 1 ))
        if [ "$daynum" -lt 1 ] || [ "$daynum" -gt "$dim" ]; then
            continue
        fi
        local daystr
        daystr=$(printf '%04d-%02d-%02d' "$y" "$m" "$daynum")
        local ev n
        ev=$("$CW" day "$daystr")
        n=$(echo "$ev" | python3 -c 'import json,sys; print(len(json.load(sys.stdin)))' 2>/dev/null)
        if [ "${n:-0}" = "0" ]; then
            notify-send "Calendario" "Sin eventos el $daystr" 2>/dev/null
            continue
        fi
        echo "$ev" | python3 -c "
import json,sys
for e in json.load(sys.stdin):
    print(f'{e[\"date\"]}  {e[\"title\"]}')
" | rofi -dmenu -p "$daystr · eventos" -mesg "ESC: volver al mes" \
            -theme-str "$(rasis)"
    done
}

# ---------- Agenda ----------
agenda_view() {
    local txt n
    txt=$("$CW" agenda-text 21)
    n=$(echo -n "$txt" | wc -l)
    [ -z "$txt" ] && { notify-send "Agenda" "Sin eventos próximos" 2>/dev/null; return 0; }
    echo -e "$txt" | rofi -dmenu -p "Agenda · próximos 21 días ($n)" \
        -theme-str "$(rasis)"
}

# ---------- Todo ----------
todo_quick() {
    local pick n
    while true; do
        local opts=()
        "$CW" todo | python3 -c "
import json,sys
for i,it in enumerate(json.load(sys.stdin)):
    mark='[x]' if it['done'] else '[ ]'
    print(f'{i} {mark} {it[\"content\"]}')
" > /tmp/todo_o.txt
        [ -z "$(cat /tmp/todo_o.txt)" ] && { notify-send "To-Do" "Lista vacía" 2>/dev/null; return 0; }
        pick=$(rofi -dmenu -p "To-Do (elige para cambiar)" -theme-str "$(rasis)" < /tmp/todo_o.txt)
        local rc=$?
        [ $rc -ne 0 ] && break
        n=$(echo "$pick" | awk '{print $1}')
        "$CW" todo-toggle "$n" >/dev/null
    done
}

# ---------- Notas ----------
notes_view() {
    local edited cur
    cur=$("$CW" notes)
    edited=$(echo "${cur:-- }" | rofi -dmenu -p "Notas (Enter guarda)" \
        -theme-str "$(rasis)")
    [ -z "$edited" ] && return 0
    "$CW" notes-set "$edited" >/dev/null
    notify-send "Notas" "Guardado" 2>/dev/null
}

# ---------- Nuevo evento ----------
new_event() {
    local title date date_full res
    title=$(rofi -dmenu -p "Título del evento" -theme-str "$(rasis)")
    [ -z "$title" ] && return 0
    date=$(rofi -dmenu -p "Fecha YYYY-MM-DD (Enter = hoy, 09:00)" -theme-str "$(rasis)")
    if [ -z "$date" ]; then
        date_full="$(date +%Y-%m-%d)T09:00:00"
    else
        date_full="${date}T09:00:00"
    fi
    local payload
    payload=$(python3 -c "import json,sys; print(json.dumps({'summary': sys.argv[1], 'dateTime': sys.argv[2], 'category': 'default'}))" "$title" "$date_full")
    res=$(python3 $HOME/.config/inir-birthdays/gcal-op.py create "$payload" 2>&1)
    if echo "$res" | grep -q '"ok": true'; then
        notify-send "Google Calendar" "Creado: $title ($date_full)" 2>/dev/null
    else
        notify-send "Google Calendar" "Error (¿re-autentica?): $(echo "$res" | tail -c 120)" 2>/dev/null
    fi
}

# ---------- Sync ----------
do_sync() {
    notify-send "Google Sync" "Sincronizando calendarios..." 2>/dev/null
    if python3 "$GCAL" 2>/tmp/gsync.err; then
        notify-send "Google Sync" "Listo" 2>/dev/null
    else
        notify-send "Google Sync" "Error: $(tail -c 100 /tmp/gsync.err)" 2>/dev/null
    fi
}

# ---------- Principal ----------
main() {
    local sel rc
    while true; do
        sel=$(printf '%s\n' \
            "📅  Calendario" \
            "📌  Agenda · próximos" \
            "✔  To-Do" \
            "📝  Notas" \
            "➕  Nuevo evento en Google" \
            "🔁  Sincronizar con Google" \
            "🚪  Salir" | rofi -dmenu -p "Dashboard" -theme-str "$(rasis)" \
                -mesg "theme sync · datos de Google Calendar")
        rc=$?
        [ $rc -ne 0 ] && exit 0
        case "$sel" in
            *Calendario*) calendar_view ;;
            *Agenda*) agenda_view ;;
            *To-Do*) todo_quick ;;
            *Notas*) notes_view ;;
            *Nuevo*) new_event ;;
            *Sincronizar*) do_sync ;;
            *Salir*) exit 0 ;;
        esac
    done
}

main "$@"