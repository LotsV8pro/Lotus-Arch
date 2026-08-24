pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

// LOTUS palette bridge: live-reads ~/.config/lotus-palette/colors.conf so
// preset switches recolor this shell too. Defaults are the LOTUS purple ramp.
Singleton {
    id: root

    property string primary: "#C4A8E2"
    property string accentDim: "#8C7AA6"
    property string background: "#141218"
    property string surface: "#1C1826"
    property string foreground: "#E8E2F2"
    property string foregroundDim: "#9C92AC"

    // theme hook (future art sets); lotus is the built-in identity
    property string shellTheme: "lotus"

    function parse(text) {
        if (!text)
            return;
        const lines = text.split("\n");
        for (let i = 0; i < lines.length; i++) {
            const idx = lines[i].indexOf("=");
            if (idx < 1)
                continue;
            const k = lines[i].slice(0, idx).trim();
            const v = lines[i].slice(idx + 1).trim();
            if (!v)
                continue;
            if (k === "primary")
                root.primary = v;
            else if (k === "primary_dim")
                root.accentDim = v;
            else if (k === "bg")
                root.background = v;
            else if (k === "bg_alt")
                root.surface = v;
            else if (k === "fg")
                root.foreground = v;
            else if (k === "fg_dim")
                root.foregroundDim = v;
            else if (k === "shell_theme")
                root.shellTheme = v;
        }
    }

    FileView {
        path: Quickshell.env("HOME") + "/.config/lotus-palette/colors.conf"
        watchChanges: true
        preload: true
        onFileChanged: reload()
        onLoaded: root.parse(text())
    }
}
