pragma ComponentBehavior: Bound
import Quickshell
import QtQuick
import "./Layers" as Lay
import "./Widgets" as Wid

ShellRoot {
    Variants {
        model: Quickshell.screens
        Scope {
            id: scopeRoot
            required property ShellScreen modelData
            Wid.WallpaperEngine {
                modelData: scopeRoot.modelData
            }
        }
    }
    Lay.ClockHUD {}
    Lay.Notifications {}
}
