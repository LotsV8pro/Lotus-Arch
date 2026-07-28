#!/usr/bin/env bash
# D̷E̷D̷S̷E̷C̷ Palette — Apply Colors
# Reads ~/.config/dedsec-palette/colors.conf and updates all theme files

set -euo pipefail

PALETTE="$HOME/.config/dedsec-palette/colors.conf"

if [[ ! -f "$PALETTE" ]]; then
    echo "Palette not found: $PALETTE"
    exit 1
fi

# Source the palette
source "$PALETTE"

# Strip # from hex values for files that need it
strip() { echo "${1#\#}"; }

# ── 1. Waybar CSS ─────────────────────────────────────────────
WAYBAR_CSS="$HOME/.config/waybar/style/[Dark] DedSec Purple.css"

cat > "$WAYBAR_CSS" << CSS
/* D̷E̷D̷S̷E̷C̷ — Waybar (Flat Purple) */

@define-color purple ${primary};
@define-color purple-dim ${primary_dim};
@define-color purple-dark ${primary_dark};
@define-color purple-light ${primary_light};
@define-color bg ${bg};
@define-color bg-alt ${bg_alt};
@define-color bg-light ${bg_light};
@define-color border ${border};
@define-color border-light ${border_light};
@define-color text ${fg};
@define-color text-dim ${fg_dim};
@define-color red ${red};
@define-color green ${green};
@define-color cyan ${cyan};
@define-color orange ${orange};
@define-color pink ${magenta};
@define-color teal ${teal};
@define-color magenta ${magenta};
@define-color indigo ${indigo};
@define-color coral ${coral};
@define-color lavender ${lavender};
@define-color neon-green ${neon_green};
@define-color neon-cyan ${neon_cyan};
@define-color neon-pink ${neon_pink};

* {
    font-family: "JetBrainsMono Nerd Font";
    font-weight: bold;
    min-height: 0;
    font-size: 90%;
    padding-top: 0px;
    padding-bottom: 0px;
}

window#waybar {
    background: @bg;
}

tooltip {
    background: @bg-alt;
    border: 1px solid @border;
    color: @text;
    border-radius: 8px;
    padding: 4px 8px;
}

tooltip label {
    color: @text;
}

.modules-left,
.modules-right,
.modules-center {
    background: transparent;
    padding: 0 4px;
}

#workspaces button {
    color: @text-dim;
    background: transparent;
    border: none;
    border-radius: 0;
    padding: 4px 12px;
    min-width: 24px;
    font-size: 115%;
}

#workspaces button.active {
    color: @bg;
    background: @purple;
    min-width: 36px;
}

#workspaces button:hover {
    color: @bg;
    background: @purple-dim;
}

#workspaces button.urgent {
    color: @bg;
    background: @red;
}

#cpu,
#custom-gpu,
#memory,
#temperature,
#clock,
#mpris,
#pulseaudio,
#bluetooth,
#window,
#tray,
#power-profiles-daemon,
#custom-menu,
#custom-updater,
#custom-power,
#custom-lock,
#custom-nightlight {
    color: @text;
    padding: 0 8px;
}

#cpu                    { color: @cyan; }
#custom-gpu             { color: @green; }
#memory                 { color: @orange; }
#temperature            { color: @text; }
#temperature.critical   { color: @red; }
#clock                  { color: @purple; font-size: 1.05em; }
#mpris                  { color: @pink; font-size: 115%; }
#pulseaudio             { color: @teal; }
#pulseaudio.muted       { color: @text-dim; opacity: 0.5; }
#bluetooth              { color: @indigo; }
#bluetooth.disabled,
#bluetooth.off          { color: @text-dim; opacity: 0.5; }
#window                 { color: @text-dim; font-style: italic; }
#power-profiles-daemon  { color: @green; }
#custom-menu            { color: @purple; font-size: 1.15em; }
#custom-updater         { color: @green; }
#custom-power           { color: @coral; }
#custom-lock            { color: @lavender; }
#custom-nightlight      { color: @orange; }

#wlr-taskbar {
    color: @text;
    padding: 0 8px;
}

#wlr-taskbar button {
    color: @text-dim;
    background: transparent;
    border: none;
    border-radius: 0;
    padding: 4px 8px;
    min-width: 20px;
}

#wlr-taskbar button.active {
    color: @bg;
    background: @purple-dim;
    min-width: 36px;
}

#wlr-taskbar button:hover {
    color: @bg;
    background: @purple-dark;
}

#tray {
    color: @text-dim;
}

#group-notify {
    background: transparent;
    margin: 0;
    padding: 0;
}

#pulseaudio-slider slider {
    min-width: 0px;
    min-height: 0px;
    opacity: 0;
    background-image: none;
    border: none;
}

#pulseaudio-slider trough {
    min-width: 80px;
    min-height: 4px;
    border-radius: 4px;
    background-color: @bg-alt;
}

#pulseaudio-slider highlight {
    min-height: 4px;
    border-radius: 4px;
    background-color: @purple;
}
CSS

