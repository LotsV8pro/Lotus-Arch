pragma Singleton

import qs.modules.common
import qs.modules.common.functions
import QtQuick
import Quickshell
import Quickshell.Io

/*
 * System updates service. Currently only supports Arch.
 */
Singleton {
    id: root

    property bool available: false
    property int count: 0
    
    readonly property bool updateAdvised: available && count > (Config.options?.updates?.adviseUpdateThreshold ?? 75)
    readonly property bool updateStronglyAdvised: available && count > (Config.options?.updates?.stronglyAdviseUpdateThreshold ?? 200)

    function load() {}
    function refresh() {
        if (!available) return;
        print("[Updates] Checking for system updates")
        checkUpdatesProc.running = true;
    }

    Timer {
        interval: (Config.options?.updates?.checkInterval ?? 120) * 60 * 1000
        repeat: true
        running: Config.ready
        onTriggered: {
            print("[Updates] Periodic update check due")
            root.refresh();
        }
    }

    Timer {
        id: availabilityDefer
        interval: 1500
        repeat: false
        onTriggered: checkAvailabilityProc.running = true
    }

    // Watch the pacman log so the counter refreshes instantly after any
    // package transaction completes (from this pill, a terminal, pamac, ...).
    // We poll the log's mtime because pacman.log is root-owned and Quickshell
    // has no inotify watcher; a 2s poll of a stat is cheap.
    property string pacmanLogPath: "/var/log/pacman.log"
    property string _lastLogMtime: ""
    property bool _firstCheck: true

    Timer {
        id: paclogPollTimer
        interval: 2000
        repeat: true
        running: root.available
        onTriggered: {
            checkLogStat.running = true
        }
    }

    Process {
        id: checkLogStat
        running: false
        command: ["stat", "-c", "%Y", root.pacmanLogPath]
        stdout: StdioCollector {
            onStreamFinished: {
                const m = (text ?? "").trim()
                if (m.length === 0) return
                if (!root._firstCheck && m !== root._lastLogMtime) {
                    print("[Updates] pacman log changed — rechecking")
                    checkRefreshDebounce.restart()
                }
                root._lastLogMtime = m
                root._firstCheck = false
            }
        }
    }

    Timer {
        id: checkRefreshDebounce
        interval: 3000
        repeat: false
        onTriggered: root.refresh()
    }

    Component.onCompleted: {
        // If Config is already ready when this singleton is created, start the check immediately
        if (Config.ready) availabilityDefer.start()
    }

    Connections {
        target: Config
        function onReadyChanged() {
            if (Config.ready) availabilityDefer.start()
        }
    }

    Process {
        id: checkAvailabilityProc
        running: false
        command: ["which", "checkupdates"]
        onExited: (exitCode, exitStatus) => {
            root.available = (exitCode === 0);
            root.refresh();
        }
    }

    Process {
        id: checkUpdatesProc
        command: ["checkupdates"]
        stdout: StdioCollector {
            onStreamFinished: {
                const t = (text ?? "").trim();
                root.count = t.length > 0 ? t.split("\n").length : 0;
            }
        }
        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0) {
                console.error("[Updates] checkupdates failed", exitCode, exitStatus)
            }
        }
    }
}
