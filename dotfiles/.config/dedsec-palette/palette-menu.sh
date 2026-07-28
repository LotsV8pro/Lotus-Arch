#!/usr/bin/env bash
# D̷E̷D̷S̷E̷C̷ Palette Menu — Presets + Visual Picker + Save

set -euo pipefail

PALETTE="$HOME/.config/dedsec-palette/colors.conf"
APPLY="$HOME/.config/dedsec-palette/apply-colors.sh"
MENU_THEME="$HOME/.config/rofi/themes/dedsec-palette.rasi"
PRESETS_DIR="$HOME/.config/dedsec-palette/presets"

# ── Built-in Presets ───────────────────────────────────────────
preset_dedsec() {
    cat > "$PALETTE" << 'EOF'
# D̷E̷D̷S̷E̷C̷ Palette — DedSec Purple
primary=#B44AFF
primary_dim=#7B2FBE
primary_dark=#4a1d80
primary_light=#D088FF
bg=#0d0a1a
bg_alt=#1a1030
bg_light=#251840
fg=#D4A5FF
fg_dim=#7B6B9E
border=#3d2a6e
border_light=#5a3e99
red=#ff4488
orange=#FF9F43
yellow=#ffcc00
coral=#FF6644
amber=#FFAA22
peach=#FFAA88
rose=#FF66AA
green=#00E5A0
teal=#00CCAA
cyan=#00D4FF
sky=#44AAFF
blue=#6688ff
indigo=#6644CC
mint=#44DDAA
magenta=#FF44CC
lavender=#AA88FF
violet=#8844EE
fuchsia=#CC44FF
plum=#AA44AA
neon_green=#00FF88
neon_cyan=#00FFCC
neon_pink=#FF44FF
neon_yellow=#CCFF00
gray=#555566
slate=#444466
stone=#554466
ash=#333344
EOF
}

preset_red() {
    cat > "$PALETTE" << 'EOF'
# D̷E̷D̷S̷E̷C̷ Palette — Blood Red
primary=#FF2244
primary_dim=#AA1133
primary_dark=#660022
primary_light=#FF6688
bg=#1a0a0a
bg_alt=#2a1010
bg_light=#3a1818
fg=#FFB3B3
fg_dim=#885555
border=#5a2222
border_light=#773333
red=#FF4444
orange=#FF6622
yellow=#FFDD00
coral=#FF5533
amber=#FF8822
peach=#FFAA88
rose=#FF4466
green=#00FF88
teal=#00CCBB
cyan=#00DDFF
sky=#44AAFF
blue=#4488FF
indigo=#8822CC
mint=#44DDAA
magenta=#FF2288
lavender=#CC88FF
violet=#AA44CC
fuchsia=#FF44EE
plum=#CC4488
neon_green=#00FF66
neon_cyan=#00FFCC
neon_pink=#FF44CC
neon_yellow=#CCFF00
gray=#664444
slate=#553333
stone=#664444
ash=#442222
EOF
}

preset_green() {
    cat > "$PALETTE" << 'EOF'
# D̷E̷D̷S̷E̷C̷ Palette — Matrix Green
primary=#00FF66
primary_dim=#00AA44
primary_dark=#004422
primary_light=#44FF88
bg=#0a1a0a
bg_alt=#102a10
bg_light=#183a18
fg=#B3FFB3
fg_dim=#558855
border=#225a22
border_light=#337733
red=#FF4444
orange=#FFAA00
yellow=#CCFF00
coral=#FF6644
amber=#FFCC22
peach=#CCFF88
rose=#FF66AA
green=#00FF66
teal=#00DDAA
cyan=#00FFCC
sky=#44CCFF
blue=#00AAFF
indigo=#4466CC
mint=#44FFAA
magenta=#FF44FF
lavender=#88CCFF
violet=#6688CC
fuchsia=#CC44FF
plum=#8844AA
neon_green=#00FF44
neon_cyan=#00FFAA
neon_pink=#FF44FF
neon_yellow=#AAFF00
gray=#446644
slate=#335533
stone=#446644
ash=#224422
EOF
}

preset_cyan() {
    cat > "$PALETTE" << 'EOF'
# D̷E̷D̷S̷E̷C̷ Palette — Neon Cyan
primary=#00DDFF
primary_dim=#0099BB
primary_dark=#004466
primary_light=#44EEFF
bg=#0a0a1a
bg_alt=#101030
bg_light=#181840
fg=#B3E5FF
fg_dim=#5588AA
border=#223a5a
border_light=#335577
red=#FF4488
orange=#FFAA44
yellow=#FFDD44
coral=#FF5566
amber=#FFCC22
peach=#FFAA88
rose=#FF66CC
green=#00FFAA
teal=#00BBDD
cyan=#00DDFF
sky=#44AAFF
blue=#4488FF
indigo=#4466DD
mint=#44DDCC
magenta=#CC44FF
lavender=#88AAFF
violet=#6666CC
fuchsia=#CC44FF
plum=#8844AA
neon_green=#00FFCC
neon_cyan=#00EEFF
neon_pink=#FF44EE
neon_yellow=#CCFF44
gray=#444466
slate=#333355
stone=#444466
ash=#222244
EOF
}

