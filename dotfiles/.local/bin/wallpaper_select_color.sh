#!/usr/bin/env bash

[ -f "$HOME/hakuspace-control/main_setting.sh" ] && source "$HOME/hakuspace-control/main_setting.sh"

WALL_DIR=${WALL_DIR:-$HOME/Pictures/Wallpapers}
ACCENT_COLOR_BASED_ON_WALLPAPER=${ACCENT_COLOR_BASED_ON_WALLPAPER:-true}

SET_WALLPAPER_SCRIPT="$HOME/.local/bin/wallpaper_set.sh"
GET_ACCENT_COLOR_SCRIPT="$HOME/.local/bin/get_accent_color.py"
CACHE="$HOME/.cache/wallpaper_colors.json"
HELPER="$HOME/.local/bin/wallpaper_color.py"

# Si la cache no existe, la genera
if [ ! -s "$CACHE" ]; then
    notify-send "Wallpaper color" "Generando base de colores, espera..." 2>/dev/null
    "$HELPER" rebuild
fi

# Swatches de color (iguales al coverflow)
swatch_dir="$HOME/.cache/wallpapers/swatches"
mkdir -p "$swatch_dir"
gen_swatch() {
    local name=$1 rgb=$2
    local f="$swatch_dir/$name.png"
    [ -f "$f" ] || python3 -c "
from PIL import Image
Image.new('RGB',(64,64),'#$rgb').save('$f')
" 2>/dev/null
}
gen_swatch Red      e53935
gen_swatch Orange   f57c00
gen_swatch Yellow   fbc02d
gen_swatch Green    43a047
gen_swatch Cyan     00acc1
gen_swatch Blue     1e88e5
gen_swatch Violet   8e24aa
gen_swatch Purple   7b1fa2
gen_swatch Pink     d81b60
gen_swatch Brown    8d6e63
gen_swatch Black    111111
gen_swatch White    f5f5f5

apply_wallpaper() {
    local wall="$1"
    "$SET_WALLPAPER_SCRIPT" "$wall"
    if [ "$ACCENT_COLOR_BASED_ON_WALLPAPER" = true ]; then
        ACCENT=$(python3 "$GET_ACCENT_COLOR_SCRIPT" "$wall")
        [[ -z "$ACCENT" ]] && ACCENT="#ffffff"
        r=$(printf "%d" 0x${ACCENT:1:2})
        g=$(printf "%d" 0x${ACCENT:3:2})
        b=$(printf "%d" 0x${ACCENT:5:2})
        if [ $((r + g + b)) -lt 180 ]; then
            ACCENT="#ffffff"
        fi
        "$HOME/.local/bin/gen_style.sh" "$ACCENT"
        sleep 0.2
        "$HOME/.local/bin/apply_style.sh"
    fi
}

# Nivel 1: carpetas de colores (swatches del coverflow) + "Todos"
pick_folder() {
    local es c
    echo -en "Todos los colores\0icon\x1f$swatch_dir/all.png\n"
    while read -r c; do
        [ -z "$c" ] && continue
        case "$c" in
            Red) es="Rojo";; Orange) es="Naranja";; Yellow) es="Amarillo";;
            Green) es="Verde";; Cyan) es="Cian";; Blue) es="Azul";;
            Violet) es="Violeta";; Purple) es="Púrpura";; Pink) es="Rosa";;
            Brown) es="Marrón";; Black) es="Negro";; White) es="Blanco";;
            *) es="$c";;
        esac
        echo -en "$es\0icon\x1f$swatch_dir/$c.png\n"
    done < <("$HELPER" cats)
}

# Nivel 2: wallpapers de esa carpeta (thumbnails siempre visibles)
pick_wall() {
    local color="$1"
    if [ "$color" = "__all__" ]; then
        "$HELPER" listall
    else
        "$HELPER" list "$color"
    fi
}

# Bucle principal: color -> wallpapers (ESC retrocede)
while true; do
    folder=$(pick_folder | rofi -dmenu -i -p "Filtrar por color" -show-icons \
        -theme-str "
            window { width: 34%; }
            listview { columns: 4; lines: 3; spacing: 8px; padding: 10px;}
            element { orientation: vertical; padding: 6px; border-radius: 12px; }
            element-icon { size: 56px; horizontal-align: 0.5; }
            element-text { horizontal-align: 0.5; }
        " -mesg "ESC sale")
    [ -z "$folder" ] && exit 0

    case "$folder" in
        "Rojo") color_en="Red";; "Naranja") color_en="Orange";; "Amarillo") color_en="Yellow";;
        "Verde") color_en="Green";; "Cian") color_en="Cyan";; "Azul") color_en="Blue";;
        "Violeta") color_en="Violet";; "Púrpura") color_en="Purple";; "Rosa") color_en="Pink";;
        "Marrón") color_en="Brown";; "Negro") color_en="Black";; "Blanco") color_en="White";;
        "Todos los colores") color_en="__all__";;
        *) color_en="$folder";;
    esac

    chosen=$(pick_wall "$color_en" | rofi -dmenu -i -p "Wallpaper" -show-icons \
        -theme-str "
            window { width: 70%; height: 88%; }
            listview { columns: 5; lines: 2; spacing: 6px; padding: 8px;}
            element { orientation: vertical; padding: 4px; border-radius: 12px; }
            element-icon { size: 200px; horizontal-align: 0.5; }
        " -mesg "ESC vuelve a los colores")
    [ -z "$chosen" ] && continue  # ESC en wallpapers => vuelve a colores

    WALL="$WALL_DIR/$chosen"
    if [ -f "$WALL" ]; then
        apply_wallpaper "$WALL"
        exit 0
    fi
done