# ── 1b. Waybar Pill Style (Floating + HyprGlass) ──────────────
WAYBAR_PILL="$HOME/.config/waybar/style/[Dark] DedSec Pill.css"

# Extract RGB components from hex for rgba()
hex_to_rgb() {
    local hex="${1#\#}"
    echo "$((16#${hex:0:2})) $((16#${hex:2:2})) $((16#${hex:4:2}))"
}
read -r BGR BGG BGB <<< "$(hex_to_rgb "$bg")"
read -r ALT_R ALT_G ALT_B <<< "$(hex_to_rgb "$bg_alt")"

cat > "$WAYBAR_PILL" << PILL
/* D̷E̷D̷S̷E̷C̷ — Waybar Floating Pill Style (HyprGlass ready) */

@define-color purple ${primary};
@define-color purple-dim ${primary_dim};
@define-color purple-dark ${primary_dark};
@define-color purple-light ${primary_light};
@define-color bg ${bg};
@define-color bg-alt ${bg_alt};
@define-color bg-light ${bg_light};
@define-color border ${border};
@define-color border-light ${border_light};
@define-color text ${fg};
@define-color text-dim ${fg_dim};
@define-color red ${red};
@define-color green ${green};
@define-color cyan ${cyan};
@define-color orange ${orange};
@define-color pink ${magenta};
@define-color teal ${teal};
@define-color magenta ${magenta};
@define-color indigo ${indigo};
@define-color coral ${coral};
@define-color lavender ${lavender};

/* RESET ALL CONTAINERS — GTK3 compatible (no !important, no shorthand) */
window#waybar {
    background-color: transparent;
    border: none;
}

#waybar {
    background-color: transparent;
    border: none;
}

.modules-left,
.modules-center,
.modules-right {
    background-color: transparent;
    border: none;
}

/* PILL MODULES */
#custom-menu,
#mpris,
#custom-weather,
#clock,
#workspaces,
#pulseaudio,
#network,
#battery,
#custom-swaync,
#tray {
    background-color: rgba(${ALT_R}, ${ALT_G}, ${ALT_B}, 0.85);
    color: @text;
    border-radius: 18px;
    padding: 4px 14px;
    margin: 6px 4px;
    border: 1px solid rgba(${BGR}, ${BGG}, ${BGB}, 0.4);
}

#custom-menu:hover,
#mpris:hover,
#custom-weather:hover,
#clock:hover,
#workspaces:hover,
#pulseaudio:hover,
#network:hover,
#battery:hover,
#custom-swaync:hover {
    background-color: rgba(${ALT_R}, ${ALT_G}, ${ALT_B}, 0.92);
    border-color: @purple;
}

#custom-menu            { color: @purple; font-size: 1.15em; }
#mpris                  { color: @pink; min-width: 120px; max-width: 280px; }
#custom-weather         { color: @cyan; }
#clock                  { color: @purple; font-size: 1.05em; }
#workspaces             { color: @text-dim; }
#pulseaudio             { color: @teal; }
#network                { color: @indigo; }
#battery                { color: @green; }
#custom-swaync          { color: @lavender; }

/* WORKSPACES BUTTONS */
#workspaces button {
    padding: 0px 6px;
    color: #a6adc8;
    background-color: transparent;
    border: none;
    border-radius: 12px;
    min-width: 20px;
    margin: 2px 1px;
}

#workspaces button.active {
    color: #11111b;
    background-color: #89b4fa;
    border-radius: 12px;
}

#workspaces button:hover {
    color: @bg;
    background-color: @purple-dim;
}

#workspaces button.urgent {
    color: @bg;
    background-color: @red;
}

tooltip {
    background-color: rgba(${ALT_R}, ${ALT_G}, ${ALT_B}, 0.92);
    border: 1px solid @border;
    color: @text;
    border-radius: 12px;
    padding: 6px 10px;
}

tooltip label {
    color: @text;
}

#tray > .passive {
    -gtk-icon-effect: dim;
}

#tray > .needs-attention {
    -gtk-icon-effect: highlight;
}

#pulseaudio-slider slider {
    min-width: 0px;
    min-height: 0px;
    opacity: 0;
    background-image: none;
    border: none;
}

#pulseaudio-slider trough {
    min-width: 80px;
    min-height: 4px;
    border-radius: 4px;
    background-color: rgba(${BGR}, ${BGG}, ${BGB}, 0.6);
}

#pulseaudio-slider highlight {
    min-height: 4px;
    border-radius: 4px;
    background-color: @purple;
}
PILL

# ── 1b2. Waybar Monochrome Pill (Dynamic Island) ─────────────
WAYBAR_MONO="$HOME/.config/waybar/style/[Black & White] Monochrome.css"

cat > "$WAYBAR_MONO" << MONO
/* M̷O̷N̷O̷C̷H̷R̷O̷M̷E̷ — Minimalistic Floating Pill (Dynamic Island) */
/* Colors auto-generated from dedsec palette — do not edit manually */