preset_orange() {
    cat > "$PALETTE" << 'EOF'
# D̷E̷D̷S̷E̷C̷ Palette — Amber Hack
primary=#FF8800
primary_dim=#AA5500
primary_dark=#553300
primary_light=#FFBB44
bg=#1a0f05
bg_alt=#2a1a0a
bg_light=#3a2a15
fg=#FFDDB3
fg_dim=#886644
border=#5a3a1a
border_light=#775533
red=#FF4444
orange=#FF8800
yellow=#FFCC00
coral=#FF7744
amber=#FFAA22
peach=#FFBB88
rose=#FF6644
green=#44FF00
teal=#00CCAA
cyan=#00DDFF
sky=#44AAFF
blue=#44AAFF
indigo=#6644CC
mint=#44DDAA
magenta=#FF44CC
lavender=#CCAAFF
violet=#8844CC
fuchsia=#FF44CC
plum=#AA4488
neon_green=#44FF00
neon_cyan=#00FFCC
neon_pink=#FF44AA
neon_yellow=#FFEE00
gray=#665544
slate=#554433
stone=#665544
ash=#443322
EOF
}

preset_pink() {
    cat > "$PALETTE" << 'EOF'
# D̷E̷D̷S̷E̷C̷ Palette — Synthwave
primary=#FF44CC
primary_dim=#AA2288
primary_dark=#551144
primary_light=#FF88DD
bg=#1a0a14
bg_alt=#2a1020
bg_light=#3a1830
fg=#FFB3E5
fg_dim=#885577
border=#5a2244
border_light=#773366
red=#FF4466
orange=#FFAA44
yellow=#FFDD88
coral=#FF6688
amber=#FFCC44
peach=#FFAA88
rose=#FF44AA
green=#44FFAA
teal=#44CCBB
cyan=#44DDFF
sky=#88AAFF
blue=#AA88FF
indigo=#8844CC
mint=#88DDCC
magenta=#FF22AA
lavender=#CC88FF
violet=#AA44DD
fuchsia=#FF44EE
plum=#CC44AA
neon_green=#44FFCC
neon_cyan=#44FFEE
neon_pink=#FF44FF
neon_yellow=#FFDD44
gray=#664455
slate=#553344
stone=#664455
ash=#442233
EOF
}

preset_mono() {
    cat > "$PALETTE" << 'EOF'
# D̷E̷D̷S̷E̷C̷ Palette — Monochrome (Light Purple)
primary=#B8B0C8
primary_dim=#787088
primary_dark=#383048
primary_light=#D8D0E8
bg=#141218
bg_alt=#1C1A22
bg_light=#282430
fg=#D8D0E8
fg_dim=#887898
border=#383048
border_light=#504860
red=#C8B8C8
orange=#D0C0C8
yellow=#E0D8E8
coral=#C8B8C0
amber=#D8C8D0
peach=#E0D0D8
rose=#D8C0D0
green=#C0D0C0
teal=#B8D0C8
cyan=#B8C0D0
sky=#C0C8E0
blue=#B8B8D0
indigo=#9080A8
mint=#B8D8C0
magenta=#D0B8D0
lavender=#C8B8D8
violet=#9080A8
fuchsia=#D0B8D0
plum=#A898A8
neon_green=#D0E8D0
neon_cyan=#D0E0E8
neon_pink=#E8D0D8
neon_yellow=#E8E0D0
gray=#585060
slate=#484058
stone=#504858
ash=#383040
EOF
}

preset_solarized() {
    cat > "$PALETTE" << 'EOF'
# D̷E̷D̷S̷E̷C̷ Palette — Solarized
primary=#6C71C4
primary_dim=#586E75
primary_dark=#073642
primary_light=#93A1A1
bg=#002B36
bg_alt=#073642
bg_light=#586E75
fg=#EEE8D5
fg_dim=#839496
border=#586E75
border_light=#93A1A1
red=#DC322F
orange=#CB4B16
yellow=#B58900
coral=#CB4B16
amber=#B58900
peach=#EEE8D5
rose=#D33682
green=#859900
teal=#2AA198
cyan=#2AA198
sky=#268BD2
blue=#268BD2
indigo=#6C71C4
mint=#859900
magenta=#D33682
lavender=#6C71C4
violet=#6C71C4
fuchsia=#D33682
plum=#93A1A1
neon_green=#859900
neon_cyan=#2AA198
neon_pink=#D33682
neon_yellow=#B58900
gray=#586E75
slate=#073642
stone=#586E75
ash=#073642
EOF
}

