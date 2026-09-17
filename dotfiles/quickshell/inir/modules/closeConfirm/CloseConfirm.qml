import QtQuick
import qs
import qs.services
import qs.modules.common
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland

Scope {
    id: root

    // Window captured at the moment of trigger (prevents race condition)
    property var targetWindow: null
    property var dialogScreen: null
    property bool dialogVisible: false

    // Debounce to prevent double-trigger
    property bool _busy: false
    Timer {
        id: debounce
        interval: 200
        onTriggered: root._busy = false
    }

    // Config state
    readonly property bool confirmEnabled: Config.options?.closeConfirm?.enabled ?? false

    // Get the currently focused window from the active compositor.
    readonly property bool isHyprland: CompositorService.isHyprland
    readonly property bool isNiri: CompositorService.isNiri

    function focusedWindowFromCompositor(): var {
        if (root.isHyprland && Hyprland.activeToplevel) {
            return {
                address: Hyprland.activeToplevel.address || "",
                app_id: Hyprland.activeToplevel.wayland?.appId || "",
                title: Hyprland.activeToplevel.title || ""
            };
        }
        if (root.isNiri) {
            return NiriService.activeWindow;
        }
        return null;
    }

    // Fallback: query the compositor directly when the cached window is stale.
    Process {
        id: focusedWindowProc
        command: [
            root.isHyprland ? "/usr/bin/hyprctl" : "niri",
            ...(root.isHyprland ? ["activewindow", "-j"] : ["msg", "-j", "focused-window"])
        ]
        stdout: StdioCollector {
            waitForEnd: true
            onDataChanged: {
                try {
                    const win = JSON.parse(data);
                    if (root.isHyprland ? (win?.address) : (win?.id))
                        root.processWindow(win);
                } catch (e) {}
            }
        }
    }

    function windowHasIdentity(win: var): bool {
        if (!win) return false;
        if (root.isHyprland) return (win?.address ?? "") !== "";
        return (win?.id ?? 0) > 0;
    }

    function processWindow(win): void {
        if (!root.windowHasIdentity(win) && !root.confirmEnabled)
            return;
        if (root.confirmEnabled && !root.windowHasIdentity(win)) {
            // For the dialog we need a displayable identity too.
            if (!(win?.title ?? ""))
                return;
        }
        if (root.confirmEnabled) {
            root.targetWindow = win;
            root.dialogScreen = GlobalStates.focusedScreen;
            root.dialogVisible = true;
        } else {
            root.closeWindowFast(win);
        }
    }

    function _acceptTrigger(): bool {
        if (root._busy)
            return false;
        root._busy = true;
        debounce.restart();
        return true;
    }

    IpcHandler {
        target: "closeConfirm"

        function trigger(): void {
            console.info("CloseConfirm: trigger received, isHyprland=" + root.isHyprland + " confirmEnabled=" + root.confirmEnabled);
            if (!root._acceptTrigger())
                return;

            // Try cached activeWindow first, fallback to compositor query
            const win = root.focusedWindowFromCompositor();
            console.info("CloseConfirm: focusedWindow=" + JSON.stringify(win) + " hasIdentity=" + root.windowHasIdentity(win));
            if (root.windowHasIdentity(win) || root.confirmEnabled) {
                root.processWindow(win);
            } else {
                console.info("CloseConfirm: falling back to process query");
                focusedWindowProc.running = true;
            }
        }

        function triggerWindow(windowId: int, appId: string): void {
            if (root.isHyprland) {
                // Under Hyprland we key windows by address, so the script sends
                // its own identity. Rely on the address-based IPC path instead.
                root.trigger();
                return;
            }
            if (windowId <= 0 || !root._acceptTrigger())
                return;
            root.processWindow({
                id: windowId,
                app_id: appId
            });
        }

        function triggerAddress(address: string, appId: string): void {
            if (root.isNiri) {
                root.trigger();
                return;
            }
            if (!address || address.length === 0 || !root._acceptTrigger())
                return;
            const win = {
                address: address,
                app_id: appId || "",
                title: ""
            };
            console.info("CloseConfirm: triggerAddress " + address + " (" + appId + ")");
            root.processWindow(win);
        }

        function close(): void {
            root.dialogVisible = false;
            root.targetWindow = null;
            root.dialogScreen = null;
        }
    }

    function closeWindowFast(win): void {
        if (!root.windowHasIdentity(win))
            return;
        const appId = String(win?.app_id ?? win?.class ?? "").toLowerCase();
        console.info("CloseConfirm: closeWindowFast appId=" + appId + " address=" + win.address);
        if (appId === "spotify") {
            if (root.isNiri)
                MinimizedWindows.minimize(win.id);
            else if (root.isHyprland)
                hyprctlMoveToWorkspaceSilent(win.address, 99);
            return;
        }
        if (root.isNiri) {
            // Use niri msg directly - more reliable than socket IPC for some apps
            Quickshell.execDetached(["niri", "msg", "action", "close-window", "--id", String(win.id)]);
        } else if (root.isHyprland) {
            // Hyprland 0.56+: dispatch via hyprctl eval with Lua syntax.
            const cmd = "hl.dispatch(hl.dsp.window.close({window = 'address:" + win.address + "'}))";
            console.info("CloseConfirm: hyprctl eval " + cmd);
            Quickshell.execDetached(["/usr/bin/hyprctl", "eval", cmd]);
        }
    }

    function hyprctlMoveToWorkspaceSilent(address: string, workspace: int): void {
        Quickshell.execDetached(["/usr/bin/hyprctl", "eval", "hl.dispatch(hl.dsp.window.move({workspace = " + String(workspace) + ", follow = false, window = 'address:" + address + "'}))"]);
    }

    function confirmClose(): void {
        if (targetWindow) {
            closeWindowFast(targetWindow);
        }
        dialogVisible = false;
        targetWindow = null;
        dialogScreen = null;
    }

    function cancel(): void {
        dialogVisible = false;
        targetWindow = null;
        dialogScreen = null;
    }

    // Dialog UI
    Loader {
        active: root.dialogVisible

        sourceComponent: PanelWindow {
            screen: root.dialogScreen ?? GlobalStates.focusedScreen

            anchors {
                top: true
                left: true
                right: true
                bottom: true
            }

            color: "transparent"
            WlrLayershell.namespace: "quickshell:closeConfirm"
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
            WlrLayershell.layer: WlrLayer.Overlay
            exclusionMode: ExclusionMode.Ignore

            Loader {
                id: contentLoader
                anchors.fill: parent
                focus: true
                // Both contents declare targetWindow as required, so they must be
                // instantiated from an inline Component. A Loader source URL cannot
                // initialize required properties and fails to Loader.Error, leaving
                // this keyboard-exclusive fullscreen window with no way out.
                sourceComponent: Config.options?.panelFamily === "waffle" ? waffleContent : iiContent
                onLoaded: if (item) item.forceActiveFocus()

                Component {
                    id: iiContent
                    CloseConfirmContent {
                        targetWindow: root.targetWindow
                        onConfirm: root.confirmClose()
                        onCancel: root.cancel()
                    }
                }

                Component {
                    id: waffleContent
                    WCloseConfirmContent {
                        targetWindow: root.targetWindow
                        onConfirm: root.confirmClose()
                        onCancel: root.cancel()
                    }
                }
            }
        }
    }
}