@define-color primary ${primary};
@define-color primary-dim ${primary_dim};
@define-color primary-dark ${primary_dark};
@define-color primary-light ${primary_light};
@define-color bg ${bg};
@define-color bg-alt ${bg_alt};
@define-color bg-light ${bg_light};
@define-color fg ${fg};
@define-color fg-dim ${fg_dim};
@define-color border ${border};
@define-color border-light ${border_light};
@define-color red ${red};
@define-color orange ${orange};
@define-color yellow ${yellow};
@define-color coral ${coral};
@define-color green ${green};
@define-color teal ${teal};
@define-color cyan ${cyan};
@define-color blue ${blue};
@define-color indigo ${indigo};
@define-color lavender ${lavender};
@define-color magenta ${magenta};

* {
    font-family: "JetBrainsMono Nerd Font";
    font-weight: 600;
    min-height: 0;
    font-size: 92%;
}

window#waybar,
window#waybar.empty,
window#waybar.empty #window {
    background-color: transparent;
    padding: 0;
    border: none;
}

.modules-left,
.modules-center,
.modules-right {
    background-color: transparent;
    border: none;
    padding: 0;
    margin: 0;
}

/* ── Floating Pill Modules ── */
#custom-menu,
#mpris,
#custom-weather,
#clock,
#workspaces,
#pulseaudio,
#network,
#battery,
#bluetooth,
#custom-swaync,
#tray,
#cpu,
#memory,
#temperature,
#custom-powerprofiles,
#idle_inhibitor {
    background-color: rgba(${ALT_R}, ${ALT_G}, ${ALT_B}, 0.88);
    color: @fg;
    border-radius: 20px;
    padding: 6px 20px;
    margin: 6px 4px;
    border: 1px solid rgba(${BGR}, ${BGG}, ${BGB}, 0.15);
    transition: all 200ms ease;
}

#custom-menu:hover,
#mpris:hover,
#custom-weather:hover,
#clock:hover,
#workspaces:hover,
#pulseaudio:hover,
#network:hover,
#battery:hover,
#bluetooth:hover,
#custom-swaync:hover,
#cpu:hover,
#memory:hover,
#temperature:hover,
#custom-powerprofiles:hover,
#idle_inhibitor:hover {
    background-color: rgba(${ALT_R}, ${ALT_G}, ${ALT_B}, 0.92);
    border-color: rgba(${ALT_R}, ${ALT_G}, ${ALT_B}, 0.3);
}

/* ── Module Colors ── */
#custom-menu {
    color: @primary-light;
    font-size: 1.15em;
    padding: 6px 18px;
}

#clock {
    color: @primary-light;
    font-size: 1.05em;
    font-weight: 700;
    padding: 6px 22px;
}

#mpris {
    color: @primary;
    min-width: 100px;
    padding: 6px 18px;
}

#workspaces {
    color: @fg-dim;
    padding: 6px 12px;
}

#pulseaudio             { color: @teal; }
#pulseaudio.muted       { color: @fg-dim; }
#network                { color: @cyan; }
#network.disconnected   { color: @fg-dim; }
#battery                { color: @green; }
#battery.full           { color: @primary-light; }
#battery.charging       { color: @primary; }
#battery.warning:not(.charging) { color: @orange; }
#battery.critical:not(.charging) {
    color: @primary-light;
    animation-name: blink;
    animation-duration: 2s;
    animation-timing-function: steps(10);
    animation-iteration-count: infinite;
}

@keyframes blink {
    to { color: @fg-dim; }
}

#bluetooth              { color: @indigo; }
#bluetooth.disabled,
#bluetooth.off          { color: @fg-dim; }
#cpu                    { color: @primary; }
#memory                 { color: @primary; }
#temperature            { color: @primary; }
#temperature.critical   { color: @primary-light; }
#custom-swaync          { color: @lavender; }
#custom-weather         { color: @cyan; }
#custom-powerprofiles   { color: @teal; }
#idle_inhibitor         { color: @fg-dim; }
#idle_inhibitor.activated { color: @primary-light; }
#tray                   { color: @fg-dim; }
#window                 { color: @fg-dim; font-style: italic; }

/* ── Workspaces Buttons ── */
#workspaces button {
    padding: 0px 8px;
    color: @fg-dim;
    background-color: transparent;
    border: none;
    border-radius: 12px;
    min-width: 20px;
    margin: 2px 1px;
    transition: all 200ms cubic-bezier(0.25, 0.46, 0.45, 0.94);
}

#workspaces button.active {
    color: @bg;
    background-color: @primary-light;
    border-radius: 12px;
    min-width: 30px;
}

#workspaces button:hover {
    color: @bg;
    background-color: @primary-dim;
}

#workspaces button.urgent {
    color: @bg;
    background-color: @primary-light;
}