# ── Robust zenity output → #RRGGBB ────────────────────────────
zenity_to_hex() {
    local raw="$1"
    # Strip whitespace
    raw=$(echo "$raw" | tr -d '[:space:]')

    # Already #RRGGBB
    if [[ "$raw" =~ ^#[0-9A-Fa-f]{6}$ ]]; then
        echo "$raw"
        return
    fi

    # rgb(R,G,B) or rgba(R,G,B,A)
    if [[ "$raw" =~ ^rgba?\(([0-9]+),\ ?([0-9]+),\ ?([0-9]+) ]]; then
        local r=${BASH_REMATCH[1]}
        local g=${BASH_REMATCH[2]}
        local b=${BASH_REMATCH[3]}
        printf '#%02X%02X%02X' "$r" "$g" "$b"
        return
    fi

    # Fallback — return as-is, validation will catch it
    echo "$raw"
}

# ── Visual color picker via zenity ─────────────────────────────
visual_picker() {
    local current_hex="$1"

    local result
    result=$(zenity --color-selection \
        --title="Pick Color" \
        --color="$current_hex" \
        --extra-button="Hex Input" \
        2>/dev/null) || true

    if [[ -z "$result" ]]; then
        echo ""
        return
    fi

    if [[ "$result" == "Hex Input" ]]; then
        echo "HEX_INPUT"
        return
    fi

    zenity_to_hex "$result"
}

# ── Save current palette as custom preset ──────────────────────
save_preset() {
    local name
    name=$(rofi -dmenu -p "  Preset Name" -theme "$MENU_THEME" 2>/dev/null)

    if [[ -z "$name" ]]; then
        return
    fi

    name=$(echo "$name" | sed 's/[^a-zA-Z0-9_-]/_/g')
    local preset_file="$PRESETS_DIR/${name}.conf"

    cp "$PALETTE" "$preset_file"
    sed -i "1s|^#.*|# Custom Preset — ${name}|" "$preset_file"

    notify-send "Preset Saved" "$name"
}

# ── Show main menu ─────────────────────────────────────────────
chosen=$(printf '%s\n' \
    "  Presets" \
    "  Edit Color" \
    "  Randomize" \
    "  Save Current as Preset" \
    "  Reset to DedSec" \
    | rofi -dmenu -p "  D̷E̷D̷S̷E̷C̷" -theme "$MENU_THEME" -no-custom 2>/dev/null)

if [[ -z "$chosen" ]]; then
    exit 0
fi

chosen=$(echo "$chosen" | xargs)

case "$chosen" in
    *Presets)
        preset_list=()
        preset_list+=(" DedSec Purple")
        preset_list+=(" Blood Red")
        preset_list+=(" Matrix Green")
        preset_list+=(" Neon Cyan")
        preset_list+=(" Amber Hack")
        preset_list+=(" Synthwave Pink")
        preset_list+=(" Monochrome")
        preset_list+=(" Solarized")

        for f in "$PRESETS_DIR"/*.conf; do
            [[ -f "$f" ]] || continue
            local_name=$(basename "$f" .conf)
            preset_list+=(" [Custom] ${local_name}")
        done

        preset_choice=$(printf '%s\n' "${preset_list[@]}" \
            | rofi -dmenu -p "  Presets" -theme "$MENU_THEME" -no-custom 2>/dev/null)

        if [[ -z "$preset_choice" ]]; then
            exit 0
        fi

        preset_choice=$(echo "$preset_choice" | xargs)

        case "$preset_choice" in
            *DedSec*)    preset_dedsec ;;
            *Red*)       preset_red ;;
            *Green*)     preset_green ;;
            *Cyan*)      preset_cyan ;;
            *Amber*)     preset_orange ;;
            *Synthwave*) preset_pink ;;
            *Mono*)      preset_mono ;;
            *Solarized*) preset_solarized ;;
            *Custom*)
                custom_name=$(echo "$preset_choice" | sed 's/.*\[Custom\] //')
                cp "$PRESETS_DIR/${custom_name}.conf" "$PALETTE"
                ;;
        esac

        bash "$APPLY"
        notify-send "Preset Applied" "$preset_choice"
        ;;

    *Edit*)
        declare -A colors
        while IFS='=' read -r key value; do
            [[ "$key" =~ ^#.*$ || -z "$key" ]] && continue
            colors["$key"]="$value"
        done < "$PALETTE"

        declare -A labels
        labels=(
            [primary]="Primary"
            [primary_dim]="Primary Dim"
            [primary_dark]="Primary Dark"
            [primary_light]="Primary Light"
            [bg]="Background"
            [bg_alt]="BG Alt"
            [bg_light]="BG Light"
            [fg]="Foreground"
            [fg_dim]="FG Dim"
            [border]="Border"
            [border_light]="Border Light"
            [red]="Red"
            [orange]="Orange"
            [yellow]="Yellow"
            [coral]="Coral"
            [amber]="Amber"
            [peach]="Peach"
            [rose]="Rose"
            [green]="Green"
            [teal]="Teal"
            [cyan]="Cyan"
            [sky]="Sky"
            [blue]="Blue"
            [indigo]="Indigo"
            [mint]="Mint"
            [magenta]="Magenta"
            [lavender]="Lavender"
            [violet]="Violet"
            [fuchsia]="Fuchsia"
            [plum]="Plum"
            [neon_green]="Neon Green"
            [neon_cyan]="Neon Cyan"
            [neon_pink]="Neon Pink"
            [neon_yellow]="Neon Yellow"
            [gray]="Gray"
            [slate]="Slate"
            [stone]="Stone"
            [ash]="Ash"
        )

        menu_entries=()
        for key in primary primary_dim primary_dark primary_light bg bg_alt bg_light fg fg_dim border border_light red orange yellow coral amber peach rose green teal cyan sky blue indigo mint magenta lavender violet fuchsia plum neon_green neon_cyan neon_pink neon_yellow gray slate stone ash; do
            val="${colors[$key]}"
            label="${labels[$key]}"
            menu_entries+=("${label}  ${val}")
        done

        chosen_color=$(printf '%s\n' "${menu_entries[@]}" | rofi -dmenu -p "  Edit Color" -theme "$MENU_THEME" -no-custom 2>/dev/null)

        if [[ -z "$chosen_color" ]]; then
            exit 0
        fi

        chosen_key=""
        for key in primary primary_dim primary_dark primary_light bg bg_alt bg_light fg fg_dim border border_light red orange yellow coral amber peach rose green teal cyan sky blue indigo mint magenta lavender violet fuchsia plum neon_green neon_cyan neon_pink neon_yellow gray slate stone ash; do
            if [[ "$chosen_color" == "${labels[$key]}"* ]]; then
                chosen_key="$key"
                break
            fi
        done

        if [[ -z "$chosen_key" ]]; then
            exit 0
        fi

        current_value="${colors[$chosen_key]}"

        input_method=$(printf '%s\n' \
            "  Visual RGB Picker" \
            "  Hex Input" \
            | rofi -dmenu -p "  ${labels[$chosen_key]}" -theme "$MENU_THEME" -no-custom 2>/dev/null)

        if [[ -z "$input_method" ]]; then
            exit 0
        fi

        new_value=""

        if [[ "$input_method" == *"Visual"* ]]; then
            new_value=$(visual_picker "$current_value")

            if [[ "$new_value" == "HEX_INPUT" ]]; then
                new_value=$(echo "$current_value" | rofi -dmenu -p "  Hex Value" -theme "$MENU_THEME" 2>/dev/null)
            fi
        else
            new_value=$(echo "$current_value" | rofi -dmenu -p "  Hex Value" -theme "$MENU_THEME" 2>/dev/null)
        fi

        if [[ -z "$new_value" || "$new_value" == "$current_value" ]]; then
            exit 0
        fi

        # Normalize: ensure # prefix and uppercase
        new_value="#${new_value#\#}"
        new_value=$(echo "${new_value:0:7}" | tr '[:lower:]' '[:upper:]')

        if [[ ! "$new_value" =~ ^#[0-9A-F]{6}$ ]]; then
            notify-send "Invalid color" "Got: ${new_value} — Use #RRGGBB"
            exit 1
        fi

        sed -i "s|^${chosen_key}=.*|${chosen_key}=${new_value}|" "$PALETTE"
        bash "$APPLY"
        notify-send "Color Updated" "${labels[$chosen_key]}: ${new_value}"
        ;;

    *Randomize)
        python3 "$HOME/.config/dedsec-palette/generate.py" > "$PALETTE"
        bash "$APPLY"
        notify-send "Randomized" "New palette generated"
        ;;

    *Save*)
        save_preset
        ;;

    *Reset*)
        preset_dedsec
        bash "$APPLY"
        notify-send "Reset" "DedSec Purple palette restored"
        ;;
esac