/* ── Tooltip ── */
tooltip {
    background-color: rgba(${ALT_R}, ${ALT_G}, ${ALT_B}, 0.94);
    border: 1px solid @border;
    color: @fg;
    border-radius: 14px;
    padding: 6px 10px;
}

tooltip label { color: @fg; }

#tray > .passive { -gtk-icon-effect: dim; }
#tray > .needs-attention { -gtk-icon-effect: highlight; }

/* ── Slider ── */
#pulseaudio-slider slider,
#backlight-slider slider {
    min-width: 0px;
    min-height: 0px;
    opacity: 0;
    background-image: none;
    border: none;
}

#pulseaudio-slider trough,
#backlight-slider trough {
    min-width: 80px;
    min-height: 4px;
    border-radius: 4px;
    background-color: rgba(${BGR}, ${BGG}, ${BGB}, 0.15);
}

#pulseaudio-slider highlight,
#backlight-slider highlight {
    min-height: 4px;
    border-radius: 4px;
    background-color: @primary;
}
MONO

# ── 1c. GTK3 Thunar Theme ─────────────────────────────────────
GTK_CSS="$HOME/.config/gtk-3.0/gtk.css"
read -r PR PRG PRB <<< "$(hex_to_rgb "$primary")"

cat > "$GTK_CSS" << 'GTKCSS'
/* D̷E̷D̷S̷E̷C̷ — GTK3 Thunar Theme (Pill / Rounded) */
GTKCSS

cat >> "$GTK_CSS" << GTK
@define-color dedsec-purple    ${primary};
@define-color dedsec-purple-dim ${primary_dim};
@define-color dedsec-purple-dark ${primary_dark};
@define-color dedsec-bg        ${bg};
@define-color dedsec-bg-alt    ${bg_alt};
@define-color dedsec-bg-light  ${bg_light};
@define-color dedsec-fg        ${fg};
@define-color dedsec-fg-dim    ${fg_dim};
@define-color dedsec-border    ${border};
@define-color dedsec-red       ${red};
@define-color dedsec-green     ${green};
@define-color dedsec-cyan      ${cyan};
GTK

cat >> "$GTK_CSS" << GTKCSS2

.thunar .view, .thunar iconview, .thunar .thunar-wallpaper,
.thunar scrolledwindow, .thunar {
    background-color: @dedsec-bg; color: @dedsec-fg;
}

.thunar headerbar, .thunar .titlebar {
    background-color: @dedsec-bg-alt; border-bottom: 1px solid @dedsec-border;
    border-radius: 0; padding: 4px 8px; min-height: 38px;
}
.thunar headerbar title, .thunar headerbar label { color: @dedsec-fg; font-weight: bold; }

.thunar .sidebar {
    background-color: @dedsec-bg-alt; border-right: 1px solid @dedsec-border; padding: 6px;
}
.thunar .sidebar .view, .thunar .sidebar treeview {
    background-color: transparent; color: @dedsec-fg; border: none; outline: none; font-weight: bold;
}
.thunar .sidebar .sidebar-label {
    color: @dedsec-fg-dim; font-size: 0.85em; font-weight: bold; padding: 8px 12px 4px 12px; letter-spacing: 1px;
}
.thunar .sidebar row, .thunar .sidebar treeview row {
    padding: 2px 4px; margin: 1px 4px; border-radius: 12px; min-height: 32px; transition: all 200ms ease;
}
.thunar .sidebar row:hover, .thunar .sidebar treeview row:hover {
    background-color: rgba(${PR}, ${PRG}, ${PRB}, 0.12); border-radius: 12px;
}
.thunar .sidebar row:selected, .thunar .sidebar treeview row:selected {
    background-color: rgba(${PR}, ${PRG}, ${PRB}, 0.25); color: @dedsec-purple; border-radius: 12px;
    border: 1px solid rgba(${PR}, ${PRG}, ${PRB}, 0.3);
}
.thunar .sidebar row:selected label, .thunar .sidebar treeview row:selected label { color: @dedsec-purple; font-weight: bold; }
.thunar .sidebar row:selected image, .thunar .sidebar treeview row:selected image { color: @dedsec-purple; }
.thunar .sidebar row image, .thunar .sidebar treeview row image { color: @dedsec-fg-dim; padding-right: 8px; }

.thunar toolbar, .thunar .toolbar {
    background-color: @dedsec-bg-alt; border-bottom: 1px solid @dedsec-border; padding: 4px 8px; border-radius: 0;
}
.thunar toolbar button, .thunar .toolbar button {
    background-color: transparent; color: @dedsec-fg; border: 1px solid transparent;
    border-radius: 12px; padding: 4px 10px; min-width: 32px; min-height: 32px; transition: all 200ms ease;
}
.thunar toolbar button:hover, .thunar .toolbar button:hover {
    background-color: rgba(${PR}, ${PRG}, ${PRB}, 0.15); border-color: @dedsec-border; color: @dedsec-purple;
}

.thunar .path-bar button {
    background-color: rgba(${ALT_R}, ${ALT_G}, ${ALT_B}, 0.6); color: @dedsec-fg;
    border: 1px solid @dedsec-border; border-radius: 12px; padding: 4px 14px; margin: 2px 2px; min-height: 28px;
    transition: all 200ms ease;
}
.thunar .path-bar button:hover {
    background-color: rgba(${PR}, ${PRG}, ${PRB}, 0.2); border-color: @dedsec-purple-dim; color: @dedsec-purple;
}
.thunar .path-bar button:checked, .thunar .path-bar button:last-child {
    background-color: rgba(${PR}, ${PRG}, ${PRB}, 0.25); color: @dedsec-purple; border-color: @dedsec-purple;
}

.thunar .search-bar entry, .thunar entry.search {
    background-color: @dedsec-bg; color: @dedsec-fg; border: 1px solid @dedsec-border;
    border-radius: 16px; padding: 4px 14px; min-height: 30px; caret-color: @dedsec-purple;
}
.thunar .search-bar entry:focus, .thunar entry.search:focus {
    border-color: @dedsec-purple; box-shadow: 0 0 0 2px rgba(${PR}, ${PRG}, ${PRB}, 0.2);
}

.thunar .view header button, .thunar GtkTreeViewHeaderButton {
    background-color: @dedsec-bg-alt; color: @dedsec-fg-dim;
    border-bottom: 1px solid @dedsec-border; border-right: 1px solid @dedsec-border;
    border-radius: 0; padding: 6px 12px; font-weight: bold; font-size: 0.9em;
}

.thunar .view row, .thunar iconview cell {
    padding: 4px 8px; margin: 1px 6px; border-radius: 10px; min-height: 34px; transition: all 150ms ease;
}
.thunar .view row:hover, .thunar iconview cell:hover {
    background-color: rgba(${PR}, ${PRG}, ${PRB}, 0.10); border-radius: 10px;
}
.thunar .view row:selected, .thunar iconview cell:selected {
    background-color: rgba(${PR}, ${PRG}, ${PRB}, 0.22); color: @dedsec-purple; border-radius: 10px;
    border: 1px solid rgba(${PR}, ${PRG}, ${PRB}, 0.3);
}
.thunar .view row:selected label, .thunar iconview cell:selected label { color: @dedsec-purple; font-weight: bold; }

.thunar scrollbar, .thunar scrolledwindow scrollbar { background-color: transparent; border: none; }
.thunar scrollbar slider, .thunar scrolledwindow scrollbar slider {
    background-color: rgba(${PR}, ${PRG}, ${PRB}, 0.25); border: none; border-radius: 20px;
    min-width: 6px; min-height: 40px; margin: 4px 2px; transition: all 200ms ease;
}
.thunar scrollbar slider:hover, .thunar scrolledwindow scrollbar slider:hover {
    background-color: rgba(${PR}, ${PRG}, ${PRB}, 0.45); min-width: 8px;
}

.thunar .statusbar, .thunar statusbar {
    background-color: @dedsec-bg-alt; border-top: 1px solid @dedsec-border;
    color: @dedsec-fg-dim; padding: 4px 12px; font-size: 0.85em;
}

.thunar button {
    color: @dedsec-fg; border-radius: 12px; padding: 4px 14px; min-height: 30px; transition: all 200ms ease;
}
.thunar button:hover { background-color: rgba(${PR}, ${PRG}, ${PRB}, 0.15); color: @dedsec-purple; }
.thunar button:active { background-color: rgba(${PR}, ${PRG}, ${PRB}, 0.25); }
.thunar button.suggested-action {
    background-color: rgba(${PR}, ${PRG}, ${PRB}, 0.3); color: @dedsec-purple;
    border: 1px solid @dedsec-purple-dim; border-radius: 12px;
}
.thunar button.suggested-action:hover {
    background-color: rgba(${PR}, ${PRG}, ${PRB}, 0.45); border-color: @dedsec-purple;
}

.thunar entry, .thunar spinbutton {
    background-color: @dedsec-bg; color: @dedsec-fg; border: 1px solid @dedsec-border;
    border-radius: 12px; padding: 4px 12px; min-height: 30px; caret-color: @dedsec-purple;
}
.thunar entry:focus, .thunar spinbutton:focus {
    border-color: @dedsec-purple; box-shadow: 0 0 0 2px rgba(${PR}, ${PRG}, ${PRB}, 0.2);
}
.thunar entry selection, .thunar spinbutton selection {
    background-color: rgba(${PR}, ${PRG}, ${PRB}, 0.35); color: @dedsec-fg;
}

.thunar .context-menu, .thunar menu, .thunar popupmenu, .thunar popover {
    background-color: @dedsec-bg-alt; border: 1px solid @dedsec-border;
    border-radius: 12px; padding: 6px; box-shadow: 0 8px 32px rgba(0, 0, 0, 0.5);
}
.thunar .context-menu menuitem, .thunar menu menuitem {
    color: @dedsec-fg; border-radius: 8px; padding: 6px 16px; min-height: 30px; transition: all 150ms ease;
}
.thunar .context-menu menuitem:hover, .thunar menu menuitem:hover {
    background-color: rgba(${PR}, ${PRG}, ${PRB}, 0.15); color: @dedsec-purple;
}
.thunar .context-menu menuitem:disabled, .thunar menu menuitem:disabled { color: @dedsec-fg-dim; opacity: 0.5; }
.thunar .context-menu separator, .thunar menu separator {
    background-color: @dedsec-border; margin: 4px 8px; min-height: 1px;
}

.thunar notebook > header tab {
    background-color: transparent; color: @dedsec-fg-dim; border: none;
    border-bottom: 2px solid transparent; border-radius: 8px 8px 0 0; padding: 6px 16px; min-height: 32px;
}
.thunar notebook > header tab:hover { color: @dedsec-fg; background-color: rgba(${PR}, ${PRG}, ${PRB}, 0.08); }
.thunar notebook > header tab:checked {
    color: @dedsec-purple; border-bottom-color: @dedsec-purple; background-color: rgba(${PR}, ${PRG}, ${PRB}, 0.12);
}

.thunar tooltip, .thunar GtkTooltip {
    background-color: @dedsec-bg-alt; color: @dedsec-fg;
    border: 1px solid @dedsec-border; border-radius: 10px; padding: 6px 10px;
}

.thunar progressbar trough, .thunar .progressbar trough {
    background-color: @dedsec-bg-light; border-radius: 10px; min-height: 8px;
}
.thunar progressbar progress, .thunar .progressbar progress {
    background-color: @dedsec-purple; border-radius: 10px; min-height: 8px;
}

.thunar checkbutton check, .thunar radiobutton radio {
    background-color: @dedsec-bg; border: 2px solid @dedsec-border; border-radius: 6px; min-width: 18px; min-height: 18px;
}
.thunar checkbutton check:checked, .thunar radiobutton radio:checked {
    background-color: @dedsec-purple; border-color: @dedsec-purple; color: @dedsec-bg;
}

.thunar switch {
    background-color: @dedsec-bg-light; border-radius: 20px; padding: 2px; min-width: 48px; min-height: 26px;
}
.thunar switch:checked { background-color: rgba(${PR}, ${PRG}, ${PRB}, 0.4); }
.thunar switch slider {
    background-color: @dedsec-fg-dim; border-radius: 20px; min-width: 22px; min-height: 22px;
}
.thunar switch:checked slider { background-color: @dedsec-purple; }
GTKCSS2

# ── 2. Rofi Theme ─────────────────────────────────────────────
ROFI_THEME="$HOME/.config/rofi/themes/dedsec.rasi"
BG_EE="${bg}ee"

cat > "$ROFI_THEME" << ROSI
/* D̷E̷D̷S̷E̷C̷ Rofi — Purple / Modern */

configuration {
    modi:                       "drun,run,filebrowser,window";
    show-icons:                 true;
    display-drun:               " ";
    display-run:                " ";
    display-filebrowser:        " ";
    display-window:             " ";
    drun-display-format:        "{name}";
    hover-select:               true;
    me-select-entry:            "MouseSecondary";
    me-accept-entry:            "MousePrimary";
    window-format:              "{w} · {c} · {t}";
}

* {
    bg:             ${BG_EE};
    bg-alt:         ${bg_alt};
    fg:             ${fg};
    fg-dim:         ${fg_dim};
    purple:         ${primary};
    purple-dim:     ${primary_dim};
    purple-dark:    ${primary_dark};
    light:          ${fg};
    selected:       ${primary}22;
    urgent:         ${red};
    teal:           ${teal};
    magenta:        ${magenta};
}

window {
    width:              600px;
    location:           center;
    anchor:             center;
    border:             2px;
    border-color:       @purple;
    border-radius:      12px;
    padding:            0;
    background-color:   @bg;
}

mainbox {
    enabled:            true;
    orientation:        vertical;
    children:           [ "inputbar", "listbox" ];
    background-color:   @bg;
    spacing:            0;
    padding:            0;
}

inputbar {
    enabled:            true;
    children:           [ "textbox-prompt-colon", "entry" ];
    background-color:   @bg-alt;
    border:             1px;
    border-color:       @purple-dim;
    border-radius:      12px 12px 0 0;
    padding:            12px 16px;
    spacing:            10px;
}

textbox-prompt-colon {
    enabled:            true;
    expand:             false;
    str:                " ";
    text-color:         @purple;
    background-color:   transparent;
    padding:            4px 0;
}

entry {
    enabled:            true;
    text-color:         @fg;
    background-color:   transparent;
    cursor:             text;
    padding:            4px 0;
}

listbox {
    children:           [ "listview" ];
    background-color:   @bg;
    spacing:            0;
    padding:            6px 0;
}

listview {
    enabled:            true;
    columns:            1;
    lines:              8;
    cycle:              true;
    dynamic:            true;
    scrollbar:          false;
    layout:             vertical;
    reverse:            false;
    fixed-height:       true;
    fixed-columns:      false;
    spacing:            2px;
    padding:            4px 8px;
    background-color:   @bg;
}

element {
    enabled:            true;
    padding:            10px 14px;
    margin:             0px 4px;
    cursor:             pointer;
    background-color:   transparent;
    border-radius:      8px;
}

element normal.normal {
    background-color:   inherit;
    text-color:         @fg;
}

element normal.urgent {
    background-color:   inherit;
    text-color:         @urgent;
}

element normal.active {
    background-color:   inherit;
    text-color:         @purple-dim;
}

element selected.normal {
    background-color:   @selected;
    text-color:         @purple;
    border:             1px;
    border-color:       @purple-dim;
}

element selected.urgent {
    background-color:   inherit;
    text-color:         @urgent;
}

element selected.active {
    background-color:   inherit;
    text-color:         @purple-dim;
}

element alternate.normal {
    background-color:   inherit;
    text-color:         @fg;
}

element alternate.urgent {
    background-color:   inherit;
    text-color:         @urgent;
}

element alternate.active {
    background-color:   inherit;
    text-color:         @purple-dim;
}

element-icon {
    background-color:   transparent;
    text-color:         inherit;
    size:               32px;
    cursor:             inherit;
}

element-text {
    background-color:   transparent;
    text-color:         inherit;
    cursor:             inherit;
    vertical-align:     0.5;
    horizontal-align:   0;
}

scrollbar {
    border:             0px;
    border-radius:      4px;
    background-color:   transparent;
    handle-color:       @purple-dim;
    handle-width:       3px;
    padding:            0;
}

message {
    background-color:   @bg;
    border:             0px;
}

textbox {
    padding:            10px 14px;
    border-radius:      0 0 12px 12px;
    background-color:   @bg-alt;
    text-color:         @fg;
    vertical-align:     0.5;
    horizontal-align:   0;
}

error-message {
    padding:            10px 14px;
    border-radius:      12px;
    background-color:   @bg-alt;
    text-color:         @urgent;
}
ROSI

# ── 3. Kitty Terminal ──────────────────────────────────────────
KITTY="$HOME/.config/kitty/kitty-dedsec.conf"

cat > "$KITTY" << KITTY
# D̷E̷D̷S̷E̷C̷ Terminal Theme — Kitty

foreground           ${fg}
background           ${bg}
selection_foreground  ${bg}
selection_background  ${primary}

cursor               ${primary}
cursor_text_color    ${bg}

active_tab_foreground   ${bg}
active_tab_background   ${primary}
inactive_tab_foreground ${fg}
inactive_tab_background ${bg_alt}

color0  ${bg}
color1  ${red}
color2  ${primary}
color3  ${yellow}
color4  ${blue}
color5  ${magenta}
color6  ${cyan}
color7  #cccccc

color8  ${primary_dark}
color9  ${coral}
color10 ${teal}
color11 ${amber}
color12 ${indigo}
color13 ${fuchsia}
color14 ${cyan}
color15 #ffffff

url_color ${primary}

mark1_foreground ${bg}
mark1_background ${primary}
mark2_foreground ${bg}
mark2_background ${blue}
mark3_foreground ${bg}
mark3_background ${red}

shell_integration enabled
KITTY

# ── 4. Ghostty Terminal ────────────────────────────────────────
GHOSTTY="$HOME/.config/ghostty/config"

cat > "$GHOSTTY" << GHOSTTY
# D̷E̷D̷S̷E̷C̷ Theme — Ghostty

adjust-cell-height = 10%
background-blur-radius = 60
background-opacity = 0.92
bold-is-bright = true
confirm-close-surface = false
cursor-style = bar
cursor-style-blink = true
font-family = JetBrainsMono Nerd Font Mono
font-size = 12
gtk-single-instance = true
mouse-hide-while-typing = true
quick-terminal-position = center
shell-integration = detect
shell-integration-features = cursor,sudo
term = xterm-256color
title = D̷E̷D̷S̷E̷C̷ Terminal
unfocused-split-opacity = 0.5
wait-after-command = false
window-height = 32
window-save-state = always
window-theme = dark
window-width = 110

# Colors
background = ${bg}
foreground = ${fg}
cursor-color = ${primary}
cursor-text = ${bg}
selection-background = ${primary}
selection-foreground = ${bg}

# Normal colors
palette = 0=${bg}
palette = 1=${red}
palette = 2=${primary}
palette = 3=${yellow}
palette = 4=${blue}
palette = 5=${magenta}
palette = 6=${cyan}
palette = 7=#cccccc

# Bright colors
palette = 8=${primary_dark}
palette = 9=${coral}
palette = 10=${teal}
palette = 11=${amber}
palette = 12=${indigo}
palette = 13=${fuchsia}
palette = 14=${cyan}
palette = 15=#ffffff

window-padding-x = 12
window-padding-y = 8
window-padding-color = extend
GHOSTTY

# ── 5. Hyprland Decorations ────────────────────────────────────
DECOR="$HOME/.config/hypr/UserConfigs/UserDecorations.lua"

cat > "$DECOR" << DECOR
-- D̷E̷D̷S̷E̷C̷ Decorations

-- General settings
hl.config({
    general = {
        border_size = 2,
        gaps_in = 4,
        gaps_out = 8,
        
        col = {
            active_border = { colors = {"rgba($(strip ${primary})cc)", "rgba($(strip ${primary_dim})cc)"}, angle = 135 },
            inactive_border = { colors = {"rgba($(strip ${primary})22)", "rgba($(strip ${primary_dim})22)"}, angle = 135 },
        },
    },
})

-- Decoration settings
hl.config({
    decoration = {
        rounding = 10,
        
        active_opacity = 1.0,
        inactive_opacity = 0.90,
        fullscreen_opacity = 1.0,
        
        dim_inactive = true,
        dim_strength = 0.12,
        dim_special = 0.8,
        
        shadow = {
            enabled = true,
            range = 10,
            render_power = 3,
            color = "rgba($(strip ${primary})30)",
            color_inactive = "rgba($(strip ${primary_dim})15)",
            offset = "0, 4",
        },
        
        blur = {
            enabled = true,
            size = 10,
            passes = 4,
            new_optimizations = true,
            xray = true,
            ignore_opacity = true,
            special = true,
            popups = true,
            noise = 0.015,
            contrast = 1.1,
            brightness = 0.8,
        },
    },
})

-- Group settings
hl.config({
    group = {
        col = {
            border_active = "rgba($(strip ${primary})cc)",
            border_inactive = "rgba($(strip ${primary_dim})33)",
        },
        
        groupbar = {
            col = {
                active = "rgba($(strip ${primary})cc)",
                inactive = "rgba($(strip ${primary_dim})33)",
            },
            enabled = true,
        },
    },
})
DECOR

# Also write .conf version (hyprland.conf still sources it)
DECOR_CONF="$HOME/.config/hypr/UserConfigs/UserDecorations.conf"

cat > "$DECOR_CONF" << DECORCONF
# D̷E̷D̷S̷E̷C̷ Decorations

general {
  border_size = 2
  gaps_in = 4
  gaps_out = 8

  col.active_border = rgba($(strip ${primary})cc) rgba($(strip ${primary_dim})cc) 135deg
  col.inactive_border = rgba($(strip ${primary})22) rgba($(strip ${primary_dim})22) 135deg
}

decoration {
  rounding = 10

  active_opacity = 1.0
  inactive_opacity = 0.90
  fullscreen_opacity = 1.0

  dim_inactive = true
  dim_strength = 0.12
  dim_special = 0.8

  shadow {
    enabled = true
    range = 15
    render_power = 3
    color = rgba($(strip ${primary})30)
    color_inactive = rgba($(strip ${primary_dim})15)
    offset = 0, 4
  }

  blur {
    enabled = true
    size = 10
    passes = 4
    new_optimizations = true
    xray = true
    ignore_opacity = true
    special = true
    popups = true
    noise = 0.015
    contrast = 1.1
    brightness = 0.8
  }
}

group {
  col.border_active = rgba($(strip ${primary})cc)
  col.border_inactive = rgba($(strip ${primary_dim})33)

  groupbar {
    col.active = rgba($(strip ${primary})cc)
    col.inactive = rgba($(strip ${primary_dim})33)
    enabled = true
  }
}
DECORCONF

# ── 5. Hyprland Wallust Colors ─────────────────────────────────
HYPR_COLORS="$HOME/.config/hypr/wallust/wallust-hyprland.conf"

cat > "$HYPR_COLORS" << HYPR
# D̷E̷D̷S̷E̷C̷ Hyprland Colors

\$background = rgb($(strip ${bg}))
\$foreground = rgb($(strip ${fg}))
\$color0 = rgb($(strip ${bg}))
\$color1 = rgb($(strip ${red}))
\$color2 = rgb($(strip ${primary}))
\$color3 = rgb($(strip ${yellow}))
\$color4 = rgb($(strip ${blue}))
\$color5 = rgb($(strip ${magenta}))
\$color6 = rgb($(strip ${cyan}))
\$color7 = rgb(cccccc)
\$color8 = rgb($(strip ${primary_dark}))
\$color9 = rgb($(strip ${coral}))
\$color10 = rgb($(strip ${teal}))
\$color11 = rgb($(strip ${amber}))
\$color12 = rgb($(strip ${indigo}))
\$color13 = rgb($(strip ${lavender}))
\$color14 = rgb($(strip ${fg}))
\$color15 = rgb(cccccc)
HYPR

# ── 6. Reload Everything ───────────────────────────────────────
hyprctl reload 2>/dev/null || true
killall waybar 2>/dev/null || true
sleep 0.5
waybar &>/dev/null &

echo "Palette applied!"
